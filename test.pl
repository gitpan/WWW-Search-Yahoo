# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use WWW::Search::Yahoo;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $iTest = 2;

my $sEngine = 'Yahoo';
my $oSearch = new WWW::Search($sEngine);
print ref($oSearch) ? '' : 'not ';
print "ok $iTest\n";

use WWW::Search::Test;

# goto GUI_TEST;
# goto MULTI_TEST;
my $debug = 0;

# This test returns no results (but we should not get an HTTP error):
$iTest++;
$oSearch->native_query($WWW::Search::Test::bogus_query);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
print STDOUT (0 < $iResults) ? 'not ' : '';
print "ok $iTest\n";
print STDERR "\n\n\n\n" if $debug;

# This query returns 1 page of results:
$iTest++;
$sQuery = 'LS'.'AM repl'.'ication';
$oSearch->native_query(
                       WWW::Search::escape_query($sQuery),
                      { 'search_debug' => $debug, },
                      );
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
# print STDERR " + got $iResults results for $sQuery\n";
if (($iResults < 2) || (84 < $iResults))
  {
  print STDERR " --- got $iResults results for '$sQuery', but expected 2..84\n";
  print STDOUT 'not ';
  }
print "ok $iTest\n";
print STDERR "\n\n\n\n" if $debug;

# goto GUI_TEST;

MULTI_TEST:
# This query returns MANY pages of results:
$iTest++;
$sQuery = 'pok'.'emon';
$oSearch->native_query(
                       WWW::Search::escape_query($sQuery),
                      { 'search_debug' => $debug, },
                      );
$oSearch->maximum_to_retrieve(39); # 2 pages
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
# print STDERR " + got $iResults results for $sQuery\n";
if (($iResults < 22))
  {
  print STDERR " --- got $iResults results for '$sQuery', but expected 22..\n";
  print STDOUT 'not ';
  }
print "ok $iTest\n";
print STDERR "\n\n\n\n" if $debug;

GUI_TEST:
# This GUI query returns 1 page of results:
$iTest++;
$sQuery = 'pi'.'catchu';
$oSearch->gui_query(
                    WWW::Search::escape_query($sQuery),
                      { 'search_debug' => $debug, },
                   );
$oSearch->maximum_to_retrieve(30);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
# print STDERR " + got $iResults GUI results for $sQuery\n";
if (($iResults < 2) || (20 < $iResults))
  {
  print STDERR " --- got $iResults GUI results for '$sQuery', but expected 2..20\n";
  print STDOUT 'not ';
  }
print "ok $iTest\n";

# This GUI query returns 2 pages of results:
$iTest++;
$sQuery = '"Shel'.'agh Fra'.'ser"';
$oSearch->gui_query(
                    WWW::Search::escape_query($sQuery),
                      { 'search_debug' => $debug, },
                   );
$oSearch->maximum_to_retrieve(40);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
# print STDERR " + got $iResults GUI results for $sQuery\n";
if (($iResults < 21))
  {
  print STDERR " --- got $iResults GUI results for '$sQuery', but expected 21..\n";
  print STDOUT 'not ';
  }
print "ok $iTest\n";

