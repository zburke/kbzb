package kbzb::helpers::typography;

# -- $Id: typography.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw( nl2br_except_pre auto_typography ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


# ------------------------------------------------------------------------
# Typography Helpers
#

# ------------------------------------------------------------------------
# Convert newlines to HTML line breaks except within PRE tags
#
# @access	public
# @param	string
# @return	string
#
sub nl2br_except_pre
{
	my $str = shift;

	return kbzb::get_instance()->load->library('typography')->nl2br_except_pre($str);
}



# ------------------------------------------------------------------------
# Auto Typography Wrapper Function
#
#
# @access	public
# @param	string
# @param	bool	whether to reduce multiple instances of double newlines to two
# @return	string
#
sub auto_typography
{
	my ($str, $reduce_linebreaks) = @_; 
	
	return kbzb::get_instance()->load->library('typography')->auto_typography($str, $reduce_linebreaks);
}



# ------------------------------------------------------------------------
# Format Characters Wrapper Function
#
#
# @access	public
# @param	string characters to format
# @return	string
#
sub format_characters
{
	my ($str) = @_; 
	
	return kbzb::get_instance()->load->library('typography')->format_characters($str);
}


1;

__END__

=pod

=head1 NAME

typography - convert plain text to nicely formatted HTML

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('typography');
 
 # auto-format a plain textblock
 $formatted = auto_typography($text_block); 
 
 # auto-format a string of characters (smart quotes, eplipses, m-dashes)
 $formatted = format_characters($text_block); 
 
 # convert newlines to HTML line breaks, except within pre tags
 $formatted = nl2br_except_pre($text_block); 
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
