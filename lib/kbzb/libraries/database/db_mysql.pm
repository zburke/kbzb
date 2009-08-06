package kbzb::libraries::database::db_mysql; 

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
		"DBI:mysql:database=$config->{database};host=$config->{hostname};port=$config->{port}", 
		$config->{username}, 
		$config->{password}, 
		{ RaiseError => 1, AutoCommit => 0 }
		) or die $DBI::errstr;
}



sub _get_sequence
{
	my $self = shift; 
	my ($dbh, $name) = @_;

	$name ||= 'sequence';
	
	my $sth = $dbh->prepare("update $name set id=LAST_INSERT_ID(id+1)"); 
	die($dbh->errstr) if $dbh->err;
	$sth->execute();
	die($dbh->errstr) if $dbh->err;
	
	$sth = $dbh->prepare('select LAST_INSERT_ID() as id'); 
	$sth->execute(); 
		
	my $id = $sth->fetchrow_arrayref()->[0];
	
	die("The sequence $name was empty!") unless $id; 
		
	return $id;
}

1; 

__END__

=pod

=head1 NAME

db_mysql - Mysql-specific database functions

=head2 DESCRIPTION

See L<kbzb::libraries::database::db> for function descriptions. 
This library is used internally by L<kbzb::libraries::database::db> 
for Mysql-specific database function such as selecting sequences, 
defining constraints, etc. 

=cut