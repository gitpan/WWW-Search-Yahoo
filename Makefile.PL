use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION' => '2.31',
              'PREREQ_PM' => {
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
