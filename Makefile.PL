use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION' => '2.33',
              'PREREQ_PM' => {
                              'Date::Manip' => 0,
                              'HTML::TreeBuilder' => 3,
                              # Jcode is needed for `make test` on Yahoo::Japan::News
                              'Jcode' => 0,
                              'Test::More' => 0,
                              # We need the version of WWW::Search::Test
                              # that exports _test_more functions
                              'WWW::Search::Test' => 2.23,
                             },
             );

print STDERR <<END;

Note: the Jcode module is only needed if you want to send Japanese
queries to www.yahoo.co.jp

END
