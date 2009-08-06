package kbzb::helpers::hash;

# -- $Id: hash.pm 156 2009-07-27 20:10:52Z zburke $

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
# Hash Helpers
#



# ------------------------------------------------------------------------
# Element
#
# Lets you determine whether an array index is set and whether it has a value.
# If the element is empty it returns FALSE (or whatever you specify as the default value.)
#
# @access	public
# @param	string
# @param	array
# @param	mixed
# @return	mixed	depends on what the array contains
sub element
{
	my ($item, $hash, $default) = @_; 
	
	$default ||= ''; 

	return $default unless 'HASH' eq ref $hash;
	return $default unless exists $hash->{$item};
	
	return $hash->{$item}; 
}	


# ------------------------------------------------------------------------
# Random Element - Takes a hash as input and returns a random element
#
# @access	public
# @param	array
# @return	mixed	depends on what the array contains	
sub random_element
{
	my $hash = shift; 
	
	return $hash unless 'HASH' eq ref $hash;
	
	return $hash->{(keys %$hash)[rand keys %$hash]};
}	



1;

__END__


=pod

=head1 NAME

hash - help with hashes.

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('hashes');
 
 # get an item given its key
 $i = element(\%list, 'key'); 
 
 # get an item given its key, or 'unavailable' if no key exists in the list
 # note that a key with an empty value will return that empty value, not
 # 'unavailable', which is returned only when there is no key.
 $i = element(\@list, 2, 'unavailable'); 
 
 # get a random value from the list
 $i = random_element(\%list);

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

  
=cut
