# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('kbzb::helpers::cookie', qw(set_cookie get_cookie delete_cookie) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#is(set_cookie('foo'), 'expected', 'testing set_cookie');
#is(get_cookie('foo'), 'expected', 'testing get_cookie');
#is(delete_cookie('foo'), 'expected', 'testing delete_cookie');
