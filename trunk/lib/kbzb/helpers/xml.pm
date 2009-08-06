package kbzb::helpers::xml;

# -- $Id: xml.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw(xml_convert) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	
);

# ------------------------------------------------------------------------
# XML Helpers
#

# ------------------------------------------------------------------------
# Convert Reserved XML characters to Entities
#
# @access	public
# @param	string
# @return	string
	
sub xml_convert
{
	my $str = shift;
	
	my $temp = '__TEMP_AMPERSANDS__';

	# Replace entities to temporary markers so that 
	# ampersands won't get messed up
	$str =~ s/&#(\d+);/$temp$1/g;
	$str =~ s/&(\w+);/$temp$1/g;

	$str =~ s/&/&amp;/g;
	$str =~ s/</&lt;/g;
	$str =~ s/>/&gt;/g;
	$str =~ s/\"/&quot;/g;
	$str =~ s/\'/&#39;/g;
	$str =~ s/-/&#45;/g;

	# Decode the temp markers back to entities		
	$str =~ s/$temp(\d+);/&#$1;/g;
	$str =~ s/$temp(\w+);/&$1;/g;
	
	return $str;
}


1; 

__END__

=pod

=head1 NAME

xml - functions for escaping reserved characters in XML 

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('xml');
 
 # convert characters that are special in HTML to entities.
 # the following six characters are converted: & < > " ' -
 $content = xml_convert('string with & or < or > or - or " or \'.');

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut