package kbzb::libraries::controller;

# -- $Id: controller.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict; 



our $_kz_scaffolding	= 0;
our $_kz_scaff_table	= 0;


#
# new
# 
sub new
{
	my ($class, $input) = @_; 
		
	my $self = {}; 
	
	bless($self, $class);
	
	kbzb::libraries::common::load_class('logger', undef, $self);
	$self->_initialize();
	
	$self->logger->debug('Controller Class Initialized');
	
	return $self; 
	
}


#
# Initialize
# Make available all base classes (load, config, input, benchmark, uri, 
# output, lang, router, parser) as subroutines on the controller; load 
# other library classes as specified in autoload.properties by calling 
# _kz_autoload().
#
sub _initialize
{
	my $self = shift; 
	
	# turn off strict references so we can dynamically generate subroutines
	# on the controller. this is just syntactic sugar. it's a little nicer
	# to have this: 
	#     $self->logger->debug('some message');
	# than this: 
	#     $self->{logger}->debug('some message');
	#
	no strict 'refs';

	# the loader class needs to be instantiated with a reference to the 
	# current class in order to allow it to load other libraries into
	# this class. 
	*{ __PACKAGE__ . '::' . 'load' } = sub { return kbzb::libraries::common::load_class('loader', $self); };
	
	# load default classes
	my $classes = {
						'config'	=> 'config',
						'input'		=> 'input',
						'benchmark'	=> 'benchmark',
						'uri'		=> 'uri',
						'output'	=> 'output',
						'lang'		=> 'language',
						'router'	=> 'router',
						'parser'	=> 'parser',
						'logger'	=> 'logger',
		};

	for my $name (keys %$classes)
	{
		*{ __PACKAGE__ ."\::$name" } = sub { return kbzb::libraries::common::load_class($classes->{$name}); };
	}

	# autoload app's libraries, helpers,
	$self->_kz_autoload();

}



#
# Run Scaffolding
#
# @access	private
# @return	void
#
sub _kz_scaffolding
{
	my $self = shift; 
	
	$self->logger->debug("BREAD SAID: running _scaffolding ($self->{_kz_scaffolding})..." .  $self->uri->segment(4));

	$self->{_kz_scaffolding} = 1;  
	$self->{_kz_scaff_table} = $self->uri->segment(4); 
	
	unless ($self->{_kz_scaffolding} && $self->{_kz_scaff_table})
	{
		kbzb::libraries::common::show_404('Scaffolding unavailable');
	}
	
	$self->logger->debug("BREAD SAID: , $self->{_kz_scaff_table}");

	my $method = $self->uri->segment(3); 
	$method = 'view' unless (grep /^$method$/, ('add', 'insert', 'edit', 'update', 'view', 'delete', 'do_delete'));
	
	my $scaff = kbzb::libraries::common::load_class('scaffolding', $self->{_kz_scaff_table});
	
	$self->logger->debug("BREAD SAID: $method, $self->{_kz_scaff_table}");
	
	$scaff->$method();
}



#
# _kz_autoload
# load libraries, plugins, helpers and models specified in the app's 
# autoload.properties config file. 
#
# @access	private
# @param	array
# @return	void
# 
sub _kz_autoload()
{
	my $self = shift; 
	
	my $autoload = $self->config->parse('autoload'); 
	
	# Load any custom config file
	if (scalar @{ $autoload->{'config'} })
	{			
		for my $key (@{ $autoload })
		{
			$self->config->load($key);
		}
	}		

	# Autoload plugins, helpers and languages
	for my $type (qw(helper plugin language))
	{
		if (scalar @{ $autoload->{$type} })
		{
			$self->load->$type($autoload->{$type})
		}
	}
	
	# Load libraries
	# the database and scaffolding libraries must be loaded first;
	# order is irrelevant for all other libraries. 
	if (scalar @{ $autoload->{'libraries'} })
	{
		# Load the database driver.
		if (grep /^database$/, @{ $autoload->{'libraries'} })
		{
			$self->database();
			@{ $autoload->{'libraries'} } = grep !/^database$/, @{ $autoload->{'libraries'}};
		}

		# Load scaffolding
		if (grep /^scaffolding$/, @{ $autoload->{'libraries'}})
		{
			$self->load->scaffolding(); 
			@{ $autoload->{'libraries'} } = grep !/^scaffolding$/, @{ $autoload->{'libraries'}};
		}
	
		# Load all other libraries
		for my $library (@{ $autoload->{'libraries'} })
		{
			$self->load->library($library);
		}
	}		

	# Autoload models
	if (scalar @{ $autoload->{'model'} })
	{
		$self->load->model($autoload->{'model'});
	}

}


1; 

__END__

=pod

=head1 NAME

controller - parent class of all controllers

=head1 DESCRIPTION

The controller parent class loads the default libraries (load, config, 
input, benchmark, uri, output, lang, router, parser, logger) and any other
libraries, models, helpers, etc. specified by the app's 
autoload.properties file.

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut