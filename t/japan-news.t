use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug;
my $iDump = 0;

JAPAN_NEWS_TEST:
$iDebug = 0;
&my_engine('Yahoo::Japan::News');
# This test returns no results (but we should not get an HTTP error):
$iDebug = 0;
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDebug);
SKIP:
  {
  eval 'use Jcode';
  skip 'because Jcode is not installed', 3 if $@;
  $iDebug = 0;
  &my_test('normal', Jcode->new('カエル')->euc, 1, 19, $iDebug, $iDump);
  $iDebug = 0;
  # &my_test('normal', Jcode->new('ホールディングス')->euc, 21, 39, $iDebug, $iDump);
  &my_test('normal', Jcode->new('株式')->euc, 41, undef, $iDebug, $iDump);
  cmp_ok(41, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
         'approximate_hit_count');
  } # end of SKIP block
SKIP_REST:
exit 0;

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
