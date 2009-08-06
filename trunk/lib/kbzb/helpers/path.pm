package kbzb::helpers::path;

# -- $Id: path.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;
use Cwd 'abs_path'; 

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( set_realpath ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );



# ------------------------------------------------------------------------
# Path Helpers
#

# ------------------------------------------------------------------------
# Set Realpath
#
# @access	public
# @param	string
# @param	bool	checks to see if the path exists
# @return	string
#
sub set_realpath
{
	my ($path, $check_existance) = @_; 
	
	# Security check to make sure the path is NOT a URL.  No remote file inclusion!
	if ($path =~ /^(http:\/\/|https:\/\/|www\.|ftp|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/i)
	{
		kbzb::libraries::common::show_error('The path you submitted must be a local server path, not a URL');
	}

	# Resolve the path
	$path = abs_path($path) . '/';

	# Add a trailing slash
	$path =~ s#([^/])/*$#$1/#;
	
	# Make sure the path exists
	if ($check_existance)
	{
		if ( ! -d $path)
		{
			kbzb::libraries::common::show_error('Not a valid path: ' . $path);
		}
	}

	return $path;
}


1;

__END__


=pod

=head1 NAME

path - find a directory's real path

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('path');
 
 # retrieve a directory's absolute path 
 $path = set_realpath('/path/containing/symlinks'); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut