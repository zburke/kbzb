package kbzb::helpers::cookie;

# -- $Id: cookie.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw( set_cookie get_cookie delete_cookie) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
        
);



# ------------------------------------------------------------------------
# Cookie Helpers
#


# ------------------------------------------------------------------------
# Set cookie
#
# Accepts six parameter, or you can submit an associative
# array in the first parameter containing all the values.
#
# @access	public
# @param	mixed
# @param	string	the value of the cookie
# @param	string	the number of seconds until expiration
# @param	string	the cookie domain.  Usually:  .yourdomain.com
# @param	string	the cookie path
# @param	string	the cookie prefix
# @return	void
#
sub set_cookie
{
	my ($name, $value, $expire, $domain, $path, $prefix) = @_; 
	
	$path ||= '/';
	
	# Set the config file options
	my $kz = kbzb::get_instance();

	if ($prefix == '' && $kz->config->item('cookie_prefix') != '')
	{
		$prefix = $kz->config->item('cookie_prefix');
	}
	if ($domain == '' && $kz->config->item('cookie_domain') != '')
	{
		$domain = $kz->config->item('cookie_domain');
	}
	if ($path == '/' && $kz->config->item('cookie_path') != '/')
	{
		$path = $kz->config->item('cookie_path');
	}
	
	if ($expire !~ /[0-9]+/)
	{
		$expire = time() - 86500;
	}
	else
	{
		if ($expire > 0)
		{
			$expire = time() + $expire;
		}
		else
		{
			$expire = 0;
		}
	}
	
	my $cookie = $kbzb::cgi->cookie(
		-name    => $name,
		-value   => $value,
		-expires => $expire,
		-domain  => $domain,
		-path    => $path);
		
	$kz->output->set_cookie($cookie); 
}

	
# --------------------------------------------------------------------
# Fetch an item from the COOKIE array
#
# @access	public
# @param	string
# @param	bool
# @return	mixed
#
sub get_cookie
{
	my ($index, $xss_clean) = @_; 
	
	my $kz = kbzb::get_instance();
	
	my $prefix = kbzb::libraries::common::config_item('cookie_prefix') || '';
	
	my $cookie = {$kbzb::cgi->cookie($index)};
	
	if ($prefix && ! $cookie)
	{
		$cookie = {$kbzb::cgi->cookie($prefix.$index)}; 
	}
	
	if ($xss_clean)
	{
		return $kz->input->xss_clean($cookie); 
	}
	else
	{
		return $cookie; 
	}
}



# --------------------------------------------------------------------
# Delete a COOKIE
#
# @param	mixed
# @param	string	the cookie domain.  Usually:  .yourdomain.com
# @param	string	the cookie path
# @param	string	the cookie prefix
# @return	void
#
sub delete_cookie
{
	my ($name, $domain, $path, $prefix) = @_; 
	
	$path ||= '/';
	
	set_cookie($name, '', '', $domain, $path, $prefix);
}


1;


__END__


=pod

=head1 NAME

cookie - help with cookies. this is essentially a wrapper around CGI::Cookie.

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('cookie');
 
 # set a cookie to be sent with the HTTP headers
 set_cookie($name, $value, $expire, $domain, $path, $prefix);  
 
 # read a cookie
 $hashref = get_cookie($name); 
 
 # remove a cookie
 delete_cookie($name, $domain, $path, $prefix);

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
