use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo::TV::Echostar') };

my $iDebug;
my $iDump = 0;

&tm_new_engine('Yahoo::TV::Echostar');
# goto ONE_TEST; # for debugging
ZERO_TEST:
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
ONE_TEST:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
&tm_run_test('normal', 'Tina Fey', 1, 24, $iDebug, $iDump);
cmp_ok(1, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');
cmp_ok($WWW::Search::Test::oSearch->approximate_hit_count, '<=', 24,
       'approximate_hit_count');
# goto ALL_DONE; # for debugging
MULTI_TEST:
$iDebug = 0;
$iDump = 0;
# This query usually returns TWO pages of results:
&tm_run_test('normal', 'spongebob', 26, undef, $iDebug, $iDump);
# &tm_run_test('normal', 'oddparents', 26, undef, $iDebug, $iDump);
cmp_ok(26, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');
ALL_DONE:
exit 0;

__END__
