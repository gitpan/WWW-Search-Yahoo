use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug;
my $iDump = 0;

GUI_TEST:
$iDebug = 0;
&my_engine('Yahoo');
# goto MULTI;
# This GUI query returns 1 page of results:
$iDebug = 0;
&my_test('gui', '"Yendor'.'ian tales demo"', 1, 99, $iDebug);
MULTI:
$iDebug = 0;
# This GUI query returns many pages of results; gui search returns 20
# per page:
&my_test('gui', 'pokemon', 35, undef, $iDebug);
$iDebug = 0;
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
