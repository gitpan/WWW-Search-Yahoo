
# $Id: Advanced.pm,v 2.7 2004/03/29 01:39:43 Daddy Exp Daddy $

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

=head1 VERSION HISTORY

If it''s not listed here, then it wasn''t a meaningful nor released revision.

=head2 2.007, 2004-03-27

overhaul for new webpage format

=head2 2.05, 2003-05-30

overhaul for new webpage format

=head2 2.04, 2002-10-31

overhaul for new webpage format

=head2 2.01, 2001-07-16

First public release.

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
$VERSION = do { my @r = (q$Revision: 2.7 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
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


sub preprocess_results_page_UNUSED
  {
  my $self = shift;
  my $s = shift;
  print STDERR " + News::Advanced::preprocess()\n" if $self->{_debug};
  # Remove all carriage-returns:
  $s =~ tr!\r\n!!d;
  # Convert nbsp to plain space:
  $s =~ s!&nbsp;! !g;
  # Delete bold tags which appear around the query terms in the descriptions:
  $s =~ s!</?b>!!gi;
  # Insert carriage-return before every HTML tag:
  $s =~ s!(</?\w)!\n$1!g;
  # Insert carriage-return after every HTML tag:
  $s =~ s!(\S>)!$1\n!g;
  # Delete blank lines:
  $s =~ s!\n\s*\n!\n!g;
  $s =~ s!\n\s*\n!\n!g;
  if (0)
    {
    print STDERR $s;
    # exit 9;
    } # if
  return $s;
  } # preprocess_results_page


sub native_retrieve_some_UNUSED
  {
  my $self = shift;
  # printf STDERR (" +   %s::native_retrieve_some()\n", __PACKAGE__) if $self->{_debug};
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));
  # If this is not the first page of results, sleep so as to not overload the server:
  $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
  # Get one page of results:
  print STDERR " +   submitting URL (", $self->{'_next_url'}, ")\n" if $self->{_debug};
  my $response = $self->http_request($self->http_method, $self->{'_next_url'});
  print STDERR " +     got response\n", $response->headers->as_string, "\n" if 2 <= $self->{_debug};
  $self->{_prev_url} = $self->{_next_url};
  # Assume there are no more results, unless we find out otherwise
  # when we parse the html:
  $self->{_next_url} = undef;
  $self->{response} = $response;
  print STDERR " --- HTTP response is:\n", $response->as_string if 4 < $self->{_debug};
  if (! $response->is_success)
    {
    if ($self->{_debug})
      {
      print STDERR " --- HTTP request failed, response is:\n", $response->as_string;
      } # if
    return undef;
    } # if
  # Pre-process the output:
  my $sPage = $self->preprocess_results_page($response->content);
  # ABOVE WAS COPIED FROM WWW::Search::native_retrieve_some()
  print STDERR " +   cooked results page ==========$sPage==========\n" if (5 < $self->{_debug});
  # Parse the output:
  my $hits_found = 0;
  my @asLine = $self->split_lines($sPage);
  chomp @asLine;
 LINE:
  while (defined(my $sLine = shift @asLine))
    {
    if (($self->approximate_result_count == 0)
        &&
        ($sLine =~ m!\A\s*\d+\s*-\s*\d+\s+(?:out\s+)?of\s+(\d+)!))
      {
      my $iCount = $1;
      print STDERR " +   found number $iCount\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($iCount);
      my $sLine = shift @asLine;
      $self->{_next_url} = $1 if ($sLine =~ m!<a href="(.+search\.news\.yahoo\.com.+)">!);
      next LINE;
      } # if
    next LINE unless (
                      ($sLine =~ m!<a href="(.+tmpl=story.+)">!)
                      ||
                      ($sLine =~ m!<a href="(.+moreover\.com/click/here.+)">!)
                      ||
                      ($sLine =~ m!<a href="(.+biz\.yahoo\.com.+)">!)
                     );
    my $sURL = $1;
    print STDERR " +   found url ==$sURL==\n" if 2 <= $self->{_debug};
    my $sTitle = shift @asLine;
    $sTitle = &WWW::Search::strip_tags(shift @asLine);
    next LINE unless ($sTitle ne '');
    print STDERR " +   found title ==$sTitle==\n" if 2 <= $self->{_debug};
    my $sDate = '';
    if ($self->lookfor('</u>', \@asLine))
      {
      $sDate = shift @asLine;
      } # if
    print STDERR " +   found raw date ==$sDate==\n" if 2 <= $self->{_debug};
    $sDate =~ s!\s*-\s+!!;
    print STDERR " +   cooked    date ==$sDate==\n" if 2 <= $self->{_debug};
    my $sDesc = shift @asLine;
    $sDesc = shift @asLine;
    print STDERR " +   found description ==$sDesc==\n" if 2 <= $self->{_debug};
    my $hit = new WWW::Search::Result;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach
  return $hits_found;
  } # native_retrieve_some

sub lookfor_UNUSED
  {
  my $self = shift;
  my ($sPattern, $ras) = @_;
  while (defined(my $s = shift @$ras))
    {
    return $s if ($s =~ m!$sPattern!);
    } # while
  # Ran off end of array?
  return undef;
  } # lookfor


sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $hits_found = 0;
  my @aoFONTcount = $tree->look_down('_tag', 'small',
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
                             'class' => 'rt',
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


sub skip_text_elements_UNUSED
  {
  my $ra = shift;
  my $o;
  # print STDERR " +     skip_text_elements\n";
  while (1)
    {
    $o = shift(@$ra);
    # Bail if we run out of arguments:
    last unless ref($o);
    # print STDERR (" +     consider o==%s", $o->as_HTML);
    # All done if we get something not text:
    last if ($o->tag ne '~text');
    } # while
  return $o;
  } # skip_text_elements

1;

__END__
