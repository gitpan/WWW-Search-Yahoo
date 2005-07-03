
# $Id: gui.t,v 1.11 2005/07/03 19:36:51 Daddy Exp $

use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug;
my $iDump = 0;

GUI_TEST:
$iDebug = 0;
&tm_new_engine('Yahoo');
# goto MULTI;
diag("Sending 1-page query to yahoo.com...");
# This GUI query returns 1 page of results:
$iDebug = 0;
&tm_run_test('gui', 'wiz'.'ardrry', 1, 19, $iDebug);
MULTI:
diag("Sending multi-page query to yahoo.com...");
$iDebug = 0;
# This GUI query returns many pages of results; gui search returns 20
# per page:
&tm_run_test('gui', 'pokemon', 21, undef, $iDebug);
exit 0;

__END__

