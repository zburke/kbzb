package kbzb::libraries::uri;

# -- $Id: uri.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;


sub new
{
	my $class = shift; 
	my $self = {};
	
	bless($self, $class);
	
	kbzb::libraries::common::load_class('config', undef, $self); 
	
	$self->{keyval}     = undef;
	$self->{uri_string} = undef;
	$self->{segments}   = [];
	$self->{rsegments}  = [];
	
	
	kbzb::libraries::common::load_class('logger', undef, $self);
	$self->logger->debug('URI Class Initialized'); 
	
	return $self; 
	
}



#
# Get the URI String
#
# @access	private
# @return	string
#
sub _fetch_uri_string
{
	my $self = shift; 
	
	if ('AUTO' eq uc $self->config->item('uri_protocol'))
	{
		# If the URL has a question mark then it's simplest to just
		# build the URI string from the zero index of the $_GET array.
		# This avoids having to deal with $_SERVER variables, which
		# can be unreliable in some environments
#@		if ($ENV{QUERY_STRING} ne '')
#		{
#			$self->{uri_string} = key($_GET);
#			return;
#		}
		
		# Is there a PATH_INFO variable?
		# Note: some servers seem to have trouble with getenv() so we'll test it two ways
		my $path = $ENV{PATH_INFO}; 
		if ($path) 
		{ 
			$path = substr($path, 1);
			chop $path if (substr($path, -1, 1) eq '/');
		}
		if ($path ne '' && $path ne "/" . kbzb::INDEX_FILE())
		{
			$self->{uri_string} = $path;
			return;
		}

		# No PATH_INFO?... What about QUERY_STRING?
		$path = $ENV{QUERY_STRING};
		chop $path if (substr($path, -1, 1) eq '/');
		if ($path ne '')
		{
			$self->{uri_string} = $path;
			return;
		}

		# No QUERY_STRING?... Maybe the ORIG_PATH_INFO variable exists?
		$path = $ENV{ORIG_PATH_INFO};
		chop $path if (substr($path, -1, 1) eq '/');
		if ($path ne '' && $path ne "/" . kbzb::INDEX_FILE())
		{
			# remove path and script information so we have good URI data
			($self->{uri_string} = $path) =~ s/$ENV{SCRIPT_NAME}//; 
			return;
		}

		# We've exhausted all our options...
		$self->{uri_string} = '';
	}
	else
	{
		my $uri = uc $self->config->item('uri_protocol');

		if ($uri eq 'REQUEST_URI')
		{
			$self->uri_string = $self->_parse_request_uri();
			return;
		}

		$self->{uri_string} = $ENV{$uri}; 
	}

	# If the URI contains only a slash we'll kill it
	if ($self->{uri_string} eq '/')
	{
		$self->{uri_string} = '';
	}
}



