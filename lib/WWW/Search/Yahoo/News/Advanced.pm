
# $Id: Advanced.pm,v 1.11 2003-11-01 16:23:53-05 kingpin Exp kingpin $

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

=head1 TESTING

There are no tests defined for this module.

=head1 AUTHOR

C<WWW::Search::Yahoo::News::Advanced> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

If it''s not listed here, then it wasn''t a meaningful nor released revision.

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

$VERSION = '2.05';
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


sub preprocess_results_page
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


sub native_retrieve_some
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

sub lookfor
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


sub parse_tree_UNUSED
  {
  my $self = shift;
  my $tree = shift;
  my $hits_found = 0;
  my @aoFONTcount = $tree->look_down('_tag', 'font',
                                     'face' => 'arial',
                                     'size' => '-1',
                                    );
 FONTcount_TAG:
  foreach my $oFONT (@aoFONTcount)
    {
    my $s = $oFONT->as_text;
    print STDERR " + FONTcount == ", $oFONT->as_HTML if 2 <= $self->{_debug};
    # print STDERR " +   TEXT == ", $s, "\n" if 2 <= $self->{_debug};
    if ($s =~ m!\d+\s*-\s*\d+\s+of\s+(\d+)!)
      {
      my $iCount = $1;
      # print STDERR " +   found number $iCount\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($iCount);
      last FONTcount_TAG;
      } # if
    } # foreach FONT_TAG

  # Each URL result is in a <FONT size=-1> tag:
  # <font face="arial" size="-1"><a href="http://story.news.yahoo.com/news?tmpl=story&amp;u=/ap/20021030/ap_on_en_mo/neeson_royal_2">Neeson Nervous About Royal Honor</a></font> <font face="arial" size="-2">(AP)</font><br><font face="arial" size="-1"> ...&quot;<b>Star Wars</b>: Episode I: The Phantom Menace.... <br>- <small><i> Oct 30 7:09 AM ET </i></small> </font>
  my @aoFONT = $tree->look_down('_tag' => 'font',
                                'size' => '-1',
                               );
FONT_TAG:
  foreach my $oFONT (@aoFONT)
    {
    my $sPrice = '';
    printf STDERR "\n + FONT == %s", $oFONT->as_HTML if 2 <= $self->{_debug};
    my $oAtitle = $oFONT->look_down('_tag', 'a');
    next FONT_TAG unless ref($oAtitle);
    my $sURL = $oAtitle->attr('href');
    next FONT_TAG unless defined($sURL);
    next FONT_TAG unless ($sURL ne '');
    next FONT_TAG if $sURL =~ m!search\.yahoo\.com!;
    print STDERR " +   URL   == $sURL\n" if 2 <= $self->{_debug};
    # In order to make it easier to parse, make sure everything is an object!
    $oFONT->parent->objectify_text;
    # Siblings contain more info.
    my @aoSib = $oFONT->right;
    # Next tag contains source:
    my $oFONTsource = &skip_text_elements(\@aoSib);
    # Bail if there are no more siblings:
    next FONT_TAG unless ref($oFONTsource);
    # Look for price of premium article:
    if (defined($oFONTsource->attr('color')) && ($oFONTsource->attr('color') eq 'red'))
      {
      $oFONTsource->deobjectify_text;
      $sPrice = $oFONTsource->as_text;
      printf STDERR " +   FONTprice == %s", $oFONTsource->as_HTML if 2 <= $self->{_debug};
      $oFONTsource = &skip_text_elements(\@aoSib);
      } # if
    printf STDERR " +   FONTsource == %s", $oFONTsource->as_HTML if 2 <= $self->{_debug};
    my $oBR = &skip_text_elements(\@aoSib);
    next FONT_TAG unless ref($oBR);
    printf STDERR " +   BR == %s", $oBR->as_HTML if 2 <= $self->{_debug};
    my $oFONTdesc = &skip_text_elements(\@aoSib);
    next FONT_TAG unless ref($oFONTdesc);
    printf STDERR " +   FONTdesc == %s", $oFONTdesc->as_HTML if 2 <= $self->{_debug};

    # The only <i> tag contains the date...
    my $oI = $oFONTdesc->look_down('_tag', 'i');
    # ...and we only need to look at <P> which contains a date:
    next FONT_TAG unless ref($oI);
    printf STDERR " +   I == %s", $oI->as_HTML if 2 <= $self->{_debug};
    $oI->deobjectify_text;
    my $sDate = $oI->as_text;
    # delete this <I> tag so the description is easy to get:
    $oI->detach;
    $oI->delete;

    # The (remaining) text of the P is the description:
    $oFONTdesc->deobjectify_text;
    my $sDesc = &strip_tags($oFONTdesc->as_text);
    # Delete junk off end of description:
    $sDesc =~ s!\s+-\s+\Z!!;
    # Add price if present:
    $sDesc .= qq{ [$sPrice]} if ($sPrice ne '');
    print STDERR " +   DESC  == $sDesc\n" if 2 <= $self->{_debug};
    $oAtitle->deobjectify_text;
    my $sTitle = $oAtitle->as_text;
    print STDERR " +   TITLE == $sTitle\n" if 2 <= $self->{_debug};
    my $hit = new WWW::Search::Result;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    # Delete this <FONT> (to make it quicker to find the "Next" link)
    $oFONT->detach;
    $oFONT->delete;
    } # foreach oFONT

  $tree->deobjectify_text;
  # The "next" link is a plain old <A>:
  my @aoA = $tree->look_down('_tag', 'a');
A_TAG:
  foreach my $oA (@aoA)
    {
    printf STDERR " + A == %s\n", $oA->as_HTML if 2 <= $self->{_debug};
    # <a href="http://search.news.yahoo.com/search/news?p=Japan&amp;b=21"><b>Next 20 &gt;</b></a>
    if ($oA->as_text =~ m!Next\s+\d+!i)
      {
      $self->{_next_url} = $HTTP::URI_CLASS->new_abs($oA->attr('href'), $self->{'_prev_url'});
      last A_TAG;
      } # if
    } # foreach $oA
  $tree->delete;
  return $hits_found;
  } # parse_tree


sub skip_text_elements
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

as of 2003-10:

http://search.news.yahoo.com/search/news/?adv=1&p=Wakayama&ei=UTF-8&c=news&o=a&s=&n=100&2=&3=

older version:

http://search.news.yahoo.com/search/news?p=george+lucas&s=&n=10&o=&2=&3=05/05/01-05/15/01

Actual pre-processed result:

<a href="http://story.news.yahoo.com/news?tmpl=story&u=/ap/20030522/ap_on_re_as/everest_50th_anniversary_11">
Dozens Head to Mount Everest's Summit
</a>
<a href="http://story.news.yahoo.com/news?tmpl=story&u=/ap/20030522/ap_on_re_as/everest_50th_anniversary_11" target=awindow>
<img src="http://us.i1.yimg.com/us.yimg.com/i/us/search/bn/newwin_1.gif" height="11" width="11" border="0" align="middle" vspace="1" hspace="4" alt="Open this result in new window">
</a>
<br>
<div class= timedate >
<span class=provtimedate>
 AP  - 
</span>
 May 22  9:25 AM 
</div>
...Miura, a native of the northern Japanese city of Aomori, began his skiing career in 1962 and won acclaim eight years later by becoming the first person...
<br>
In 
<a href="http://news.yahoo.com/">
Yahoo! News
</a>
 > 
<a href="http://news.yahoo.com/news?tmpl=index2&cid=721">
World
</a>
 > 
<a href="http://news.yahoo.com/news?tmpl=index2&cid=516">
AP
</a>
<br>
<p>
