# China.pm
# by Martin Thurn
# $Id: China.pm,v 2.4 2004/09/12 12:51:13 Daddy Exp $

=head1 NAME

WWW::Search::Yahoo::China - class for searching Yahoo! China

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::China');
  my $sQuery = WWW::Search::escape_query("暴囂勧秤");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo! China specialization of L<WWW::Search>.  It
handles making and interpreting searches on Yahoo! China
F<http://cn.yahoo.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

I have no idea what character encoding(s) are accepted/expected by
Yahoo's website.  To create/test this backend I just cut-and-pasted
Chinese characters from cn.yahoo.com.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 AUTHOR

C<WWW::Search::Yahoo> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Yahoo::China;

use Data::Dumper;  # for debugging only
use WWW::Search::Yahoo;

use strict;
use vars qw( @ISA $VERSION $MAINTAINER );
@ISA = qw( WWW::Search::Yahoo );

$VERSION = do { my @r = (q$Revision: 2.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         'p' => $sQuery,
                         'scch' => 'on',
                         'stype' => '',
                        };
  $rh->{'search_base_url'} = 'http://cn.search.yahoo.com';
  $rh->{'search_base_path'} = '/search/cn';
  return $self->SUPER::native_setup_search($sQuery, $rh);
  } # native_setup_search

sub _string_has_count
  {
  my $self = shift;
  my $s = shift;
  # THIS IS THE ENGLISH VERSION, I NEED A CHINESE READER TO SEND ME
  # THE CORRECT PATTERN.  UNTIL THEN THIS MODULE WILL ALWAYS RETURN
  # 0 in approximate_result_count.
  return $1 if ($s =~ m!\bof\s+(?:about\s+)?([,0-9]+)!i);
  return -1;
  } # _string_has_count

sub _a_is_next_link
  {
  my $self = shift;
  my $oA = shift;
  return 0 unless (ref $oA);
  # I can not type Chinese, nor even cut-and-paste into Emacs with
  # confidence that the encoding will not get screwed up, so I resort
  # to this ugliness:
  return ($oA->as_HTML =~ m!&Iuml;&Acirc;&Ograve;&raquo;&Ograve;&sup3;!i);
  } # _a_is_next_link

1;

__END__
