# $Id: News.pm,v 1.3 2001/09/21 13:55:51 mthurn Exp $

=head1 NAME

WWW::Search::Yahoo::Japan::News - class for searching News on Yahoo Japan (in Japanese)

=head1 SYNOPSIS

  use Jcode;
  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::Japan::News');
  my $sQuery = WWW::Search::escape_query(Jcode->new("料理の鉄人")->euc);
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo Japan News specialization of L<WWW::Search>.  It
handles making and interpreting searches of Yahoo News in Japanese
F<http://headlines.yahoo.co.jp>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Query string must be in EUC encoding, and then escaped with
WWW::Search::escape_query().

If you have multiple query terms, put an ASCII space character in
between all of them.

Yahoo Japan does an AND of all query terms.
There is no way to change this.

In the results, description will be in EUC encoding (I think).

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 TESTING

This module adheres to the C<WWW::Search> test suite mechanism.

=head1 AUTHOR

Martin Thurn (mthurn@tasc.com).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

If it''s not listed here, then it wasn''t a meaningful nor released revision.

=head2 2.02, 2001-09-13

bugfix, apparently 2.01 could not load at all!?!

=head2 2.01, 2001-09-07

First release.

=cut

package WWW::Search::Yahoo::Japan::News;

@ISA = qw( WWW::Search WWW::Search::Yahoo );

$VERSION = '2.02';
$MAINTAINER = 'Martin Thurn <mthurn@tasc.com>';

use WWW::Search qw( strip_tags );
use WWW::SearchResult;
use WWW::Search::Yahoo;

sub native_setup_search
  {
  my ($self, $sQuery) = (shift, shift);
  $self->{'_options'} = {
                         'p' => $sQuery,
                        };
  return WWW::Search::Yahoo::native_setup_search($self, $sQuery,
                                            {
                                             'search_base_url' => 'http://nsearch.yahoo.co.jp',
                                             'search_base_path' => '/bin/nsearch',
                                            },
                                          @_);
  } # native_setup_search

# sub native_retrieve_some() is inherited from WWW::Search::Yahoo

# When I ran queries with Netscape, yahoo gave me EUC encoding.  So
# that's what I use in the regexen below.  Thanks to Emacs 20.7, I can
# just type it right in the code!

sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $hits_found = 0;
  # The hit count is in a <center> tag:
  my @aoCENTER = $tree->look_down('_tag', 'center');
 CENTER_TAG:
  foreach my $oCENTER (@aoCENTER)
    {
    next unless ref $oCENTER;
    my $sCenter = $oCENTER->as_text;
    if ($sCenter =~ m!\241\312(\d+)件中!)
      {
      my $iCount = $1;
      $self->approximate_result_count($iCount);
      print STDERR " +   num results = $iCount\n" if $self->{_debug};
      } # if
    elsif ($sCenter =~ m!次の\d+件を表示!)
      {
      my $oA = $oCENTER->look_down('_tag', 'a');
      if (ref $oA)
        {
        $self->{_next_url} = $oA->attr('href');
        } # if
      } # else
    } # foreach
  # Each result is in a <P>, but HTML::Parser can not parse those <P>s
  # because the first one is mal-formed (contains a <BASE> tag which
  # is not legal inside a <P>).  So, just look for <A> with a <SMALL>
  # sibling.
  my @aoA = $tree->look_down('_tag', 'a');
 A_TAG:
  foreach my $oA (@aoA)
    {
    next A_TAG unless ref $oA;
    if (2 <= $self->{_debug})
      {
      my $s = $oA->as_HTML;
      print STDERR " +   A ===$s===\n";
      } # if debug
    # Result <A> must have a <SMALL> sibling with a <BR> in between:
    my $oBR = $oA->right;
    next A_TAG unless ref $oBR;
    my $oSMALL = $oBR->right;
    next A_TAG unless ref $oSMALL;
    if (2 <= $self->{_debug})
      {
      my $s = $oSMALL->as_HTML;
      print STDERR " +   SMALL ===$s===\n\n";
      } # if debug
    my $sURL = $oA->attr('href') || '';
    next A_TAG unless $sURL ne '';
    my $sTitle = $oA->as_text;
    my $sDesc = &strip_tags($oSMALL->as_text);
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach
  print STDERR " +   found $hits_found results on this page\n" if $self->{_debug};
  return $hits_found;
  } # parse_tree

1;

__END__
