# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 43;
BEGIN { use_ok('kbzb::helpers::string', qw(trim_slashes strip_slashes strip_quotes quotes_to_entities reduce_double_slashes reduce_multiples random_string alternator repeater) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
is(trim_slashes('/foo/bar/'), 'foo/bar', 'trim_slashes: leading, trailing');
is(trim_slashes('//foo/bar//'), 'foo/bar', 'trim_slashes: leading, trailing multiples');
is(trim_slashes('foo/bar'), 'foo/bar', 'trim_slashes: none');
is(trim_slashes('/foo/bar'), 'foo/bar', 'trim_slashes: leading');
is(trim_slashes('foo/bar/'), 'foo/bar', 'trim_slashes: trailing');

is(strip_slashes('/foo/'), 'foo', 'strip_slashes: leading, trailing');
is(strip_slashes('/foo/bar/'), 'foobar', 'strip_slashes: leading, trailing, embedded');
is(strip_slashes('//foo/bar//'), 'foobar', 'strip_slashes: leading, trailing, embeddd, multiple');
is(strip_slashes('foo/bar'), 'foobar', 'strip_slashes: embedded');
my $hash = { a => 'foo/bar', b => '/foo/bar/'}; 
my $hash_unslashed = { a => 'foobar', b => 'foobar'}; 
my $hash_treated = strip_slashes($hash); 

is($hash_treated->{a}, 'foobar', 'strip_slashes: hash');
is($hash_treated->{b}, 'foobar', 'strip_slashes: hash');


is(strip_quotes('foo"bar'), 'foobar', 'strip_quotes: quote');
is(strip_quotes("foo'bar"), 'foobar', 'strip_quotes: apostrophe');
is(strip_quotes("foo'\"bar"), 'foobar', 'strip_quotes: apostrophe, quote');


is(quotes_to_entities('o\'clock'), 'o&#39;clock', 'quotes_to_entities');
is(quotes_to_entities('o"clock'), 'o&quot;clock', 'quotes_to_entities');


is(reduce_double_slashes('www.example.org//foo//'), 'www.example.org/foo/', 'reduce_double_slashes');
is(reduce_double_slashes('http://www.example.org//foo//'), 'http://www.example.org/foo/', 'reduce_double_slashes: skip http://');


is(reduce_multiples('list,,of,items,,to,trim', ','), 'list,of,items,to,trim', 'reduce_multiples');
is(reduce_multiples('list,,of,items,,to,trim', ','), 'list,of,items,to,trim', 'reduce_multiples');
is(reduce_multiples(',,list,,of,items,,to,trim,,', ',', 1), 'list,of,items,to,trim', 'reduce_multiples');


like(random_string('alnum'), qr/[0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]{8,8}/, 'random_string: alnum');
like(random_string('numeric'), qr/[0123456789]{8,8}/, 'random_string: numeric');
like(random_string('nozero'), qr/[123456789]{8,8}/, 'random_string: numeric, no zeros');
like(random_string(), qr/[0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]{8,8}/, 'random_string: default');
like(random_string('numeric', 12), qr/[0123456789]{12,12}/, 'random_string: set-length');
like(random_string('numeric', 'abc'), qr/[0123456789]{8,8}/, 'random_string: bad-length');
like(random_string('numeric', 0), qr/[0123456789]{8,8}/, 'random_string: bad-length');
like(random_string('numeric', -1), qr/[0123456789]{8,8}/, 'random_string: bad-length');



is(alternator('foo', 'bar', 'bat'), 'foo', 'alternator - first');
is(alternator('foo', 'bar', 'bat'), 'bar', 'alternator - second');
is(alternator('foo', 'bar', 'bat'), 'bat', 'alternator - third');
is(alternator('foo', 'bar', 'bat'), 'foo', 'alternator - fourth');
is(alternator(), '', 'alternator - reset');
is(alternator('abc', 'def', 'ghi'), 'abc', 'alternator - new first');
is(alternator('abc', 'def', 'ghi'), 'def', 'alternator - new second');
is(alternator('abc', 'def', 'ghi'), 'ghi', 'alternator - new third');


is(repeater('foo'), 'foo', 'repeater');
is(repeater('foo', 2), 'foofoo', 'repeater,  x2');
is(repeater('foo', -1), 'foo', 'repeater, bad-count (negative)');
is(repeater('foo', 0), 'foo', 'repeater, bad-count (zero)');
is(repeater('foo', 'abc'), 'foo', 'repeater, bad-count (non-numeric)');
