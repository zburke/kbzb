package kbzb::helpers::download;

# -- $Id: download.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw(force_download) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
);


# ------------------------------------------------------------------------
# Download Helpers
#

# ------------------------------------------------------------------------
# Force Download
#
# Generates headers that force a download to happen
#
# @access	public
# @param	string	filename
# @param	mixed	the data to be downloaded
# @return	void
#
sub force_download
{
	my ($filename, $data) = @_; 
	
	unless ($filename && $data)
	{
		return undef;
	}

	# Try to determine if the filename includes a file extension.
	# We need it in order to set the MIME type
	if (! $filename =~ /\./)
	{
		return undef;
	}

	# Grab the file extension
	my @x = split /\./, $filename;
	my $extension = pop @x;

	# Load the mime types
	my $config = kbzb::libraries::common::load_class('config');
	my $mimes = $config->load('mimes');
	
	# Set a default mime if we can't find it
	my $mime = $mimes->{$extension} || 'application/octet-stream';
#@		$mime = (is_array($mimes[$extension])) ? $mimes[$extension][0] : $mimes[$extension];
	
	# Generate the server headers
	if ($ENV{'HTTP_USER_AGENT'} =~ /MSIE/)
	{
		print $kbzb::cgi->header(
			'-type' => $mime,
			'-attachment' => "$filename",
			'-expires' => '0',
			'-Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
			'-Content-Transfer-Encoding' => 'binary',
			'-Pragma' => 'public',
			'-Content-Length' => length($data)
		); 
	}
	else
	{
		print $kbzb::cgi->header(
			'-type' => $mime,
			'-attachment' => "$filename",
			'-expires' => '0',
			'-Content-Transfer-Encoding' => 'binary',
			'-Pragma' => 'no-cache',
			'-Content-Length' => length($data)
		); 
	}
	
	print $data; 

}



1;


__END__


=pod

=head1 NAME

download - manipulate HTTP headers to cause the browser to prompt to download a file.

=head2 DESCRIPTION

 # load the helper from within a controller ... 
 $self->load->helper('download');
 
 # force the browser to prompt the user to save a PDF as 
 # an attachment named 'some_file.pdf', rather than allowing
 # it to be displayed inline. the appropriate MIME-type will
 # be set automatically.
 $bits = ... slurp in some data, e.g. a PDF file ...
 force_download('some_file.pdf', $bits); 
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
