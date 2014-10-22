
# $Id: news-advanced.t,v 1.17 2006/05/01 19:17:13 Daddy Exp $

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
&tm_new_engine('Yahoo::News::Advanced');

# goto DEBUG_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

diag("Sending 1-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', 'thurn', 1, 99, $iDebug, $iDump);

DEBUG_NOW:
diag("Sending multi-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', 'Japan', 51, undef, $iDebug, $iDump);
exit 0;

;
TODO:
  {
  $TODO = qq{yahoo.com advanced search is often broken.};
  $WWW::Search::Test::oSearch->date_from('2004-03-21');
  $WWW::Search::Test::oSearch->date_to  ('2004-03-30');
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', 'Aomori', 1, 9, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO block
SKIP_REST:
exit 0;

__END__

