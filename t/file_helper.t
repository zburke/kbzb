# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('kbzb::helpers::file', qw(read_file write_file delete_files get_filenames get_dir_file_info get_file_info get_mime_by_extension symbolic_permissions octal_permissions) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#is(read_file('foo'), 'expected', 'testing read_file');
#is(write_file('foo'), 'expected', 'testing write_file');
#is(delete_files('foo'), 'expected', 'testing delete_files');
#is(get_filenames('foo'), 'expected', 'testing get_filenames');
#is(get_dir_file_info('foo'), 'expected', 'testing get_dir_file_info');
#is(get_file_info('foo'), 'expected', 'testing get_file_info');
#is(get_mime_by_extension('foo'), 'expected', 'testing get_mime_by_extension');
#is(symbolic_permissions('foo'), 'expected', 'testing symbolic_permissions');
#is(octal_permissions('foo'), 'expected', 'testing octal_permissions');
