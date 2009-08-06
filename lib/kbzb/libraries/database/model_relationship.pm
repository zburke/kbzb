package kbzb::libraries::database::model_relationship;

# -- $Id$

use strict;
use warnings; 

use constant HAS_ONE  => 'has_one';
use constant HAS_MANY => 'has_many';

sub new
{
	my $class = shift; 
	
	my ($classname, $fk, $type, $through, $through_fk) = @_; 

	my $self = {}; 
	
	bless $self, $class; 
	
	$self->{_classname} = $classname; # name of the related-class
	$self->{_fk}        = $fk;        # foreign key on related-class tying it to source-class or join-class
	$self->{_type}      = $type;      # to-one or to-many
	
	# flattened relationship
	if ($through && $through_fk)
	{
		$self->{_through}    = $through;    # name of the intermediary-class
		$self->{_through_fk} = $through_fk; # foreign key on join-class to source-class
	}
	
	return $self; 
}



#
# classname 
# simple accessor method	
sub classname 
{
	my $self = shift; 
	return $self->{_classname}; 
}



#
# fk 
# simple accessor method	
sub fk 
{
	my $self = shift; 
	return $self->{_fk}; 
}



#
# type 
# simple accessor method	
sub type
{
	my $self = shift; 
	return $self->{_type}; 
}



#
# through 
# simple accessor method	
sub through 
{
	my $self = shift; 
	return $self->{_through}; 
}



#
# through_fk 
# simple accessor method	
sub through_fk 
{
	my $self = shift; 
	return $self->{_through_fk}; 
}

1; 

__END__

=pod

=head1 NAME

=head1 DESCRIPTION

 user: id, name
 group: id, name
 group_user_join: group_id, user_id
 
 # simple relationship: 
 $item->has_many('relationship_name', 'related_class', 'related-to-source_fk');
 
 # flattened relationship
 $item->has_many('relationship_name', 'related_class', 'join-to-related_fk', 'join_class', 'join-to-source_fk');

 $user->has_many('group_memberships', 'group_user_join', 'user_id');
 $user->has_many('groups', 'group', 'group_id', 'group_user_join', 'user_id');
 
 $group->has_many('user_memberships', 'group_user_join', 'group_id');
 $group->has_many('users', 'user', 'user_id', 'group_user_join', 'group_id');

=cut