package kbzb::libraries::loader; 

# -- $Id: loader.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;
use Carp; 

#
#
#
sub new
{
	my $class = shift;
	my $self = {}; 
	
	bless($self, $class);
	
	# keep a reference to the controller so we can 
	# load packages onto it. 
	die('Could not construct ' . __PACKAGE__ . ' without a reference to the controller.') unless $_[0];
	$self->{kz} = shift; 
	
	kbzb::libraries::common::load_class('logger', undef, $self); 
	
	$self->{_kz_view_path}    = '';
	$self->{_kz_cached_vars}  = undef;
	$self->{_kz_classes}      = undef;
	$self->{_kz_loaded_files} = undef;
	$self->{_kz_models}       = undef;
	$self->{_kz_helpers}      = undef;
	$self->{_kz_plugins}      = undef;
	$self->{_kz_varmap}       = {'unit_test' => 'unit', 'user_agent' => 'agent'};
	
	$self->{_kz_view_path} = kbzb::PKGPATH() . 'views/';
			
	$self->logger->debug('Loader Class Initialized');
	
	return $self; 
	
}



#
# library - load libraries. designed to be called from controllers. 
#
sub library
{
	my $self = shift; 
	my ($library, $params, $object_name) = @_; 
	
	if (! $library)
	{
		return 0; 
	}
	
	if ($params && 'HASH' ne ref $params)
	{
		$params = undef;
	}

	if ('ARRAY' eq ref $library)
	{
		$self->_kz_load_class($_, $params, $object_name) for (@{ $library }); 
	}
	else
	{
		$self->_kz_load_class($library, $params, $object_name);
		
		return $self->{_kz_classes}->{$object_name} if $object_name;
		
		return $self->{_kz_classes}->{$library};
		
	}
	
}



#
# model
# instantiate ORM models. 
#
sub model 
{
	my $self = shift;
	my ($model, $dbh, $config) = @_;

	if ('ARRAY' eq ref $model) 
	{
		$self->model($_, $dbh, $config) for (@$model); 
	}
	
	require(kbzb::PKGPATH() . 'models/' . $model . '.pm');
}



#
# view
# load and parse a view file. 
#
# arguments: 
#     $string:   name of the "view" file to be included.
#     \%hashref: data the view will display
#     $boolean:  whether to return the view contents, or append it to output. 
#                append-to-output is the default, but it could be returned for
#                additional processing.
#
sub view
{
	my $self = shift;
	my ($view, $vars, $return) = @_; 
	
	my $parser = kbzb::libraries::common::load_class('parser');
	return $parser->parse($self->_kz_load($view, undef, 1), $vars, $return); 
}



#
# file
# load a file. 
# arguments: 
#     $string:   name of the "view" file to be included.
#     $boolean:  whether to return the file's contents, or append it to output. 
#                append-to-output is the default, but it could be returned for
#                additional processing.
#
sub file
{
	my $self = shift;
	my ($path, $return) = @_; 
	
	return $self->_kz_load(undef, $path, $return);
}



#
# Set Variables
#
# Once variables are set they become available within
# the controller class and its "view" files.
#
# @access	public
# @param	array
# @return	void
#
sub vars
{
	my $self = shift;
	my ($vars, $val) = @_;
	
	if ($val && ! ref $vars)
	{
		my $key = $vars;
		$vars = { $key => $val };
	}

	if (ref $vars == 'HASH' && scalar keys %$vars > 0)
	{
		for my $key ($vars)
		{
			$self->{_kz_cached_vars}->{$key} = $vars->{$val};
		}
	}
}



