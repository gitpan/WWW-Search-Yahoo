use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION' => '2.27',
              'PREREQ_PM' => {
                              'Date::Manip' => 1,  # any version should do
                              'HTML::TreeBuilder' => 3.00,
                              'Jcode' => 0,  # only needed for `make test`
                              'WWW::Search' => 2.25,
                             },
             );
