use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('Date::Manip') };
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

&Date_Init('TZ=US/Eastern');

my $iDebug = 0;
my $iDump = 0;

NEWS_ADVANCED_TEST:
&my_engine('Yahoo::News::Advanced');
# goto DEBUG_NOW;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
$iDebug = 0;
&my_test('normal', 'Wakayama', 1, 99, $iDebug, $iDump);
$iDebug = 0;
&my_test('normal', 'Japan', 105, undef, $iDebug, $iDump);
cmp_ok(105, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');
# goto SKIP_REST;

DEBUG_NOW:
;
TODO:
  {
  local $TODO = qq{yahoo.com advanced search is often broken.};
  $WWW::Search::Test::oSearch->date_from('2003-12-21');
  $WWW::Search::Test::oSearch->date_to  ('2003-12-30');
  $iDebug = 0;
  $iDump = 0;
  &my_test('normal', 'Aomori', 1, 9, $iDebug, $iDump);
  } # end of TODO block
SKIP_REST:
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
