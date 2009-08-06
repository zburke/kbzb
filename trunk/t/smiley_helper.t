# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('kbzb::helpers::smiley', qw(js_insert_smiley get_clickable_smileys parse_smileys) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#is(js_insert_smiley('foo'), 'expected', 'testing js_insert_smiley');
#is(get_clickable_smileys('foo'), 'expected', 'testing get_clickable_smileys');
#is(parse_smileys('foo'), 'expected', 'testing parse_smileys');
#is(_get_smiley_array('foo'), 'expected', 'testing _get_smiley_array');
