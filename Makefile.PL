use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION_FROM' => 'Yahoo.pm', # finds $VERSION
              'PREREQ_PM' => {
                              'HTML::TreeBuilder' => 0,
                              'WWW::Search' => 2.15,
                             },
             );
