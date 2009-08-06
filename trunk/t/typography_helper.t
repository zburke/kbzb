# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('kbzb::helpers::typography', qw(nl2br_except_pre auto_typography) ) };

use kbzb; 
use CGI; 
use Cwd;
kbzb::run({BASEPATH => getcwd() . '/lib', APPPATH => getcwd(), APPPKG => 'app', 'cgi' =>  CGI->new()}); 

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#is(nl2br_except_pre('foo'), 'expected', 'testing nl2br_except_pre');
#is(auto_typography('foo'), 'expected', 'testing auto_typography');
