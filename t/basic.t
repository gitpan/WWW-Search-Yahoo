use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug;
my $iDump = 0;

YAHOO_TEST:
$iDebug = 0;
&my_engine('Yahoo');
# goto MULTI_TEST;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
&my_test('normal', 'pi'.'kaku', 1, 99, $iDebug, $iDump);
MULTI_TEST:
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
&my_test('normal', 'pok'.'emon', 101, undef, $iDebug, $iDump);
cmp_ok(101, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');

sub my_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
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
