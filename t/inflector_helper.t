# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 29;
BEGIN { use_ok('kbzb::helpers::inflector', qw(singular plural camelize underscore humanize ucwords) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(singular('pansies'), 'pansy', 'testing singular: pansies -> pansy');
is(singular('octopuses'), 'octopus', 'testing singular: octopuses -> octopus');
is(singular('computers'), 'computer', 'testing singular: computers -> computer');

is(plural('pansy'), 'pansies', 'testing plural: pansy -> pansies');
is(plural('octopus'), 'octopus', 'testing plural no-force: octopus -> octopus');
is(plural('octopus', 1), 'octopuses', 'testing plural force: octopus -> octopuses');
is(plural('computer'), 'computers', 'testing plural: computer -> computers');


is(camelize('foo_bar_bat'), 'fooBarBat', 'testing camelize');
is(camelize('foo bar bat'), 'fooBarBat', 'testing camelize');
is(camelize('foo  bar  bat'), 'fooBarBat', 'testing camelize');

is(underscore('foo bar bat'), 'foo_bar_bat', 'testing underscore');
is(underscore('foo  bar  bat'), 'foo_bar_bat', 'testing underscore');
is(underscore(' foo  bar  bat '), 'foo_bar_bat', 'testing underscore');
is(underscore(' foo  bar  bat'), 'foo_bar_bat', 'testing underscore');
is(underscore('foo  bar  bat '), 'foo_bar_bat', 'testing underscore');

is(humanize('foo_bar_bat'), 'Foo Bar Bat', 'testing humanize');
is(humanize('__foo_bar_bat'), 'Foo Bar Bat', 'testing humanize');
is(humanize('foo_bar_bat__'), 'Foo Bar Bat', 'testing humanize');
is(humanize('__foo_bar_bat__'), 'Foo Bar Bat', 'testing humanize');


is(ucwords('foo'), 'Foo', 'testing ucwords');
is(ucwords('fOO'), 'Foo', 'testing ucwords');
is(ucwords('foo bar'), 'Foo Bar', 'testing ucwords');
is(ucwords('foo BAR'), 'Foo Bar', 'testing ucwords');
is(ucwords('FOO'), 'Foo', 'testing ucwords');
is(ucwords(' foo bar'), 'Foo Bar', 'testing ucwords: leading whitespace');
is(ucwords('foo bar '), 'Foo Bar', 'testing ucwords: leading, trailing whitespace');
is(ucwords(' foo bar '), 'Foo Bar', 'testing ucwords: trailing whitespace');
is(ucwords(' foo  bar '), 'Foo Bar', 'testing ucwords: extra whitespace');
