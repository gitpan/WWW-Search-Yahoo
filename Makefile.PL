use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION_FROM' => 'lib/WWW/Search/Yahoo.pm',
              'PREREQ_PM' => {
                              'HTML::TreeBuilder' => 0,
                              'WWW::Search' => 2.15,
                             },
             );
