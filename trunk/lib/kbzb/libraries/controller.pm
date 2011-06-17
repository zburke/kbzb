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

sub render {
	my ($self, $tpl, $return) = @_;
	open(TPL, "<".kbzb::APPPATH().'app/views/'.$tpl.'.tmpl');
	my $entirefile = join('', <TPL>);
	($entirefile) = ($entirefile =~ /(.+)/s); # untainting
	close(TPL);
	
	my $buffer_ref;
	my $buffer_fh;
	my $orig_fh;
	open($buffer_fh, ">", \$buffer_ref);
	$orig_fh = select $buffer_fh;
	
	# split the file into delimiters and segments:
	my @segments = split(/(<\?perl|<\?=|[^\\]{1}\?>)/gs, $entirefile);
	
	# save some memory:
	undef $entirefile;
	
	# parse the template file into eval-able perl:
	# TODO: come up with a way to cache these for performance
	my $mode = 'text';
	my ($open_seg, $seg_varname, $last_mode, $trail_char, $i);
	my $translated = 'package '.ref($self).'; my $run_tpl = sub { my $self = $_[0]; my $OUT;'."\n";
	foreach my $seg(@segments) {
		if($seg eq '<?perl' || $seg eq '<?=') {
			$last_mode = $mode;
			$mode = 'code';
			$open_seg = $seg;
			if($segments[$i + 2] =~ /([^\\]{1})\?>/s) {
				$trail_char = $1;
			}
		}
		
		elsif($seg =~ /[^\\]{1}\?>/s && $mode eq 'code') {
			$last_mode = $mode;
			$mode = 'text';
		}
		
		else {
			if($mode eq 'code') {
				if($i > 1 && $segments[$i] ne '') {
					if($open_seg eq '<?=') {
						$translated .= 'print ';
					}
					$translated .= $segments[$i].$trail_char;
					if($open_seg eq '<?=') {
						$translated .= ";\n";
					}
				}
			}
			
			if($mode eq 'text') {
				if($segments[$i] ne '') {
					$seg_varname = $self->rand_id();
					$translated .= "\$OUT = <<'$seg_varname';\n".$segments[$i]."\n$seg_varname\n".'$OUT =~ s/\n$//'.";print \$OUT;\n";
				}
			}
		}
		$i++;
	}
	
	$translated .= '}; $run_tpl->($self);';
	
	
	# run the parsed perl code:
	my $err = $self->expand($translated);
	
	if($err) { $buffer_ref .= 'In parsing '.$tpl.".tmpl:<br />".$err."\n"; }
	
	# get print statements routing back where they belong:
	close($buffer_fh); select $orig_fh;
	
	# $buffer_ref .= '<pre>'.$translated.'</pre>';
	
	# returning as string, or adding to output buffer?
	if($return) { return $buffer_ref; }
	
	$kbzb::out->append_output($buffer_ref);

}

# we just want a sub with practically no variables declared with "my ..."
sub expand {
	my ($self) = @_; # nothing but $self for now.
	eval $_[1];
	return $@;
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