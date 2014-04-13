# NAME

Mojo::UserAgent::Assistant - A rate-limiting wrapper for queuing non-blocking calls to Mojo::UserAgent

# SYNOPSIS

    use Mojo::UserAgent::Assistant;
    my $uaa = Mojo::UserAgent::Assistant->new();
    $uaa->ua->max_redirects(5); # set properties on Assistant's Mojo::UserAgent instance
    for my $url (@big_list_of_urls) {
      $uaa->get($url, 
             sub { 
              my ($ua, $tx) = @_;
              warn "failed to get $url" unless ($tx->success);
              say "Page at $url is titled: ",
                $tx->res->dom->at('title')->text;
             });
    }

# DESCRIPTION

[Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant) is a wrapper implementing a rate-limiting queue around [Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent).

[Mojo::UserAgent](http://search.cpan.org/perldoc?Mojo::UserAgent) allows you to to make concurrent, non-blocking HTTP requests using Mojo's event loop support.  However, if you make too many simultaneous requests, you will "overload" the event loop, and many of your requests will fail because 

# ATTRIBUTES

[Mojo::UserAgent::Assistant](http://search.cpan.org/perldoc?Mojo::UserAgent::Assistant) has the following attributes:
=head1 METHODS

[Mojolicious::Plugin::MyPlugin](http://search.cpan.org/perldoc?Mojolicious::Plugin::MyPlugin) inherits all methods from
[Mojolicious::Plugin](http://search.cpan.org/perldoc?Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](http://search.cpan.org/perldoc?Mojolicious) application.

# SEE ALSO

[Mojolicious](http://search.cpan.org/perldoc?Mojolicious), [Mojolicious::Guides](http://search.cpan.org/perldoc?Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us).
[http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html](http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html), [http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests](http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests).
