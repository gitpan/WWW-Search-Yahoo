# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use WWW::Search::Test qw( new_engine run_test run_gui_test );

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
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
&run_test('Yoda', 1, 99, $debug);
&run_test('Bangladesh', 101, 199, $debug);
$WWW::Search::Test::oSearch->date_from('2001-07-05');
$WWW::Search::Test::oSearch->date_to(  '2001-07-15');
# $debug = 2;
&run_test('"Geor'.'ge Lu'.'cas"', 2, 2, $debug);
