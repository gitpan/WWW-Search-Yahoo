# $Id: Echostar.pm,v 1.3 2003-07-27 21:15:36-04 kingpin Exp kingpin $

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

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

This backend does a basic keyword search against the Echostar (Dish
Network) East Coast channel lineup.

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

package WWW::Search::Yahoo::TV::Echostar;

use Carp ();
use Data::Dumper;  # for debugging only
use Date::Manip;
# We don't care what timezone we're in, we only use Date::Manip to
# convert date formats:
$ENV{'TZ'} ||= 'US/Eastern';
use HTML::TreeBuilder;
use WWW::Search qw( generic_option strip_tags );
use WWW::Search::Result;

use strict;

use vars qw( @ISA $VERSION $MAINTAINER );

@ISA = qw( WWW::Search );
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/o);
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
                           'range' => 14,
                          };
    } # if
  my $rhOptions = $self->{'_options'};
  if (defined($rhOptsArg))
    {
    # Copy in new options, promoting special ones:
    foreach my $key (keys %$rhOptsArg)
      {
      print STDERR " +   inspecting option $key..." if DEBUG_SETUP;
      if (WWW::Search::generic_option($key))
        {
        print STDERR "promote & delete\n" if DEBUG_SETUP;
        $self->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        delete $rhOptsArg->{$key};
        }
      else
        {
        print STDERR "copy\n" if DEBUG_SETUP;
        $rhOptions->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        }
      } # foreach
    print STDERR (" + resulting rhOptsArg is ", Dumper($rhOptsArg)) if DEBUG_SETUP;
    } # if
  # Finally, figure out the url.
  $self->{'_next_url'} = $self->{'search_base_url'} . $self->{'search_base_path'} .'?'. $self->hash_to_cgi_string($rhOptions);

  $self->{_debug} = $self->{'search_debug'} || 0;
  $self->{_debug} = 2 if ($self->{'search_parse_debug'});
  } # native_setup_search


sub preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  print STDERR qq{=========$sPage=========} if (2 < $self->{_debug});
  return $sPage;
  } # preprocess_results_page


sub parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  my $iHits = 0;
  my @aoFONT = $oTree->look_down('_tag' => 'font');
 FONT_TAG:
  foreach my $oFONT (@aoFONT)
    {
    next unless $oFONT;
    next unless ref $oFONT;
    if ($oFONT->as_text =~ m!\bfound\s+(\d+)\s+matches\b!)
      {
      $self->approximate_hit_count($1);
      last FONT_TAG;
      } # if
    } # foreach
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
          print STDERR " +   datetime=$sDTG==\n" if (2 <= $self->{_debug});
          my $sDate = &UnixDate($sDTG, '%A, %b %E at %H:%M');
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
