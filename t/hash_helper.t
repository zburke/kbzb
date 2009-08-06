# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('kbzb::helpers::hash', qw(element random_element) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $list = { a => 'foo', b => 'bar', 'c' => 'bat'}; 

is(element('b', $list), 'bar', 'element');
is(element('mimsy', $list), '', 'element: non-existent index');
is(element('mimsy', $list, 'borogoves'), 'borogoves', 'element: non-existent index with default');
is(element('b', 'string'), '', 'element: non-hash');

like(random_element($list), qr/^foo|bar|bat$/, 'random element');
is(random_element('list'), 'list', 'random element: non-hash');
