
use inc::Module::Install;

name('WWW-Search-Yahoo');
version(2.37);

author('Martin Thurn <mthurn@cpan.org>');
license('perl');

requires('Date::Manip');
requires('HTML::TreeBuilder');
# We need the version of WWW::Search that allows empty query string:
requires('WWW::Search' => 2.42);
# We need the version of WWW::Search that has its own
# native_setup_search():
requires('WWW::Search' => 2.43);
# We need the version of WWW::Search::Test where count_results() takes
# a hashref as argument 7:
requires('WWW::Search::Test' => 2.26);

# Test::More is needed for `make test`:
include_deps('Test::More', 5.004);
requires('Test::More');
# Jcode is needed only for `make test` on Yahoo::Japan::News
recommends('Jcode');

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

print STDERR <<END;

Note: the Jcode module is only needed if you want to send Japanese
queries to www.yahoo.co.jp using WWW::Search::Yahoo::Japan::News

END
