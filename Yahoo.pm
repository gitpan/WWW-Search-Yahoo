# Yahoo.pm
# by Wm. L. Scheding and Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Yahoo.pm,v 1.38 2000/12/15 14:13:04 mthurn Exp $

=head1 NAME

WWW::Search::Yahoo - class for searching Yahoo 

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

You can also search Yahoo Korea.  Just add this search_base_url to
your search setup:

  $oSearch->native_query($sQuery, 
                         {'search_base_url' => 'http://search.yahoo.co.kr'});

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
(MartinThurn@iname.com).

C<WWW::Search::Yahoo> was originally written by Wm. L. Scheding,
based on C<WWW::Search::AltaVista>.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

If it''s not listed here, then it wasn''t a meaningful nor released revision.

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

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);

$VERSION = '2.21';
$MAINTAINER = 'Martin Thurn <MartinThurn@iname.com>';

use Carp ();
use HTML::TreeBuilder;
use WWW::Search qw( generic_option strip_tags );
use WWW::SearchResult;
use URI;

sub gui_query
  {
  # actual URL as of 2000-03-27 is
  # http://search.yahoo.com/bin/search?p=sushi+restaurant+Columbus+Ohio
  my ($self, $sQuery, $rh) = @_;
  $self->{'search_base_url'} = 'http://search.yahoo.com';
  $self->{'_options'} = {
                         'search_url' => $self->{'search_base_url'} .'/bin/search',
                         'p' => $sQuery,
                         # 'hc' => 0,
                         # 'hs' => 0,
                        };
  # print STDERR " +   Yahoo::gui_query() is calling native_query()...\n";
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
  $self->{agent_e_mail} = 'MartinThurn@iname.com';

  $self->{_next_to_retrieve} = 1;
  $self->{'_num_hits'} = 0;

  if (! defined($self->{'_options'}))
    {
    # We do not clobber the existing _options hash, if there is one;
    # e.g. if gui_search() was already called on this object
    $self->{'search_base_url'} ||= 'http://ink.yahoo.com';
    $self->{'_options'} = {
                           'search_url' => $self->{'search_base_url'} .'/bin/query',
                           'o' => 1,
                           'p' => $native_query,
                           'd' => 'y',  # Yahoo's index, not usenet
                           'za' => 'or',  # OR of query words
                           'h' => 'c',  # web sites
                           'g' => 0,
                           'n' => $self->{_hits_per_page},
                           'b' => $self->{_next_to_retrieve}-1,
                          };
    } # if
  my $rhOptions = $self->{'_options'};
  if (defined($rhOptsArg)) 
    {
    # Copy in new options.
    foreach my $key (keys %$rhOptsArg) 
      {
      $rhOptions->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
      } # foreach
    } # if
  # Finally, figure out the url.
  $self->{'_next_url'} = $self->{'_options'}{'search_url'} .'?'. $self->hash_to_cgi_string($rhOptions);

  $self->{_debug} = $rhOptions->{'search_debug'};
  $self->{_debug} = 2 if ($rhOptions->{'search_parse_debug'});
  $self->{_debug} = 0 if (!defined($self->{_debug}));
  } # native_setup_search


# private
sub native_retrieve_some
  {
  my ($self) = @_;
  print STDERR " +   Yahoo::native_retrieve_some()\n" if $self->{_debug};
  
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));
  my $hits_found = 0;
  
  # If this is not the first page of results, sleep so as to not overload the server:
  $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
  
  # get some
  my $urlCurrent = $self->{_next_url};
  print STDERR " +   sending request ($urlCurrent)\n" if $self->{_debug};
  my $response = $self->http_request('GET', $urlCurrent);
  $self->{response} = $response;
  if (! $response->is_success)
    {
    return undef;
    } # if
  
  $self->{'_next_url'} = undef;

  # Parse the output:
  my $tree = new HTML::TreeBuilder;
  $tree->parse($response->content);
  $tree->eof;

  # The hit count is inside a <FONT> tag:
  my @aoFONT = $tree->look_down('_tag', 'font');
 FONT_TAG:
  foreach my $oFONT (@aoFONT)
    {
    my $s = $oFONT->as_text;
    print STDERR " + FONT == ", $oFONT->as_HTML if 2 <= $self->{_debug};
    # print STDERR " +   TEXT == ", $s, "\n" if 2 <= $self->{_debug};
    if (($s =~ m!found!i) &&
        ($s =~ m!(\d+)\s+(?:pages?|results?|sites?)!i))
      {
      my $iCount = $1;
      # print STDERR " +   found number $iCount\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($iCount);
      last FONT_TAG;
      } # if
    } # foreach

  # Each URL result is in a <LI> tag:
  my @aoLI = $tree->look_down('_tag', 'li');
 LI:
  foreach my $oLI (@aoLI)
    {
    printf STDERR " + LI == %s\n", $oLI->as_HTML if 2 <= $self->{_debug};
    # The first <a> tag contains the title:
    my $oA = $oLI->look_down('_tag', 'a');
    next LI unless ref($oA);
    my $sTitle = $oA->as_text;
    print STDERR " +   TITLE == $sTitle\n" if 2 <= $self->{_debug};
    my $sURLfallback = $oA->attr('href');
    $oA->detach();
    $oA->delete();
    # The last <font> tag contains the URL:
    my $sURL;
    my @aoFONT = $oLI->look_down('_tag', 'font');
    $oFONT = $aoFONT[-1];
    if (ref($oFONT))
      {
      # Delete the "More like this" link if present:
      my $oA = $oFONT->look_down('_tag', 'a');
      if (ref $oA)
        {
        $oA->detach;
        $oA->delete;
        } # if
      $sURL = $oFONT->as_text;
      $sURL =~ m!(.)\Z!;
      # print STDERR "\n + the last char of sURL is ", ord($1), "\n";
      # exit 88;
      $sURL =~ s![\240\s\t\r\n\ ]+!!g;
      $oFONT->detach();
      $oFONT->delete();
      }
    else
      {
      # Use the fallback URL:
      $sURL = $sURLfallback;
      $sURL =~ s!^.+?\*!!;
      }
    print STDERR " +   URL   == $sURL\n" if 2 <= $self->{_debug};
    # Ignore Yahoo Directory categories, etc.:
    next LI if $sURL =~ m!^http://dir\.yahoo\.com!;
    # The text of the LI is the description:
    my $sDesc = $oLI->as_text;
    print STDERR " +   DESC  == $sDesc\n" if 2 <= $self->{_debug};
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach oLI

  # The "next" button is in a table:
  my @aoTABLE = $tree->look_down('_tag', 'table');
 TABLE:
  foreach my $oTABLE (@aoTABLE)
    {
    printf STDERR " + TABLE == %s\n", $oTABLE->as_HTML if 2 <= $self->{_debug};
    my @aoA = $oTABLE->look_down('_tag', 'a');
 A:
    foreach my $oA (@aoA)
      {
      printf STDERR " +   A == %s\n", $oA->as_HTML if 2 <= $self->{_debug};
      if ($oA->as_text =~ m!next!i)
        {
        $self->{_next_url} = $HTTP::URI_CLASS->new_abs($oA->attr('href'), $urlCurrent);
        last TABLE;
        } # if
      } # foreach $oA
    } # foreach $oTABLE
  $tree->delete;
  return $hits_found;
  } # native_retrieve_some


1;

__END__

GUI search:
http://ink.yahoo.com/bin/query?p=sushi+restaurant+Columbus+Ohio&hc=0&hs=0

Advanced search:
http://ink.yahoo.com/bin/query?o=1&p=LSAm&d=y&za=or&h=c&g=0&n=20
