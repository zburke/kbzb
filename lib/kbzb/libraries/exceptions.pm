package kbzb::libraries::exceptions;

# -- $Id: exceptions.pm 156 2009-07-27 20:10:52Z zburke $

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
	
	return $self;
}



#
# show_404
# 404 Error pages prints the 404 message to the log and the client, then exits. 
#
sub show_404
{
	my $self = shift; 
	my ($page, $message) = @_;  
	
	print $kbzb::cgi->header(-status => "404 Page Not Found"); 
	print $self->show_error('404 Page Not Found', 'The page you requested was not found.', 'error_404.htmx');
	exit(1); 
}


#
# show_error
# General purpose error handler returns an HTML page ready for output. 
#
sub show_error
{
	my $self = shift; 
	my ($heading, $message, $template) = @_; 
	
	$template = $template || 'error_general.htmx';
	
	my $content = kbzb::libraries::common::read_file(kbzb::PKGPATH() . 'errors/' . $template); 

	$content =~ s/\{heading\}/$heading/g; 
	$content =~ s/\{message\}/$message/g; 
	
	return $content; 
}

1; 

__END__


=pod

=head1 NAME

exceptions - display error pages

=head2 DESCRIPTION

 $e = kbzb::libraries::exceptions;->new(); 

 # display a 404 error, then exit. the page and message will be logged
 $e->show_404('page', 'message'); 
 
 # return an HTML string containing heading and message, suitable for display
 # the error_general.htmx template from the app's errors directory will be used.
 $e->show_error('heading', 'message'); 

 # return an HTML string containing heading and message, suitable for display.
 # use the template.htmx template from the app's errors directory.
 $e->show_error('heading', 'message', 'template.htmx'); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
