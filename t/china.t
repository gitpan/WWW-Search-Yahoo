use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };
BEGIN { use_ok('WWW::Search::Yahoo::China') };

&my_engine('Yahoo::China');
my $iDebug;
my $iDump = 0;

# goto TEST_NOW;
# goto MULTI_TEST;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to cn.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query to cn.yahoo.com...");
&my_test('normal', "\xCB\xBD\xD3"."\xEF\xB4\xAB\xC7\xE9", 1, 99, $iDebug, $iDump);
TODO:
  {
  local $TODO = q{I need a Chinese reader to implement the result-count regex};
  cmp_ok(1, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
         qq{lower-bound approximate_result_count});
  cmp_ok($WWW::Search::Test::oSearch->approximate_result_count, '<=', 99,
         qq{upper-bound approximate_result_count});
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
&my_test('normal', "\xCB\xBD", 21, undef, $iDebug, $iDump);
TODO:
  {
  local $TODO = q{I need a Chinese reader to implement the result-count regex};
  cmp_ok(21, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
         qq{lower-bound approximate_result_count});
  } # end of TODO block

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
