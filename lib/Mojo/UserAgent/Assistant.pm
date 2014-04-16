package Mojo::UserAgent::Assistant;
use Mojo::Base '-base';
use Mojo::IOLoop;
use Mojo::UserAgent;
use Mojo::Util 'monkey_patch';

our $VERSION = '0.01';

has max => sub { $_[0]->ua->max_connections || 4 };
has active => sub { 0 };
has jobs => sub { [] };
has timer => sub { undef };
has ua => sub { Mojo::UserAgent->new() };

use constant DEBUG => $ENV{HADASHOT_DEBUG} || 0;

sub pending {
  my $self = shift;
  return scalar @{$self->jobs};
};

for my $name (qw(delete get head options patch post put)) {
  monkey_patch __PACKAGE__, $name, sub {
    my $self = shift;
    my $job = { method => $name };
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    $job->{'cb'} = $cb if ($cb);
    $job->{'url'} = shift;
    $job->{'headers'} = { @_ } if (scalar @_ > 1 && @_ % 2 == 0);
    return $self->enqueue($job);
  };
}

sub start {
  my ($self) = @_;
  unless ($self->timer) {
    Mojo::IOLoop->start unless (Mojo::IOLoop->is_running);
    my $id = Mojo::IOLoop->recurring(3 => sub { $self->process(); });
    $self->timer($id);
  }
  return $self;
}

sub stop {
  my ($self) = @_;
  if ($self->timer) {
    Mojo::IOLoop->remove($self->timer);
    $self->timer(undef);
  }
  return $self;
}

sub enqueue {
  my $self = shift;
  # validate the job:
  my $job = shift;
  if ($job && ref $job eq 'HASH') {
    die "enqueue requires a url key in the hashref argument" unless ($job->{'url'} && Mojo::URL->new($job->{'url'}));
    die "enqueue requires a callback (cb key) in the hashref argument" unless ($job->{'cb'} && ref $job->{'cb'} eq 'CODE');
  # other valid keys: headers, data, method
  push @{$self->jobs}, $job;
  print STDERR "\nenqueued request for ", $job->{'url'}, "\n" if (DEBUG);
  }
  $self->start;
  return $self; # make chainable?
}

sub dequeue {
  my $self = shift;
  return shift @{$self->jobs};
}

sub process {
  my ($self) = @_;
  # we have jobs and can run them:
  while ($self->active < $self->max and my $job = $self->dequeue) {
      my ($url, $headers, $cb, $data, $method) = map { $job->{$_} } (qw(url headers cb data method));
      $method ||= 'get';
      $self->active($self->active+1);
      $self->ua->$method($url => $headers => sub {
        my ($ua, $tx) = @_;
        $self->active($self->active-1);
        print STDERR "handled " . $tx->req->url,
                     , " active is now ", $self->active, ", pending is ", $self->pending , "\n"
                     if (DEBUG);
        $cb->($ua, $tx, $data, $self);
        $self->process();
      });
  }
  if ($self->pending == 0 && $self->active == 0) {
    $self->stop(); # the timer shouldn't run STAM.
  }
}

1;
__END__

=encoding utf8

=head1 NAME

Mojo::UserAgent::Assistant - A rate-limiting wrapper for queuing non-blocking calls to Mojo::UserAgent

=head1 SYNOPSIS

  use Mojo::UserAgent::Assistant;

  my $uaA = Mojo::UserAgent::Assistant->new();

  $uaA->ua->max_redirects(5); # set properties on Assistant's Mojo::UserAgent instance
  
  for my $url (@big_list_of_urls) {
    $uaA->get($url, 
           sub { 
            my ($ua, $tx) = @_;
            warn "failed to get $url" unless ($tx->success);
            say "Page at $url is titled: ",
              $tx->res->dom->at('title')->text;
           });
  }

=head1 DESCRIPTION

L<Mojo::UserAgent::Assistant> is a wrapper implementing a rate-limiting queue 
around L<Mojo::UserAgent>.

While L<Mojo::UserAgent> allows you to to make concurrent, non-blocking HTTP
requests using Mojo's event loop support, you must take care to limit the number
of simultaneous requests, because it is still a single process handling all 
these connections.

