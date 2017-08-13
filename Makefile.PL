use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojo::UserAgent::Assistant',
    VERSION_FROM => 'lib/Mojo/UserAgent/Assistant.pm',
    AUTHOR       => 'Dotan Dimet <dotan@corky.net>',
    PREREQ_PM    => {
        'Mojolicious' => '7.40',
        'Role::Tiny'  => '2.000001',
        'Class::Method::Modifiers' => '1.05'
    },
    LICENSE      => 'artistic_2',
    ABSTRACT     => 'Queue non-blocking calls to Mojo::UserAgent',
    META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/dotandimet/Mojo-UserAgent-Assistant',
      bugtracker  => 'http://github.com/dotandimet/Mojo-UserAgent-Assistant/issues'
    },
    no_index => {directory => ['t']}
  },
#    test => { TESTS => 't/*.t' }
);
