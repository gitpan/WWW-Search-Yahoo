use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };
BEGIN { use_ok('WWW::Search::Yahoo::China') };

&tm_new_engine('Yahoo::China');
my $iDebug;
my $iDump = 0;

# goto TEST_NOW;
# goto MULTI_TEST;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to cn.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query to cn.yahoo.com...");
TODO:
  {
  $TODO = q{I need a Chinese reader to implement the result-count regex};
  &tm_run_test('normal', "\xCB\xBD\xD3"."\xEF\xB4\xAB\xC7\xE9", 1, 99, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO block
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  } # foreach
# goto ALL_DONE;
MULTI_TEST:
diag("Sending multi-page query to cn.yahoo.com...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
TODO:
  {
  $TODO = q{I need a Chinese reader to implement the result-count regex};
  &tm_run_test('normal', "\xCB\xBD", 21, undef, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO block

ALL_DONE:
exit 0;

__END__
