package kbzb::libraries::router;

# -- $Id: router.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;
use Scalar::Util;
 



#
# new
# runs the mapping function
sub new
{
	my $class = shift;
	
	my $self = {}; 

	bless($self, $class);
	
	$self->{routes} 		= {};
	$self->{error_routes}	= {};
	$self->{class}			= '';
	$self->{method}			= 'index';
	$self->{uri_protocol} 	= 'auto';
	$self->{default_controller} = undef;
	$self->{scaffolding_request} = undef; # Must be set to undef
	
	
	$self->{_class} = undef;
	$self->{_method} = undef;
	
	kbzb::libraries::common::load_class('uri',    undef, $self); 
	kbzb::libraries::common::load_class('config', undef, $self); 
	kbzb::libraries::common::load_class('logger', undef, $self);	
	
	
	$self->_set_routing(); 

	$self->logger->debug('Router Class Initialized');

	return $self; 
}



#
# Set the route mapping
#
# This function determines what should be served based on the URI request,
# as well as any "routes" that have been set in the routing config file.
#
# @access	private
# @return	void
#
sub _set_routing
{
	my $self = shift; 
	
	$self->{routes} = $self->config->load('routes') || {}; 

	# Set the default controller so we can display it in the event
	# the URI doesn't correlated to a valid controller.
	$self->{default_controller} = $self->{routes}->{'default_controller'}; 

	# Fetch the complete URI string
	$self->uri->_fetch_uri_string();

	if (! $self->uri->{'uri_string'})
	{
		if (! defined $self->{default_controller})
		{
			die('Unable to determine what should be displayed. A default route has not been specified in the routing file.');
		}

		if (index($self->{default_controller}, '/') > 0)
		{
			my @x = split /\//, $self->{default_controller};

			$self->set_class($x[$#x]);
			$self->set_method('index');
			$self->_set_request(\@x);
		}
		else
		{
			$self->set_class($self->{default_controller});
			$self->set_method('index');
			$self->_set_request([$self->{default_controller}, 'index']);
		}

		# re-index the routed segments array so it starts with 1 rather than 0
		$self->uri->_reindex_segments();
		
		$self->logger->debug('No URI present. Default controller set.');
		return;
	}

	delete $self->{routes}->{'default_controller'};
	
	# Do we need to remove the URL suffix?
	$self->uri->_remove_url_suffix();
	
	# Compile the segments into an array
	$self->uri->_explode_segments();
	
	# Parse any custom routing that may exist
	$self->_parse_routes();		
	
	# Re-index the segment array so that it starts with 1 rather than 0
	$self->uri->_reindex_segments();


	return;


}



#
# Set the Route
#
# This function takes an array of URI segments as
# input, and sets the current class/method
#
sub _set_request
{
	my $self = shift;
	my ($segments) = @_; 
	
	$segments = $self->_validate_request($segments); 
	
	if (0 == scalar @{ $segments })
	{
		return;
	}
	
	if ($segments->[1])
	{
		# A scaffolding request. No funny business with the URL
		if ($self->{routes}->{'scaffolding_trigger'} eq $segments->[1] && $segments->[1] ne '_kz_scaffolding')
		{
			$self->{scaffolding_request} = 1;
			$self->{routes}->{'scaffolding_trigger'} = undef;
		}
		else
		{
			# A standard method request
			$self->set_method($segments->[1]);
		}
		
	}
	else
	{
		# This lets the "routed" segment array identify that the default
		# index method is being used.
		$segments->[1] = 'index';
		$self->set_method($segments->[1]);
	}

	# Update our "routed" segment array to contain the segments.
	# Note: If there is no custom routing, this array will be
	# identical to $this->uri->segments
	#
	# NOTE: gotta make a copy of $segments, since it may be a reference
	# to $self->uri->{'segments'} and we don't want segments and rsegments
	# to be references to the same array. 
	my @list = ();
	push @list, $_ for (@$segments); 
	$self->uri->{'rsegments'} = \@list;

}

	

#
# Validates the supplied segments.  Attempts to determine the path to
# the controller.
#
sub _validate_request
{
	my $self = shift;
	my $segments = shift;
	
	# Does the requested controller exist in the root folder?
	if (-f kbzb::PKGPATH() . 'controllers/' . $segments->[0] . '.pm')
	{
		$self->set_class($segments->[0]);
		return $segments;
	}
	
	# Is the controller in a sub-folder?
	if (-d kbzb::PKGPATH() . 'controllers/' . $segments->[0])
	{
		my $dir = '';
		# if a sub-dir path matches the request-path, take it. 
		while ( -d kbzb::PKGPATH() . 'controllers/' . $segments->[0])
		{
			$dir .= shift(@$segments) . '/';
		}
		
		(my $pkg = $dir) =~ s/\//::/g;
	
		if (scalar @$segments)
		{
			if (-f kbzb::PKGPATH() . 'controllers/' . $dir . $segments->[0] . '.pm')
			{
				$self->set_class($pkg . $segments->[0]); 
				return $segments;
			}

			kbzb::libraries::common::show_404()

		}
		else
		{	
			$self->set_class($pkg . $self->{default_controller}); 
			$self->set_method('index');

			# Does the default controller exist in the sub-folder?
			if ( ! -f kbzb::PKGPATH() . 'controllers/' . $dir . $self->{default_controller} . '.pm')
			{
				return {};
			}
		}
		
		return $segments; 
	}

	# Can't find the requested controller...
	kbzb::libraries::common::show_404($segments->[0]);
}



#
#  Parse Routes
#
# This function matches any routes that may exist in
# the config/routes.php file against the URI to
# determine if the class/method need to be remapped.
#
# @access	private
# @return	void
#
sub _parse_routes
{
	my $self = shift;
	
	# Do we even have any custom routing to deal with?
	# There is a default scaffolding trigger, so we'll look just for 1
	if (1 == scalar keys %{ $self->{routes} })
	{
		$self->_set_request($self->uri->{'segments'});
		return;
	}


	# Turn the segment array into a URI string
	my $uri = join('/', $self->uri->{'segments'});

	# Is there a literal match?  If so we're done
	if (exists $self->{routes}->{$uri})
	{
		$self->_set_request(split(/\//, $self->{routes}->{$uri}));		
		return;
	}
			
	# Loop through the route array looking for wild-cards
	for my $key (keys %{ $self->{routes} })
	{						
		my $val = $self->{routes}->{$key};

		# Convert wild-cards to RegEx
		$key =~ s/':any'/.+/;
		$key =~ s/':num'/[0-9]+/;
		
		# Does the RegEx match?
		if ($uri =~ /^$key/)
		{
			# Do we have a back-reference?
			if (index($val, '$') && index($key, '('))
			{
				($val = $uri) =~ s/^$key$/$val/; 
			}
		
			$self->_set_request(explode('/', $val));		
			return;
			
		}
	}

	# If we got this far it means we didn't encounter a
	# matching route so we'll set the site default route
	$self->_set_request($self->uri->{'segments'});
}



#
# Set the class name
#
# @access	public
# @param	string
# @return	void
#
sub set_class
{
	my $self = shift;
	my $class = shift;
	
#@	# $class should already be untainted (uri::_fetch_uri_string eventually calls _filter_uri,
	# which runs input through this same regex), but it's not, so we double check for nasty 
	# characters in the URL
	my $permitted = $self->config->item('permitted_uri_chars');
	if ($class =~ /^([$permitted]+)$/)
	{
		$self->{_class} = $1;
	}
	else
	{
		$self->logger->warn("The request to load the class '$class' from the URL failed due to disallowed characters."); 
		$self->{_class} = undef;
	}
}



#
# Fetch the current class
#
# @access	public
# @return	string
#
sub fetch_class
{
	my $self = shift;
	return kbzb::APPPKG() . '::controllers::' . $self->{_class} || '';
}



#
#  Set the method name
#
# @access	public
# @param	string
# @return	void
#
sub set_method
{
	my $self = shift;
	my $method = shift;
	
	$self->{_method} = $method;
}



#
#  Fetch the current method
#
# @access	public
# @return	string
#
sub fetch_method
{
	my $self = shift;
	
	if ($self->{_method} eq $self->fetch_class())
	{
		return 'index';
	}

	return $self->{_method} || '';
}


1; 

__END__

=pod

=head1 NAME

router - parses URIs and determines routing

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->router so there is no need to 
re-instantiate it yourself. 

The routing class parses a URI and determines what controller class to 
load, what method to call on it, and what parameters to pass to it. 
By default, a URI like this: 

 http://somehost.org/kbzb.cgi/package/method/param-1/.../param-n
 
will result in L<kbzb> doing the following: 

 $c = app::controllers::package->new();
 $c->method(param-1, ..., param-n);
 
To change the way some URIs are routed to your application controllers,
add your own routes to the config file routes.properties in your app's
config directory.

=head1 SYNOPSIS

 # retrieve the name of the controller class, including its package.
 # this is used by L<kbzb> to determine which package to instantiate
 # and call. 
 $string = $self->uri->fetch_class();

 # retrieve the name of the method to be called on the controller class.
 # this is used by L<kbzb> to determine which method to call on the 
 # controller class loaded by fetch_class. 
 $string = $self->uri->fetch_class();

 # set the name of the package to be loaded and used as the application
 # controller. this package will then be loaded by L<kbzb>. 
 $self->uri->set_class('some::package'); 

 # set the name of the method to be called on the application controller. 
 # this method will then be called on the packaged set by set_class. 
 $self->uri->set_method('method_name');

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut
