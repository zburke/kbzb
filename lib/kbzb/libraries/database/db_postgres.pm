package kbzb::libraries::database::db_postgres; 

# -- $Id$

use strict; 
use warnings; 
use DBI; 



sub new
{
	my $class = shift; 

	my $self = {}; 

	bless $self, $class;

	return $self;	
}



sub _connect
{
	my $self = shift;
	my ($config) = @_;
	
	return DBI->connect(
		"DBI:$config->{dbdriver}:database=$config->{database};host=$config->{hostname};port=$config->{port}", 
		$config->{username}, 
		$config->{password}, 
		{ RaiseError => 1, AutoCommit => 0 }
		) or die $DBI::errstr;
}


1; 

__END__