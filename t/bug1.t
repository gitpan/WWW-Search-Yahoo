
=head2 description

This bug was reported by mc at hack dot pl on 2005-07-01.
Here is the original report:

I've found a bug in [WWW::Search::Yahoo]. It was unable to switch to next
result page if you did a search like 'link:http://www.google.com'.  The
reason was that the query itself contained 'http' string and this
regular expression in parse_tree function failed:

      # Delete Yahoo-redirect portion of URL:
[339] $sURL =~ s!\A.+?\*?-?(?=http)!!;
      $sURL =~ s!\Ahttp%3A!http:!i;
      $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $sURL);
      printf STDERR " +   cooked next URL ==$self->{_next_url}==\n" if
      (2 <= $self->{_debug});

My temporary solution was to change the line 339 to:

      $sURL =~ s!\A.+?\*-(?=http)!!;

=cut

use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

&tm_new_engine('Yahoo');
my $iDebug = 0;
my $iDump = 0;
# Make sure the "link:http://..." search is able to go past the first
# page of results:
&tm_run_test('normal', 'link:http://www.google.com', 101, undef, $iDebug, $iDump);

__END__
