package kbzb::libraries::common;

# -- $Id: common.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use Carp;
use strict;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


# --
# -- cache of loaded libraries
# -- 
my $objects = undef;

# --
# -- cached default config file
# -- 
my $config =  undef;



#
# load_class
# require, instantiate, cache and return the requested library, or 
# return the cached copy if it's available.
# 
sub load_class
{
	my ($class, $config, $receiver) = @_; 
	
	if (exists $objects->{$class})
	{
		_load_class_receiver($class, $receiver); 
		return $objects->{$class};
	}
	
	# first check the app's libraries directory, 
	# then check the kbzb framework's libraries directory,
	# then throw an error.
	my ($classname, $filename); 
	
	(my $c_path = $class) =~ s/::/\//g; 
	(my $c_pkg  = $class) =~ s/\//::/g; 
	
	$classname = kbzb::APPPKG() . "::libraries::$c_pkg";
	($filename = $classname) =~ s/::/\//g;

	if (-f kbzb::APPPATH() . $filename . '.pm')
	{
		require(kbzb::APPPATH() . $filename . '.pm');
		$objects->{$class} = $classname->new($config); 

	}
	elsif (-f kbzb::BASEPATH() . 'kbzb/libraries/' . $c_path . '.pm')
	{
		my $classname = "kbzb::libraries::$class";
		(my $filename = $classname) =~ s/::/\//g;
		require(kbzb::BASEPATH() . $filename . '.pm'); 
		$objects->{$class} = $classname->new($config); 

	}
	else
	{
		confess("Could not find a module corresponding to $class!");
	}
	
	_load_class_receiver($class, $receiver); 

	return $objects->{$class};
	
}



#
# _load_class_receiver
# if receiver exists, create a subroutine returning the requested class. 
# 
sub _load_class_receiver
{
	my ($class, $receiver) = @_; 
	
	if ($receiver)
	{
		no strict 'refs'; 
		*{(ref $receiver) . "::$class"} = sub { return $objects->{$class}; };
	}
}



#
# get_config
# load, parse, cache and return the default config file, or return
# the cached copy, if available.
# 
sub get_config
{
	if ($config)
	{
		return $config;
	}
		
	my $filepath = kbzb::PKGPATH() . 'config/config.properties';

	if (! -f $filepath)
	{
		die("The configuration file $filepath does not exist."); 
	}
	
	
	open(CONFIG, "<$filepath") or die "The configuration file '$filepath' does not exist. $!\n";
	while (<CONFIG>)
	{
		chomp;
		next if $_ =~ /^#/;	
		next if $_ =~ /^\s*$/;

		my ($key, $val) = split(/\s*=\s*/, $_); 
		$config->{$key} = $val;

	}
	close CONFIG;
		
	return $config; 
}



#
# config_item
# return a single item from the default config file, or an 
# empty string if the key is not found.
#
sub config_item
{
	my ($item) = @_; 
	
	get_config(); 
	
	if (exists $config->{$item})
	{
		return $config->{$item};
	}
	
	return '';
}



#
# show_error
# log an error, print a message, and EXIT
#
sub show_error
{
	my $message = shift; 
	
	my ($package, $filename, $line) = caller;
	
	load_class('logger')->error('ERROR: ' . "$package:$line"); 
	
	print $kbzb::cgi->header; 
	print load_class('exceptions')->show_error('An Error Was Encountered', $message);
	exit(1);
}



#
# show_404
# log a 404 error, print a 404 message, and EXIT 
#
sub show_404
{
	my $page = shift; 
	my $message = shift;
	
	my ($package, $filename, $line) = caller;
	load_class('logger')->error('404 ERROR: ' . "$package:$line"); 
	
	load_class('exceptions')->show_404($page, $message, "$package:$line");
	exit(1); 
}



#
# read_file
# parse a file into a newline-delimited string, then return it.
#
sub read_file
{
	my $filepath = shift;
	
	my $content = ''; 
	open(FILE, "<$filepath") or die("Couldn't open '$filepath': $!"); 
	while (<FILE>)
	{
		$_ =~ s/\s*$//g; # zap trailing whitespace, i.e. windows' \r
		$content .= $_ . "\n"; 
	}
	close FILE;
	
	return $content; 
}


1;

__END__

=pod

=head1 NAME

common - utility routines widely used throughout the framework

=head1 DESCRIPTION

=head2 config_item - return a single item from the default config file

=head2 get_config - load and return the main config file

Load the app's main config file. The config parameters will be 
cached so that multiple requests can be handled quickly from the 
cache.

=head2 load_class - class registry loads and caches library classes

This class caches libraries so that multiple requests for the same
library use the same object, rather than instantiating duplicate 
copies. 

=head2 read_file - read a file into a new-line delimited string and return it

=head2 show_error - use the exception class to display an error, then exit

This function lets us invoke the exception class and
display errors using the standard error template located
at app/errors/error_general.htmx
This function will send the error page directly to the
browser and exit.

=head2 show_404 - use the exception class to display a 404 error, then exit

This function lets us invoke the exception class and
display errors using the 404 error template located
at app/errors/error_404.htmx
This function will send the error page directly to the
browser and exit.

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
