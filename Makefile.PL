use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION_FROM' => 'lib/WWW/Search/Yahoo.pm',
              'PREREQ_PM' => {
                              'Date::Manip' => 1,  # any version should do
                              'HTML::TreeBuilder' => 3.00,
                              'WWW::Search' => 2.23,
                             },
             );
