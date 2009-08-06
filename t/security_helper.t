# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('kbzb::helpers::security', qw(xss_clean dohash strip_image_tags encode_php_tags) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#@is(xss_clean('foo'), 'expected', 'testing xss_clean');

is(dohash('asdf'), '912ec803b2ce49e4a541068d495ab570', 'dohash');
is(dohash(''), 'd41d8cd98f00b204e9800998ecf8427e', 'dohash: empty string');
is(dohash('1234'), '81dc9bdb52d04dc20036dbd8313ed055', 'testing dohash');
is(dohash('1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf1234asdf'), '1f42858199c11e5900b1c7b587569a55', 'testing dohash');

is(strip_image_tags('<img src="/some/path/to/image.jpg" />'), '/some/path/to/image.jpg', 'testing strip_image_tags');
is(strip_image_tags('<img src="/some/path/to/image.jpg" title="some title" height="640" width="480" />'), '/some/path/to/image.jpg', 'testing strip_image_tags');

is(encode_php_tags('<?php echo "foo" ?>'), '&lt;?php echo "foo" ?&gt;', 'testing encode_php_tags');
is(encode_php_tags('<?PHP echo "foo" ?>'), '&lt;?PHP echo "foo" ?&gt;', 'testing encode_php_tags');
is(encode_php_tags('<? echo "foo" ?>'), '&lt;? echo "foo" ?&gt;', 'testing encode_php_tags');