#
# Load Helper
#
# This function loads the specified helper file.
#
# @access	public
# @param	mixed
# @return	void
#
sub helper
{
	my $self = shift; 
	my ($helpers) = @_; 
	
	if (! ref $helpers)
	{
		$helpers = [$helpers];
	}

	for my $helper (@$helpers)
	{
		
		$helper = lc $helper;

		if ($self->{_kz_helpers}->{$helper})
		{
			next;
		}
		
		my $helper_path = kbzb::PKGPATH() . 'helpers/' . kbzb::libraries::common::config_item('subclass_prefix') . $helper .'.pm';

		# Is this a helper extension request?			
		if (-f $helper_path)
		{
			my $base_helper = kbzb::BASEPATH() . 'helpers/' . $helper . '.pm';
			
			if (! -f $base_helper)
			{
				die('Unable to load the requested file: helpers/' . $helper . '.pm');
			}
			
			require "$base_helper";
			require "$helper_path"; 
		}
		elsif (-f kbzb::PKGPATH() . '/helpers/' . $helper . '.pm')
		{
			$helper_path = kbzb::PKGPATH() . 'helpers/' . $helper . '.pm';
			require "$helper_path"; 
		}
		else
		{		
			if (-f kbzb::BASEPATH() . 'kbzb/helpers/' . $helper . '.pm')
			{
				$helper_path = kbzb::BASEPATH() . 'kbzb/helpers/' . $helper . '.pm';
				require "$helper_path";
			}
			else
			{
				die('Unable to load the requested file: helpers/' . $helper );
			}
		}

		$self->{_kz_helpers}->{$helper} = 1;
		$self->logger->debug('Helper loaded: '.$helper);	
	}		
}



#
# Load Helpers
#
# This is simply an alias to the above function in case the
# user has written the plural form of this function.
#
# @access	public
# @param	array
# @return	void
#
sub helpers
{
	my $self = shift;
	my $helpers = shift;
	
	$self->helper($helpers);
}




#
# Load Plugin
#
# This function loads the specified plugin.
#
# @access	public
# @param	array
# @return	void
#
sub plugin
{
	my $self = shift; 
	my ($plugins) = @_;
	
	if (! ref $plugins)
	{
		$plugins = [$plugins];
	}

	for my $plugin (@{ $plugins })
	{
		$plugin = lc $plugin . '_pi.pm';
		if ($self->{_kz_plugins}->{$plugin})
		{
			next;
		}
		
		if (-f kbzb::PKGPATH() . 'plugins' . $plugin)
		{
			my $requirable = kbzb::PKGPATH() . 'plugins' . $plugin;
			require $requirable; 
		}
		else
		{
			if (-f kbzb::BASEPATH() . 'plugins' . $plugin)
			{
				my $requirable = kbzb::BASEPATH() . 'plugins' . $plugin;
				require $requirable; 
			}
			else
			{
				die('Unable to load the requested file: plugins/'.$plugin);
			}
			
		}
		
		$self->{_kz_plugins}->{$plugin} = 1; 
		$self->logger->debug('Plugin loaded: ' . $plugin); 
		
	}
	
	
}



#
# Load Plugins
#
# This is simply an alias to the above function in case the
# user has written the plural form of this function.
#
# @access	public
# @param	array
# @return	void
#
sub plugins
{
	my $self = shift;
	my $plugins = shift;
	
	$self->plugin($plugins);
}



#
# Load a language file
#
# arguments
#     $string - 
#     $lang - name of the lang to load
sub language
{
	my $self = shift;
	my ($file, $lang) = @_;
	
	if (! ref $file)
	{
		$file = [$file];
	}

	for my $langfile (@$file)
	{	
		$self->{kz}->lang->load($langfile, $lang);
	}
}



#
# Loads language files for scaffolding
#
# @access	public
# @param	string
# @return	arra
#
sub scaffold_language
{
	my $self = shift;
	my ($file, $lang, $return) = @_;
	
	return $self->{kz}->lang->load($file, $lang, $return);
}



#
# Loads a config file
#
# @access	public
# @param	string
# @return	void
#
sub config
{
	my $self = shift;
	my ($file, $use_sections, $fail_gracefully) = @_; 
	
	$self->{kz}->config->load($file, $use_sections, $fail_gracefully);
}



#
# Scaffolding Loader
#
# This initializing function works a bit different than the
# others. It doesn't load the class.  Instead, it simply
# sets a flag indicating that scaffolding is allowed to be
# used.  The actual scaffolding function below is
# called by the front controller based on whether the
# second segment of the URL matches the "secret" scaffolding
# word stored in the application/config/routes.php
#
# @access	public
# @param	string
# @return	void
#
sub scaffolding
{
	my $self = shift;
	my ($table) = @_;
	
	if ($table)
	{
		$self->{kz}->{_kz_scaffolding} = 1;
		$self->{kz}->{_kz_scaff_table} = $table;
	}
	else
	{
		die('You must include the name of the table you would like to access when you initialize scaffolding');
	}
}



