use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo::TV::Echostar') };

my $iDebug;
my $iDump = 0;

&my_engine('Yahoo::TV::Echostar');
# goto ONE_TEST; # for debugging
ZERO_TEST:
$iDebug = 0;
$iDump = 0;
# This test should return no results:
&my_test('normal', '', 0, 0, $iDebug, $iDump,
        {
         search => 'adv',
         # There should be no such person with this name:
         contrib => 'Saturday Night Live',
        },
        );
# goto ALL_DONE;
ONE_TEST:
$iDebug = 0;
$iDump = 0;
# This query usually returns 1 page of results:
&my_test('normal', '', 1, 24, $iDebug, $iDump,
           {
            search => 'adv',
            contrib => 'Diane Lane',
            range => 7,
           },
        );
cmp_ok(1, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');
cmp_ok($WWW::Search::Test::oSearch->approximate_hit_count, '<=', 24,
       'approximate_hit_count');
# goto ALL_DONE;
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<=', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://tv\.yahoo\.com},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  } # foreach
MULTI_TEST:
$iDebug = 0;
$iDump = 0;
# This query usually returns TWO pages of results:
&my_test('normal', '', 26, undef, $iDebug, $iDump,
           {
            search => 'adv',
            title => 'Oddparents',
            range => 14,
           },
        );
cmp_ok(26, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');

ALL_DONE:
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
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults, $rh) = @_;
  my $iCount = &WWW::Search::Test::count_results(@_);
  cmp_ok($iMin, '<=', $iCount, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test

__END__
