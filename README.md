# NAME

Mojo::UserAgent::Assistant - A rate-limiting wrapper for queuing non-blocking calls to Mojo::UserAgent

# SYNOPSIS

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

# DESCRIPTION

[Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant) is a wrapper implementing a rate-limiting queue 
around [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent).

While [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent) allows you to to make concurrent, non-blocking HTTP
requests using Mojo's event loop support, you must take care to limit the number
of simultaneous requests, because it is still a single process handling all 
these connections.

Some discussion of this issue is available here
[http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html](http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html)
and in Joel Berger's answer here:
[http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests](http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests).

[Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant) tries to provide a transparent proxy between your
code and [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent), encapsulating the queuing of pending requests.

# ATTRIBUTES

[Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant) has the following attributes:

## ua

    $self->ua(Mojo::UserAgent->new);
    $self->ua->max_redirects(3);

The [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent) instance which handles all HTTP Requests.

## active

    say "There are ", $assistant->active, " active requests";

Number of uncompleted requests that [Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant) has submitted to [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent) for handling.

## max

    $assistant->max(4);

The maximum number of requests that can be active at one time; defaults to `Mojo::UserAgent-`max\_connections> or 4.

## jobs

The array of pending jobs that the assistant will submit to the user agent. Jobs are added to this array with the `enqueue` method
and removed with `dequeue`.

## timer

A recurring timer for checking for new pending jobs.



# METHODS

[Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant) inherits all methods from [Mojo::Base](http://search.cpan.org/perldoc?Mojo::Base) and implements the following new ones.

__get__, __post__, __head__, __delete__, __options__, __put__, __patch__ are proxy methods to the methods
of the same name in [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent).

## get

    $uaA->get('http://example.com' => { DNT => 1 } => sub {
      my ($ua, $tx) = @_;
      say $tx->res->body;
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking GET request. Accepts the same arguments as [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent)'s `get` method.
The callback argument is required.

## post

    $uaA->post('http://example.com' => { DNT => 1 } => sub {
      my ($ua, $tx) = @_;
      say $tx->res->body;
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking POST request. Accepts the same arguments as [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent)'s `post` method.
The callback argument is required.

## head

    $uaA->head('http://example.com' => { DNT => 1 } => sub {
      my ($ua, $tx) = @_;
      say $tx->res->body;
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking HEAD request. Accepts the same arguments as [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent)'s `head` method.
The callback argument is required.

## delete

    $uaA->delete('http://example.com' => { DNT => 1 } => sub {
      my ($ua, $tx) = @_;
      say $tx->res->body;
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking DELETE request. Accepts the same arguments as [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent)'s `delete` method.
The callback argument is required.

## options

    $uaA->options('http://example.com' => { DNT => 1 } => sub {
      my ($ua, $tx) = @_;
      say $tx->res->body;
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking OPTIONS request. Accepts the same arguments as [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent)'s `options` method.
The callback argument is required.

## patch

    $uaA->patch('http://example.com' => { DNT => 1 } => sub {
      my ($ua, $tx) = @_;
      say $tx->res->body;
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking PATCH request. Accepts the same arguments as [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent)'s `patch` method.
The callback argument is required.

## put

    $uaA->put('http://example.com' => { DNT => 1 } => sub {
      my ($ua, $tx) = @_;
      say $tx->res->body;
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

Submit a non-blocking PUT request. Accepts the same arguments as [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent)'s `put` method.
The callback argument is required.

## enqueue

    $uaA->enqueue({ method  => 'GET',
                    url     => 'http://example.com',
                    headers => { DNT => 1 },
                    data    => $global_count,
                    cb      => sub {
                        my ($ua, $tx, $data, $uaA) = @_;
                        $$data++ if ($tx->success);
                    } );

Low-level method for submitting a request. Argument is a hashref with __method__, __url__, __headers__,
__data__ and __cb__ keys. The value of the __data__ key and a reference to the [Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant)
object are passed as the 3rd and 4th arguments of the callback.

This method is used internally to implement the proxied methods above.

## pending

    say $uaA->pending, " jobs are still pending";

The number of jobs still in the request queue.

# SEE ALSO

[Mojolicious](http://search.cpan.org/perldoc?Mojolicious), [Mojolicious::Guides](http://search.cpan.org/perldoc?Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us).
[http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html](http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html), [http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests](http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests).
