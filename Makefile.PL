
use inc::Module::Install;

name('WWW-Search-Yahoo');
version(2.394);

author('Martin Thurn <mthurn@cpan.org>');
license('perl');

requires( perl => '5.004' );
requires('Data::Dumper');
requires('Date::Manip');
requires('HTML::TreeBuilder');
# Jcode is needed only for `make test` on Yahoo::Japan::News
recommends('Jcode');
# Test::More is needed for `make test`:
build_requires('Test::More');
requires('URI');
requires('URI::Escape');
# We need the version of WWW::Search that calls need_to_delay():
requires('WWW::Search' => 2.523);
# We need the version of WWW::Search::Test where count_results() takes
# a hashref as argument 7:
requires('WWW::Search::Test' => 2.26);

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

print STDERR <<END;

Note: the Jcode module is only needed if you want to send Japanese
queries to www.yahoo.co.jp using WWW::Search::Yahoo::Japan::News

END
