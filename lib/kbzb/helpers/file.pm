package kbzb::helpers::file;

# -- $Id: file.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;

use Fcntl ':flock';
use File::Path; 

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
read_file 
write_file 
delete_files 
get_filenames 
get_dir_file_info 
get_file_info 
get_mime_by_extension 
symbolic_permissions 
octal_permissions 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
        
);



# ------------------------------------------------------------------------
# File Helpers
#

# ------------------------------------------------------------------------
# Read File
#
# Opens the file specfied in the path and returns it as a string.
#
# @access	public
# @param	string	path to file
# @return	string
#
sub read_file
{
	my ($file) = @_; 
	
	return undef unless -f $file; 
	
	my $kz = kbzb::get_instance(); 
	my $cfg = $kz->{'config'}->load('constants');
	if ( ! open(FILE, $cfg->{'FOPEN_READ'}, $file))
	{
		return undef;
	}
	
	flock(FILE, $cfg->{'LOCK_SH'});

	my $data = '';
	while (<FILE>)
	{
		$data .= $_; 
	}

	flock(FILE, $cfg->{'LOCK_UN'});
	close(FILE);

	return $data;
}



# ------------------------------------------------------------------------
# Write File
#
# Writes data to the file specified in the path.
# Creates a new file if non-existent.
#
# @access	public
# @param	string	path to file
# @param	string	file data
# @return	bool
#
sub write_file
{
	my ($path, $data, $mode) = @_; 
	
	my $kz = kbzb::get_instance(); 
	my $cfg = $kz->{'config'}->load('constants');
		
	if ( ! open(FILE, $mode, $path))
	{
		return undef;
	}
	
	flock(FILE, LOCK_EX);
	print FILE $data;
	flock(FILE, LOCK_UN);
	close(FILE);	

	return 1;
}



