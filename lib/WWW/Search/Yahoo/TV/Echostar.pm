# $Id: Echostar.pm,v 1.9 2003/12/30 04:03:06 Daddy Exp $

=head1 NAME

WWW::Search::Yahoo::TV::Echostar - backend for searching tv.yahoo.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::TV::Echostar');
  my $sQuery = WWW::Search::escape_query("Bai Ling");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo specialization of L<WWW::Search>.  It handles
making and interpreting Yahoo TV searches F<http://tv.yahoo.com>.

=head1 NOTES

This backend does a basic keyword search against the Echostar (Dish
Network) East Coast channel lineup.  The query is a set of words
(phrase searching is not supported at tv.yahoo.com).  By default, the
query terms are ORed and applied to all available fields (title,
subtitle, description, and cast/crew).  See below for how to do
Advanced search on these fields individually.

=head1 METHODS

In addition to the following special method(s), this class exports the
entire L<WWW::Search> interface.

=cut

package WWW::Search::Yahoo::TV::Echostar;

use Carp ();
use Data::Dumper;  # for debugging only
use Date::Manip;
use HTML::TreeBuilder;
use WWW::Search qw( generic_option strip_tags );
use WWW::Search::Result;

use strict;

use vars qw( @ISA $VERSION $MAINTAINER );

@ISA = qw( WWW::Search );
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/o);
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

use constant DEBUG_SETUP => 0;

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  print STDERR (" + Yahoo::TV::native_setup_search(), incoming rhOptsArg is ", Dumper($rhOptsArg)) if DEBUG_SETUP;
  $self->{'_hits_per_page'} = 100;
  $self->{'_hits_per_page'} = 10 if DEBUG_SETUP;

  # www.yahoo.com refuses robots.
  $self->user_agent('non-robot');
  # We don't care what the time zone really is:
  &Date_Init(q{TZ=-0500});

  $self->{_next_to_retrieve} = 1;

  $self->{'search_base_url'} ||= 'http://search.tv.yahoo.com';
  $self->{'search_base_path'} ||= '/search/tv';
  if (! defined($self->{'_options'}))
    {
    # We do not clobber the existing _options hash, if there is one;
    # e.g. if gui_search() was already called on this object
    $self->{'_options'} = {
                           'title' => $native_query,
                           'type' => 'n',
                           'lineup' => 'us_ECHOST1',
                           'search' => 'true',
                           '.intl' => 'us',
                           # How many days ahead to search:
                           'range' => 7,
                          };
    } # if
  my $rhOptions = $self->{'_options'};
  if (defined($rhOptsArg))
    {
    # Copy in new options, promoting special ones:
    while (my ($key, $val) = each %$rhOptsArg)
      {
      print STDERR " +   inspecting option $key..." if DEBUG_SETUP;
      if (WWW::Search::generic_option($key))
        {
        print STDERR "promote & delete\n" if DEBUG_SETUP;
        $self->{$key} = $val if defined($val);
        delete $rhOptsArg->{$key};
        }
      else
        {
        print STDERR "copy\n" if DEBUG_SETUP;
        if (($key eq 'search') && ($val eq 'adv'))
          {
          # User has requested Advanced Search.
          $self->{_allow_empty_query} = 1;
          } # if
        $rhOptions->{$key} = $val if defined($val);
        }
      } # foreach
    print STDERR (" + resulting rhOptsArg is ", Dumper($rhOptsArg)) if DEBUG_SETUP;
    } # if
  # Finally, figure out the url.
  $self->{'_next_url'} = $self->{'search_base_url'} . $self->{'search_base_path'} .'?'. $self->hash_to_cgi_string($rhOptions);

  $self->{_debug} = $self->{'search_debug'} || 0;
  $self->{_debug} = 2 if ($self->{'search_parse_debug'});
  } # native_setup_search


=head2 ignore_channels(@)

The arguments are a list of TV channels
(by the 3- to 6-letter abbreviation used on Yahoo.com).
URLs for TV programs on any of these channels will not be returned.
(But note that approximate_result_count() will still count them!)

For example, if you do not subscribe to HBO, and you don't care about
network shows on the West Coast, do something like the following
anytime before calling results() or next_result() or the like:

  $oSearch->ignore_channels(qw( HBO HBOW HBO2E HBO2W KABC KCBS KNBC ));

=cut

sub ignore_channels
  {
  my $self = shift;
  foreach my $sChannel (@_)
    {
    $self->{_ignore_channel}->{$sChannel} = 1;
    } # foreach
  } # ignore_channels


sub preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  print STDERR qq{=========$sPage=========} if (2 <= $self->{_debug});
  return $sPage;
  } # preprocess_results_page


sub parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  my $iHits = 0;
  my $today = &ParseDate('today');
  my @aoFONT = $oTree->look_down('_tag' => 'font');
 FONT_TAG:
  foreach my $oFONT (@aoFONT)
    {
    next unless $oFONT;
    next unless ref $oFONT;
    my $sFONT = $oFONT->as_text;
    print STDERR " + for count, try FONT ==$sFONT==\n" if (2 <= $self->{_debug});
    if ($sFONT =~ m!\bfound\s+(\d+)\s+match(?:es)?\b!i)
      {
      print STDERR " +   for count, matched $1\n" if (2 <= $self->{_debug});
      $self->approximate_hit_count($1);
      last FONT_TAG;
      } # if
    } # foreach
  if ($self->approximate_hit_count <= 0)
    {
    # Still need to find result count.  Maybe this was an Advanced
    # search:
    my @aoTABLE = $oTree->look_down(
                                    '_tag' => 'table',
                                    'width' => 440,
                                   );
 TABLE_TAG:
    foreach my $oTABLE (@aoTABLE)
      {
      next unless $oTABLE;
      next unless ref $oTABLE;
      my $sTABLE = $oTABLE->as_text;
      print STDERR " + for count, try TABLE ==$sTABLE==\n" if (2 <= $self->{_debug});
      if ($oTABLE->as_text =~ m!\s*--\s+Found\s+(\d+)\s+matches\b!i)
        {
        print STDERR " +   for count, matched $1\n" if (2 <= $self->{_debug});
        $self->approximate_hit_count($1);
        last TABLE_TAG;
        } # if
      } # foreach TABLE_TAG
    } # if
  my @aoA = $oTree->look_down('_tag' => 'a');
  A_TAG:
  foreach my $oA (@aoA)
    {
    my $sURL = $oA->attr('href');
    print STDERR " +   raw    URL ==$sURL==\n" if (2 <= $self->{_debug});
    $sURL =~ tr!\r\n!!d;
    print STDERR " +   cooked URL ==$sURL==\n" if (2 <= $self->{_debug});
    if ($sURL =~ m!/tvtitlesearch!)
      {
      # This is the NEXT link.  There are no PREV links, so we don't
      # have to look any more carefully at it!
      $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $sURL);
      next A_TAG;
      } # if
    if ($sURL =~ m!/tvpdb!)
      {
      my $sTitle = $oA->as_text;
      my @aoRight = $oA->right;
 SMALL_TAG:
      foreach my $oSMALL (@aoRight)
        {
        next SMALL_TAG unless defined($oSMALL);
        next SMALL_TAG unless ref($oSMALL);
        if ($oSMALL->tag eq 'small')
          {
          my $sSMALL = $oSMALL->as_text;
          print STDERR " +   raw    SMALL ==", $oSMALL->as_HTML, "==\n" if (2 <= $self->{_debug});
          print STDERR " +   cooked SMALL ==$sSMALL==\n" if (2 <= $self->{_debug});
          my ($sEpisode, $sChannel,
              $sDTG) = $sSMALL =~ m!(?:"(.+)"\s+)?([A-Z0-9]+),\s+(.+)\Z!;
          $sEpisode ||= '';
          print STDERR " +   episode==$sEpisode==\n" if (2 <= $self->{_debug});
          print STDERR " +   channel==$sChannel==\n" if (2 <= $self->{_debug});
          next SMALL_TAG if exists($self->{_ignore_channel}->{$sChannel});
          print STDERR " +   raw    dtg=$sDTG==\n" if (2 <= $self->{_debug});
          # Yahoo does not put the year on the dtg.  Without a year,
          # Date::Manip defaults to the same year as today.
          # Date::Manip barfs if the day-of-week does not agree with
          # the rest of the date-string.  Therefore, we delete the
          # day-of-week, and add an explicit year:
          substr($sDTG, 0, 3) = '';
          my $date = &ParseDate($sDTG);
          print STDERR " +    date=$date==\n" if (2 <= $self->{_debug});
          print STDERR " +   today=$today==\n" if (2 <= $self->{_debug});
          if (&Date_Cmp($date, $today) < 0)
            {
            # Date of TV show is in the past; it must be that today is
            # December and the whow is in January of next year!
            $sDTG .= ' '. &UnixDate('next month', '%Y');
            } # if
          print STDERR " +   cooked dtg=$sDTG==\n" if (2 <= $self->{_debug});
          my $sDate = &UnixDate($sDTG, '%A, %b %E at %H:%M');
          print STDERR " +   cooked date=$sDate==\n" if (2 <= $self->{_debug});
          my $sDesc = "$sDate on $sChannel";
          $sTitle .= qq{ ("$sEpisode")} if ($sEpisode ne '');
          my $oHit = new WWW::Search::Result;
          $oHit->add_url($sURL);
          $oHit->title($sTitle);
          $oHit->description($sDesc);
          push(@{$self->{cache}}, $oHit);
          $iHits++;
          next A_TAG;
          } # if
        } # foreach SMALL_TAG
      } # if
    } # foreach A_TAG
  return $iHits;
  } # parse_tree

1;

__END__

=head1 OPTIONS

To do advanced search (by subtitle, description, cast/crew) add the
following options to the native_query().  For example, if you want to
see if the lovely Lena Olin appears anytime in the next 24 hours:

  $oSearch->native_query('',
                         {
                         search => 'adv',
                         contrib => 'Lena Olin',
                         range => 1,
                         },
                         );

Note: if you search agains more than one of the fields, the result
will be the AND of the searches.  For example, the following search
will never return anything:

  $oSearch->native_query('',
                           {
                           search => 'adv',
                           title => 'football',
                           subtit => 'Yankees',
                           desc => 'Enterprise',
                           contrib => 'Madonna',
                           range => 1,
                           },
                         );

=over

=item search => 'adv'

This option is required if you want to use any of the following:

=item title => 'title words'

Series title, like "Star Trek"; or sport, like "College Football".

=item subtit => 'subtitle words'

Episode title, like "All Our Yesterdays"; or team, like "Ohio State".

=item desc => 'description words'

Searches for words in the description.

=item contrib => 'Actor Name'

Unfortunately, tv.yahoo.com does not allow phrase searches, so "Diane
Lane" returns a lot of bogus hits for "The Nanny", which stars Lauren
Lane and was directed by Diane Somebody.

=item range => 1

To search only the next 24 hours.

=item range => 7

To search the next 7 days.  This is the default.

=item range => 14

To search the next 14 days.

=item sort => 'timesort'

To sort the results chronologically.

=item sort => 'score'

To sort the results by relevance.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Martin Thurn C<mthurn@cpan.org>

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
