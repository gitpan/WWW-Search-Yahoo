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
diag("Sending 0-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
diag("Sending 1-page query to news.yahoo.com...");
DEBUG_NOW:
$iDebug = 0;
$iDump = 0;
&my_test('normal', 'Wakayama', 1, 99, $iDebug, $iDump);
diag("Sending multi-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', 'Japan', 105, undef, $iDebug, $iDump);

;
TODO:
  {
  local $TODO = qq{yahoo.com advanced search is often broken.};
  $WWW::Search::Test::oSearch->date_from('2004-03-21');
  $WWW::Search::Test::oSearch->date_to  ('2004-03-30');
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
  if (defined $iMin)
    {
    cmp_ok($iMin, '<=', $iCount, qq{lower-bound num-hits for query=$sQuery});
    cmp_ok($iMin, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
           'min. approximate_hit_count');
    } # if
  if (defined $iMax)
    {
    cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery});
    cmp_ok($WWW::Search::Test::oSearch->approximate_hit_count, '<=', $iMax,
           'max. approximate_hit_count');
    } # if
  } # my_test

__END__