#
# Parse the REQUEST_URI
#
# Due to the way REQUEST_URI works it usually contains path info
# that makes it unusable as URI data.  We'll trim off the unnecessary
# data, hopefully arriving at a valid URI that we can use.
#
# @access	private
# @return	string
#
sub _parse_request_uri
{
	my $self = shift; 
	
	if (! $ENV{REQUEST_URI})
	{
		return '';
	}

	(my $request_uri = $ENV{REQUEST_URI}) =~ s/\/(.*)/$1/g;
	$request_uri =~ s/\\/\//g; 

	if ($request_uri eq '' || $request_uri eq kbzb::INDEX_FILE())
	{
		return '';
	}

	my $fc_path = kbzb::FCPATH();
	if (index ($request_uri, '?') >= 0)
	{
		$fc_path .= '?';
	}

	my @parsed_uri = split /\//, $request_uri;

	my $i = 0;
	for (split /\//, $fc_path)
	{
		if ($parsed_uri[$i] && $_ eq $parsed_uri[$i])
		{
			$i++;
		}
	}

	my $parsed_uri = join("/", @parsed_uri[$i..$#parsed_uri]); 

	if ($parsed_uri ne '')
	{
		$parsed_uri = '/' . $parsed_uri;
	}

	return $parsed_uri;
}



#
# Filter segments for malicious characters
#
# @access	private
# @param	string
# @return	string
#
sub _filter_uri
{
	my $self = shift;
	my $str = shift;
	
	if ($str && $self->config->item('permitted_uri_chars') && ! $self->config->item('enable_query_strings'))
	{
		my $permitted = $self->config->item('permitted_uri_chars');
		if ($str =~ /^([$permitted]+)$/)
		{
	# Convert programatic characters to entities
#@
#	my @bad  = array('$', 		'(', 		')',	 	'%28', 		'%29');
#	my @good = array('&#36;',	'&#40;',	'&#41;',	'&#40;',	'&#41;');
#	for (@bad)
#	{
#		$str =~ s/$bad/$/g;
#	}
#
#	return str_replace($bad, $good, $str);
			return $1;
		}
	}

	die('The URI you submitted has disallowed characters.');
}





#
# Remove the suffix from the URL if needed
#
# @access	private
# @return	void
#
sub _remove_url_suffix
{
	my $self = shift; 
	if  ($self->config->item('url_suffix') ne '')
	{
		$self->{uri_string} = preg_replace("|".preg_quote($self->config->item('url_suffix'))."$|", "", $self->uri_string);
	}
}



#
# Explode the URI Segments. The individual segments will
# be stored in the $self->segments array.
#
# @access	private
# @return	void
#
sub _explode_segments()
{
	my $self = shift;
	
	for (split /\/+/, $self->{uri_string})
	{
		# Filter segments for security
		$_ = $self->_filter_uri($_);
		if ($_ && $_ ne '')
		{
			push @{ $self->{segments} }, $_;
		}
	}
}



#
# Re-index Segments
#
# This function re-indexes the $self->segment array so that it
# starts at 1 rather than 0.  Doing so makes it simpler to
# use functions like $self->uri->segment(n) since there is
# a 1:1 relationship between the segment array and the actual segments.
#
# @access	private
# @return	void
#
sub _reindex_segments()
{
	my $self = shift; 
	
	unshift @{ $self->{segments} }, '';
	unshift @{ $self->{rsegments} }, ''; 

}



#
# Fetch a URI Segment
#
# This function returns the URI segment based on the number provided.
#
# @access	public
# @param	integer
# @param	bool
# @return	string
#
sub segment
{
	my $self = shift;
	my ($n, $no_result) = @_; 
	
	return ($self->{segments}->[$n] ? $self->{segments}->[$n] : $no_result); 
}



#
# Fetch a URI "routed" Segment
#
# This function returns the re-routed URI segment (assuming routing rules are used)
# based on the number provided.  If there is no routing this function returns the
# same result as $self->segment()
#
# @access	public
# @param	integer
# @param	bool
# @return	string
#
sub rsegment
{
	my $self = shift;
	my ($n, $no_result) = @_; 
	
	return ($self->{rsegments}->[$n] ? $self->{rsegments}->[$n] : $no_result); 
}



#
# Generate a key value pair from the URI string
#
# This function generates an associative array of URI data starting
# at the supplied segment. For example, if this is your URI:
#
#	example.com/user/search/name/joe/location/UK/gender/male
#
# You can use this function to generate an array with this prototype:
#
# array (
#			name => joe
#			location => UK
#			gender => male
#		 )
#
# @access	public
# @param	integer	the starting segment number
# @param	array	an array of default values
# @return	array
#
sub uri_to_assoc
{
	my $self = shift; 
	my ($n, $default) = @_;
	
	$n = $n || 3;

	return $self->_uri_to_assoc($n, $default, 'segment');
}


#
# Identical to above only it uses the re-routed segment array
#
#
sub ruri_to_assoc
{
	my $self = shift; 
	my ($n, $default) = @_;
	
	$n = $n || 3;

	return $self->_uri_to_assoc($n, $default, 'rsegment');
}




#
# Generate a key value pair from the URI string or Re-routed URI string
#
# @access	private
# @param	integer	the starting segment number
# @param	array	an array of default values
# @param	string	which array we should use
# @return	array
#
sub _uri_to_assoc
{
	my $self = shift; 
	my ($n, $default, $which) = @_; 
	
	$n ||= 3;
	$default ||= {};
	$which ||= 'segment';
	
	
	my $total_segments = 'total_rsegments';
	my $segment_array = 'rsegment_array';
	if ($which eq 'segment')
	{
		$total_segments = 'total_segments';
		$segment_array = 'segment_array';
	}

	if ($n !~ /^[0-9]+$/)
	{
		return $default;
	}

	if (exists $self->{keyval}->{$n})
	{
		return $self->{keyval}->{$n};
	}

	if ($self->$total_segments() < $n)
	{
		if (! scalar keys %$default)
		{
			return {};
		}

		my $retval = {};
		for (keys %$default)
		{
			$retval->{$_} = '';
		}
		return $retval;
	}
	
	my $offset = $n - 1;
	my @segments = @{ $self->$segment_array() }[$offset..$#{ $self->$segment_array() }];

	my $i = 0;
	my $lastval = '';
	my $retval  = {};
	for (@segments)
	{
		if ($i % 2)
		{
			$retval->{$lastval} = $_;
		}
		else
		{
			$retval->{$_} = undef;
			$lastval = $_;
		}

		$i++;
	}

	if (scalar keys %$default > 0)
	{
		for (keys %$default)
		{
			if (! exists $retval->{$_})
			{
				$retval->{$_} = undef; 
			}
		}
	}

	# Cache the array for reuse
	$self->{keyval}->{$n} = $retval;
	return $retval;
}



#
# Generate a URI string from an associative array
#
#
# @access	public
# @param	array	an associative array of key/values
# @return	array
#
sub assoc_to_uri
{
	my $self = shift;
	my $list = shift;
	
	return join '', map { $_ . '/' . $list->{$_} . '/' } keys %{ $list }
}



#
# Fetch a URI Segment and add a trailing slash
#
# @access	public
# @param	integer
# @param	string
# @return	string
#
sub slash_segment
{
	my $self = shift;
	my ($n, $where) = @_; 
	
	$where = $where || 'trailing';
	
	return $self->_slash_segment($n, $where, 'segment');
}




#
# Fetch a URI Segment and add a trailing slash
#
# @access	public
# @param	integer
# @param	string
# @return	string
#
sub slash_rsegment
{
	my $self = shift;
	my ($n, $where) = @_; 
	
	$where = $where || 'trailing';
	
	return $self->_slash_segment($n, $where, 'rsegment');
}




#
# Fetch a URI Segment and add a trailing slash - helper function
#
# @access	private
# @param	integer
# @param	string
# @param	string
# @return	string
#
sub _slash_segment
{
	my $self = shift;
	my ($n, $where, $which) = @_; 
	
	my $trailing = ''; 
	my $leading = '';
	
	$where = $where || 'trailing';
	$which = $which || 'segment';

	if ($where eq 'trailing')
	{
		$trailing	= '/';
		$leading	= '';
	}
	elsif ($where eq 'leading')
	{
		$leading	= '/';
		$trailing	= '';
	}
	else
	{
		$leading	= '/';
		$trailing	= '/';
	}
	
	return $leading . $self->$which($n) . $trailing;
}




#
# Segment Array
#
# @access	public
# @return	array
#
sub segment_array
{
	my $self = shift;

	return $self->{segments};
}




#
# Routed Segment Array
#
# @access	public
# @return	array
#
sub rsegment_array
{
	my $self = shift;

	return $self->{rsegments};
}




#
# Total number of segments
#
# @access	public
# @return	integer
#
sub total_segments
{
	my $self = shift;

	return scalar @{$self->{segments}};
}



#
# Total number of routed segments
#
# @access	public
# @return	integer
#
sub total_rsegments
{
	my $self = shift;
	
	return scalar @{$self->{rsegments}};
}




#
# Fetch the entire URI string
#
# @access	public
# @return	string
#
sub uri_string
{
	my $self = shift;
	
	return $self->{uri_string};
}




#
# Fetch the entire Re-routed URI string
#
# @access	public
# @return	string
#
sub ruri_string
{
	my $self = shift;

	return '/' . join('/', @{ $self->rsegment_array() }) . '/';
}




1; 

__END__

=pod

=head1 NAME

uri - parses URIs and determines routing

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->uri so there is no need to 
re-instantiate it yourself. 

The URI Class provides functions that help you retrieve information 
from your URI strings. If you use URI routing, you can also retrieve 
information about the re-routed segments.

=head1 SYNOPSIS

 # retrieve the value of a certain URI segment, post routing.
 # segments are 1-indexed
 $value = $self->uri->segment($int);
 
 # retrieve all values of the URI.
 $a_ref = $self->uri->segment_array();

 # retrieve the URI, e.g. /controller/method/param1/param2
 $value = $self->uri->uri_string();

 # same as segment, with a trailing slash
 $value = $self->uri->slash_segment($int);

 # same as segment, with a leading slash
 $value = $self->uri->slash_segment($int, 'leading');

 # same as segment, with leading and trailing slashes
 $value = $self->uri->slash_segment($int, 'both');

 # the total number of segments
 $value = $self->uri->total_segments();

 # convert the URI to a hash, e.g. convert /foo/one/bar/two
 # to { foo => 'one', bar => 'two' }
 $value = $self->uri->uri_to_assoc();
 
 # convert a hash to an array, e.g. translate
 # { foo => 'one', bar => 'two'} to /foo/one/bar/two/
 $value = $self->uri->assoc_to_uri();
 
 # the following methods perform the same functions on the ROUTED
 # URI. see L<kbzb::libraries::router> for details. 
 $value = $self->uri->rsegment($int);
 $a_ref = $self->uri->rsegment_array();
 $value = $self->uri->ruri_string();
 $value = $self->uri->slash_rsegment();
 $value = $self->uri->total_rsegments();
 $value = $self->uri->ruri_to_assoc();

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
