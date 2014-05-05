use Mojo::UserAgent::Assistant;

use FindBin;
use File::Spec;

use Mojo::Util qw(trim);

my $u = Mojo::UserAgent::Assistant->new;
$u->ua->max_redirects(5);

my $list = File::Spec->catfile( $FindBin::Bin, 'sites_from_feeds.txt' );
open my $fh, '<', $list || die "Can't read $list: $!\n";
my %results;
while (<$fh>) {
    chomp;
    $results{$_} = undef;
    $u->get(
        $_ => sub {
            my $tx = $_[1];
            my $url = $tx->req->url;
            if ( $tx->success ) {
                $results{$url} = $tx->res->code . ' '
                  . trim $tx->res->dom->find(q{title})->pluck('text')->join('');
            }
            else {
## Please see file perltidy.ERR
              $results{$url}   = ":(";
            }
            print $url, " ", $results{$url}, "\n";
        }
    );
}

Mojo::IOLoop->start;