Some discussion of this issue is available here
L<http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html>
and in Joel Berger's answer here:
L<http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests>.

L<Mojo::UserAgent::Assistant> tries to provide a transparent proxy between your
code and L<Mojo::UserAgent>, encapsulating the queuing of pending requests.

=head1 ATTRIBUTES

L<Mojo::UserAgent::Assistant> has the following attributes:

=head2 ua

  $self->ua(Mojo::UserAgent->new);
  $self->ua->max_redirects(3);

The L<Mojo::UserAgent> instance which handles all HTTP Requests.

=head2 active

  say "There are ", $assistant->active, " active requests";

Number of uncompleted requests that L<Mojo::UserAgent::Assistant> has submitted to L<Mojo::UserAgent> for handling.

=head2 max

  $assistant->max(4);

The maximum number of requests that can be active at one time; defaults to C<Mojo::UserAgent->max_connections> or 4.

=head2 jobs

The array of pending jobs that the assistant will submit to the user agent. Jobs are added to this array with the C<enqueue> method
and removed with C<dequeue>.

=head2 timer

A recurring timer for checking for new pending jobs.


=head1 METHODS

L<Mojo::UserAgent::Assistant> inherits all methods from L<Mojo::Base> and implements the following new ones.

B<get>, B<post>, B<head>, B<delete>, B<options>, B<put>, B<patch> are proxy methods to the methods
of the same name in L<Mojo::UserAgent>.

=head2 get

  $uaA->get('http://example.com' => { DNT => 1 } => sub {
    my ($ua, $tx) = @_;
    say $tx->res->body;
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking GET request. Accepts the same arguments as L<Mojo::UserAgent>'s C<get> method.
The callback argument is required.

=head2 post

  $uaA->post('http://example.com' => { DNT => 1 } => sub {
    my ($ua, $tx) = @_;
    say $tx->res->body;
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking POST request. Accepts the same arguments as L<Mojo::UserAgent>'s C<post> method.
The callback argument is required.

=head2 head

  $uaA->head('http://example.com' => { DNT => 1 } => sub {
    my ($ua, $tx) = @_;
    say $tx->res->body;
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking HEAD request. Accepts the same arguments as L<Mojo::UserAgent>'s C<head> method.
The callback argument is required.

=head2 delete

  $uaA->delete('http://example.com' => { DNT => 1 } => sub {
    my ($ua, $tx) = @_;
    say $tx->res->body;
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking DELETE request. Accepts the same arguments as L<Mojo::UserAgent>'s C<delete> method.
The callback argument is required.

=head2 options

  $uaA->options('http://example.com' => { DNT => 1 } => sub {
    my ($ua, $tx) = @_;
    say $tx->res->body;
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking OPTIONS request. Accepts the same arguments as L<Mojo::UserAgent>'s C<options> method.
The callback argument is required.

=head2 patch

  $uaA->patch('http://example.com' => { DNT => 1 } => sub {
    my ($ua, $tx) = @_;
    say $tx->res->body;
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking PATCH request. Accepts the same arguments as L<Mojo::UserAgent>'s C<patch> method.
The callback argument is required.

=head2 put

  $uaA->put('http://example.com' => { DNT => 1 } => sub {
    my ($ua, $tx) = @_;
    say $tx->res->body;
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking PUT request. Accepts the same arguments as L<Mojo::UserAgent>'s C<put> method.
The callback argument is required.

=head2 enqueue

  $uaA->enqueue({ method  => 'GET',
                  url     => 'http://example.com',
                  headers => { DNT => 1 },
                  data    => $global_count,
                  cb      => sub {
                      my ($ua, $tx, $data, $uaA) = @_;
                      $$data++ if ($tx->success);
                  } );

Low-level method for submitting a request. Argument is a hashref with B<method>, B<url>, B<headers>,
B<data> and B<cb> keys. The value of the B<data> key and a reference to the L<Mojo::UserAgent::Assistant>
object are passed as the 3rd and 4th arguments of the callback.

This method is used internally to implement the proxied methods above.

=head2 pending

  say $uaA->pending, " jobs are still pending";

The number of jobs still in the request queue.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.
L<http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html>, L<http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests>.

=cut

