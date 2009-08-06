package kbzb::helpers::number;

# -- $Id: number.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw( byte_format) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );



# ------------------------------------------------------------------------
# Number Helpers

# ------------------------------------------------------------------------
# Formats a numbers as bytes, based on size, and adds the appropriate suffix
#
# @access	public
# @param	mixed	// will be cast as int
# @return	string#
sub byte_format
{
	my $num = shift; 
	my $unit = undef; 
	
	my $kz = kbzb::get_instance();
	$kz->lang->load('number');

	if ($num >= 1000000000000) 
	{
		$num = sprintf("%1f", $num / 1099511627776);
		$unit = $kz->lang->line('terabyte_abbr');
	}
	elsif ($num >= 1000000000) 
	{
		$num = sprintf("%1f", $num / 1073741824);
		$unit = $kz->lang->line('gigabyte_abbr');
	}
	elsif ($num >= 1000000) 
	{
		$num = sprintf("%1f", $num / 1048576);
		$unit = $kz->lang->line('megabyte_abbr');
	}
	elsif ($num >= 1000) 
	{
		$num = sprintf("%1f", $num / 1024);
		$unit = $kz->lang->line('kilobyte_abbr');
	}
	else
	{
		$unit = $kz->lang->line('bytes');
	}
	
	return $num . ' ' . $unit; 
}	


1;

__END__


=pod

=head1 NAME

number - convert numbers representing byte-sizes to words, e.g. KB, MB

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('number');
 
 # retrieve size in words, e.g. "1.1 KB"
 $size = byte_format(1111); 

 # retrieve size in words, e.g. "1.2 MB"
 $size = byte_format(1200000); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut