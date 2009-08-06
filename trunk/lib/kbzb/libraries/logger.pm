package kbzb::libraries::logger;

# -- $Id: logger.pm 161 2009-07-28 20:49:55Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict; 

my $threshold = 0; 

use constant FATAL => 0; 
use constant ERROR => 10; 
use constant WARN  => 20; 
use constant INFO  => 30; 
use constant DEBUG => 40; 


sub new
{
	my $class = shift;
	my $self = {}; 
	
	bless($self, $class);
	
	return $self; 
}



sub fatal
{
	shift if ref $_[0];
	if (kbzb::libraries::common::config_item('log_threshold') >= FATAL)
	{
		my ($package, $filename, $line) = caller;
		print STDERR 'FATAL: ' . $package . ':' . $line . ' '. shift() . "\n"; 
	}
}



sub error
{
	shift if ref $_[0];
	if (kbzb::libraries::common::config_item('log_threshold') >= ERROR)
	{
		my ($package, $filename, $line) = caller;
		print STDERR 'ERROR: ' . $package . ':' . $line . ' '. shift() . "\n"; 
	}
	
}



sub warn
{
	shift if ref $_[0];
	if (kbzb::libraries::common::config_item('log_threshold') >= WARN)
	{
		my ($package, $filename, $line) = caller;
		print STDERR 'WARN: ' . $package . ':' . $line . ' '. shift() . "\n"; 
	}
	
}



sub info
{
	shift if ref $_[0];
	if (kbzb::libraries::common::config_item('log_threshold') >= INFO)
	{
		my ($package, $filename, $line) = caller;
		print STDERR 'INFO: ' . $package . ':' . $line . ' '. shift() . "\n"; 
	}
	
}



sub debug
{
	shift if ref $_[0];
	if (kbzb::libraries::common::config_item('log_threshold') >= DEBUG)
	{
		my ($package, $filename, $line) = caller;
		print STDERR 'DEBUG: ' . $package . ':' . $line . ' '. shift() . "\n"; 
	}
}

1; 

__END__


=pod

=head1 NAME

logger - graduated logging methods (debug, info, warn, error, fatal)

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->logger so there is no need to 
re-instantiate it yourself. 

The logger class provides graduated debugging levels so you can vary 
the level of information that shows up in the error log by changing
the value of log_threshold in your app's config.properties file.

Messages are printed to STDERR and include the calling package name
and line number. 

 $self->logger->debug('A debugging message'); 
 $self->logger->info('An informational message'); 
 $self->logger->warn('A warning message'); 
 $self->logger->error('An error message'); 
 $self->logger->fatal('A fatal message'); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
