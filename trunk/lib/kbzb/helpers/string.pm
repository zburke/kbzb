package kbzb::helpers::string;

# -- $Id: string.pm 174 2009-08-06 02:11:16Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
trim_slashes
strip_slashes
strip_quotes
quotes_to_entities
reduce_double_slashes
reduce_multiples
random_string
alternator
repeater
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
        
);


# ------------------------------------------------------------------------
# CodeIgniter String Helpers
#
# @package		CodeIgniter
# @subpackage	Helpers
# @category	Helpers
# @author		ExpressionEngine Dev Team
# @link		http://codeigniter.com/user_guide/helpers/string_helper.html


# ------------------------------------------------------------------------
# Trim Slashes
#
# Removes any leading/traling slashes from a string:
#
# /this/that/theother/
#
# becomes:
#
# this/that/theother
#
# @access	public
# @param	string
# @return	string
#
sub trim_slashes
{
	my ($str) = @_; 
	
	$str =~ s/^\/*|\/*$//g; 
	return $str;
} 



# ------------------------------------------------------------------------
# Strip Slashes
#
# Removes slashes contained in a string or in an array
#
# @access	public
# @param	mixed	string or array
# @return	mixed	string or array
#
sub strip_slashes
{
	my ($str) = @_; 

	$str ||= ''; 

	if ('HASH' eq ref $str)
	{
		for my $key (%{ $str })
		{
			$str->{$key} = strip_slashes($str->{$key});
		}
		
	}
	else
	{
		$str =~ s/\///g;
	}

	return $str;
}



# ------------------------------------------------------------------------
# Strip Quotes
#
# Removes single and double quotes from a string
#
# @access	public
# @param	string
# @return	string
#
sub strip_quotes
{
	my ($str) = @_; 
	
	$str =~ s/'|"//g;
	
	return $str; 
}



# ------------------------------------------------------------------------
# Quotes to Entities
#
# Converts single and double quotes to entities
#
# @access	public
# @param	string
# @return	string
#
sub quotes_to_entities
{	
	my ($str) = @_; 
	
	$str =~ s/'/&#39;/; 
	$str =~ s/"/&quot;/; 
	
	return $str; 
}



# ------------------------------------------------------------------------
# Reduce Double Slashes
#
# Converts double slashes in a string to a single slash,
# except those found in http://
#
# http://www.some-site.com//index.php
#
# becomes:
#
# http://www.some-site.com/index.php
#
# @access	public
# @param	string
# @return	string
#
sub reduce_double_slashes
{
	my ($str) = @_; 
	
	$str =~ s#([^:])//+#$1/#g;
	
	return $str; 
}



# ------------------------------------------------------------------------
# Reduce Multiples
#
# Reduces multiple instances of a particular character.  Example:
#
# Fred, Bill,, Joe, Jimmy
#
# becomes:
#
# Fred, Bill, Joe, Jimmy
#
# @access	public
# @param	string
# @param	string	the character you wish to reduce
# @param	bool	TRUE/FALSE - whether to trim the character from the beginning/end
# @return	string
#
sub reduce_multiples
{
	my ($str, $character, $trim) = @_;
	
	$character ||= ',';
	
	$str =~ s/$character{2,}/$character/g;

	if ($trim)
	{
		$str =~ s/^$character*|$character*$//g;
	}

	return $str;
}



# ------------------------------------------------------------------------
# Create a Random String
#
# Useful for generating passwords or hashes.
#
# @access	public
# @param	string 	type of random string.  Options: alunum, numeric, nozero, unique, hex
# @param	integer	number of characters
# @return	string
#
sub random_string
{					
	my ($type, $len) = @_; 
	
	$type ||= 'alnum';
	$len = 8 unless ($len && $len =~ /^[0-9]+$/ && $len > 0);
	
	if ($type eq 'unique')
	{
#@		case 'unique' : return md5(uniqid(mt_rand()));
#@		  break;
	}
	else
	{
		my $pool = '';
		$type eq 'alnum'   && ($pool = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ');
		$type eq 'numeric' && ($pool = '0123456789');
		$type eq 'nozero'  && ($pool = '123456789');
		$type eq 'hex'     && ($pool = '0123456789abcdef');
		
		my $str = ''; 
		my $max = length $pool;
		for (0..$len)
		{
			$str .= substr($pool, int(rand($max)), 1);
		}
		
		return $str; 
	}

}



# ------------------------------------------------------------------------
# Alternator
#
# Allows strings to be alternated.  See docs...
#
# @access	public
# @param	string (as many parameters as needed)
# @return	string
#
my $alternator_i = 0; 
sub alternator
{
	if (! scalar @_)
	{
		$alternator_i = 0; 
		return ''; 
	}
	
	return $_[($alternator_i++ % scalar @_)];
}



# ------------------------------------------------------------------------
# Repeater function
#
# @access	public
# @param	string
# @param	integer	number of repeats
# @return	string
#
sub repeater
{
	my ($data, $num) = @_; 
	
	$num = 1 unless $num && $num =~ /^[0-9]+$/ && $num > 0; 
	
	return ($num > 0) ? ($data x $num) : '';
} 


1;


__END__


=pod

=head1 NAME

string - functions for manipulating strings

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('string');
 
 # cycle through words on a list
 alternator([qw/a b c/]);   # returns a
 alternator([qw/a b c/]);   # returns b
 alternator([qw/a b c/]);   # returns c
 alternator([qw/a b c/]);   # returns a
 alternator();              # resets internal counter
 
 # convert " and ' to HTML entities
 $s = quotes_to_entities('I said, "You\'d better listen to me."');
 
 # generate an 8-character random alphanumeric string, i.e. [A-Za-z0-9]{8,8}
 $s = random_string('alnum');

 # generate an 8-character numeric random string
 $s = random_string('numeric');

 # generate an 8-character numeric random string without zeroes
 $s = random_string('nozero');
 
 # generate an 8-character hexadecimal random string, i.e. [a-f0-9]{8,8}
 $s = random_string('hex');
 
 # generate an $n-character random alphanumeric string
 $s = random_string('alnum', $n);

 # reduce double slashes: reduce embedded doubles, without affecting http://, https:// etc
 $s = reduce_double_slashes('/path/with//extra//slashes');
 
 # reduce multiple instances of a string, e.g. "foo, bar, , bat" -> "foo, bar, bat"
 $s = reduce_multiples('foo, bar, , bat', ', ');
 
 # reduce multiple instances of a string, and zap leading or trailing instances
 $s = reduce_multiples(', foo, bar, , bat', ', ');
 
 # copy a string n-times; just like perl's built-in x function
 $s = repeater('string', $n);
 
 # remove " and ' from a string. 
 $s = strip_quotes('I said, "You\'d better listen to me."');
 
 # remove / from within a string
 $s = strip_slashes('a and/or b');
 
 # remove leading and trailing / from a string.
 $s = trim_slashes('/path/to/directory/');
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
