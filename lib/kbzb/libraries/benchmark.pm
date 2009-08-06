package kbzb::libraries::benchmark;

# -- $Id: benchmark.pm 161 2009-07-28 20:49:55Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --



use strict; 
use Time::HiRes; 



#
# new
# initialize the markers hash.
#
sub new
{
	my $class = shift; 
	my $self = {};
	
	bless($self, $class);
	
	$self->{marker} = {}; 
	
	return $self; 
}



#
# mark
# set a benchmark label.
#
sub mark
{
	my $self = shift; 
	my ($name) = @_; 
	
	$self->{marker}->{$name} = [Time::HiRes::gettimeofday];
}



#
# elapsed time
# return the elapsed time between two marks, in seconds. if the first
# argument is empty, the parser/output placeholder string {elapsed_time} is 
# returned so full execution time can be calculated during output. 
# 
# arguments
#    $string - marker 1
#    $string - marker 2
#    $int - number of decimal places to return
#
# return
#    if both markers are set, the elapsed time between markers. 
#    if only the first marker is set, the elapsed time since it was set.
#    if the first marker was not set, an empty string.
#
sub elapsed_time
{
	my $self = shift; 
	my ($t1, $t2, $decimals) = @_; 
	
	$decimals = $decimals || 4; 
	
	if ($t1 eq '')
	{
		return '{elapsed_time}';
	}


	if (! exists $self->{marker}->{$t1})
	{
		return '';
	}

	if (! exists $self->{marker}->{$t2})
	{
		$self->{marker}->{$t2} = [Time::HiRes::gettimeofday];
	}
	
	return sprintf("%.*f", $decimals, Time::HiRes::tv_interval($self->{marker}->{$t1}, $self->{marker}->{$t2}));
}



#
# memory_usage
# return the string {memory_usage}
#
# return
#     $string - the {memory_usage} output class pseudo variable.
# 
sub memory_usage
{
	return '{memory_usage}';
}


1; 

__END__

=pod

=head1 NAME

benchmark - mark points and calculate time differences

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->benchmark so there is no need to 
re-instantiate it yourself. 

 $tag = kbzb::libraries::common::load_class('benchmark'); 

 $tag->mark('total_execution_time_start');

 [ ... code ...]

 $tag->mark('total_execution_time_end');
 
 # get elapsed time, in milliseconds, to four decimal places
 $elapsed = $tag->elapsed('total_execution_time_start', 'total_execution_time_end');
 
 # get elapsed time, in milliseconds, to $n decimal places
 $elapsed = $tag->elapsed('total_execution_time_start', 'total_execution_time_end', $n);
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

