# Yahoo.pm
# by Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Yahoo.pm,v 2.33 2003-09-20 15:49:47-04 kingpin Exp kingpin $

=head1 NAME

WWW::Search::Yahoo - backend for searching www.yahoo.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo');
  my $sQuery = WWW::Search::escape_query("sushi restaurant Columbus Ohio");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo specialization of L<WWW::Search>.  It handles
making and interpreting Yahoo searches F<http://www.yahoo.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The default search is: Yahoo's web-based index (not Directory).

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 AUTHOR

As of 1998-02-02, C<WWW::Search::Yahoo> is maintained by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Yahoo> was originally written by Wm. L. Scheding,
based on C<WWW::Search::AltaVista>.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

See ChangeLog for all changes since version 2.07

=head2 2.07, 2000-02-04

Added gui_query() function

=head2 2.06, 1999-11-22

Added support for Yahoo Korea.

=head2 2.04, 1999-10-11

fixed parser

=head2 2.03, 1999-10-05

now uses hash_to_cgi_string()

=head2 2.02, 1999-09-29

update test cases; add caveat about repeated URLs

=head2 2.01, 1999-07-13

version number alignment with new WWW::Search;
new test mechanism

=head2 1.12, 1998-10-22

BUG FIX: now captures citation descriptions;
BUG FIX: next page of results was often wrong or missing!

=head2 1.11, 1998-10-09

Now uses split_lines function

=head2 1.5

Fixed bug where next page tag was always missed.
Fixed the maximum_to_retrieve off-by-one problem.
Updated test cases.

=cut

#####################################################################

package WWW::Search::Yahoo;

use Carp ();
use Data::Dumper;  # for debugging only
use HTML::TreeBuilder;
use WWW::Search qw( generic_option strip_tags );
use WWW::SearchResult;
use URI;

use strict;
use vars qw( $VERSION $MAINTAINER @ISA );

@ISA = qw( WWW::Search );
$VERSION = sprintf("%d.%02d", q$Revision: 2.33 $ =~ /(\d+)\.(\d+)/o);
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub gui_query
  {
  # actual URL as of 2000-03-27 is
  # http://search.yahoo.com/bin/search?p=sushi+restaurant+Columbus+Ohio
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         'p' => $sQuery,
                         # 'hc' => 0,
                         # 'hs' => 0,
                         'ei' => 'UTF-8',
                        };
  # print STDERR " +   Yahoo::gui_query() is calling native_query()...\n";
  $rh->{'search_base_url'} = 'http://search.yahoo.com';
  $rh->{'search_base_path'} = '/bin/query';
  return $self->native_query($sQuery, $rh);
  } # gui_query


sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  # print STDERR " +     This is Yahoo::native_setup_search()...\n";
  # print STDERR " +       _options is ", $self->{'_options'}, "\n";

  $self->{'_hits_per_page'} = 100;
  # $self->{'_hits_per_page'} = 10;  # for debugging

  # www.yahoo.com refuses robots.
  $self->user_agent('non-robot');
  # www.yahoo.com completely changes the HTML output depending on the
  # browser!
  # $self->{'agent_name'} = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)';
  # $self->{agent_e_mail} = 'mthurn@cpan.org';

  $self->{_next_to_retrieve} = 1;

  $self->{'search_base_url'} ||= 'http://search.yahoo.com';
  $self->{'search_base_path'} ||= '/search';
  if (! defined($self->{'_options'}))
    {
    # We do not clobber the existing _options hash, if there is one;
    # e.g. if gui_search() was already called on this object
    $self->{'_options'} = {
                           'vo' => $native_query,
                           'h' => 'w',  # web sites
                           'n' => $self->{_hits_per_page},
                           # 'b' => $self->{_next_to_retrieve}-1,
                          };
    } # if
  my $rhOptions = $self->{'_options'};
  if (defined($rhOptsArg))
    {
    # Copy in new options, promoting special ones:
    foreach my $key (keys %$rhOptsArg)
      {
      # print STDERR " +   inspecting option $key...";
      if (WWW::Search::generic_option($key))
        {
        # print STDERR "promote & delete\n";
        $self->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        delete $rhOptsArg->{$key};
        }
      else
        {
        # print STDERR "copy\n";
        $rhOptions->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        }
      } # foreach
    # print STDERR " + resulting rhOptions is ", Dumper($rhOptions);
    # print STDERR " + resulting rhOptsArg is ", Dumper($rhOptsArg);
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
  # Delete the <BASE> tag that appears BEFORE the <html> tag (because
  # it causes HTML::TreeBuilder to NOT be able to parse it!)
  $sPage =~ s!<BASE\s[^>]+>!!;
  return $sPage;
  # For debugging only.  Print the page contents and abort.
  print STDERR $sPage;
  exit 88;
  } # preprocess_results_page


sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  print STDERR " + ::Yahoo got a tree $tree\n" if 2 <= $self->{_debug};
  my $hits_found = 0;
  my $iCountSpoof = 0;
  my $WS = q{[\t\r\n\240\ ]};
  # Only try to parse the hit count if we haven't done so already:
  print STDERR " + start, approx_h_c is ==", $self->approximate_hit_count(), "==\n" if 2 <= $self->{_debug};
  if ($self->approximate_hit_count() < 1)
    {
    # Sometimes the hit count is inside a <DIV> tag:
    my @aoDIV = $tree->look_down('_tag' => 'div',
                                  'class' => 'ygbody',
                                 );
 DIV_TAG:
    foreach my $oDIV (@aoDIV)
      {
      next unless ref $oDIV;
      print STDERR " + try DIV ==", $oDIV->as_HTML if 2 <= $self->{_debug};
      my $s = $oDIV->as_text;
      print STDERR " +   TEXT ==$s==\n" if 2 <= $self->{_debug};
      if ($s =~ m!out\s+of\s+(?:about\s+)?([,0-9]+)!i)
        {
        my $iCount = $1;
        $iCount =~ s!,!!g;
        $self->approximate_result_count($iCount);
        last DIV_TAG;
        } # if
      } # foreach DIV_TAG
    } # if
  if ($self->approximate_hit_count() < 1)
    {
    # Sometimes the hit count is inside a <small> tag:
    my @aoDIV = $tree->look_down('_tag' => 'small',
                                 );
 SMALL_TAG:
    foreach my $oDIV (@aoDIV)
      {
      next unless ref $oDIV;
      print STDERR " + try SMALL ==", $oDIV->as_HTML if 2 <= $self->{_debug};
      my $s = $oDIV->as_text;
      print STDERR " +   TEXT ==$s==\n" if 2 <= $self->{_debug};
      if ($s =~ m!out\s+of\s+(?:about\s+)?([,0-9]+)!i)
        {
        my $iCount = $1;
        $iCount =~ s!,!!g;
        $self->approximate_result_count($iCount);
        last SMALL_TAG;
        } # if
      } # foreach DIV_TAG
    } # if
  print STDERR " + found approx_h_c is ==", $self->approximate_hit_count(), "==\n" if 2 <= $self->{_debug};

  # Unfortunately, the URL results are not logically marked up with
  # HTML.  We have to resort to old-fashioned string parsing!
  my $sAll = $tree->as_HTML;
  my @asChunk = split('<big>', $sAll);
  # Throw out what's before the first <big> tag:
  shift @asChunk;
 CHUNK:
  foreach my $sChunk (@asChunk)
    {
    # The last chunk ends with </span>:
    $sChunk =~ s!</span>.*\Z!!;
    print STDERR " +   consider <big> chunk ==$sChunk==\n" if 2 <= $self->{_debug};
    # The first <A> tag contains the URL and title:
    unless ($sChunk =~ s!\A.*?<a\shref="([^"]+)">(.+?)</a>!!)
      {
      print STDERR " --- did not find <A> inside <big> chunk\n" if 2 <= $self->{_debug};
      next CHUNK;
      } # unless
    my ($sURL, $sTitle) = ($1, $2);
    print STDERR " +   TITLE == $sTitle\n" if 2 <= $self->{_debug};
    # Delete Yahoo-redirect portion of URL:
    next CHUNK unless ($sURL =~ s!\A.+?\*-!!);
    print STDERR " +   URL   == $sURL\n" if 2 <= $self->{_debug};
    # Ignore Yahoo Directory categories, etc.:
    next CHUNK if $sURL =~ m!(\A|/search/empty/\?)http://dir\.yahoo\.com!;
    # Delete all remaining <A> tags:
    $sChunk =~ s!<a\s.+?</a>!!g;
    # The remaining text of the LI is the description:
    my $sDesc = $sChunk;
    print STDERR " +   raw DESC  ==$sDesc==\n" if 2 <= $self->{_debug};
    # Chop off extraneous:
    $sDesc =~ s!\s+\|\s+.*?\Z!!i;
    print STDERR " +   DESC  == $sDesc\n" if 2 <= $self->{_debug};
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $sTitle = $self->strip($sTitle);
    $sDesc = $self->strip($sDesc);
    $hit->title($sTitle);
    $hit->description($sDesc);
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    } # foreach CHUNK

  if (! $iCountSpoof)
    {
    # The "next" button is in a table...
    my @aoTABLE = $tree->look_down('_tag' => 'table');
    # ...but we want the LAST one appearing on the page:
 TABLE:
    foreach my $oTABLE (reverse @aoTABLE)
      {
      printf STDERR " + TABLE == %s\n", $oTABLE->as_HTML if 2 <= $self->{_debug};
      my @aoA = $oTABLE->look_down('_tag' => 'a');
 A:
      foreach my $oA (@aoA)
        {
        printf STDERR " +   A == %s\n", $oA->as_HTML if 2 <= $self->{_debug};
        if ($oA->as_text =~ m!\ANext(\s+\d+)?\Z!i)
          {
          my $sURL = $oA->attr('href');
          # Delete Yahoo-redirect portion of URL:
          $sURL =~ s!\A.+?\*-!!;
          $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $sURL);
          last TABLE;
          } # if
        } # foreach $oA
      } # foreach $oTABLE
    } # if
  return $hits_found;
  } # parse_tree


sub strip
  {
  my $self = shift;
  my $s = &WWW::Search::strip_tags(shift);
  $s =~ s!\A[\240\t\r\n\ ]+  !!x;
  $s =~ s!  [\240\t\r\n\ ]+\Z!!x;
  return $s;
  } # strip

1;

__END__

GUI search:
http://ink.yahoo.com/bin/query?p=sushi+restaurant+Columbus+Ohio&hc=0&hs=0

Advanced search:
http://search.yahoo.com/search?h=w&fr=op&va=&vp=&vo=Martin+Thurn&ve=&bbase=Search&vl=&vc=&vd=all&vt=any&vss=i&vs=&vr=&vk=
http://ink.yahoo.com/bin/query?o=1&p=LSAm&d=y&za=or&h=c&g=0&n=20

actual next link from page:

http://google.yahoo.com/bin/query?p=%22Shelagh+Fraser%22&b=21&hc=0&hs=0&xargs=

_next_url :

http://google.yahoo.com/bin/query?%0Ap=%22Shelagh+Fraser%22&b=21&hc=0&hs=0&xargs=
