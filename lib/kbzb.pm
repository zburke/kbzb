package kbzb;

# -- $Id: kbzb.pm 157 2009-07-27 20:11:03Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use 5.008000;
use strict;
use warnings;
use Carp;

use kbzb::libraries::common;

our @ISA = qw();

our $VERSION = '0.01';

my  $input = undef; # config input from the CGI script 
my  $kz = undef;    # root controller object
our $cgi = undef;   # CGI instance
our $bm = undef;    # benchmark class instance
our $cfg = undef;   # config class instance
our $out = undef;   # output class instance



# full server path to the "app" folder
sub APPPATH
{
	return $input->{APPPATH} . '/';
}



# name of the application package
sub APPPKG
{
	return $input->{APPPKG};
}



# name of the application package
sub PKGPATH
{
	return APPPATH() . $input->{APPPKG} . '/';
}



# full server path to the kbzb "lib" folder
sub BASEPATH
{
	return $input->{BASEPATH} . '/';
}



# full server path to the index script
sub FCPATH
{
	return $input->{FCPATH};
}



# name of the index script
sub INDEX_FILE
{
	return $input->{INDEX_FILE} . '/';
}



#
# run
# 1. load core libraries
# 2. start benchmark timers
# 3. call run-time hooks as necessary
# 4. instantiate the requested controller
# 5. call the requested method on said controller
# 6. wrap up, sending output to the client
# 
sub run
{
	eval
	{
		$input = shift; 
		
		$cgi  = $input->{'cgi'};
		
		# ------------------------------------------------------
		#  Push the app's libraries onto the include path
		# ------------------------------------------------------
		unshift @INC, "$input->{APPPATH}";
		
		$cfg = kbzb::libraries::common::get_config();
	
		# ------------------------------------------------------
		#  Start the timer... tick tock tick tock...
		# ------------------------------------------------------
		$bm = kbzb::libraries::common::load_class('benchmark'); 
		$bm->mark('total_execution_time_start');
		$bm->mark('loading_time_base_classes_start');
			
			
		# ------------------------------------------------------
		#  Instantiate the hooks class
		# ------------------------------------------------------
		my $ext = kbzb::libraries::common::load_class('hooks'); 
		
		
		# ------------------------------------------------------
		#  Is there a "pre_system" hook?
		# ------------------------------------------------------
		$ext->_call_hook('pre_system');
		
		
		# ------------------------------------------------------
		#  Instantiate the base classes
		# ------------------------------------------------------
		my $uri = kbzb::libraries::common::load_class('uri'); 
		my $rtr = kbzb::libraries::common::load_class('router'); 
		$out = kbzb::libraries::common::load_class('output'); 
		
		
		# ------------------------------------------------------
		#	Is there a valid cache file?  If so, we're done...
		# ------------------------------------------------------
	#	if (! $ext->_call_hook('cache_override'))
	#	{
	#		if ($out->_display_cache($cfg, $uri))
	#		{
	#			exit(0);
	#		}
	#	}
	
		# ------------------------------------------------------
		#  Load the remaining base classes
		# ------------------------------------------------------
		my $in   = kbzb::libraries::common::load_class('input');
		my $lang = kbzb::libraries::common::load_class('language');
	
	
		# Set a mark point for benchmarking
		$bm->mark('loading_time_base_classes_end');


		# ------------------------------------------------------
		#  Load the app controller and local controller
		# ------------------------------------------------------
		
		# Note: The Router class automatically validates the controller 
		# path. If this fails it means that the default controller in the 
		# routes.properties file is not resolving to something valid.
		(my $classfile = $rtr->fetch_class()) =~ s/::/\//g;  
		if ( ! -f APPPATH() . $classfile . '.pm')
		{
			kbzb::libraries::common::show_error('Unable to load your default controller. Please make sure the controller specified in your routes.properties file is valid.');
		}
		
		
		# ------------------------------------------------------
		#  Security check
		# ------------------------------------------------------
		#
		#  None of the functions in the app controller or the
		#  loader class can be called via the URI, nor can
		#  controller functions that begin with an underscore
			
		my $class  = $rtr->fetch_class();
		my $method = $rtr->fetch_method();
		
		eval "require $class";
	
		if ( (! defined $class) || $method eq 'new' || substr($method, 0, 1) eq '_')
		{
			kbzb::libraries::common::show_404("{$class}/{$method}");
		}
	
		# ------------------------------------------------------
		#  Is there a "pre_controller" hook?
		# ------------------------------------------------------
		$ext->_call_hook('pre_controller');

		# ------------------------------------------------------
		#  Instantiate the controller and call requested method
		# ------------------------------------------------------
		# Mark a start point so we can benchmark the controller
		$bm->mark('controller_execution_time_( ' . $class . ' / ' . $method . ' )_start');
		
		$kz = $class->new($input);
	
		# Is this a scaffolding request?
		if ($rtr->{'scaffolding_request'})
		{
			if (! $ext->_call_hook('scaffolding_override'))
			{
				$kz->_kz_scaffolding();
			}
		}
		else
		{
			# ------------------------------------------------------
			#  Is there a "post_controller_constructor" hook?
			# ------------------------------------------------------
			$ext->_call_hook('post_controller_constructor');
			
			my $callable = $class . '::' . $method;
	
			#@ Is there a "remap" function?
			my $remap_method = $class . '::_remap';
			if (defined &$remap_method)
			{
				$kz->_remap($method);
			}
			else
			{
				if (! defined &$callable)
				{
					kbzb::libraries::common::show_404($callable);
				}
			}
			
			# Call the requested method.
			# URI segments (besides 1 and 2, class and method) will be passed to the method
			if (scalar @{ $uri->{'rsegments'} } > 3)
			{
				$kz->$method(@{ $uri->{'rsegments'} }[3..$#{ $uri->{'rsegments'} }]);
			}
			else
			{
				$kz->$method();
			}
		}
		
		# Mark a benchmark end point
		$bm->mark('controller_execution_time_( ' . $class . ' / ' . $method . ' )_end');
		
		# ------------------------------------------------------
		#  Is there a "post_controller" hook?
		# ------------------------------------------------------
		$ext->_call_hook('post_controller');
		
		
		# ------------------------------------------------------
		#  Send the final rendered output to the browser
		# ------------------------------------------------------
		if (! $ext->_call_hook('display_override'))
		{
			$out->_display();
		}
		
		
		# ------------------------------------------------------
		#  Is there a "post_system" hook?
		# ------------------------------------------------------
		$ext->_call_hook('post_system');
		
		
		# ------------------------------------------------------
		#  Close the DB connection if one exists
		# ------------------------------------------------------
		#if (class_exists('CI_DB') AND isset($CI->db))
		#{
		#	$CI->db->close();
		#}

	};
	if ($@)
	{
		print "Content-type: text/html\n\n"; 
		my $error = $@; 
		print kbzb::libraries::common::load_class('exceptions')->show_error('Fatal Error', "$error");
	}

}



#
# get_instance
# static method access to the global controller object
sub get_instance
{
	if (! $kz)
	{
		confess('Cannot return the root controller because it has not been instantiated.'); 
		kbzb::libraries::common::show_error('Could not return the root controller object; it has not yet been instantiated!');
	}
	
	return $kz; 
}


1;


__END__

=head1 NAME

kbzb - Perl clone of CodeIgniter, a kick-ass PHP webapp framework.

=head1 DESCRIPTION

This is a Perl clone of the PHP CodeIgniter framework, a kick-ass web 
application framework for PHP. CodeIgniter's goal "is to enable you 
to develop projects much faster than you could if you were writing 
code from scratch, by providing a rich set of libraries for commonly 
needed tasks, as well as a simple interface and logical structure to 
access these libraries."

=head1 SEE ALSO

L<http://code.google.com/p/kbzb/>

L<http://codeigniter.com/>

=head1 AUTHOR

Zak Burke, E<lt>kbzbfw@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Zak Burke, except as noted elsewhere. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
