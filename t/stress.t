use Mojo::Base -strict;

use Test::Mojo;
use Test::More;

use Mojo::UserAgent::Assistant; # this we test;

use Mojolicious::Lite;

my $counter;

get '/:id' => sub {
  my $self = shift;
  $self->render(text => "Page " . $self->param('id') . " with count " . $counter++);
}

my $pid = fork();

unless ($pid) {
  app->start();
}



done_testing;
