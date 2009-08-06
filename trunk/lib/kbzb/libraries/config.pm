package kbzb::libraries::config;

# -- $Id: config.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict; 



#
# new 
# cache and return the app's config.properties file
#
sub new
{
	my $class = shift;
	my $self = {};
	
	bless($self, $class);
		
	$self->{config} = kbzb::libraries::common::get_config(); 

	$self->{section} = {}; 
	
	$self->{logger} = kbzb::libraries::common::load_class('logger');
	$self->{logger}->debug('Config Class Initialized');
	
	return $self;
}



#
# load
# parse, cache and return a config file
#
# arguments
#     $string - file to be read, without the .properties extension
#     $boolean - whether to cache in one big fat config hash (default) or named sections
#     $boolean - whether to die on error (default) or simply return
#
sub load
{
	my $self = shift; 
	my ($file, $use_sections, $fail_gracefully) = @_; 
	
	my $hash = $self->parse($file, $fail_gracefully);

	# cache the values in a section
	$self->_load_section($file, $hash); 

	# and store values in the global config array, if requested.  
	if (! $use_sections)
	{
		for my $key (keys %$hash)
		{
			$self->{config}->{$key} = $hash->{$key};
		}
	}

	$self->{logger}->debug('Config file loaded: config/'.$file); 
	
	
	return $hash; 
}



#
# parse
# Read and parse a config file, returning a hashref of key-value pairs. 
# 
# arguments
#     $string - file to be read, without the .properties extension
#     $boolean - whether to die on error (default) or simply return an empty hash
#
sub parse
{
	my $self = shift; 
	my ($file, $fail_gracefully) = @_; 
	
	$file = $file || 'config';
	
	# return the file from the cache, if available
	if ($self->{section}->{$file})
	{
		return $self->{section}->{$file}; 
	}
	
	my $filepath = kbzb::PKGPATH() . "config/$file.properties";

	if (! -f $filepath)
	{
		if ($fail_gracefully)
		{
			return {}; 
		}
		
		die("The configuration file '$file' does not exist."); 
	}
	
	my $hash = {}; 
	open(CONFIG, "<$filepath") or die("The configuration file '$file' could not be read: $!\n");
	while (<CONFIG>)
	{
		chomp;
		next if $_ =~ /^#/;	
		next if $_ =~ /^\s*$/;
		
		my ($key, $val) = split(/\s*=\s*/, $_); 
		
		# val is an array of comma-separated terms
		if ($val =~ /^\[\s*(.*)\s*\]$/)
		{
			my @list = split /\s*,\s*/, $1;
			
			push @{ $hash->{$key} }, @list; 
		}
		
		# val is a hash of comma-separated, colon-delimited terms
		elsif ($val =~ /^\{\s*(.*)\s*\}$/)
		{
			my @list = split /\s*,\s*/, $1;
			for my $item (@list)
			{
				my ($k, $v) = split /\s*:\s*/, $item;
				next unless $k; 
				
				$k =~ s/^\s*//g; 
				$v =~ s/\s*$//g;
				
				$hash->{$key}->{$k} = $v; 
			}
		}
		
		# simple key-value pair
		else
		{
			$hash->{$key} = $val; 
		}
	}
	close CONFIG;
	
	return $hash; 
}



#
# _load_section
# stash a parsed config file in the cache
#
sub _load_section
{
	my $self = shift;
	my ($file, $hash) = @_; 
	
	# update values if this has already been loaded once
	if ($self->{section}->{$file})
	{
		for my $key (keys %$hash)
		{
			$self->{section}->{$file}->{$key} = $hash->{$key};
		}
	}
	else
	{
		$self->{section}->{$file} = $hash;
	}
	
}
	


#
# item
# retrieve an item from a config file
# 
# arguments
#     $string - item to search for 
#     $string - section to search in, if sections are in use
#
sub item
{
	my $self = shift; 
	my ($item, $index) = @_; 
	
	my $pref = undef; 
	
	if (! $index)
	{
		if (! exists $self->{config}->{$item})
		{
			return ''; 
		}
		
		$pref = $self->{config}->{$item};
	}
	else
	{
		if (! exists $self->{section}->{$index})
		{
			return '';
		}

		if (! exists $self->{section}->{$index}->{$item})
		{
			return '';
		}
		
		$pref = $self->{section}->{$index}->{$item};
	}
	
	
#@	# untaint preferences. this is kinda dangerous, but I think the assumption
	# that data read from a config file is untainted is legit. it's not the 
	# same as something read from regular user input, like a form submission.
	$pref =~ /(.*)/; 
	return $1;
	
}



#
# slash_item
# add a trailing slash to an item from the default config file 
#
# arguments
#     $string - item to search for 
#
sub slash_item
{
	my $self = shift;
	my ($item) = @_;
	
	if (! exists $self->{config}->{$item})
	{
		return '';
	}
	
	if (substr($self->{config}->{$item}, -1, 1) ne '/')
	{
		return $self->{config}->{$item} . '/';
	}

	return $self->{config}->{$item};
	
}




#
# site_url
# the URI string, including the index page
#
# return
# The fully qualified URI string, including the index page,
# e.g. http://www.somedomain.org/index.cgi.
#
sub site_url
{
	my $self = shift;
	my ($uri) = @_; 
	
	my $link = ''; 
	if (! $uri)
	{
		return $self->slash_item('base_url') . $self->item('index_page');
	}
	
	if (ref $uri)
	{
		$link = join('/', @{$uri}); 
	}

	my $suffix = $self->item('url_suffix') || '';
	
	# zap double slashes
	$link =~ s|^/*(.+?)/*$|$1|;
	
	return $self->slash_item('base_url') . $self->slash_item('index_page') . $link . $suffix;
}



#
# set_item
# set a config item in-memory only
#
# arguments
#     key - the key
#     value - the value
#
sub set_item
{
	my $self = shift;
	my ($item, $value) = @_; 
	
	$self->{config}->{$item} = $value;
}


1; 


__END__

=pod

=head1 NAME

config - methods for managing config files and items

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->config so there is no need to 
re-instantiate it yourself. 

Additionally, the app's main config file, config.properties, is automatically
loaded when the config class is initialized, so there is no need to load that
either.

 # load a file, or retrieve it from the cache
 $c = $self->config->load('some_file'); 
 
 # retrieve an item from a loaded file
 $item = $c->item('item'); # $item may be a scalar, hashref or arrayref
 
 # set an item's value IN THE CACHE ONLY
 # this does not update the config file
 $c->set_item('key', 'value'); 
 
 # retrieve item with a trailing /, if none was present
 $item = $c->slash_item('item');
 
 # fully qualified URL to your index, e.g. http://www.somesite.org/index.cgi
 $url = $c->site_url();

=head1 EXAMPLE CONFIG FILE

A config file is a plain-text file containing key-value pairs. Empty lines, 
those containing only whitespace or those starting with a # are ignored. 
Keys must be scalars; values may be scalars, arrays or hashes. 

 # a simple pair
 key = value
 
 # list contains an arrayref
 list = [value1, value2, value3]
 
 # hash contains a hashref
 hash = { key1:value1, key2:value2, key3:, key4:value4}
 
 # arrays and hashes do not have to be specified on a single 
 # line, though key-value pairs do. below, the first line 
 # overwrites the previous value for key; the others add new 
 # items to the array and hash, respectively
 key = new value
 list = [value4]
 hash = { key5:value5 }

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut 