package kbzb::helpers::directory;

# -- $Id: directory.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw(directory_map) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );




# ------------------------------------------------------------------------
# Directory Helpers


# ------------------------------------------------------------------------
# Create a Directory Map
#
# Reads the specified directory and builds an array
# representation of it.  Sub-folders contained with the
# directory will be mapped as well.
#
# @access	public
# @param	string	path to source
# @param	bool	whether to limit the result to the top level only
# @return	array
	
sub directory_map
{
	my ($source_dir, $top_level_only) = @_; 
	
	my $hash = {}; 
	
	opendir(DIR, $source_dir) || return;
	
	# read directory, skipping dot files
	my @contents = grep { (! /^\./) && -e "$source_dir/$_" } readdir(DIR);
	closedir DIR;
	
	if (scalar @contents)
	{
		for (@contents)
		{
			if ((! $top_level_only) && -d "$source_dir/$_")
			{
				$hash->{$_} = directory_map("$source_dir/$_");
			}
			else
			{
				$hash->{$_}; 
			}
		}
	}
	
	return $hash; 
	
}


1;


__END__


=pod

=head1 NAME

directory - build a hash analagous to a directory tree. 

=head2 DESCRIPTION

 # load the helper from within a controller ... 
 $self->load->helper('directory');
 
 # build a recursive hash with keys representing entries and values
 # representing nested directories.
 $hash_ref = directory_map('/path/to/directory');  

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
