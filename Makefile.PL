use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION' => '2.32',
              'PREREQ_PM' => {
                              'Date::Manip' => 0,
                              'HTML::TreeBuilder' => 3,
                              # Jcode is needed for `make test` on Yahoo::Japan::News
                              'Jcode' => 0,
                              'Test::More' => 0,
                              # We need the version of WWW::Search
                              # that sets store_comments() on its
                              # HTML::TreeBuilder object:
                              'WWW::Search' => 2.36,
                             },
             );

print STDERR <<END;

Note: the Jcode module is only needed if you want to send Japanese
queries to www.yahoo.co.jp

END
