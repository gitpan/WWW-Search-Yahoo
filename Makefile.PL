use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME' => 'WWW::Search::Yahoo',
              'VERSION_FROM' => 'Yahoo.pm', # finds $VERSION
              'PREREQ_PM' => {
                              'URI' => 0,
                              'WWW::Search' => 2.13,
                             },
             );
