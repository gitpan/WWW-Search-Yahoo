use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION' => '2.24',
              'PREREQ_PM' => {
                              'Date::Manip' => 1,  # any version should do
                              'HTML::TreeBuilder' => 3.00,
                              'WWW::Search' => 2.23,
                             },
             );
