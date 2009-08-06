package kbzb::libraries::hooks; 

# -- $Id: hooks.pm 156 2009-07-27 20:10:52Z zburke $

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
	
	kbzb::libraries::common::load_class('logger', undef, $self);

	$self->{enabled} = 0;
	$self->{hooks} = {};
	$self->{in_progress} = 0; 
	
	
	$self->_initialize(); 
	
	$self->logger->debug('Hooks Class Initialized');
	
	return $self; 
}



# 
# _initialize
# init preferences
sub _initialize
{
	my $self = shift;
	
	my $cfg = kbzb::libraries::common::load_class('config');

	# If hooks are not enabled in the config file
	# there is nothing else to do
	if (! $cfg->item('enable_hooks'))
	{
		return;
	}
	
	# Grab the "hooks" definition file.
	# If there are no hooks, we're done.
	my $hooks = $cfg->parse('hooks');
	
	if (scalar keys %{ $hooks })
	{
		$self->{hooks} = $hooks;
		$self->{enabled} = 1; 
	}
	
}



#
# _call_hook
# call a named hook
sub _call_hook
{
	my $self = shift; 
	my ($which) = shift; 
	
	# return unless a hook matches this injection-point
	my @list = grep /^$which/, sort keys %{ $self->{hooks} };
	return unless ($self->{enabled} && scalar @list);
	
	for (@list)
	{
		$self->_run_hook(@{$self->{hooks}->{$_}}); 
	}
}



# 
# _run_hook
# run a hook
sub _run_hook
{
	my $self = shift;
	my ($class, $method, $args) = @_; 
	
	# -----------------------------------
	# Safety - Prevents run-away loops
	# -----------------------------------
	# If the script being called happens to have the same
	# hook call within it a loop can happen
	return if $self->{in_progress};

	(my $c_path = $class) =~ s/::/\//g; 
	(my $c_pkg  = $class) =~ s/\//::/g; 
	
	my $classname = kbzb::APPPKG() . "::hooks::$c_pkg";
	(my $filename = $classname) =~ s/::/\//g;
	
	# does the requested hook class actually exist? 
	return unless ( -f kbzb::APPPATH() . $filename . '.pm');

	# -----------------------------------
	# Safety: set the in_progress flag
	# -----------------------------------
	$self->{in_progress} = 1;

	# -----------------------------------
	# Call the requested class and/or function
	# -----------------------------------
	require(kbzb::APPPATH() . $filename . '.pm');

	if (defined &{$classname . '::' . $method})
	{
		$classname->$method($args); 
	}
	else
	{
		$self->logger->error("hook error: could not call $classname\::$method"); 
	}

	$self->{in_progress} = 0;
}

1;

__END__


=pod

=head1 NAME

hooks - inject code into the workflow without hacking the core

=head1 SYNOPSIS

 # in config.properties
 enable_hooks = 1
 
 # in hooks.properties
 pre_controller-a = { hooks::package1, method_1, "arg1, arg2, arg3" }
 pre_controller-b = { hooks::package1, method_2, "arg1, arg2, arg3" }
 
 # app::hooks::package1
 sub method_1 { my $class = shift; my ($a1, $a2, $a3) = @_; ...}
 sub method_2 { my $class = shift; my ($a1, $a2, $a3) = @_; ...}


=head1 DESCRIPTION

Hooks provide a means to tap into and modify the inner workings of the 
framework without hacking the core files. kbzb::run follows a set execution
process, and using hooks allows you to take actions at various set points
in that process.

=over

=item pre_system

Called very early during system execution. Only the benchmark and hooks class have been loaded at this point. No routing or other processes have happened.

=item pre_controller

Called immediately prior to any of your controllers being called. All base classes, routing, and security checks have been done.

=item post_controller_constructor

Called immediately after your controller is instantiated, but prior to any method calls happening.

=item post_controller

Called immediately after your controller is fully executed.

=item display_override

Overrides the _display() function, used to send the finalized page to the web browser at the end of system execution. This permits you to use your own display methodology. Note that you will need to reference the CI superobject with $this->CI =& get_instance() and then the finalized data will be available by calling $this->CI->output->get_output()

=item cache_override

Enables you to call your own function instead of the _display_cache() function in the output class. This permits you to use your own cache display mechanism.

=item scaffolding_override

Permits a scaffolding request to trigger your own script instead.

=item post_system

Called after the final rendered page is sent to the browser, at the end of system execution after the finalized data is sent to the browser.

=back

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
