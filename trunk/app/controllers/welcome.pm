package app::controllers::welcome; 

use kbzb::libraries::controller;
use base qw(kbzb::libraries::controller);

sub new
{
	my $class = shift; 

	my $self = $class->SUPER::new();

	bless($self, $class); 

	return $self; 
}



sub index
{
	my $self = shift; 
	my (@input) = @_; 
	
	$self->load->view('welcome_message');	
}


1;
