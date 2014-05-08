use Mojo::Base -strict;

use Test::More;

use Mojo::UserAgent::Assistant; # this we test;

use Mojolicious::Lite;

get '/:id' => sub {
  my $self = shift;
  $self->render(text => "Page " . $self->param('id'));
};

post '/:id' => sub {
  my $self = shift;
  my $wait = $self->param('wait') || 3;
  $self->render_later;
  my $msg = "Page " . $self->param('id') . " waited $wait seconds ";
  my $tid = Mojo::IOLoop->timer(
      $wait => sub {
          $self->render( text => $msg );
     }
  );
  $self->on(error  => sub { Mojo::IOLoop->remove($tid); });
  $self->on(finish => sub { Mojo::IOLoop->remove($tid); });
};

get '/redirect/:id' => sub {
  my $self = shift;
  $self->render_later;
  my $tid = Mojo::IOLoop->timer(
    7 => sub {
      $self->redirect_to('/' . $self->stash('id'));
    }
  );
  $self->on(error  => sub { Mojo::IOLoop->remove($tid) });
  $self->on(finish => sub { Mojo::IOLoop->remove($tid) });
};

# fork 7 server daemons:
my @urls;
for (1..7) {
  my $port = Mojo::IOLoop->generate_port;
  my $url = "http://localhost:$port";
  my $pid = fork();
  unless($pid) {
    my $server = Mojo::Server::Daemon->new(listen => [$url]);
    $server->app(app);
    $server->run();
    $server->daemonize();
    exit(0);
  }
  push @urls, $url;
}

sub make_cb {
  my ($id, $wait) = @_;
  unless ($wait) { # get request
    return sub {
      my ($ua, $tx) = @_;
      is($tx->res->code, 200);
      is($tx->res->body, "Page $id");
    };
  }
  if ($wait < 15) { # wait but get response
    return sub {
      my ($ua, $tx) = @_;
      is($tx->res->code, 200);
      is($tx->res->body, "Page $id waited $wait seconds ", "$wait second wait");
    };
  }
  else { # wait == timeout
    return sub {
      my ($ua, $tx) = @_;
      is($tx->res->code, undef);
      is($tx->error, 'Premature connection close', 'connection close');
    };
  }
};

my $ua = Mojo::UserAgent::Assistant->new();
$ua->ua->max_redirects(3);
for my $url (@urls) {
  for my $id (qw(red blue pink spotty tim frank zoop flarg dick jane elaine george forge storm dorm hank bank)) {
    $ua->get("$url/$id" => make_cb($id));
    $ua->get("$url/redirect/$id" => make_cb($id)); # redirect
    for my $w (8, 5, 3) {
      $ua->post("$url/$id", form => { wait => $w}, make_cb($id, $w));
    }
    if ($id eq 'spotty' or $id eq 'zoop' or $id eq 'dorm') {
      $ua->post("$url/$id", form => { wait => 13}, make_cb($id, 13));
      $ua->post("$url/$id", form => { wait => 20}, make_cb($id, 20));
    }
  }
}
diag("test start");
Mojo::IOLoop->start() unless (Mojo::IOLoop->is_running);

done_testing;
