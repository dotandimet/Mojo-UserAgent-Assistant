use Mojo::Base -strict;

use Test::More;

use Mojo::UserAgent::Assistant; # this we test;

use Mojolicious::Lite;

app->log->path('stress_servers.log');
app->log->format(sub { 
'[' . localtime(shift) . '] [' . app->moniker . '] [' . shift() . '] ' . join "\n", @_, '';
});


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
my (@urls, @pids);
for (1..7) {
  my $port = 340 . $_;
  my $url = "http://localhost:$port";
  my $pid = fork();
  unless($pid) {
    my $server = Mojo::Server::Daemon->new(listen => [$url]);
    $server->app(app);
    $server->app->moniker("test_$port");
    $server->run();
    $server->daemonize();
    exit(0);
  }
  push @urls, $url;
  push @pids, $pid;
}
say "@pids";
my ($disconnects, $expected_disconnects) = (0,0);
sub make_cb {
  my ($id, $wait) = @_;
  unless ($wait) { # get request
    return sub {
      my ($ua, $tx) = @_;
      is($tx->res->code, 200);
      is($tx->res->body, "Page $id");
    };
  }
  if ($wait == 20 && ($id eq 'spotty' or $id eq 'zoop' or $id eq 'dorm')) { # timeout
    return sub {
      my ($ua, $tx) = @_;
      is($tx->res->code, undef);
      is($tx->error->{message}, 'Premature connection close', "page $id $wait connection close");
      $disconnects++;
    };
  }
  else { #($wait < 15) { # wait but get response
    return sub {
      my ($ua, $tx) = @_;
      is($tx->res->code, 200);
      is($tx->res->body, "Page $id waited $wait seconds ", "page $id $wait second wait");
    };
  }
};

my $ua = Mojo::UserAgent::Assistant->new();
$ua->ua->max_redirects(3);
my $ua = Mojo::UserAgent->new();
$ua->max_redirects(3);
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
      $expected_disconnects++;
    }
  }
}
diag("test start");
Mojo::IOLoop->start() unless (Mojo::IOLoop->is_running);

is($disconnects, $expected_disconnects, "got expected number of disconnects");

done_testing;
