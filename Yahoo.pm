# Yahoo.pm
# by Wm. L. Scheding and Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Yahoo.pm,v 1.29 2000/05/10 17:50:21 mthurn Exp $

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

$VERSION = '2.13';
$MAINTAINER = 'Martin Thurn <MartinThurn@iname.com>';

use Carp ();
use WWW::Search(qw( generic_option strip_tags ));
require WWW::SearchResult;
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
                           'b' => $self->{_next_to_retrieve},
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
  
  # If this is not the first page of results, sleep so as to not overload the server:
  $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
  
  # get some
  my $urlCurrent = $self->{_next_url};
  print STDERR " +   sending request ($urlCurrent)\n" if $self->{_debug};
  my($response) = $self->http_request('GET', $urlCurrent);
  $self->{response} = $response;
  if (!$response->is_success) 
    {
    return undef;
    }
  
  $self->{'_next_url'} = undef;
  print STDERR " +   got response\n" if $self->{_debug};
  # parse the output
  my ($HEADER, $HITS, $INSIDE, $TRAILER) = qw(HE HI IY TR);
  my $hits_found = 0;
  my $state = $HEADER;
  my $hit;
 LINE_OF_INPUT:
  foreach ($self->split_lines($response->content()))
    {
    next if m@^$@; # short circuit for blank lines
    print STDERR " + $state ===$_=== " if 2 <= $self->{'_debug'};
    if (9 < $self->{'_debug'})
      {
      if ($state eq $HITS && m@\074a\shref=\"[^"]+\">(.......)@i)
        {
        print STDERR " + EIGHT BYTES AFTER href are: ",  sprintf "\\%.3lo"x length($1), unpack("C*", $1), "\n";
        } # if
      } # if debug
    if ($state eq $HITS &&
        m!<a\shref=\"([^\"]+)">Next\s\d+\smatches</a>!i)
      {
      # Actual line of input is:
      # <a href="/bin/query?p=sushi+restaurant+Columbus+Ohio&b=21&hc=0&hs=0">Next 20 matches</a></font></center>
      print STDERR "gui next line\n" if 2 <= $self->{_debug};
      my $sURL = $1;
      $self->{'_next_to_retrieve'} += $self->{'_hits_per_page'};
      $self->{'_next_to_retrieve'} = $1 if $sURL =~ m/b=(\d+)/;
      $self->{'_next_url'} = URI->new_abs($sURL, $urlCurrent);
      print STDERR " + next URL is ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
      $state = $TRAILER;
      next LINE_OF_INPUT;
      }
    if ($state eq $HITS &&
        m!<a\shref=\"([^\"]+)">Go\sTo\sWeb\sPage\sMatches</a>!i)
      {
      # Actual line of input is:
      # <a href="http://ink.yahoo.com/bin/query?p=toyota+camry&hc=1&hs=5">Go To Web Page Matches</a>
      print STDERR "gui 1 next line\n" if 2 <= $self->{_debug};
      my $sURL = $1;
      $self->{'_next_to_retrieve'} += $self->{'_hits_per_page'};
      $self->{'_next_to_retrieve'} = $1 if $sURL =~ m/b=(\d+)/;
      # print STDERR " +   sURL       = $sURL\n";
      # print STDERR " +   urlCurrent = $urlCurrent\n";
      $self->{'_next_url'} = URI->new_abs($sURL, $urlCurrent);
      print STDERR " + next URL is ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
      $state = $TRAILER;
      next LINE_OF_INPUT;
      }

    elsif ($state eq $HITS &&
           m@Inside\sYahoo!\sMatches@ )
      {
      # Actual line of input is:
      # <font face=arial><b>Inside Yahoo! Matches</b></font><p>
      print STDERR "inside yahoo line\n" if 2 <= $self->{_debug};
      $state = $INSIDE;
      }
    elsif ($state eq $INSIDE)
      {
      my @asHits = split/<br\076/;
      foreach my $sLine (@asHits)
        {
        print STDERR " + $state ===$sLine=== " if 2 <= $self->{'_debug'};
        if ($sLine =~ m!href=\"(.+?)\"!i)
          {
          print STDERR "hit" if 2 <= $self->{'_debug'};
          if (defined($hit)) 
            {
            push(@{$self->{cache}}, $hit);
            } # if
          $hit = new WWW::SearchResult;
          $hit->add_url($1);
          $hit->title(strip_tags($sLine));
          $hits_found++;
          } # if
        print STDERR "\n" if 2 <= $self->{'_debug'};
        } # foreach
      $state = $HITS;
      }

    elsif ($state eq $HITS &&
           m!^<li><a\shref=\"([^\"]+)">(.+?)</a>\s-\s(.+?)<br>.+<p>$!i)
      {
      # Actual line of input is:
      # <li><a href="http://www.savvydiner.com/columbus/sapporowind">Sapporo Wind Page</a> - <b>Restaurant</b> info and reservations for the BEST places in Chicago, San Francisco, Seattle, Vancouver and other cities.<br><i>--http://www.savvydiner.com/<b>columbus</b>/sapporowind</i><p>      
      print STDERR "gui hit line\n" if 2 <= $self->{_debug};
      my ($sURL, $sTitle, $sDesc) = ($1,$2,$3);
      if (defined($hit)) 
        {
        push(@{$self->{cache}}, $hit);
        } # if
      $hit = new WWW::SearchResult;
      $hit->add_url($sURL);
      $hit->title(strip_tags($sTitle));
      $hit->description(strip_tags($sDesc));
      $hits_found++;
      next LINE_OF_INPUT;
      }

    elsif ($state eq $HITS && s@^\s-\s(.+)(\074/UL>|\074LI>)@$2@i)
      {
      # Actual line of input is:
      #  - Links to many other <b>Star</b> <b>Wars</b> sites as well as some cool original stuff.<LI><A HREF="http://www.geocities.com/Hollywood/Hills/3650/"><b>Star</b> <b>Wars</b>: A New Hope for the Internet</A>
      print STDERR "description line\n" if 2 <= $self->{_debug};
      $hit->description(strip_tags($1)) if defined($hit);
      # Don't change state, and don't go to the next line! The <LI> on
      # this line is the next hit!
      }

    elsif ($state eq $HITS && m=^(.*?)\074BR>\074cite>=)
      {
      # Actual line of input is:
      # 
      print STDERR "citation line\n" if 2 <= $self->{_debug};
      if (ref($hit))
        {
        my $sDescrip = '';
        if (defined($hit->description) and $hit->description ne '')
          {
          $sDescrip = $hit->description . ' ';
          }
        $sDescrip .= strip_tags($1);
        $hit->description($sDescrip);
        $state = $HITS;
        } # if hit
      } # CITATION line

    if ($state eq $HEADER && m|^and\s\074b>(\d+)\074/b>\s*$|)
      {
      print STDERR "header line\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($1);
      $state = $HITS;
      }
    elsif ($state eq $HEADER && m|\074b>\(\d+-\d+\s+of\s+(\d+)\)\074/b>|)
      {
      print STDERR "header count line\n" if 2 <= $self->{_debug};
      # Actual line of input:
      # &nbsp; <FONT SIZE="-1"><b>(1-20 of 801)</b></FONT></center><ul>
      $self->approximate_result_count($1);
      $state = $HITS;
      }
    elsif ($state eq $HEADER && m|\(\d+&nbsp;-&nbsp;\d+&nbsp;/&nbsp;(\d+)\)|)
      {
      print STDERR "header count line (korea)\n" if 2 <= $self->{_debug};
      # Actual line of input from Yahoo Korea:
      # <CENTER><FONT SIZE="+1"><B>$B"="i"B"N"H"0(B $B"2"M"="x"2"c"2"|(B &nbsp; <FONT SIZE="-1">(1&nbsp;-&nbsp;84&nbsp;/&nbsp;114)</FONT></B></FONT></CENTER>
      $self->approximate_result_count($1);
      $state = $HITS;
      }
    elsif ($state eq $HEADER && m|^\074CENTER>Found\s\074B>\d+\074/B>\sCategory\sand\s\074B>(\d+)\074/B>\sSite\sMatches\sfor|i)
      {
      # Actual line of input is:
      # <CENTER>Found <B>15</B> Category and <B>1297</B> Site Matches for
      print STDERR "header line\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($1);
      $state = $HITS;
      }

    elsif ($state eq $HITS &&
           m|\074LI>\074A HREF=\042([^\042]+)\042>(.*)\074/A>|i) 
      {
      # Actual lines of input are:
      # <UL TYPE=disc><LI><A HREF="http://events.yahoo.com/Arts_and_Entertainment/Movies_and_Films/Star_Wars_Series/">Yahoo! Net Events: <b>Star</b> <b>Wars</b> Series</A>
      #  - Links to many other <b>Star</b> <b>Wars</b> sites as well as some cool original stuff.<LI><A HREF="http://www.geocities.com/Hollywood/Hills/3650/"><b>Star</b> <b>Wars</b>: A New Hope for the Internet</A>
      my ($sURL, $sTitle) = ($1, $2);
      if ($sURL =~ m/^news:/)
        {
        print STDERR "ignore 'news:' url line\n" if 2 <= $self->{_debug};
        next;
        } # if
      print STDERR "hit url line\n" if 2 <= $self->{_debug};
      if (defined($hit)) 
        {
        push(@{$self->{cache}}, $hit);
        }
      $hit = new WWW::SearchResult;
      $hit->add_url($sURL);
      $hits_found++;
      $hit->title(strip_tags($sTitle));
      }
 
    elsif ($state eq $HITS && m@\074a\shref=\"([^"]+)\">(Next|\264\331\300\275)\s*\d+@i)
      {
      print STDERR "next line\n" if 2 <= $self->{_debug};
      # Actual line of input from Yahoo Korea:
      # <a href="/bin/search?&d=y&n=84&o=1&p=moon&za=or&hc=3&hs=114&h=s&b=85">$B"6"["B"?(B 30$B"2"5"B"I(B $B"2"M"="x"2"c"2"|(B</a>
      # There is a "next" button on this page, therefore there are
      # indeed more results for us to go after next time.
      my $sURL = $1;
      $self->{'_next_to_retrieve'} += $self->{'_hits_per_page'};
      $self->{'_next_to_retrieve'} = $1 if $sURL =~ m/b=(\d+)/;
      $self->{'_next_url'} = URI->new_abs($sURL, $urlCurrent);
      print STDERR " + next URL is ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
      $state = $TRAILER;
      }
 
    else 
      {
      print STDERR "didn't match\n" if 2 <= $self->{_debug};
      };
    } # foreach
  if ($state ne $TRAILER) 
    {
    # Reached end of page without seeing "Next" button
    $self->{_next_url} = undef;
    } # if
  if (defined($hit)) 
    {
    push(@{$self->{cache}}, $hit);
    } # if
  
  return $hits_found;
  } # native_retrieve_some

1;

__END__

GUI search:
http://ink.yahoo.com/bin/query?p=sushi+restaurant+Columbus+Ohio&hc=0&hs=0

Advanced search:
http://ink.yahoo.com/bin/query?o=1&p=LSAm&d=y&za=or&h=c&g=0&n=20
