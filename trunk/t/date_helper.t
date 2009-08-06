# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 50;
BEGIN { 
	use_ok('kbzb::helpers::date', qw(now mdate standard_date timespan days_in_month local_to_gmt gmt_to_local mysql_to_unix unix_to_human human_to_unix timezone_menu timezones) ) 
};

use Cwd; 
use CGI; 
use kbzb; 
kbzb::run({BASEPATH => getcwd() . '/lib', APPPATH => getcwd(), APPPKG => 'app', 'cgi' =>  CGI->new()}); 

# force timezone to EDT so the date conversions test work 
$ENV{TZ} = 'EDT+4';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $time = time();
my $date_time = now(); 
my $diff = $time - $date_time; 

ok(-1 * time() - now() < 10, 'now');

is(days_in_month(1, 2009), 31, 'days_in_month: January');
is(days_in_month(3, 2009), 31, 'days_in_month: March');
is(days_in_month(4, 2009), 30, 'days_in_month: April');
is(days_in_month(5, 2009), 31, 'days_in_month: May');
is(days_in_month(6, 2009), 30, 'days_in_month: June');
is(days_in_month(7, 2009), 31, 'days_in_month: July');
is(days_in_month(8, 2009), 31, 'days_in_month: August');
is(days_in_month(9, 2009), 30, 'days_in_month: September');
is(days_in_month(10, 2009), 31, 'days_in_month: October');
is(days_in_month(11, 2009), 30, 'days_in_month: November');
is(days_in_month(12, 2009), 31, 'days_in_month: December');
is(days_in_month(2, 1900), 28, 'days_in_month: February 1900 (no)');
is(days_in_month(2, 1901), 28, 'days_in_month: February 1901 (no)');
is(days_in_month(2, 1996), 29, 'days_in_month: February 1996 (yes)');
is(days_in_month(2, 2000), 29, 'days_in_month: February 2000 (yes)');
is(days_in_month(2, 2001), 28, 'days_in_month: February 2001 (no)');

is(gmt_to_local(1247672355, 'UM5'), 1247672355 - 5 * 60 * 60, 'gmt_to_local: GMT - 5');
is(gmt_to_local(1247672355, 'UM5', 1), 1247672355 - 4 * 60 * 60, 'gmt_to_local: GMT -5, DST');
is(gmt_to_local(1247672355, 'UP5', 0), 1247672355 + 5 * 60 * 60, 'gmt_to_local: GMT + 5');
is(gmt_to_local(1247672355, 'UP5', 1), 1247672355 + 6 * 60 * 60, 'gmt_to_local: GMT + 5, DST');

is(human_to_unix('2009-07-15 4:53:19 PM'), '1247691199', 'human_to_unix');

is(local_to_gmt(1247691199), 1247691199 + 5 * 60 * 60, 'local_to_gmt');

is(mysql_to_unix('2009-07-15 16:53:19'), '1247691199', 'mysql_to_unix: date with punctuation');
is(mysql_to_unix('20090715165319'), '1247691199', 'mysql_to_unix: date without punctuation');
is(mysql_to_unix('2009-07-15 16:53'), undef, 'mysql_to_unix: bad date');

is(standard_date('ATOM',    1247691199), '2009-07-15T16:53:19-0400', 'standard_date: atom');
is(standard_date('ISO8601', 1247691199), '2009-07-15T16:53:19-0400', 'standard_date: iso-8601');
is(standard_date('W3C',     1247691199), '2009-07-15T16:53:19-0400', 'standard_date: w3c');

is(standard_date('COOKIE',  1247691199), 'Wed, 15 Jul 2009 16:53:19 UTC', 'standard_date: cookie');

is(standard_date('RFC850',  1247691199), 'Wednesday 15-Jul-09 16:53:19 UTC', 'standard_date: rfc-850');

is(standard_date('RFC822',  1247691199), 'Wed, 15 Jul 09 16:53 EDT', 'standard_date: rfc-822');

is(standard_date('RFC1036', 1247691199), 'Wed, 15 Jul 09 16:53:19 -0400', 'standard_date: rfc-1036');

is(standard_date('RFC1123', 1247691199), 'Wed, 15 July 2009 16:53:19 -0400', 'standard_date: rfc-1123');
is(standard_date('RSS',     1247691199), 'Wed, 15 July 2009 16:53:19 -0400', 'standard_date: rss');

is(standard_date('asdf',     1247691199), undef, 'standard_date: bad format');
is(standard_date('',     1247691199), 'Wed, 15 Jul 09 16:53 EDT', 'standard_date: no format');


is(timespan(1247672355, 1247672375), '20 Seconds', 'timespan: seconds');
is(timespan(1247672355, 1247672435), '1 Minute, 20 Seconds', 'timespan: minutes, seconds');
is(timespan(1247672355, 1247676035), '1 Hour, 1 Minute, 20 Seconds', 'timespan: hour, minutes, seconds');

is(unix_to_human(1247691199), '2009-07-15 16:53', 'unix_to_human');
is(unix_to_human(1247691199, 1), '2009-07-15 16:53:19', 'unix_to_human: with seconds');
is(unix_to_human(1247691199, 0, 'us'), '2009-07-15  4:53 PM', 'unix_to_human: US format');
is(unix_to_human(1247691199, 1, 'us'), '2009-07-15  4:53:19 PM', 'unix_to_human: US format with seconds');

#@is(timezone_menu('foo'), 'expected', 'timezone_menu');

is(timezones('GMT'), 0, 'timezones: GMT');
is(timezones('UTC'), 0, 'timezones: UTC');
is(timezones('UM5'), -5, 'timezones: UM5');
is(timezones('UP5'), 5, 'timezones: UP5');
is(timezones('foo'), undef, 'timezones: junk timezone');