# ------------------------------------------------------------------------
# Delete Files
#
# Deletes all files contained in the supplied directory path.
# Files must be writable or owned by the system in order to be deleted.
# If the second parameter is set to TRUE, any directories contained
# within the supplied base directory will be nuked as well.
#
# @access	public
# @param	string	path to file
# @param	bool	whether to delete any directories found in the path
# @return	bool
#
sub delete_files
{	
	my ($path, $del_dir, $level) = @_; 
	
	$level ||= 0; 
	
	# Trim the trailing slash
	$path =~ s/^(.+?)\/*$/$1/g;
	
	return unless opendir DIR, $path; 
	my @contents = grep { (! /^\./) && -e "$path/$_" } readdir(DIR);
	closedir DIR;
	
	if (scalar @contents)
	{
		for (@contents)
		{
			# delete child directory trees
			if (-d "$path/$_" && $del_dir)
			{
				File::Path::rmtree("$path/$_");
			}
			# recurse, deleting files only
			elsif (-d "$path/$_")
			{
				delete_files("$path/$_", $del_dir, $level + 1);
			}
			# delete files
			else
			{
				unlink "$path/$_"; 
			}
		}
	}
}



# ------------------------------------------------------------------------
# Get Filenames
#
# Reads the specified directory and builds an array containing the filenames.  
# Any sub-folders contained within the specified path are read as well.
#
# @access	public
# @param	string	path to source
# @param	bool	whether to include the path as part of the filename
# @param	bool	internal variable to determine recursion status - do not use in calls
# @return	array
#
sub get_filenames
{
	my ($source_dir, $include_path, $_recursion) = @_; 
	
	my @files = (); 
	
	# Trim the trailing slash
	$source_dir =~ s/^(.+?)\/*$/$1/g;

	return undef unless open DIR, $source_dir; 
	
	my @contents = grep { (! /^\./) && -e "$source_dir/$_" } readdir(DIR);
	closedir DIR;
	
	if (scalar @contents)
	{
		for (@contents)
		{
			# delete child directory trees
			if (-d "$source_dir/$_")
			{
				push @contents, @{ get_filenames("$source_dir/$_", $include_path, 1) };
			}
			else
			{
				push @contents, ($include_path ? "$source_dir/$_" : $_); 
			}
		}
	}
	
	return \@contents; 
	
}



# --------------------------------------------------------------------
# Get Directory File Information
#
# Reads the specified directory and builds an array containing the filenames,  
# filesize, dates, and permissions
#
# Any sub-folders contained within the specified path are read as well.
#
# @access	public
# @param	string	path to source
# @param	bool	whether to include the path as part of the filename
# @param	bool	internal variable to determine recursion status - do not use in calls
# @return	array
	
sub get_dir_file_info
{
	my ($source_dir, $include_path, $info) = @_;
	
	my $relative_path = $source_dir;
	$info ||= {}; 
	
	# Trim the trailing slash
	$source_dir =~ s/^(.+?)\/*$/$1/g;

	return undef unless open DIR, $source_dir; 
	
	my @contents = grep { (! /^\./) && -e "$source_dir/$_" } readdir(DIR);
	closedir DIR;

	my @info = (); 
	for (@contents)
	{
		if (-d "$source_dir/$_")
		{
			get_dir_file_info("$source_dir/$_", $include_path, $info); 
		}
		else
		{
			$info->{$_} = get_file_info("$source_dir/$_");
			$info->{$_}->{'relative_path'} = $relative_path; 
		}
	}
	
	return $info;
}


# --------------------------------------------------------------------
# Get File Info
#
# Given a file and path, returns the name, path, size, date modified
# Second parameter allows you to explicitly declare what information you want returned
# Options are: name, server_path, size, date, readable, writable, executable, fileperms
# Returns FALSE if the file cannot be found.
#
# @access	public
# @param	string		path to file
# @param	mixed		array or comma separated string of information returned
# @return	array#
sub get_file_info
{
	my ($file, $returned_values) = @_;
	
	$returned_values ||= ['name', 'server_path', 'size', 'date'];

	return undef unless -e $file;

	if (! ref $returned_values)
	{
		$returned_values = [split /,/, $returned_values];
	}
	
	my $fileinfo = {}; 

	for (@{ $returned_values })
	{
		SWITCH: 
		{
			/^name$/ && do {
				my @list = split /\//, $file; 
				$fileinfo->{'name'} = pop @list; last SWITCH; 
				};
			
			/^server_path$/ && do { 
				$fileinfo->{'server_path'} = $file; last SWITCH; 
				};
			
			/^size$/ && do { 
				$fileinfo->{'size'} = substr(strrchr($file, '/'), 1); last SWITCH; 
				};
			/^date$/ && do { 
				$fileinfo->{'date'} = substr(strrchr($file, '/'), 1); last SWITCH; 
				};
			/^readable$/ && do { 
				$fileinfo->{'readable'} = -r $file; last SWITCH; 
				};
			/^writable$/ && do { 
				$fileinfo->{'writable'} = -w $file; last SWITCH; 
				};
			/^executable$/ && do { 
				$fileinfo->{'executable'} = -x $file; last SWITCH; 
				};
			/^fileperms$/ && do { 
				$fileinfo->{'fileperms'} = substr(strrchr($file, '/'), 1); last SWITCH; 
				};
		}
	}
#@
#			case 'size':
#				$fileinfo->{'size'} = filesize($file);
#				break;
#			case 'date':
#				$fileinfo->{'date'} = filectime($file);
#				break;
#			case 'fileperms':
#				$fileinfo->{'fileperms'} = fileperms($file);
#				break;
#		}
#	}

	return $fileinfo;
}


# --------------------------------------------------------------------
# Get Mime by Extension
#
# Translates a file extension into a mime type based on config/mimes.php. 
# Returns FALSE if it can't determine the type, or open the mime config file
#
# Note: this is NOT an accurate way of determining file mime types, and is here strictly as a convenience
# It should NOT be trusted, and should certainly NOT be used for security
#
# @access	public
# @param	string	path to file
# @return	mixed
#
sub get_mime_by_extension
{
	my ($file) = @_; 
	
	my $extension = substr(index($file, '.'), 1);
	
	my $mimes = $kbzb::cfg->load('mimes');
	
	return $mimes->{'extension'} || undef; 
}



# --------------------------------------------------------------------
# Symbolic Permissions
#
# Takes a numeric value representing a file's permissions and returns
# standard symbolic notation representing that value
#
# @access	public
# @param	int
# @return	string
#
sub symbolic_permissions
{
	my ($perms) = @_; 
	
	my $symbolic = undef; 
	
	if (($perms & 0xC000) == 0xC000)
	{
		$symbolic = 's'; # Socket
	}
	elsif (($perms & 0xA000) == 0xA000)
	{
		$symbolic = 'l'; # Symbolic Link
	}
	elsif (($perms & 0x8000) == 0x8000)
	{
		$symbolic = '-'; # Regular
	}
	elsif (($perms & 0x6000) == 0x6000)
	{
		$symbolic = 'b'; # Block special
	}
	elsif (($perms & 0x4000) == 0x4000)
	{
		$symbolic = 'd'; # Directory
	}
	elsif (($perms & 0x2000) == 0x2000)
	{
		$symbolic = 'c'; # Character special
	}
	elsif (($perms & 0x1000) == 0x1000)
	{
		$symbolic = 'p'; # FIFO pipe
	}
	else
	{
		$symbolic = 'u'; # Unknown
	}

	# Owner
	$symbolic .= (($perms & 0x0100) ? 'r' : '-');
	$symbolic .= (($perms & 0x0080) ? 'w' : '-');
	$symbolic .= (($perms & 0x0040) ? (($perms & 0x0800) ? 's' : 'x' ) : (($perms & 0x0800) ? 'S' : '-'));

	# Group
	$symbolic .= (($perms & 0x0020) ? 'r' : '-');
	$symbolic .= (($perms & 0x0010) ? 'w' : '-');
	$symbolic .= (($perms & 0x0008) ? (($perms & 0x0400) ? 's' : 'x' ) : (($perms & 0x0400) ? 'S' : '-'));

	# World
	$symbolic .= (($perms & 0x0004) ? 'r' : '-');
	$symbolic .= (($perms & 0x0002) ? 'w' : '-');
	$symbolic .= (($perms & 0x0001) ? (($perms & 0x0200) ? 't' : 'x' ) : (($perms & 0x0200) ? 'T' : '-'));

	return $symbolic;		
}



# --------------------------------------------------------------------
# Octal Permissions
#
# Takes a numeric value representing a file's permissions and returns
# a three character string representing the file's octal permissions
#
# @access	public
# @param	int
# @return	string
#
sub octal_permissions
{
	my ($perms) = @_; 

	return substr(sprintf('%o', $perms), -3);
}



1;

__END__



=pod

=head1 NAME

file - manipulate files. 

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('file');
 
 delete_files
 get_dir_file_info
 get_file_info
 get_filenames
 get_mime_by_extension
 octal_permissions
 read_file
 symbolic_permissions
 write_file
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut
