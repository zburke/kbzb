package kbzb::helpers::email;

# -- $Id: email.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw(valid_email send_email) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );



# ------------------------------------------------------------------------
# Email Helpers
#

# ------------------------------------------------------------------------
# Validate email address
#
# @access	public
# @return	bool
#	
sub valid_email
{
	my ($address) = @_; 
	return $address =~ /^([a-z0-9\+_\-]+)(\.[a-z0-9\+_\-]+)*@([a-z0-9\-]+\.)+[a-z]{2,6}$/ix;
}


# ------------------------------------------------------------------------
# Send an email
#
# @access	public
# @return	bool
#@send_email
#sub send_email
#{
#	my ($recipient, $subject, $message) = @_; 
#	
#	$subject ||= 'Test email';
#	$message ||= 'Hello World';
#	
#	return mail($recipient, $subject, $message);
#}


1;

__END__


=pod

=head1 NAME

email - send email using sendmail or SMTP. 

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('email');
 
 # validate an email address
 $boolean = valid_email('somebody@somewhere.org'); 

 # send an email
 # mail server parameters are set in the config file config.properties
 send_mail($recipient, $subject, $message);

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

 
=cut
