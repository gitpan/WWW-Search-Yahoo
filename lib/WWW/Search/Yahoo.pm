# Yahoo.pm
# by Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Yahoo.pm,v 2.352 2004/03/13 14:31:48 Daddy Exp Daddy $

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
# We must have version 
use WWW::Search;
use WWW::SearchResult;
use URI;
use URI::Escape;

use strict;
use vars qw( $VERSION $MAINTAINER @ISA );
use vars qw( $iMustPause );

@ISA = qw( WWW::Search );
$VERSION = do { my @r = (q$Revision: 2.352 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

# Thanks to the hard work of Gil Vidals and his team at
# positionresearch.com, we know the following: In early 2004,
# yahoo.com implemented new robot-blocking tactics that look for
# frequent requests from the same client IP.  One way around these
# blocks is to slow down and randomize the timing of our requests.  We
# therefore insert a random sleep before every request except the
# first one.  This variable is equivalent to a "first-time" flag for
# this purpose:
$iMustPause = 0;

sub need_to_delay
  {
  # print STDERR " + this is Yahoo::need_to_delay()\n";
  return $iMustPause;
  } # need_to_delay


sub gui_query
  {
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


sub user_agent_delay
  {
  my $self = shift;
  my $iSecs = int(30 + rand(30));
  print STDERR " + sleeping $iSecs seconds, to make yahoo.com think we're NOT a robot...\n" if ($self->{search_debug} < 0);
  sleep($iSecs);
  } # user_agent_delay


sub preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  # goto PRP_DEBUG;
  # Delete the <BASE> tag that appears BEFORE the <html> tag (because
  # it causes HTML::TreeBuilder to NOT be able to parse it!)
  $sPage =~ s!<BASE\s[^>]+>!!;
  return $sPage;
  # For debugging only.  Print the page contents and abort.
 PRP_DEBUG:
  print STDERR $sPage;
  exit 88;
  } # preprocess_results_page


sub parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  print STDERR " + ::Yahoo got a tree $oTree\n" if (2 <= $self->{_debug});
  # Every time we get a page from yahoo.com, we have to pause before
  # fetching another.
  $iMustPause++;
  my $hits_found = 0;
  my $WS = q{[\t\r\n\240\ ]};
  # Only try to parse the hit count if we haven't done so already:
  print STDERR " + start, approx_h_c is ==", $self->approximate_hit_count(), "==\n" if (2 <= $self->{_debug});
  if ($self->approximate_hit_count() < 1)
    {
    # Sometimes the hit count is inside a <DIV> tag:
    my @aoDIV = $oTree->look_down('_tag' => 'div',
                                  'class' => 'ygbody',
                                 );
 DIV_TAG:
    foreach my $oDIV (@aoDIV)
      {
      next unless ref $oDIV;
      print STDERR " + try DIV ==", $oDIV->as_HTML if (2 <= $self->{_debug});
      my $s = $oDIV->as_text;
      print STDERR " +   TEXT ==$s==\n" if (2 <= $self->{_debug});
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
    my @aoDIV = $oTree->look_down('_tag' => 'small',
                                 );
 SMALL_TAG:
    foreach my $oDIV (@aoDIV)
      {
      next unless ref $oDIV;
      print STDERR " + try SMALL ==", $oDIV->as_HTML if (2 <= $self->{_debug});
      my $s = $oDIV->as_text;
      print STDERR " +   TEXT ==$s==\n" if (2 <= $self->{_debug});
      if ($s =~ m!out\s+of\s+(?:about\s+)?([,0-9]+)!i)
        {
        my $iCount = $1;
        $iCount =~ s!,!!g;
        $self->approximate_result_count($iCount);
        last SMALL_TAG;
        } # if
      } # foreach DIV_TAG
    } # if
  print STDERR " + found approx_h_c is ==", $self->approximate_hit_count(), "==\n" if (2 <= $self->{_debug});

  my @aoLI = $oTree->look_down(_tag => 'li');
 LI_TAG:
  foreach my $oLI (@aoLI)
    {
    # Sanity check:
    next LI_TAG unless ref($oLI);
    my @aoA = $oLI->look_down(_tag => 'a');
    my $oA = shift @aoA;
    next LI_TAG unless ref($oA);
    my $sTitle = $oA->as_text || '';
    my $sURL = $oA->attr('href') || '';
    next LI_TAG unless ($sURL ne '');
    unshift @aoA, $oA;
    # Strip off the yahoo.com redirect part of the URL:
    $sURL =~ s!\A.*?\*-!!;
    # Delete the useless human-readable restatement of the URL (first
    # <EM> tag we come across):
    my $oEM = $oLI->look_down(_tag => 'em');
    if (ref($oEM))
      {
      $oEM->detach;
      $oEM->delete;
      } # if
 A_TAG:
    foreach my $oA (@aoA)
      {
      $oA->detach;
      $oA->delete;
      } # foreach A_TAG
    my $sDesc = $oLI->as_text;
    print STDERR " +   raw     sDesc is ==$sDesc==\n" if (2 <= $self->{_debug});
    # Grab stuff off the end of the description:
    my $sSize = $1 if ($sDesc =~ s!\s+(-\s+)+(\d+k?)(\s+-)+\s+\Z!!);
    $sSize ||= '';
    print STDERR " +   cooked  sDesc is ==$sDesc==\n" if (2 <= $self->{_debug});
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $sTitle = $self->strip($sTitle);
    $sDesc = $self->strip($sDesc);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->size($sSize);
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    } # foreach LI_TAG
  # Now try to find the "next page" link:
  my @aoA = $oTree->look_down('_tag' => 'a');
 NEXT_A:
  foreach my $oA (reverse @aoA)
    {
    next NEXT_A unless ref($oA);
    my $sAhtml = $oA->as_HTML;
    printf STDERR (" +   next A ==%s==\n", $sAhtml) if (2 <= $self->{_debug});
    my $sURL = $oA->attr('href');
    if (
        ($oA->as_text eq 'Next')
        ||
        # I can not type Chinese, nor even cut-and-paste into Emacs
        # with confidence that the encoding will not get screwed up,
        # so I resort to this:
        ($sAhtml =~ m!&Iuml;&Acirc;&Ograve;&raquo;&Ograve;&sup3;!i)
       )
      {
      # Delete Yahoo-redirect portion of URL:
      $sURL =~ s!\A.+?\*?-?(?=http)!!;
      $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $sURL);
      last NEXT_A;
      } # if
    } # foreach NEXT_A
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
