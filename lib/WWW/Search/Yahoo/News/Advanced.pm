
# $Id: Advanced.pm,v 2.53 2004/09/11 22:30:10 Daddy Exp $

=head1 NAME

WWW::Search::Yahoo::News::Advanced - class for searching Yahoo! News
using the "advanced" interface

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::News::Advanced');
  my $sQuery = WWW::Search::escape_query("George Lucas");
  $oSearch->date_from('2001-05-05');
  $oSearch->date_to(  '2001-07-05');
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo! News specialization of L<WWW::Search>.  It
handles making and interpreting searches on Yahoo! News
F<http://search.news.yahoo.com> using the Advanced search interface.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

This backend supports narrowing the search by date-range.
Use date_from() and date_to() to set the endpoints of the desired date range.
You can use any date format supported by the Date::Manip module.

If either date endpoint is not set explicitly,
it will search with an appropriately open-ended date range.

NOTE that Yahoo only keeps the last 90 days worth of news in its index.

ALSO NOTE that Yahoo will return an ERROR if date_from() is set to
anything prior to Jan. 1 1999.  This backend does NOT check for that.

News.yahoo.com dies if the unescaped query is longer than 485
characters or so.  This backend does NOT check for that.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 AUTHOR

C<WWW::Search::Yahoo::News::Advanced> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Yahoo::News::Advanced;

use Data::Dumper;  # for debugging only
use Date::Manip;
use WWW::Search qw( strip_tags );
use WWW::Search::Result;
use WWW::Search::Yahoo;

use strict;
use vars qw( @ISA $VERSION $MAINTAINER );
@ISA = qw( WWW::Search::Yahoo );
$VERSION = do { my @r = (q$Revision: 2.53 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # print STDERR " +   in UK::native_setup_search, rh is ", Dumper($rh);
  my $sDateFrom = $self->date_from || '';
  my $sDateTo = $self->date_to || '';
  my $iUseDate = 0;
  if ($sDateFrom ne '')
    {
    # User specified the beginning date.
    $sDateFrom = &UnixDate(&ParseDate($sDateFrom), '%m/%d/%y');
    $iUseDate = 1;
    }
  else
    {
    # User did not specify the beginning date.  Set it to the distant
    # past.  Yahoo.com barfs if it gets a date earlier than 1999,
    # though.
    $sDateFrom = &UnixDate(&ParseDate('1999-01-01'), '%m/%d/%y');
    }
  if ($sDateTo ne '')
    {
    # User specified the ending date.
    $sDateTo = &UnixDate(&ParseDate($sDateTo), '%m/%d/%y');
    $iUseDate = 1;
    }
  else
    {
    # User did not specify the ending date.  Set it to the future:
    $sDateTo = &UnixDate(&ParseDate('tomorrow'), '%m/%d/%y');
    }
  $self->{'_options'} = {
                         'adv' => 1,
                         # '1' => '', # this if for selecting sources
                         # '2' => '', # this is number of days to search
                         'c' => 'news',
                         # 'cat' => '', # this is for selecting category
                         'ei' => 'UTF-8',
                         'n' => 100,  # 10 for testing, 100 for release
                         'o' => 'o',  # OR of all words
                         'p' => $sQuery,
                         # I want to sort by descending relevance, but
                         # yahoo.com is broken.  the 's' parameter in
                         # the URL has no meaningful effect.

                         # 's' => '-s',  # sort order
                        };
  if ($iUseDate)
    {
    $self->{'_options'}->{'3'} = qq{$sDateFrom-$sDateTo};
    } # if

  $rh->{'search_base_url'} = 'http://search.news.yahoo.com';
  $rh->{'search_base_path'} = '/search/news/';
  # print STDERR " +   Yahoo::UK::native_setup_search() is calling SUPER::native_setup_search()...\n";
  return $self->SUPER::native_setup_search($sQuery, $rh);
  } # native_setup_search


sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $hits_found = 0;
  my @aoFONTcount = $tree->look_down('_tag', 'div',
                                     'class' => 'yschhd',
                                    );
 FONTcount_TAG:
  foreach my $oFONT (@aoFONTcount)
    {
    my $s = $oFONT->as_text;
    print STDERR " + FONTcount == ", $oFONT->as_HTML if 2 <= $self->{_debug};
    # print STDERR " +   TEXT == ", $s, "\n" if 2 <= $self->{_debug};
    if ($s =~ m!\d+\s*-\s*\d+\s+of\s+(?:about\s+)?(\d+)!)
      {
      my $iCount = $1;
      # print STDERR " +   found number $iCount\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($iCount);
      last FONTcount_TAG;
      } # if
    } # foreach FONT_TAG

  my @aoA = $tree->look_down('_tag' => 'a',
                             'class' => 'yschttl',
                            );
A_TAG:
  foreach my $oA (@aoA)
    {
    printf STDERR "\n + A == %s", $oA->as_HTML if 2 <= $self->{_debug};
    my $sMouseOver = $oA->attr('onmouseover');
    next A_TAG unless ($sMouseOver =~ m!window\.status='(.+)'!);
    my $sURL = $1;
    next A_TAG unless defined($sURL);
    next A_TAG unless ($sURL ne '');
    print STDERR " +   URL   == $sURL\n" if 2 <= $self->{_debug};
    my $sTitle = $oA->as_text;
    print STDERR " +   TITLE == $sTitle\n" if 2 <= $self->{_debug};
    # In order to make it easier to parse, make sure everything is an object!
    my $oLI = $oA->parent;
    next A_TAG unless ref($oLI);
    $oA->detach;
    $oA->delete;
    my $oEM = $oLI->look_down('_tag' => 'em');
    next A_TAG unless ref($oEM);
    my $sEM = $oEM->as_text;
    my ($sSource, $sDate) = split(/[\s\240]-[\s\240]/, $sEM);
    $oEM->detach;
    $oEM->delete;
    # The (remaining) text of the LI is the description:
    my $sDesc = &strip_tags($oLI->as_text);
    print STDERR " +   DESC  == $sDesc\n" if 2 <= $self->{_debug};
    my $hit = new WWW::Search::Result;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach oFONT

  # The "next" link is a plain old <A>:
  @aoA = $tree->look_down('_tag', 'a');
A_TAG:
  foreach my $oA (@aoA)
    {
    printf STDERR " + A == %s\n", $oA->as_HTML if 2 <= $self->{_debug};
    # <a href="http://search.news.yahoo.com/search/news?p=Japan&amp;b=21"><b>Next 20 &gt;</b></a>
    if ($oA->as_text eq 'Next')
      {
      $self->{_next_url} = $HTTP::URI_CLASS->new_abs($oA->attr('href'), $self->{'_prev_url'});
      last A_TAG;
      } # if
    } # foreach $oA
  $tree->delete;
  return $hits_found;
  } # parse_tree


1;

__END__
