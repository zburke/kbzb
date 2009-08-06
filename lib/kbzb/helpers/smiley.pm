package kbzb::helpers::smiley;

# -- $Id: smiley.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw( 
get_clickable_smileys
js_insert_smiley
parse_smileys
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );



# ------------------------------------------------------------------------
# Smiley Helpers
#


# ------------------------------------------------------------------------
# JS Insert Smiley
#
# Generates the javascript function needed to insert smileys into a form field
#
# @access	public
# @param	string	form name
# @param	string	field name
# @return	string#
sub js_insert_smiley
{
	my ($form_name, $form_field) = @_; 
	
	my $content = <<EOF;
<script type="text/javascript">
function insert_smiley(smiley)
{
	document.$form_name.$form_field.value += " " + smiley;
}
</script>
EOF
	return $content; 
}



# ------------------------------------------------------------------------
# Get Clickable Smileys
#
# Returns an array of image tag links that can be clicked to be inserted 
# into a form field.  
#
# @access	public
# @param	string	the URL to the folder containing the smiley images
# @return	array
#
sub get_clickable_smileys
{
	my ($image_url, $smileys) = @_; 
	if ('HASH' ne ref $smileys)
	{
		$smileys = _get_smiley_array() || return ''; 
	}

	# Add a trailing slash to the file path if needed
	$image_url =~ s/(.+?)\/*$/$1\//;
	
	my %used = ();
	my @links = (); 
	for (keys %$smileys)
	{
		# Keep duplicates from being used, which can happen if the
		# mapping array contains multiple identical replacements.  For example:
		# :-) and :) might be replaced with the same image so both smileys
		# will be in the array.
		if ($used{ $smileys->{$_}->[0] })
		{
			next;
		}
		
		push @links, "<a href=\"javascript:void(0);\" onClick=\"insert_smiley('".$_."')\"><img src=\"".$image_url.$smileys->{$_}->[0]."\" width=\"".$smileys->{$_}[1]."\" height=\"".$smileys->{$_}->[2]."\" alt=\"".$smileys->{$_}->[3]."\" style=\"border:0;\" /></a>";

		$used{$smileys->{$_}->[0]} = 1;
		
	}
	
	return \@links;
}



# ------------------------------------------------------------------------
# Parse Smileys
#
# Takes a string as input and swaps any contained smileys for the actual image
#
# @access	public
# @param	string	the text to be parsed
# @param	string	the URL to the folder containing the smiley images
# @return	string
#
sub parse_smileys
{
	my ($str, $image_url, $smileys) = @_; 
	
	if ($image_url eq '')
	{
		return $str;
	}

	if ('HASH' ne ref $smileys)
	{
		$smileys = _get_smiley_array() || return $str; 
	}

	# Add a trailing slash to the file path if needed
	$image_url = preg_replace("/(.+?)\/*$/", "\\1/",  $image_url);

	for (keys %$smileys)
	{
		$str =~ s/$_/<img src="$image_url$smileys->{$_}->[0]" width="$smileys->{$_}->[1]" height="$smileys->{$_}->[2]" alt="$smileys->{$_}->[3]" style="border:0;" \/>/g;
	}

	return $str;
}



# ------------------------------------------------------------------------
# Get Smiley Array
#
# Fetches the config/smiley.php file
#
# @access	private
# @return	mixed
#
sub _get_smiley_array
{
	my $kz = kbzb::get_instance();
	
	return $kbzb::cfg->load('smileys'); 
}


1;


__END__


=pod

=head1 NAME

smiley - functions for replacing text emoticons with images

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('smiley');
 
 # retrieve HTML form element listing emoticons
 $html = get_clickable_smileys('/path/to/images');
 
 # insert an emoticon image tag in a form field; used in concert with 
 # get_clickable_smileys
 $js = js_insert_smiley('form_name', 'field_name');
 
 $html = parse_smileys(':)', '/path/to/images', $parsed_smileys.properties);

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

 
 
=cut
