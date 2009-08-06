package kbzb::libraries::database::db; 

# -- $Id: db.pm 172 2009-08-05 20:30:30Z zburke $

use strict; 
use warnings; 
use DBI; 


sub new
{
	my $class = shift; 
	my $self = {}; 

	bless $self, $class;
	
	kbzb::libraries::common::load_class('config', undef, $self); 
	
	$self->{_dbh} = undef; 
	$self->{_delegate} = undef; 

	return $self;
	
}



#
# dbh
# return an open database handle, which will also be cached for reuse. 
# if we are handed a DSN, always create a new connection, even if a 
# cached handle is already available. 
sub dbh
{
	my $self = shift; 
	my %input = @_; 
		
	# use the given DSN if we were given one directly;
	# otherwise, get connection properties from the 
	# database.properties config file
	if ($input{dsn}) 
	{
		$self->_init_dsn(%input); 
	}
	else
	{
		return $self->{_dbh} if ($self->{_dbh});
		
		$self->_init_config(); 
	}
	
	if (! $self->{_dbh}) 
	{
		die DBI::errstr;
	}
	
	return $self->{_dbh}; 
}



#
# _init_config
# initialize the db connection from parameters in the config file.
# stashes the connection handle in the package global $dbh on success. 
#
sub _init_config
{
	my $self = shift;
	
	if (! $self->{_dbh}) 
	{
		my $params = $self->config->load('database');
		unless ($params->{active_group} && $params->{$params->{active_group}})
		{
			die('Invalid database active group specified.');
		}
		
		my $config = $params->{$params->{active_group}};
		
		# instantiate a delegate for DB-dependent operations such as
		# sequence selection, listing tables, listing fields, etc.
		require(kbzb::BASEPATH() . 'kbzb/libraries/database/db_' . lc $config->{dbdriver} . '.pm');
		my $classname = 'kbzb::libraries::database::db_' . lc $config->{dbdriver};
		$self->{_delegate} = $classname->new(); 
		
		# use said delegate to connect
		$self->{_dbh} = $self->{_delegate}->_connect($config); 
	}   
	
}



#
# _init_dsn
# initialize the db connection from the given parameters.
# stashes the connection handle in the package global $dbh on success. 
#
sub _init_dsn
{
	my $self = shift; 
	my %input = @_; 

	if (! $self->{_dbh}) 
	{
		# validate the DSN 
		my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($input{dsn});
		if (! $scheme)
		{
			die("Invalid DSN: $input{dsn}"); 
		}
		
		$driver = lc $driver; 
		
		# instantiate a delegate for other DB-dependent operations such as
		# sequence selection, listing tables, listing fields, etc.
		if (-f kbzb::BASEPATH() . 'kbzb/libraries/database/db_' . $driver . '.pm')
		{
			require(kbzb::BASEPATH() . 'kbzb/libraries/database/db_' . $driver . '.pm');
			my $classname = 'kbzb::libraries::database::db_' . $driver;
			$self->{_delegate} = $classname->new(); 
		}		
		
		$self->{_dbh} = DBI->connect($input{dsn}, $input{username}, $input{password}) 
			or die $DBI::errstr;
	
	}   
}



sub get_sequence
{
	my $self = shift; 
	return $self->{_delegate}->_get_sequence(@_); 
}

1;

__END__

