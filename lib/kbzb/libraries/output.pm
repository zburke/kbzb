package kbzb::libraries::output;

# -- $Id: output.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict; 

#import flock constants, LOCK_SH, LOCK_EX, LOCK_UN, LOCK_NB
use Fcntl ':flock';



sub new
{
	my $class = shift;
	my $self = {}; 
	
	bless($self, $class);
	
	$self->{final_output} = '';
	$self->{cache_expiration} = 0;
	$self->{headers} = [];
	$self->{cookies} = {};
	$self->{enable_profiler} = 0; 
	
	$self->{logger} = kbzb::libraries::common::load_class('logger');
	
	$self->{logger}->debug('Output Class Initialized'); 
	
	return $self; 
}



# --------------------------------------------------------------------

#
# Get Output
#
# Returns the current output string
#
# @access	public
# @return	string
#
sub get_output
{
	my $self = shift;
	return $self->{final_output};
}



#
# Set Output
#
# Sets the output string
#
# @access	public
# @param	string
# @return	void
#
sub set_output
{
	my $self = shift; 
	my $output = shift; 
	$self->{final_output} = $output;
}



#
# Append Output
#
# Appends data onto the output string
#
# @access	public
# @param	string
# @return	void
#
sub append_output
{
	my $self = shift;
	my $output = shift; 
	
	if (! $self->{final_output})
	{
		$self->{final_output} = $output;
	}
	else
	{
		$self->{final_output} .= $output;
	}
}



#
# append
# shrtct to append_output. 
sub append
{
	my $self = shift;
	$self->append_output(@_); 
}



#
# Set Header
#
# Lets you set a server header which will be output with the final display.
#
# Note:  If a file is cached, headers will not be sent.  We need to figure out
# how to permit header data to be saved with the cache data...
#
# @access	public
# @param	string
# @return	void
#
sub set_header
{
	my $self = shift; 
	my ($name, $value, $replace) = @_; 
	
	$replace = ($replace ne '') ? $replace : 1;
	
	if ($replace)
	{
		# zap existing headers with the same name
		for (@{ $self->{headers} })
		{
			if ($_->{name} eq $name)
			{
				$_ = undef; 
			}
		}
	}
	
	push @{ $self->{headers} }, {name => $name, value => $value, replace => $replace}; 
}



#
# Set Cookie
#
# Lets you add a cookie. 
#
# Note:  If a file is cached, headers will not be sent.  We need to figure out
# how to permit header data to be saved with the cache data...
#
# @access	public
# @param	string
# @return	void
#
sub set_cookie
{
	my $self = shift; 
	my ($name, $value, $expires, $path, $domain, $secure) = @_;
	
	if ($expires)
	{
		$self->{cookies}->{$name} = $kbzb::cgi->cookie(
			-name    => $name,
			-value   => $value,
			-expires => $expires,
			-path    => $path,
			-domain  => $domain,
			-secure  => $secure
		); 
	}
	else
	{
		$self->{cookies}->{$name} = $kbzb::cgi->cookie(
			-name    => $name,
			-value   => $value,
			-path    => $path,
			-domain  => $domain,
			-secure  => $secure
		); 
	}
}



#
# Set HTTP Status Header
#
# @access	public
# @param	int 	the status code
# @param	string	
# @return	void
#
sub set_status_header
{
	my $self = shift;
	my ($code, $text) = @_; 
	
	$code = $code || 200; 
	$text = $text || ''; 
	
	my $stati = {
						'200'	=> 'OK',
						'201'	=> 'Created',
						'202'	=> 'Accepted',
						'203'	=> 'Non-Authoritative Information',
						'204'	=> 'No Content',
						'205'	=> 'Reset Content',
						'206'	=> 'Partial Content',
						
						'300'	=> 'Multiple Choices',
						'301'	=> 'Moved Permanently',
						'302'	=> 'Found',
						'304'	=> 'Not Modified',
						'305'	=> 'Use Proxy',
						'307'	=> 'Temporary Redirect',
						
						'400'	=> 'Bad Request',
						'401'	=> 'Unauthorized',
						'403'	=> 'Forbidden',
						'404'	=> 'Not Found',
						'405'	=> 'Method Not Allowed',
						'406'	=> 'Not Acceptable',
						'407'	=> 'Proxy Authentication Required',
						'408'	=> 'Request Timeout',
						'409'	=> 'Conflict',
						'410'	=> 'Gone',
						'411'	=> 'Length Required',
						'412'	=> 'Precondition Failed',
						'413'	=> 'Request Entity Too Large',
						'414'	=> 'Request-URI Too Long',
						'415'	=> 'Unsupported Media Type',
						'416'	=> 'Requested Range Not Satisfiable',
						'417'	=> 'Expectation Failed',
	
						'500'	=> 'Internal Server Error',
						'501'	=> 'Not Implemented',
						'502'	=> 'Bad Gateway',
						'503'	=> 'Service Unavailable',
						'504'	=> 'Gateway Timeout',
						'505'	=> 'HTTP Version Not Supported'
	};

	unless ($code && $code =~ /^0-9+$/)
	{
		die('Status codes must be numeric');
	}

	if ($stati->{$code} && ! $text)
	{				
		$text = $stati->{$code};
	}
	
	if (! $text)
	{
		die('No status text available. Please check your status code number or supply your own message text.');
	}
	
	my $server_protocol = $ENV{'SERVER_PROTOCOL'} ? $ENV{'SERVER_PROTOCOL'} : 'FALSE';

	if (lc substr($ENV{'REQUEST_URI'}, -3, 3) eq 'cgi')
	{
		print "Status: $code $text\n\n";;
	}
	elsif ($server_protocol eq 'HTTP/1.1' || $server_protocol eq 'HTTP/1.0')
	{
		print $server_protocol . " $code $text\n\n";
	}
	else
	{
		print "HTTP/1.1 $code $text\n\n";
	}
}



#
# Enable/disable Profiler
#
# @access	public
# @param	bool
# @return	void
#
sub enable_profiler
{
	my $self = shift;
	my $val = shift;
	if ($val eq '')
	{
		$val = 1;
	}
	
	$self->{enable_profiler} = $val;
}



#
# Set Cache
#
# @access	public
# @param	integer
# @return	void
#
sub cache
{
	my $self = shift;
	my $time = shift;
	
	$self->{cache_expiration} = ($time =~ /[0-9]+/) ? $time : 0;
}



#
# Display Output
# print headers, then print content. 
#
# All "view" data is automatically put into this variable by the controller class:
#
# $this->final_output
#
# This function sends the finalized output data to the browser along
# with any server headers and profile data.  It also stops the
# benchmark timer so the page rendering speed and memory usage can be shown.
#
sub _display
{
	my $self = shift; 
	my $output = shift;
	
	# --------------------------------------------------------------------
	
	# Set the output data
	if (! $output)
	{
		$output = $self->{final_output};
	}
	
	# --------------------------------------------------------------------
	
	# Do we need to write a cache file?
	if ($self->{cache_expiration} > 0)
	{
		$self->_write_cache($output);
	}
	
	# --------------------------------------------------------------------

	# Parse out the elapsed time and memory usage,
	# then swap the pseudo-variables with the data

	my $elapsed = $kbzb::bm->elapsed_time('total_execution_time_start', 'total_execution_time_end');		
	$output =~ s/\{elapsed_time\}/$elapsed/;
	
#@@	my $memory	 = ( ! function_exists('memory_get_usage')) ? '0' : round(memory_get_usage()/1024/1024, 2).'MB';
#@@	$output = str_replace('{memory_usage}', $memory, $output);		
	
	# Are there any server headers to send?
	$self->_display_headers();
		
	# --------------------------------------------------------------------
	
	# Does the get_instance() function exist?
	# If not we know we are dealing with a cache file so we'll
	# simply echo out the data and exit.
#@@	if ( ! function_exists('get_instance'))
#	{
#		print $output;
#		$self->{logger}->debug('Final output sent to browser');
#		$self->{logger}->debug('Total execution time: '.$elapsed);
#		return 1;
#	}

	# --------------------------------------------------------------------

	# Grab the controller so we can: 
	#
	# 1. call its profiler, if requested
	# 2. call its _output method, if it has one, instead of using our own.
	#
	my $kz = kbzb::get_instance();
	
	# generate profile data, if requested
	if ($self->{enable_profiler})
	{
		$self->_display_profiler($kz, \$output); 
	}
	
	# --------------------------------------------------------------------

	# Does the controller contain a function named _output()?
	# If so send the output there.  Otherwise, echo it.
	my $callable = ref($kz) . '::_output';
	if (defined &$callable)
	{
		$kz->_output($output);
	}
	else
	{
		print $output;  
	}
	
	$self->{logger}->debug('Final output sent to browser');
	$self->{logger}->debug('Total execution time: ' . $elapsed);		
}



#
# _display_headers
# print HTTP headers, including cookies
sub _display_headers
{
	my $self = shift; 

	if (scalar @{ $self->{headers} })
	{
		for my $header (@{ $self->{headers} })
		{
			my %hash = ();
			$hash{'-cookie'} = [values %{ $self->{cookies} }];
			
			for (@{ $self->{headers} })
			{
				$hash{'-' . $_->{name} } = $_->{value};
			}
			
			print $kbzb::cgi->header(%hash); 
		}
	}
	else
	{
		print $kbzb::cgi->header(-cookie => [values %{ $self->{cookies} }]); 
	}
}



