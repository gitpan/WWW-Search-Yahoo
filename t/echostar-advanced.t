use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo::TV::Echostar') };

my $iDebug;
my $iDump = 0;

&tm_new_engine('Yahoo::TV::Echostar');
TODO:
  {
  $TODO = q{as of 2004-01-11, Yahoo's advanced TV search website is broken};
  # goto ONE_TEST; # for debugging
 ZERO_TEST:
  $iDebug = 0;
  $iDump = 0;
  # This test should return no results:
  &tm_run_test('normal', '', 0, 0, $iDebug, $iDump,
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
  &tm_run_test('normal', '', 1, 24, $iDebug, $iDump,
             {
              search => 'adv',
              contrib => 'Smith',
              range => 7,
             },
          );
  # goto ALL_DONE;
  my @ao = $WWW::Search::Test::oSearch->results();
  cmp_ok(0, '<', scalar(@ao), 'got any results');
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
  &tm_run_test('normal', '', 26, undef, $iDebug, $iDump,
             {
              search => 'adv',
              title => 'Oddparents',
              range => 14,
             },
          );
  $TODO = '';
  } # end of TODO block
ALL_DONE:
exit 0;

__END__
