use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo::TV::Echostar') };

my $iDebug;
my $iDump = 1;

&tm_new_engine('Yahoo::TV::Echostar');
# goto ONE_TEST; # for debugging
ONE_TEST:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
&tm_run_test('normal', 'Tina Fey', 1, 24, $iDebug, $iDump);
$WWW::Search::Test::oSearch->ignore_channels(qw( ETV KNBC ));
&tm_run_test('normal', 'Tina Fey', 1, 19, $iDebug, $iDump);

__END__

