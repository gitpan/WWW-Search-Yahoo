# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use Jcode;
use Test::More tests => 24;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug;
my $iDump = 0;

# goto GUI_TEST;
# goto MULTI_TEST;
# goto NEWS_ADVANCED_TEST;
# goto JAPAN_NEWS_TEST;

YAHOO_TEST:
$iDebug = 0;
&my_new_engine('Yahoo');
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
$iDebug = 0;
# This query returns 1 page of results:
# &my_test('normal', 'LS'.'AM repl'.'ication', 1, 19, $iDebug);
MULTI_TEST:
$iDebug = 0;
# This query returns MANY pages of results:
&my_test('normal', 'pok'.'emon', 22, undef, $iDebug);

GUI_TEST:
$iDebug = 0;
# This GUI query returns 1 page of results:
$iDebug = 0;
&my_test('gui', '"Yendor'.'ian tales demo"', 1, 19, $iDebug);
$iDebug = 0;
# This GUI query returns 2 pages of results:
&my_test('gui', '"Shel'.'agh Fraser"', 21, undef, $iDebug);
$iDebug = 0;

NEWS_ADVANCED_TEST:
&my_new_engine('Yahoo::News::Advanced');
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto DEBUG_NOW;
$iDebug = 0;
&my_test('normal', 'Presidio', 1, 99, $iDebug);
DEBUG_NOW:
$iDebug = 0;
&my_test('normal', 'Japan', 101, undef, $iDebug);
# goto SKIP_REST;
$WWW::Search::Test::oSearch->date_from('2002-10-29');
$WWW::Search::Test::oSearch->date_to(  '2002-10-30');
$iDebug = 0;
$iDump = 0;
&my_test('normal', '"Star Wars"', 7, 7, $iDebug, $iDump);

JAPAN_NEWS_TEST:
$iDebug = 0;
&my_new_engine('Yahoo::Japan::News');
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
&my_test('normal', Jcode->new('カエル')->euc, 1, 19, $iDebug, $iDump);
$iDebug = 0;
# &my_test('normal', Jcode->new('ホールディングス')->euc, 21, 39, $iDebug, $iDump);
&my_test('normal', Jcode->new('株式')->euc, 41, undef, $iDebug, $iDump);

SKIP_REST:
exit 0;

sub my_new_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  } # my_new_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &count_results(@_);
  cmp_ok($iCount, '>=', $iMin, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test


__END__
