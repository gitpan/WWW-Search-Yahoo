
use inc::Module::Install;

name('WWW::Search::Yahoo');
version(2.34);

author('Martin Thurn <mthurn@cpan.org>');
license('perl');

requires('Date::Manip');
requires('HTML::TreeBuilder');
# We need the version of WWW::Search that has its own
# native_setup_search():
requires('WWW::Search' => 2.43);

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
