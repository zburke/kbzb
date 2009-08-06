package kbzb::helpers::security;

# -- $Id: security.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;
use Digest::MD5 qw(md5_hex);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(xss_clean dohash strip_image_tags encode_php_tags) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );



# Security Helpers
#



# XSS Filtering
#
# @access	public
# @param	string
# @param	bool	whether or not the content is an image file
# @return	string
	
sub xss_clean
{
	my ($str, $is_image) = @_; 

	return kbzb::get_instance()->input->xss_clean($str, $is_image);
}



# Hash encode a string
#
# @access	public
# @param	string
# @return	string	
#
sub dohash
{
	return md5_hex($_[0]);
}



# Strip Image Tags
#
# @access	public
# @param	string
# @return	string
#
sub strip_image_tags
{
	my $str = shift; 
	$str =~ s#<img\s+.*?src\s*=\s*[\"'](.+?)[\"'].*?\>#$1#g;
	$str =~ s#<img\s+.*?src\s*=\s*(.+?).*?\>#$1#g;
		
	return $str;
}



# Convert PHP tags to entities
#
# @access	public
# @param	string
# @return	string
#
sub encode_php_tags
{
	my $str = shift; 
	
	$str =~ s/<\?php/&lt;?php/g;
	$str =~ s/<\?PHP/&lt;?PHP/g;
	$str =~ s/<\?/&lt;?/g;
	$str =~ s/\?>/?&gt;/g;
	
	return $str; 
}


1;

__END__



=pod

=head1 NAME

security - security functions, e.g. hashing and input cleaning

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('security');
 
 # dohash: return an md5 hash of the input
 $hash = dohash('some string');  
  
 # encode_php_tags: convert PHP open/close tags to HTML entities
 $string = encode_php_tags('<?php ... ?>');
 
 # strip_image_tags: remove image tags, leaving only the src attribute
 $string = strip_image_tags('<img src="/path/to/file.jpg" />');
 
 # xss_clean
 NOT YET IMPLEMENTED

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut