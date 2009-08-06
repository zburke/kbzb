package kbzb::libraries::database::db_oracle; 

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
		"DBI:Oracle:host=$config->{hostname};sid=$config->{database}", 
		$config->{username}, 
		$config->{password}, 
		{ RaiseError => 1, AutoCommit => 0 }
		) or die $DBI::errstr;
}



sub _get_sequence
{
	my $self = shift; 
	my ($dbh, $name) = @_;
	
	my $sth = $dbh->prepare("select $name.NEXTVAL ID from dual");
    
    die($dbh->errstr) if $dbh->err;

	$sth->execute();

	die($dbh->errstr) if $dbh->err;
	
	my ($id) = $sth->fetchrow_array();
    
	die("The sequence $name was empty!") unless $id; 

    return $id;

}


1; 

__END__

=pod

=head1 NAME

db_oracle - Oracle-specific database functions

=head2 DESCRIPTION

See L<kbzb::libraries::database::db> for function descriptions. 
This library is used internally by L<kbzb::libraries::database::db> 
for Oracle-specific database function such as selecting sequences, 
defining constraints, etc. 

=cut