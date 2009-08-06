# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('kbzb::helpers::array', qw(element random_element) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @list = qw/foo bar bat/; 

is(element(1, \@list), 'bar', 'element');
is(element(10, \@list), '', 'element: bad positive index');
is(element(-1, \@list), '', 'element: bad negative index');
is(element('foo', \@list), '', 'element: non-numeric index');
is(element(1, 'string'), '', 'element: non-array');
is(element(10, \@list, 'undefined'), 'undefined', 'element: default value');

like(random_element(\@list), qr/^foo|bar|bat$/, 'random element');