#
# _display_profiler
# add profile info to the output stream
sub _display_profiler
{
	my $self = shift;
	my ($kz, $output) = @_; 
	
	$kz->load->library('profiler');				
									
	# If the output data contains closing </body> and </html> tags
	# we will remove them and add them back after we insert the profile data
	if ($$output =~ /<\/body>.*?<\/html>/is)
	{
		$$output  =~ s/<\/body>.*?<\/html>//is;
		$$output .= $kz->profiler->run();
		$$output .= '</body></html>';
	}
	else
	{
		$$output .= $kz->{'profiler'}->run();
	}
	
}



#
# Write a Cache File
#
# @access	public
# @return	void
#
sub _write_cache
{
	my $self = shift; 
	my $output = shift; 
	
	my $kz = kbzb::get_instance();
	
	my $path = $kz->{'config'}->item('cache_path');

	my $cache_path = ($path eq '') ? kbzb::BASEPATH() . 'cache/' : $path;
	
	unless (-d $cache_path && -w $cache_path)
	{
		return;
	}
	
	my $uri =	$kz->{'config'}->item('base_url').
			$kz->{'config'}->item('index_page').
			$kz->{'config'}->uri_string();
	
	$cache_path .= md5($uri);

	if (! open(CACHE_PATH, $kz->{'config'}->item('FOPEN_WRITE_CREATE_DESTRUCTIVE'), $cache_path))
	{
		$self->{logger}->error("Unable to write cache file: ".$cache_path);
		return;
	}
	
	
	my $expire = time() + ($self->{cache_expiration} * 60);
	
	if (flock CACHE_PATH, $kz->{'config'}->item('LOCK_EX'))
	{
		print CACHE_PATH $expire.'TS--->' . $output;
		flock CACHE_PATH, $kz->{'config'}->item('LOCK_UN');
	}
	else
	{
		log_message('error', "Unable to secure a file lock for file at: ".$cache_path);
		return;
	}
	close CACHE_PATH;
	
	chmod $kz->{'config'}->item('DIR_WRITE_MODE'), $cache_path;

	$self->{logger}->debug("Cache file written: ".$cache_path);
}



#
# Update/serve a cached file
#
# @access	public
# @return	void
#
sub _display_cache
{
	my $self = shift;
	my ($cfg, $uri) = @_;
	
	my $cache_path = undef;
	if (! $cfg->{'cache_path'})
	{
		$cache_path = kbzb::BASEPATH() . 'cache/'
	}
	else
	{
		$cache_path = $cfg->{'cache_path'};
	}
#	my $cache_path = ($cfg->item('cache_path') eq '') ? kbzb::BASEPATH() . 'cache/' : $cfg->item('cache_path');
		
	unless(-d $cache_path && -w $cache_path)
	{
		return 0;
	}
	
	# Build the file path.  The file name is an MD5 hash of the full URI
	$uri =	$cfg->{'base_url'} .
			$cfg->{'index_page'} .
			$uri->{'uri_string'};
			
	my $filepath = $cache_path.md5($uri);
	
	if ( ! -f $filepath)
	{
		return 0;
	}

	if (! open CACHE_FILE, $cfg->{'FOPEN_READ'}, $filepath)
	{
		return 0;
	}
		
	flock(CACHE_FILE, LOCK_SH);
	
	my $cache = '';
	while (<CACHE_FILE>)
	{
		$cache .= $_; 
	}

	flock(CACHE_FILE, LOCK_UN);
	close(CACHE_FILE);
				
	# Strip out the embedded timestamp		
	if ($cache =~ /(\d+TS--->)/)
	{
		return 0;
	}
	
	my $timestamp = $1;
	
	# Has the file expired? If so we'll delete it.
	$timestamp =~ s/TS--->//;
	$timestamp =~ s/^\s*//g;  # zap leading whitespace
	$timestamp =~ s/\s*$//g;  # zap trailing whitespace
	if (time() >= $timestamp)
	{ 		
		unlink($filepath);
		$self->{logger}->debug("Cache file has expired. File deleted");
		return 0;
	}

	# Display the cache
	$cache =~ s/(\d+TS--->)//;
	$self->_display($cache);
	$self->{logger}->debug('Cache file is current. Sending it to browser.');		
	return 1;
}


1; 

__END__


=pod

=head1 NAME

output - responsible for sending final output to browser

=head2 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->output so there is no need to 
re-instantiate it yourself. 

 # add content to the output stream
 $self->append_output('content');
 
 # whether to include benchmarks and memory usage in the output
 $self->enable_profiler($boolean);
 
 # retrieve the output stream
 $self->get_output();
 
 # set a cookie to be sent when the page is rendered
 $self->set_cookie($name, $value, $expires, $path, $domain, $secure);
 
 # set a header to be sent when the page is rendered
 $self->set_header('name', 'value');
 
 # set a header to be sent when the page is rendered,
 # replacing a header of the same name
 $self->set_header('name', 'value', 1);
 
 # overwrite current output stream with a new string
 $self->set_output('some content');
 
 $self->set_status_header();

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

