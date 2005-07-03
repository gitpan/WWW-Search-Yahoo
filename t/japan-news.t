use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('Encode', qw( from_to )) };
BEGIN { use_ok('Encode::JP') };
BEGIN { use_ok('I18N::Charset') };
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug;
my $iDump = 0;

JAPAN_NEWS_TEST:
$iDebug = 0;
&tm_new_engine('Yahoo::Japan::News');
# goto SKIP;
# This test returns no results (but we should not get an HTTP error):
$iDebug = 0;
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDebug);
# My Emacs decided to use this encoding when I typed Japanese and
# saved this file:
my $sFrom = &I18N::Charset::enco_charset_name('iso-2022-jp');
# yahoo.co.jp expects queries to be in this encoding:
my $sEUC = &I18N::Charset::enco_charset_name('EUC-jp');
# diag("sFrom =$sFrom=");
# diag("sEUC  =$sEUC=");
$iDebug = 0;
my $sQuery = 'カエル';
# diag("before  =$sQuery=");
from_to($sQuery, $sFrom, $sEUC);
# diag("after   =$sQuery=");
&tm_run_test('normal', $sQuery, 1, 39, $iDebug, $iDump);
$iDebug = 0;
$sQuery = '東京';
from_to($sQuery, $sFrom, $sEUC);
&tm_run_test('normal', $sQuery, 41, undef, $iDebug, $iDump);
SKIP_REST:
exit 0;

__END__
