use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('Encode', qw( from_to )) };
BEGIN { use_ok('Encode::JP') };
BEGIN { use_ok('I18N::Charset') };
BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug = 0;
my $iDump = 0;

&tm_new_engine('Yahoo::Japan::News');
# goto DEBUG_NOW;

ZERO_PAGE:
# This test returns no results (but we should not get an HTTP error):
$iDebug = 0;
$iDump  = 0;
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDebug);

DEBUG_NOW:
;
SINGLE_PAGE:
# My Emacs decided to use this encoding when I typed Japanese and
# saved this file:
my $sFrom = &I18N::Charset::enco_charset_name('iso-2022-jp');
# yahoo.co.jp expects queries to be in this encoding:
my $sEUC = &I18N::Charset::enco_charset_name('EUC-jp');
# diag("sFrom =$sFrom=");
# diag("sEUC  =$sEUC=");
my $sQuery = 'カエル';
# diag("before  =$sQuery=");
from_to($sQuery, $sFrom, $sEUC);
# diag("after   =$sQuery=");
$sQuery = 'Florensia';
$iDebug = 0;
$iDump  = 0;
&tm_run_test('normal', $sQuery, 1, 19, $iDebug, $iDump);
# goto ALL_DONE;

MULTI_PAGE:
$iDebug = 0;
$iDump  = 0;
$sQuery = '東京';
from_to($sQuery, $sFrom, $sEUC);
&tm_run_test('normal', $sQuery, 41, undef, $iDebug, $iDump);
ALL_DONE:
exit 0;

__END__
