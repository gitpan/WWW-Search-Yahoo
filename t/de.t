
# $Id$

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More 'no_plan';

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };
BEGIN { use_ok('WWW::Search::Yahoo::DE') };

&tm_new_engine('Yahoo::DE');
my $iDebug;
my $iDump = 0;

# goto TEST_NOW;
# goto MULTI_TEST;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to de.yahoo.com...");
$iDebug = 0;
$iDump = 1;
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
# goto MULTI_TEST;
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query to de.yahoo.com...");
&tm_run_test('normal', 'wiz'.'ardrry', 1, 99, $iDebug, $iDump);
my @ao = $WWW::Search::Test::oSearch->results();
my $iCount = scalar(@ao);
cmp_ok(0, '<', $iCount, 'got any results');
my $iCountDesc = 0;
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  $iCountDesc++ if ($oResult->description ne '');
  } # foreach
cmp_ok(0.95, '<', $iCountDesc/$iCount, 'mostly non-empty descriptions');
# goto ALL_DONE;

MULTI_TEST:
diag("Sending multi-page query to de.yahoo.com...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
&tm_run_test('normal', "Thurn", 101, undef, $iDebug, $iDump);

ALL_DONE:
exit 0;

__END__

