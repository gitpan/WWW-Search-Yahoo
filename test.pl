# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use Jcode;
use WWW::Search::Test qw( new_engine run_test run_gui_test );

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use WWW::Search::Yahoo;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$WWW::Search::Test::iTest = 1;

&new_engine('Yahoo');

# goto GUI_TEST;
# goto MULTI_TEST;
# goto NEWS_ADVANCED_TEST;
# goto JAPAN_NEWS_TEST;

my $debug = 0;

# This test returns no results (but we should not get an HTTP error):
&run_test($WWW::Search::Test::bogus_query, 0, 0, $debug);
# This query returns 1 page of results:
&run_test('LS'.'AM repl'.'ication', 2, 84, $debug);
MULTI_TEST:
# This query returns MANY pages of results:
&run_test('pok'.'emon', 22, undef, $debug);

GUI_TEST:
# This GUI query returns 1 page of results:
&run_gui_test('"Yoda Stories demo"', 1, 19, $debug);
# This GUI query returns 2 pages of results:
&run_gui_test('"Shel'.'agh Fra'.'ser"', 21, undef, $debug);

NEWS_ADVANCED_TEST:
&new_engine('Yahoo::News::Advanced');
&run_test('"George Lucas"', 1, 99, $debug);
&run_test('Japan', 101, undef, $debug);
$WWW::Search::Test::oSearch->date_from('2001-09-01');
$WWW::Search::Test::oSearch->date_to(  '2001-09-06');
# $debug = 2;
&run_test('"Star Wars"', 11, 11, $debug);
# goto SKIP_REST;

JAPAN_NEWS_TEST:
$debug = 0;
my $iDump = 0;
&new_engine('Yahoo::Japan::News');
&run_test(Jcode->new('カエル')->euc, 1, 19, $debug, $iDump);
&run_test(Jcode->new('ホールディングス')->euc, 21, 39, $debug, $iDump);
&run_test(Jcode->new('株式')->euc, 41, undef, $debug, $iDump);

SKIP_REST:
exit 0;
