# DE.pm

=head1 NAME

WWW::Search::Yahoo::DE - class for searching Yahoo! Deutschland (Germany/.DE)

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::DE');
  my $sQuery = WWW::Search::escape_query("Perl OOP Freelancer");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result()) {
    print $oResult->url, "\n";
  }

=head1 DESCRIPTION

This class is a Yahoo! Deutschland (Germany) specialization of L<WWW::Search>.  It
handles making and interpreting searches on Yahoo! Deutschland (Germany)
F<http://de.yahoo.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 TESTING

There are no tests defined for this module.

=head1 AUTHOR

C<WWW::Search::Yahoo> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

If it''s not listed here, then it wasn''t a meaningful nor released revision.

=head2 1.00, 2003-06-20

First public release.

=cut

#####################################################################

package WWW::Search::Yahoo::DE;

use Data::Dumper;  # for debugging only
use WWW::Search::Yahoo;

use strict;
use vars qw( @ISA $VERSION $MAINTAINER );
@ISA = qw( WWW::Search::Yahoo );

$VERSION = '1.00';
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # print STDERR " +   in DE::native_setup_search, rh is ", Dumper($rh);
  $self->{'_options'} = {
                         'p' => $sQuery,
                         'y' => 'y',   # german sites only
                        };
  $rh->{'search_base_url'} = 'http://de.search.yahoo.com';
  $rh->{'search_base_path'} = '/search/de';
  # print STDERR " +   Yahoo::DE::native_setup_search() is calling SUPER::native_setup_search()...\n";
  return $self->SUPER::native_setup_search($sQuery, $rh);
  } # native_setup_search

1;

__END__