#
# _kz_load - load views and files
#
# This function is used to load views and files.
# Variables are prefixed with _kz_ to avoid symbol collision with
# variables made available to view files
#
# @access	private
# @param	array
# @return	void
# 
sub _kz_load
{
	my $self = shift; 
	my ($view, $path, $return) = @_; 
	
	my $file = undef; 
	
	# Set the path to the requested file
	if (! $path)
	{
		$file = $view.'.htmx'; ;
		$path = $self->{_kz_view_path} . $view . '.htmx';
	}
	else
	{
		my @_kz_x = split /\//, $path;
		$file = pop @_kz_x;
	}
	
	if ( ! -f $path)
	{
		die('Unable to load the requested file: ' . $file . "; $path");
	}

	my $content = kbzb::libraries::common::read_file($path);
	
	$self->logger->debug('File loaded: ' . $path);
	
	# Return the file data if requested
	if ($return)
	{
		return $content; 
	}
	else
	{
		$kbzb::out->append_output($content);  
		return; 
	}
}



#
# Load class
#
# This function loads the requested class.
#
sub _kz_load_class
{
	my $self = shift;
	my ($class, $params, $object_name) = @_;
	
	# how will this class be reference on the controller object? 
	# 1. by the given object name
	# 2. by its _kz_varmap alias
	# 3. by its modulename (DEFAULT)
	$object_name ||= $self->{_kz_varmap}->{$class} || $class;
		
	if (exists $self->{_kz_classes}->{$object_name})
	{
		$self->logger->debug($object_name . ' already loaded. Second attempt ignored.');
		return $self->{_kz_classes}->{$object_name};
	}
	
	my ($classname, $filename); 
	
	(my $c_path = $class) =~ s/::/\//g; 
	(my $c_pkg  = $class) =~ s/\//::/g; 
	
	# first check the app's libraries directory
	$classname = kbzb::APPPKG() . "::libraries::$c_pkg";
	($filename = $classname) =~ s/::/\//g;

	if (-f kbzb::APPPATH() . $filename . '.pm')
	{
		require(kbzb::APPPATH() . $filename . '.pm');
		$self->_kz_init_class($c_pkg, $classname, $params, $object_name); 
		return;

	}
	elsif (-f kbzb::BASEPATH() . 'kbzb/libraries/' . $c_path . '.pm')
	{
		my $classname = "kbzb::libraries::$c_pkg";
		($filename = $classname) =~ s/::/\//g;

		require(kbzb::BASEPATH() . $filename . '.pm'); 
		$self->_kz_init_class($c_pkg, $classname, $params, $object_name); 
		return; 
	}
	else
	{
		die('Unable to load the requested class: ' . $class);
	}
}



#
# _kz_init_class
# instantiate a class
#
#
sub _kz_init_class
{
	my $self = shift;
	my ($class, $classname, $config, $object_name) = @_; 
	
	# Is there an associated config file for this class?
	$config ||= $self->{kz}->config->load($class, undef, 1); 

	# Set the variable name we will assign the class to
	$object_name =~ s/\//_/g;

	$self->{_kz_classes}->{$class} = $classname->new($config);
	
	# assign the loaded class to a typeglob so it can be accessed
	# as a simple subroutine. 
	no strict 'refs'; 
	*{(ref $self->{kz}) . "::$object_name"} = sub { return $self->{_kz_classes}->{$class}; };
	
} 	


1; 

__END__


=pod

=head1 NAME

loader - load libraries, helpers, views and files. 

=head2 DESCRIPTION

The loader package is instantiated automatically by the controller
parent class. 

 # load the file "config.properties" in the app's config directory
 $hash_ref = $self->load->config('config');

 # append the contents of 'file' to the output.
 $content = $self->load->file('file');

 # retrieve the contents of 'file'
 $content = $self->load->file('file', 1);

 # load a helper package; first search the app's helper directory,
 # then kbzb's helper directory
 $self->load->helper('uri');

 # load the "calendar_lang.properties" file in the default language.
 # first search the app's language directory, then the kbzb's. 
 $hash = $self->load->language('calendar');

 # load the french "calendar_lang.properties" file 
 $hash = $self->load->language('calendar', 'french');

 # load a package; first search the app's libraries directory, 
 # then kbzb's libraries directory.
 $self->load->library('lib'); 

 # load and parse the file "some_view.htmx" in the app's view directory,
 # substituting in 'value' wherever the string '{key}' appears. the content
 # is automatically appended to the output. 
 $self->load->view('some_view', {key => 'value'}); 

 # load and parse the file "some_view.htmx", returning the content. 
 $self->load->view('some_view', {key => 'value'}, 1); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

