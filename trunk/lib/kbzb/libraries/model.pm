package kbzb::libraries::model; 

use strict; 
use warnings; 
use DBI; 
use kbzb::libraries::database::model_relationship; 


# static DB handle
my $dbh = undef; 

# static DB instance
my $db = undef; 


sub new
{
	my $class = shift;
	my $self = {}; 
	
	bless $self, $class;
	
	# for, um, logging
	kbzb::libraries::common::load_class('logger', undef, $self); 
	
	# for loading models
	kbzb::libraries::common::load_class('loader', undef, $self); 
	
	# cache a DB handle and a DB instance (created by dbhS)
	$self->{_dbh} = $_[0] || $class->dbhS();
	$self->{db} = $db; 

	$self->{config}          = undef;  # db config params (hostname, db name, etc)
	
	$self->{has_updates}     = 0;      # any changes to this item? 1 if so.
	
	$self->{_relations}      = undef;  # % named relationships
	$self->{cache}           = undef;  # cached relationships
	
	$self->{fields}          = [];     # list of field names
	$self->{fields_required} = [];     # required fields
	$self->{pk}              = undef;  # primary key; field-name or array-ref
	$self->{table_name}      = undef;  # table name
	$self->{order}           = [];     # default sort fields
	$self->{sequence_name}   = undef;  # name of unique ID generator
	
	$self->logger->debug('Database::Orm Class Initialized'); 
	
	return $self; 
}




#
# order_default
# default sort ordering, if none is specified
sub order_default
{
	my $self = shift; 
	
	if (grep /^rank$/, @{$self->{fields}})
	{
		return 'rank';
	}
	elsif (grep /^name$/, @{$self->{fields}})
	{
		return 'name';
	}
	
	return ''; 
}



#
# order 
# list of fields to use in an SQL order by clause. it first checks the 
# class's order list, then tries order_default. returns an empty string
# if no suitable guess about ordering can be made. 
sub order
{
	my $self = shift;
	
	if (scalar @{ $self->{order} })
	{
		return join ', ', @{ $self->{order} }; 
	}
	
	return $self->order_default(); 
}



#
# dbhS
# static method: create and cache a static DB connection if it hasn't 
# already been done
sub dbhS
{
	my $class = shift; 
	my ($input) = @_; 
	
	if (! $dbh) 
	{
		$db = kbzb::libraries::common::load_class('database::db');
		$dbh = $db->dbh();
	}
	
	return $dbh;
}



# 
# dbh
# instance method: retrieve the database handle used to instantiate this 
# object
sub dbh
{
	my $self = shift; 
	my ($input) = @_; 

	if (! $self->{_dbh})
	{
		$self->{config} = $input; 
		$self->{_dbh} = $self->dbhS($input); 
	}
	
	return $self->{_dbh};
}



# 
# get_sequence
# retrieve next value of a named sequence. assumes the table contains
# a field named id. 
# 
sub get_sequence
{
	my $self = shift; 
	my ($name) = @_; 
	
	return $self->{db}->get_sequence($dbh, $self->{sequence_name}); 
}



#
# insert
#
sub insert
{
	my $self = shift; 
	
	my ($dbh, $tn, $hash) = @_; 
	
	$dbh = $self->dbh() unless $dbh; 
	
	my (@bkeys, @bvals, @vals) = undef; 
	
	for (keys %$hash)
	{
		if ($hash->{$_})
		{
			push @bkeys, $_;
			push @bvals, '?';
			push @vals , $hash->{$_};
		}
		else
		{
			$self->logger->debug("The field $self->{table_name}:$_ is NULL.");
		}
	}
	
	my $sth = $dbh->prepare('insert into ' . $tn . ' (' . join(',', @bkeys) . ') values (' . join(', ', @bvals) . ')'); 
	$sth->execute(@vals); 
}



#
# update
#
sub update
{
	my $self = shift; 
	
	$self->validate_for_save(); 
	
	my ($set, $bindings) = $self->update_bindings();
	
	my $where = ''; 
	
	if ('ARRAY' eq ref $self->{pk})
	{
		my @where; 
		for (@{$self->{pk}})
		{
			push @where, "$_ = ?";
			push @$bindings, $self->{$_}; 
		}
		
		$where = join ', ', @where; 
	}
	else
	{
		$where = "$self->{pk} = ?";
		push @$bindings, $self->{$self->{pk}};
	}
	
	my $sql = 'update ' . $self->{table_name} . ' set ' . join(', ', @$set) . ' where ' . $where;
	
	my $sth = $self->dbh()->prepare($sql); 
	$sth->execute(@$bindings); 
}

	
	
	
#	/**
#	 * Refresh a snapshot with current data from the DB
#	 * @return unknown_type
#	 */
#	public function refresh()
#	{
#		$s = $this->_dbh()->prepare(
#			  "select " . join (", ", $this->_fieldNames()) 
#				. " from {$this->_tableName()} "
#				. " where {$this->_primaryKeyName()} = :id");
#		$s->setFetchMode(PDO::FETCH_CLASS, get_class($this));
#		$s->execute(array('id' => $this->{$this->_primaryKeyName()}));
#		
#		$item = $s->fetch(PDO::FETCH_CLASS);
#		foreach ($this->_fieldNames() as $field)
#		{
#			$this->{$field} = $item->{$field}; 
#		}
#	}
	
	
sub update_bindings
{
	my $self = shift; 
	
	my (@set, @bindings); 
	for (@{$self->{fields}})
	{
		next if (grep /^$_$/, @{ $self->{pk}}); 
		
		if (exists $self->{$_})
		{
			push @set, "$_ = ?"; 
			push @bindings, $self->{$_}; 
		}
		else
		{
			push @set, "$_ = NULL"; 
		}
	}
	
	return (\@set, \@bindings); 
}



# 
# remove
# remove an item from the DB. if the item contains any has-many relationships,
# remove the related items as well. 
sub remove
{
	my $self = shift; 
	
	for (keys %{ $self->{_relations} })
	{
		$self->logger->debug("Checking on all $_ instances for $self->{table_name} id $self->{$self->{pk}}");
		if ($self->{_relations}->{$_}->type() eq kbzb::libraries::database::model_relationship::HAS_MANY)
		{
			$self->logger->debug("    removing all $_ instances"); 
			for my $i ($self->$_())
			{
				$i->remove(); 
			}
		}
	}
	
	if ('ARRAY' eq ref $self->{pk})
	{
		$self->remove_compound();
	}
	else
	{
		$self->remove_simple(); 
	}
}



# 
# remove_simple
# remove helper function: simple PK
sub remove_simple
{
	my $self = shift; 
	
	my $sth = $self->dbh()->prepare("delete from $self->{table_name} where $self->{pk} = ?");
	$sth->execute(($self->{$self->{pk}})); 
}



#
# remove_compound
# remove helper function: multi-column pk
sub remove_compound
{
	my $self = shift; 
	
	my (@bkeys, @bvals); 
	
	for (@{ $self->{pk} })
	{
		push @bkeys, "$_ = ?";
		push @bvals, $self->{$_}; 
	}
	
	my $sth = $self->dbh()->prepare("delete from $self->{table_name} where " . join(' AND ', @bkeys)); 
	$sth->execute(@bvals); 
}



# 
# find
# retrieve an item from the DB by its primary key
# STATIC METHOD
sub find
{
	my $class = shift; 
	my ($dbh, $id) = @_; 
	
	die('Missing required parameters to ' . __PACKAGE__ .'::find!') unless ($class && $id);
	$dbh ||= $class->dbhS(); 
	
	my $instance = $class->new($dbh); 

	my $sql = 'select ' . join (', ', @{ $instance->{fields} }) . " from $instance->{table_name} where $instance->{pk} = ?";

	my $sth = $dbh->prepare($sql); 
				
	$sth->execute(($id)); 
	
	my @result = @{ $sth->fetchall_arrayref({}) };
	die('Object not found exception: ' . $class . '::find failed for id ' . $id) unless scalar @result == 1; 

	for (keys %{ $result[0] })	
	{
		$instance->{$_} = $result[0]->{$_};
	}
	
	return $instance; 
	
}



#
# find_all
# retrieve all items from the DB
# STATIC METHOD
sub find_all
{
	my $class = shift; 
	my ($dbh, $order) = @_; 
	$dbh ||= $class->dbhS(); 
	
	my $instance = $class->new($dbh); 
	
	$order ||= $instance->order(); 
	
	my $sth = $dbh->prepare('select ' . join (', ', @{ $instance->{fields} }) . " from $instance->{table_name} " . ($order ? " order by $order" : '')); 
	$sth->execute(); 
	
	my @results = (); 
	for my $item (@{ $sth->fetchall_arrayref({}) })
	{
		my $object = $class->new($dbh); 
		map { $object->{$_} = $item->{$_} } keys %$item; 
		push @results, $object; 
	}
	
	return \@results; 
}



#
# find_list
# retrieve a list of items, given their primary keys.
sub find_list
{
	my $class = shift;
	my ($dbh, $ids, $order) = @_; 
	$dbh ||= $class->dbhS(); 
	
	die("No IDs specified!") unless scalar @$ids; 
	
	my $instance = $class->new($dbh); 
	
	$order ||= $instance->order(); 
	
	my $sth = $dbh->prepare(
		'select ' . join (', ', @{ $instance->{fields} }) . 
		" from $instance->{table_name} " . 
		" where $instance->{pk} in (" . join(", ", @$ids) . ")" .
		($order ? " order by $order" : '')); 
	$sth->execute(); 
	
	my @results = (); 
	for my $item (@{ $sth->fetchall_arrayref({}) })
	{
		my $object = $class->new($dbh); 
		map { $object->{$_} = $item->{$_} } keys %$item; 
		push @results, $object; 
	}
	
	if ($#results != $#{$ids})
	{
		die((scalar @$ids) . " specified but only " . (scalar @results) . " items could be found!"); 
	}
	
	return \@results; 
	
}
	
	
#	/**
#	 * retrieve an individual object by its name.
#	 * 
#	 * @param string $classname: name of the class to map the db row to
#	 * @param string[] $fields: columns in the db to retrieve 
#	 * @param string $table: table in the db to retrieve from
#	 * @param string $name: unique value in the row to retrieve
#	 * @param string $nameField: name of the field to search in; defaults to NAME
#	 * 
#	 * @throws Exception if required parameters are not passed
#	 * @throws PDOException if there are problems preparing or executing the statement
#	 * @throws ObjectNotFoundException if the requested row cannot be found
#	 * 
#	 * @return extends Object: instance of $class with given PK
#	 * 
#	 */
#	protected static function findByName(PDO $dbh, $classname, $name, $nameField) {
#		if (! ($classname && $name)) {
#			throw new Exception("Couldn't find a $classname by PK because invalid parameters were specified."); 
#		}
#		
#		if (! $dbh) {
#			$dbh = self::dbhS();
#		}
#		
#		try {
#			// temp instance so we can extract DB metadata
#			$instance = new $classname($dbh); 
#			
#			$s = $dbh->prepare(
#				"select " . join (", ", $instance->fieldNames()) .
#				" from {$instance->tableName()}" . 
#				" where $nameField = :name"); 
#				
#			$s->setFetchMode(PDO::FETCH_CLASS, $classname);
#			$s->execute(array('name' => $name));
#			$item = $s->fetch(PDO::FETCH_CLASS);
#			
#		}
#		catch(PDOException $e) {
#			throw new PDOException($e);
#		}
#		
#		if ($item) {
#			return $item;
#		}
#				
#		// requested a specific name and couldn't find it. that smells like trouble.
#		throw new ObjectNotFoundException("Couldn't find a $classname identified by $name."); 
#	}
	
	
	
#	/**
#	 * retrieve objects matching one or more criteria. 
#	 * 
#	 * @param PDO $dbh
#	 * @param string $classname: name of the class to map the db row to
#	 * @param string[] $where: columns in the db to retrieve 
#	 * @param string $glue: default: ' AND '
#	 * @param string $sortBy: field to sort by
#	 * 
#	 * @throws Exception if required parameters are not passed
#	 * @throws PDOException if there are problems preparing or executing the statement
#	 * @throws ObjectNotFoundException if the requested row cannot be found
#	 * 
#	 * @return extends $classname[]: instances of $class matching the given key/value pairs
#	 * 
#	 */
#
# find_where
# static finder
sub find_where
{
	my $class = shift; 
	my ($dbh, $where, $glue, $order) = @_; 
	$dbh ||= $class->dbhS(); 
	
	$glue ||= ' AND '; 
	
	die() unless $class && $where; 
	
	my @list = (); 
	my $instance = $class->new($dbh); 
	$order ||= $instance->order_default(); 
	
	my (@bkeys, @bvals);
	for (keys %$where)
	{
		if ('null' eq $where->{$_})
		{
			push @bkeys, "$_ is null";
		}
		else
		{
			push @bkeys, "$_ = ?";
			push @bvals, $where->{$_};
		}
	}
		
	my $sql = "select " . join (", ", @{ $instance->{fields} }) .
			" from " . $instance->{table_name} . 
			" where " . join(" $glue ", @bkeys);

	$sql .= " order by $order" if $order; 
		
	my $sth = $dbh->prepare($sql); 
		
	$sth->execute(@bvals); 
	
	my @results = (); 
	for my $item (@{ $sth->fetchall_arrayref({}) })
	{
		my $object = $class->new($dbh); 
		map { $object->{$_} = $item->{$_} } keys %$item; 
		push @results, $object; 
	}
	
	return \@results; 
}



#
# id
# retrieve an item's primary key, assuming a one-field PK.
sub id
{
	my $self = shift; 
	
	return $self->{$self->{pk}};
}	
	


#
# max
# find the max value of a column in the current table.
sub max
{
	my $self = shift;
	
	my ($field) = @_; 
	
	die("The table $self->{table_name} does not contain a field $field.") unless grep /^$field$/, @{ $self->{fields} };
	
	my $sth = $self->dbh()->prepare("select max($field) as max from $self->{table_name}"); 
	$sth->execute(); 
	my $row = $sth->fetchrow_arrayref(); 

	return $$row[0] ? $$row[0] : 0; 
}	



# 
# save
# commit the currently open transaction
sub save
{
	my $self = shift;
	
	$self->dbh()->commit(); 	
}



#
# equals
# determine if two objects are equal by comparing their primary key values
sub equals
{
	my $self = shift;
	my ($item) = @_; 
	
	# gotta be the same class
	return 0 unless ($self->{table_name} eq $item->{table_name});
	
	if ('ARRAY' eq ref $self->{pk})
	{
		for (@{ $self->{pk} })
		{
			if ($self->{$_} ne $item->{$_})
			{
				return 0;
			}
		}
		return 1; 
		
	}
	else
	{
		return 1 if ($self->{$self->{pk}} eq $item->{$item->{pk}});
		return 0;
	}
	
}



#
# count_all
# count the items in a table
# STATIC METHOD
sub count_all
{
	my $class = shift;
	my ($config) = @_; 
	
	my $instance = $class->new(); 
	my $sth = $class->dbhS($config)->prepare("select count(*) as i from $instance->{table_name}"); 
	$sth->execute(); 
	my $row = $sth->fetchrow_arrayref(); 

	return $$row[0] ? $$row[0] : 0; 	
}



#
# Add a to-one relationship
#
# @param string $name Name of the relationship
# @param string $classname Name of the destination class
# @param string $fk Name of the foreign key on this class referencing the destination class
#
sub has_one
{
	my $self = shift;
	my ($name, $classname, $fk) = @_; 
	
	if (exists $self->{_relations}->{$name})
	{
		die("Cannot create a relationship named $name; one already exists!"); 
	}

	if (! $fk)
	{
		$fk = lc $classname . '_id';
		if (! grep /^$fk$/, @{$self->{fields}})
		{
			die("Could not create a relationship from " . __PACKAGE__ . " to $classname because no foreign key was specified, nor could one be determined automatically.");
		}
	}
	
	my $r = kbzb::libraries::database::model_relationship->new($classname, $fk, kbzb::libraries::database::model_relationship::HAS_ONE);
	$self->{_relations}->{$name} = $r; 
	
	no strict 'refs'; 
	*{ ref($self) . "\::$name"} = sub {
		
		my $s = shift; 

		if (! $s->{cache}->{$name})
		{
			$self->loader->model($name); 

			ref($self) =~ /(.*)::\w+$/; 
			my $pkg_path = $1; 

			my $r = $s->{_relations}->{$name}; 
			$s->{cache}->{$name} = "$pkg_path\::$name"->find(undef, $s->{$r->fk()}); 
		}

		return $s->{cache}->{$name};
	}; 
		
}



#
# Add a to-many relationship
#
# @param string $name Name of the relationship
# @param string $classname Name of the destination class
# @param string $fk Name of the foreign key on the destination referencing this class, or referencing the join class
# @param string $through Name of a join table the relationship is flattened through
# @param string $throughFK Name of the foreign key on the join table referencing this class
#
sub has_many
{
	my $self = shift; 
	my ($name, $classname, $fk, $through, $through_fk) = @_; 
	
	if (exists $self->{_relations}->{$name})
	{
		die("Cannot create a relationship for $classname; one already exists!"); 
	}
	
	if (! $fk)
	{
		$fk = __PACKAGE__ . "_id"; 
	}

	my $r = kbzb::libraries::database::model_relationship->new($classname, $fk, kbzb::libraries::database::model_relationship::HAS_MANY, $through, $through_fk);
	$self->{_relations}->{$name} = $r; 
	
	no strict 'refs'; 
	*{__PACKAGE__ . "\::$name"} = sub {
		
		my $s = shift; 

		if (! $s->{cache}->{$name})
		{
			my $r = $s->{_relations}->{$name}; 

			# require the related class
			$self->loader->model($r->classname()); 

			ref($self) =~ /(.*)::\w+$/; 
			my $pkg_path = $1; 

			
			# flattened to-many
			if ($r->through())
			{
				# require the join-class
				$self->loader->model($r->through());
				
				# fully-qualified join-class package, so we can easily call methods on it
				my $pkg = $pkg_path . '::' . $r->through();
				
				my $keys = ();
				my $list = $pkg->find_where(undef, {$r->through_fk() => $self->id()}); 
				for (@$list)
				{
					push @$keys, $_->{$r->fk()}; 
				}

				# fully-qualified related-class package, so we can easily call methods on it
				$pkg = $pkg_path . '::' . $r->classname();
				
				$s->{cache}->{$name} = $pkg->find_list(undef, $keys); 
			}
			# regular to-many
			else
			{
				my $pkg = $pkg_path . '::' . $r->through();
				$s->{cache}->{$name} = "$pkg_path\::$name"->find_where(undef, $r->classname(), { $r->fk() => $self->id() }); 

			}			
		}

		return $s->{cache}->{$name};
	}; 
	
}

1; 

__END__	
	
