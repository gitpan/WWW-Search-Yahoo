
use inc::Module::Install;

name('WWW-Search-Yahoo');
version(2.413);

author('Martin Thurn <mthurn@cpan.org>');
license('perl');

requires( perl => '5.004' );
requires('Data::Dumper');
requires('Date::Manip');
build_requires('Encode');
requires('HTML::TreeBuilder');
build_requires('I18N::Charset');
# Test::More is needed for `make test`:
build_requires('Test::More');
requires('URI');
requires('URI::Escape');
# We need the version of WWW::Search that calls need_to_delay():
requires('WWW::Search' => 2.523);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
build_requires('WWW::Search::Test' => 2.265);

WriteAll;

__END__
