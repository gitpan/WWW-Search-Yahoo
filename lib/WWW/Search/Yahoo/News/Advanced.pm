
# $Id: Advanced.pm,v 1.2 2001/07/16 15:15:14 mthurn Exp mthurn $

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

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 TESTING

There are no tests defined for this module.

=head1 AUTHOR

C<WWW::Search::Yahoo::News::Advanced> is maintained by Martin Thurn
(MartinThurn@iname.com).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

If it''s not listed here, then it wasn''t a meaningful nor released revision.

=head2 2.01, 2001-07-16

First public release.

=cut

#####################################################################

package WWW::Search::Yahoo::News::Advanced;

use Data::Dumper;  # for debugging only
use Date::Manip;
use WWW::Search qw( strip_tags );
use WWW::Search::Yahoo;

use strict;
use vars qw( @ISA $VERSION $MAINTAINER );
@ISA = qw( WWW::Search::Yahoo );

$VERSION = '2.01';
$MAINTAINER = 'Martin Thurn <MartinThurn@iname.com>';

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # print STDERR " +   in UK::native_setup_search, rh is ", Dumper($rh);
  my $sDateFrom = $self->date_from || '';
  my $sDateTo = $self->date_to || '';
  if ($sDateFrom ne '')
    {
    # User specified the beginning date.
    $sDateFrom = &UnixDate(&ParseDate($sDateFrom), '%m/%d/%y');
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
    }
  else
    {
    # User did not specify the ending date.  Set it to the future:
    $sDateTo = &UnixDate(&ParseDate('tomorrow'), '%m/%d/%y');
    }
  $self->{'_options'} = {
                         'p' => $sQuery,
                         'n' => 100,  # 10 for testing, 100 for release
                         '3' => "$sDateFrom-$sDateTo",
                        };
  $rh->{'search_base_url'} = 'http://search.news.yahoo.com';
  $rh->{'search_base_path'} = '/search/news';
  # print STDERR " +   Yahoo::UK::native_setup_search() is calling SUPER::native_setup_search()...\n";
  return $self->SUPER::native_setup_search($sQuery, $rh);
  } # native_setup_search


sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $hits_found = 0;
  # The hit count is inside a <CENTER> tag...
  my @aoCENTER = $tree->look_down('_tag', 'center');
 CENTER_TAG:
  foreach my $oCENTER (@aoCENTER)
    {
    next unless ref $oCENTER;
    # ...inside a FONT tag with size=-1:
    my @aoFONT = $tree->look_down('_tag', 'font',
                                  'size' => '-1',
                                 );
 FONT_TAG:
    foreach my $oFONT (@aoFONT)
      {
      my $s = $oFONT->as_text;
      print STDERR " + FONT == ", $oFONT->as_HTML if 2 <= $self->{_debug};
      # print STDERR " +   TEXT == ", $s, "\n" if 2 <= $self->{_debug};
      if ($s =~ m!\d+\s+-\s+\d+\s+of\s+(\d+)!)
        {
        my $iCount = $1;
        # print STDERR " +   found number $iCount\n" if 2 <= $self->{_debug};
        $self->approximate_result_count($iCount);
        last FONT_TAG;
        } # if
    } # foreach FONT_TAG
  } # foreach CENTER_TAG

  # Each URL result is in a <P> tag:
  my @aoP = $tree->look_down('_tag', 'p');
P_TAG:
  foreach my $oP (@aoP)
    {
    printf STDERR " + P == %s\n", $oP->as_HTML if 2 <= $self->{_debug};
    # The only <i> tag contains the date...
    my $oI = $oP->look_down('_tag', 'i');
    # ...and we only need to look at <P> which contains a date:
    next P_TAG unless ref($oI);
    printf STDERR " +   I == %s\n", $oI->as_HTML if 2 <= $self->{_debug};
    my $sDate = $oI->as_text;
    # delete this <I> tag so the description is easy to get:
    $oI->detach;
    $oI->delete;
    my $oA = $oP->look_down('_tag', 'a');
    next P_TAG unless ref($oA);
    my $sTitle = $oA->as_text;
    print STDERR " +   TITLE == $sTitle\n" if 2 <= $self->{_debug};
    my $sURL = $oA->attr('href');
    # Delete this <A> so it doesn't get added to the description:
    $oA->detach;
    $oA->delete;
    print STDERR " +   URL   == $sURL\n" if 2 <= $self->{_debug};

    # The (remaining) text of the P is the description:
    my $sDesc = &strip_tags($oP->as_text);
    print STDERR " +   DESC  == $sDesc\n" if 2 <= $self->{_debug};
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    # Delete this <P> (to make it quicker to find the "Next" link)
    $oP->detach;
    $oP->delete;
    } # foreach oP

  # The "next" link is a plain old <A>:
  my @aoA = $tree->look_down('_tag', 'a');
A_TAG:
  foreach my $oA (@aoA)
    {
    printf STDERR " + A == %s\n", $oA->as_HTML if 2 <= $self->{_debug};
    if ($oA->as_text =~ m!Next\s+\d+\s+Matches!i)
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

http://search.news.yahoo.com/search/news?p=george+lucas&s=&n=10&o=&2=&3=05/05/01-05/15/01
