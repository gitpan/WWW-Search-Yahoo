use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };
BEGIN { use_ok('WWW::Search::Yahoo::DE') };

&my_engine('Yahoo::DE');
my $iDebug;
my $iDump = 0;

# goto TEST_NOW;
# goto MULTI_TEST;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to de.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
# goto MULTI_TEST;
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query to de.yahoo.com...");
&my_test('normal', 'wiz'.'radry', 1, 99, $iDebug, $iDump);
cmp_ok(1, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
       qq{lower-bound approximate_result_count});
cmp_ok($WWW::Search::Test::oSearch->approximate_result_count, '<=', 99,
       qq{upper-bound approximate_result_count});
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
diag("Sending multi-page query to de.yahoo.com...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
&my_test('normal', "Thurn", 101, undef, $iDebug, $iDump);
cmp_ok(101, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
       qq{lower-bound approximate_result_count});

ALL_DONE:
exit 0;

sub my_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  $WWW::Search::Test::oSearch->env_proxy('yes');
  } # my_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &WWW::Search::Test::count_results(@_);
  cmp_ok($iMin, '<=', $iCount, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test

__END__
