use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION' => '2.28',
              'PREREQ_PM' => {
                              'HTML::TreeBuilder' => 3.00,
                              'Jcode' => 0,  # only needed for `make test` on Yahoo::Japan::News
                              'WWW::Search' => 2.33,
                             },
             );
