package kbzb::helpers::array;

# -- $Id: array.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw( element random_element) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


# ------------------------------------------------------------------------
# Array Helpers
#


# ------------------------------------------------------------------------
# Element
#
# Lets you determine whether an array index is set and whether it has a value.
# If the element is empty it returns '' (empty string, or whatever you specify as the default value.)
#
# @access	public
# @param	string
# @param	array
# @param	mixed
# @return	mixed	depends on what the array contains
sub element
{
	my ($index, $array, $default) = @_; 
	
	$default ||= ''; 
	return $default unless $index =~ /^[0-9]+$/;
	return $default unless 'ARRAY' eq ref $array;
	return $default unless $index >=0 && $index <= $#{$array};
		
	return $array->[$index]; 
}	



# ------------------------------------------------------------------------
# Random Element - Takes an array as input and returns a random element
#
# @access	public
# @param	array
# @return	mixed	depends on what the array contains	
sub random_element
{
	my ($array) = @_; 
	
	return $array unless 'ARRAY' eq ref $array;
	
	return ${ $array }[int(rand($#{$array}))]
}	



1;

__END__

=pod

=head1 NAME

array - help with arrays. NOTE THAT ARRAYS ARE ZERO-BASED.

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('array');
 
 # get the zeroeth item on a list
 $i = element(\@list, 0); 
 
 # get the second item on a list, or '' if the list contains < 3 items
 $i = element(\@list, 2); 

 # get the second item on a list, or 'unavailable' if the list contains < 3 items
 $i = element(\@list, 2, 'unavailable'); 
 
 # get a random element from the list
 $i = random_element(\@list);

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

