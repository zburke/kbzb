# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('kbzb::helpers::url', qw(site_url base_url current_url uri_string index_page anchor anchor_popup mailto safe_mailto auto_link prep_url url_title redirect) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#is(site_url('foo'), 'expected', 'testing site_url');
#is(base_url('foo'), 'expected', 'testing base_url');
#is(current_url('foo'), 'expected', 'testing current_url');
#is(uri_string('foo'), 'expected', 'testing uri_string');
#is(index_page('foo'), 'expected', 'testing index_page');
#is(anchor('foo'), 'expected', 'testing anchor');
#is(anchor_popup('foo'), 'expected', 'testing anchor_popup');
#is(mailto('foo'), 'expected', 'testing mailto');
#is(safe_mailto('foo'), 'expected', 'testing safe_mailto');
#is(auto_link('foo'), 'expected', 'testing auto_link');
#is(prep_url('foo'), 'expected', 'testing prep_url');
#is(url_title('foo'), 'expected', 'testing url_title');
#is(redirect('foo'), 'expected', 'testing redirect');
#is(_parse_attributes('foo'), 'expected', 'testing _parse_attributes');
