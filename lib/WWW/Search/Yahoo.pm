# Yahoo.pm
# by Wm. L. Scheding and Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Yahoo.pm,v 2.29 2003/01/23 14:04:02 mthurn Exp $

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

The default search is: Yahoo's Inktomi-based index (not usenet).

The default search is the "OR" of all query terms (not "AND").
If you want the "AND" of all the query terms, add {'za' => 'and'} to the second argument to native_query.
If you want to search the query as a phrase, add {'za' => 'phrase'} to the second argument to native_query.
If you want to search the query as Yahoo's "intelligent default" (whatever that means), add {'za' => 'default'} to the second argument to native_query.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 TESTING

This module adheres to the C<WWW::Search> test suite mechanism. 

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

If it''s not listed here, then it wasn''t a meaningful nor released revision.

=head2 2.29, 2003-01-23

FIX parsing for new yahoo.com page format

=head2 2.28, 2002-11-08

FIX pattern for single-digit result-count integer match

=head2 2.27, 2002-10-31

new URL; tweak parser for new webpage format

=head2 2.24, 2001-12-24

fix for slightly changed output format

=head2 2.23, 2001-07-16

even better support for subclassing

=head2 2.22, 2001-03-31

added support for subclassing, for regional Yahoo sites

=head2 2.21, 2000-12-15

clean up URL parsing (yahoo.com added text to it)

=head2 2.19, 2000-11-10

rewrote parser using HTML::TreeBuilder

=head2 2.18, 2000-10-02

fixed parsing again.

=head2 2.17, 2000-09-22

fix description parsing and URL parsing

=head2 2.16, 2000-09-19

fix gui-style results parsing & new URL

=head2 2.15, 2000-09-14

fix result-count parsing

=head2 2.14, 2000-07-05

output format changed (thanks to Bin Yu for fixes)

=head2 2.11, 2000-04-27

new URL for gui_query

=head2 2.09, 2000-03-27

fixed for new CGI options

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

# require Exporter;
# @EXPORT = qw();
# @EXPORT_OK = qw();
@ISA = qw( WWW::Search ); # Exporter);

$VERSION = sprintf("%d.%02d", q$Revision: 2.29 $ =~ /(\d+)\.(\d+)/o);
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

use Carp ();
use Data::Dumper;  # for debugging only
use HTML::TreeBuilder;
use WWW::Search qw( generic_option strip_tags );
use WWW::SearchResult;
use URI;

sub gui_query
  {
  # actual URL as of 2000-03-27 is
  # http://search.yahoo.com/bin/search?p=sushi+restaurant+Columbus+Ohio
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         'p' => $sQuery,
                         # 'hc' => 0,
                         # 'hs' => 0,
                        };
  # print STDERR " +   Yahoo::gui_query() is calling native_query()...\n";
  $rh->{'search_base_url'} = 'http://google.yahoo.com';
  $rh->{'search_base_path'} = '/bin/query';
  return $self->native_query($sQuery, $rh);
  } # gui_query


sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  # print STDERR " +     This is Yahoo::native_setup_search()...\n";
  # print STDERR " +       _options is ", $self->{'_options'}, "\n";

  # As of 2000-03-27 or so, yahoo.com does NOT let you choose the
  # number of hits per page:
  $self->{'_hits_per_page'} = 20;

  # If we run as a robot, WWW::RobotRules fetches the
  # http://www.yahoo.com instead of http://www.yahoo.com/robots.txt,
  # and dumps a thousand warnings to STDERR.
  $self->user_agent('non-robot');
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
                           # 'n' => $self->{_hits_per_page},
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


sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  print STDERR " + ::Yahoo got a tree $tree\n" if 2 <= $self->{_debug};
  my $hits_found = 0;
  my $iCountSpoof = 0;
  my $WS = q{[\t\r\n\240\ ]};
  # Only try to parse the hit count if we haven't done so already:
  if ($self->approximate_hit_count < 1)
    {
    # The hit count is inside a <FONT> tag:
    my @aoFONT = $tree->look_down('_tag', 'font');
 FONT_TAG:
    foreach my $oFONT (@aoFONT)
      {
      my $s = $oFONT->as_text;
      print STDERR " + try FONT == ", $oFONT->as_HTML if 2 <= $self->{_debug};
      # print STDERR " +   TEXT == ", $s, "\n" if 2 <= $self->{_debug};
      if ($s =~ m!(\d+)\s*-\s*(\d+)\s+of\s+([,0-9]+)!i)
        {
        my ($iStart, $iPageMax, $iCount) = ($1, $2, $3);
        # Looks like a page range and hit count, but we have to make
        # sure we're looking at the right section of output:
        my $oTDmom = $oFONT->parent;
        next FONT_TAG unless ref $oTDmom;
        my $oTDaunt = $oTDmom->left;
        next FONT_TAG unless ref $oTDaunt;
        my $sSection = $oTDaunt->as_text;
        next FONT_TAG unless ($sSection =~ m!Web Matches!i);
        print STDERR " +   found numbers $iStart $iPageMax $iCount\n" if 2 <= $self->{_debug};
        $iCount =~ s!,!!g;
        $self->approximate_result_count($iCount);
        if (
            # Last hit on this page is NOT a multiple of ten
            # (i.e. looks like this is the last page of results)...
            (($iPageMax % 10) ne 0)
            &&
            # BUT last hit on this page is NOT the last global hit!?!
            ($iPageMax < $iCount))
          {
          # Yahoo.com is trying to trick us???
          $iCountSpoof = 1;
          } # if
        last FONT_TAG;
        } # if
      } # foreach
    } # if

  # Each URL result is in a <LI> tag:
  my @aoLI = $tree->look_down('_tag', 'li');
 LI:
  foreach my $oLI (@aoLI)
    {
    printf STDERR " + LI == %s\n", $oLI->as_HTML if 2 <= $self->{_debug};
    #  + LI == <li><p><font face="arial"><big> <a href="http://srd.yahoo.com/goo/%22Shelagh+Fraser%22/20/T=1009210773/F=191de59def3b5fd43b17abdedd4397ad/*http://home.fuse.net/mckee/addresses.htm"> Star Wars Stars' Addresses</a> </big><br><b>...</b> Denis Lawson c/o Star Wars Fan Club PO Box 111000 Aurora, CO 80042. Aunt Beru<br><b>Shelagh</b> <b>Fraser</b> c/o Ken McReddie Ltd. 91 Regent St. London W1R 7TB, ENGLAND <b>...</b><br><font color=006600>http://home.fuse.net/mckee/addresses.htm</font> </font><p><table><tr><td height=4></td></tr></table><table bgcolor="e3e9f8" border=0 cellpadding=2 cellspacing=0 width="100%"><tr><td align="right" nowrap><font face="arial" size="-1">1-20 of 318 |&nbsp;<b><a href="http://google.yahoo.com/bin/query?\np=%22Shelagh+Fraser%22&amp;b=21&amp;hc=0&amp;hs=0&amp;xargs=">Next 20 &gt;</a></b> </font></td></tr></table><table><tr><td height=6></td></tr></table>

    # The first <a> tag contains the title:
    my $oA = $oLI->look_down('_tag', 'a');
    next LI unless ref($oA);
    my $sTitle = $oA->as_text;
    print STDERR " +   TITLE == $sTitle\n" if 2 <= $self->{_debug};
    my $sURL = $oA->attr('href');
    $oA->detach();
    $oA->delete();
    $sURL =~ s!^.+?\*!!;
    print STDERR " +   URL   == $sURL\n" if 2 <= $self->{_debug};
    # Ignore Yahoo Directory categories, etc.:
    next LI if $sURL =~ m!(\A|/search/empty/\?)http://dir\.yahoo\.com!;
    # Delete the FONT tag:
    my $oFONT = $oLI->look_down('_tag' => 'font');
    if (ref $oFONT)
      {
      $oFONT->detach();
      $oFONT->delete();
      } # if
    # The remaining text of the LI is the description:
    my $sDesc = $oLI->as_text || '';
    # Chop off extraneous:
    $sDesc =~ s!\A$WS*-$WS+!!;
    $sDesc =~ s!More\s+(Results|sites)\s+(about|From):.*?\Z!!i;
    # $sDesc =~ s!\s?\d+-\d+\sof\s\d+\s\|?\240.*?\Z!!i;

    print STDERR " +   DESC  == $sDesc\n" if 2 <= $self->{_debug};
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $sTitle = $self->strip($sTitle);
    $sDesc = $self->strip($sDesc);
    $hit->title($sTitle);
    $hit->description($sDesc);
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    $oLI->delete;
    $oLI->detach;
    } # foreach oLI

  if (! $iCountSpoof)
    {
    # The "next" button is in a table...
    my @aoTABLE = $tree->look_down('_tag', 'table');
    # ...but we want the LAST one appearing on the page:
 TABLE:
    foreach my $oTABLE (reverse @aoTABLE)
      {
      printf STDERR " + TABLE == %s\n", $oTABLE->as_HTML if 2 <= $self->{_debug};
      my @aoA = $oTABLE->look_down('_tag', 'a');
 A:
      foreach my $oA (@aoA)
        {
        printf STDERR " +   A == %s\n", $oA->as_HTML if 2 <= $self->{_debug};
        if ($oA->as_text =~ m!Next\s+\d+!i)
          {
          my $sURL = $oA->attr('href');
          $sURL =~ tr!\r\n!!d;
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
  my $s = shift;
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
