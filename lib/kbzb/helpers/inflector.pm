package kbzb::helpers::inflector;

# -- $Id: inflector.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw(singular plural camelize underscore humanize ucwords) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
        
);



# ------------------------------------------------------------------------
# Inflector Helpers
#


# --------------------------------------------------------------------
# Singular
#
# Takes a plural word and makes it singular
#
# @access	public
# @param	string
# @return	str
#
sub singular
{
	my $str = shift;
	
	chomp $str; 
	$str = lc $str;
	
	my $end = substr($str, -3);

	if ($end eq 'ies')
	{
		$str = substr($str, 0, length($str)-3) . 'y';
	}
	elsif ($end eq 'ses')
	{
		$str = substr($str, 0, length($str)-2);
	}
	else
	{
		$end = substr($str, -1);
	
		if ($end eq 's')
		{
			$str = substr($str, 0, length($str)-1);
		}
	}

	return $str;
}



# --------------------------------------------------------------------
# Plural
#
# Takes a singular word and makes it plural
#
# @access	public
# @param	string
# @param	bool
# @return	str
#
sub plural
{
	my ($str, $force) = @_; 
	
	chomp $str; 
	
	$str = lc $str;
	my $end = substr($str, -1);

	if ($end eq 'y')
	{
		# Y preceded by vowel => regular plural
		my $letter = substr $str, -1, 1;
		if (grep /$letter/ , qw(a e i o u))
		{
			$str .= 's';
		}
		else
		{
			$str = substr($str, 0, -1) . 'ies';
		}
	}
	elsif ($end eq 's')
	{
		if ($force)
		{
			$str .= 'es';
		}
	}
	else
	{
		$str .= 's';
	}

	return $str;
}



# --------------------------------------------------------------------
# Camelize
#
# Takes multiple words separated by spaces or underscores and camelizes them
#
# @access	public
# @param	string
# @return	str
#
sub camelize
{
	my $str = shift;
	
	$str = 'x' . lc $str;
	$str =~ s/[\s_]+/ /g; 
	$str = ucwords($str); 
	$str =~ s/ //g;
	
	return substr($str, 1); 
}



# --------------------------------------------------------------------
# Underscore
#
# Takes multiple words separated by spaces and underscores them. 
# Leading and trailing whitespace is removed.
#
# @access	public
# @param	string
# @return	str
#
sub underscore
{
	my $str = shift; 
	
	$str =~ s/^\s*|\s*$//g;
	$str =~ s/[\s]+/_/g;
	
	return $str; 
}


# --------------------------------------------------------------------
# Humanize
#
# Takes multiple words separated by underscores and changes them to spaces
#
# @access	public
# @param	string
# @return	str
#
sub humanize
{
	my $str = shift;
	
	chomp $str; 
	
	$str =~ s/[_]+/ /g;
	$str =~ s/^\s*|\s*$//g; 
	
	return ucwords($str); 
}



# --------------------------------------------------------------------
# ucwords
#
# Takes multiple words separated by whitespace and capitalizes them
#
# @access	public
# @param	string
# @return	str
#
sub ucwords
{
	my $str = shift;
	
	$str = lc $str;
	$str =~ s/\b(\w)/\u$1/g;
	$str =~ s/\s\s*/ /g;     # condense multiple spaces to one
	$str =~ s/^\s*|\s*$//g;  # zap leading, trailing whitespace
	
	return $str; 
}

1;

__END__


=pod

=head1 NAME

inflector - single/plural helpers, and a few others.

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('inflector');
 
 # camelize: convert "package in java" to "packageInJava"
 $string = camelize('package in java'); 
 
 # humanize: convert "words_with_underscores" to "Words With Underscores"
 $string = humanize('words_with_underscores');
 
 # plural: convert "test" to "tests", "pansy" to "pansies"
 $string = plural('test'); 
 
 # plural: force conversion for words ending in 's', e.g. "octopus" to "octopuses"
 $string = plural('octopus', 1); 
 
 # singular: convert plurals back to singular
 $string = singular('pansies'); 
 
 # ucwords: convert 'all lower case' to 'All Lower Case'
 $string = ucwords('all lower case');
 
 # underscore: convert ' this is a test ' to 'this_is_a_test'
 $string = underscore(' this is a test '); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut