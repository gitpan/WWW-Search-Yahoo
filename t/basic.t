use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

&my_engine('Yahoo');
my $iDebug;
my $iDump = 0;

# goto MULTI_TEST;
# goto TEST_NOW;
# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to yahoo.com...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query to yahoo.com...");
&my_test('normal', 'pi'.'kaku', 1, 99, $iDebug, $iDump);
my @ao = $WWW::Search::Test::oSearch->results();
my $iCount = scalar(@ao);
my $iCountDesc = 0;
cmp_ok(0, '<', $iCount, 'got any results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://}, 'result URL is http');
  cmp_ok($oResult->title, 'ne', '', 'result Title is not empty');
  # cmp_ok($oResult->size, 'ne', '', 'result size is not empty');
  $iCountDesc++ if ($oResult->description ne '');
  } # foreach
cmp_ok(0.95, '<', $iCountDesc/$iCount, 'mostly non-empty descriptions');
MULTI_TEST:
diag("Sending multi-page query to yahoo.com...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
&my_test('normal', 'pok'.'emon', 101, undef, $iDebug, $iDump);
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
  cmp_ok($iMin, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
         qq{lower-bound approximate_result_count}) if defined $iMin;
  cmp_ok($WWW::Search::Test::oSearch->approximate_result_count, '<=', $iMax,
         qq{upper-bound approximate_result_count}) if defined $iMax;
  } # my_test

__END__
