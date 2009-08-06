package kbzb::libraries::user_agent; 

# -- $Id: user_agent.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --

use strict;


#
# Constructor
#
# Sets the User Agent and runs the compilation routine
#
# @access	public
# @return	void
#		
sub new
{
	my $class = shift; 
	my $self = {}; 
	
	bless($self, $class); 
	
	$self->{agent}		= undef;
	
	$self->{is_browser}	= 0;
	$self->{is_robot}	= 0;
	$self->{is_mobile}	= 0;
	
	$self->{languages}	= ();
	$self->{charsets}	= ();
	
	$self->{platforms}	= ();
	$self->{browsers}	= ();
	$self->{mobiles}	= ();
	$self->{robots}		= ();
	
	$self->{platform}	= '';
	$self->{browser}	= '';
	$self->{version}	= '';
	$self->{mobile}		= '';
	$self->{robot}		= '';
	
	if ($ENV{'HTTP_USER_AGENT'})
	{
		($self->{agent} = $ENV{'HTTP_USER_AGENT'}) =~ s/\s*$//
	}
	
	if ($self->{agent})
	{
		if ($self->_load_agent_file())
		{
			$self->_compile_data(); 
		}
		
	}
	
	$self->{logger} = kbzb::libraries::common::load_class('logger'); 
	$self->{logger}->debug('User Agent Class Initialized'); 
	
	return $self; 
	
}


#
# Compile the User Agent Data
#
# @access	private
# @return	bool
#
sub _load_agent_file
{
	my $self = shift; 
	
	my $kz = kbzb::get_instance(); 
	my $agents = $kz->config->load('user_agents');
	if (! keys %$agents)
	{
		return undef;
	}
	
	my $return = 0;
	
	if ($agents->{platforms})
	{
		$self->{platforms} = $agents->{platforms};
		$return = 1;
	}

	if ($agents->{browsers})
	{
		$self->browsers = $agents->{browsers};
		$return = 1;
	}

	if ($agents->{mobiles})
	{
		$self->mobiles = $agents->{mobiles};
		$return = 1;
	}
	
	if ($agents->{robots})
	{
		$self->robots = $agents->{robots};
		$return = 1;
	}

	return $return;
}



#
# Compile the User Agent Data
#
# @access	private
# @return	bool
#
sub _compile_data
{
	my $self = shift; 
	
	$self->_set_platform();
	
	return if $self->_set_browser();
	return if $self->_set_robot();
	return if $self->_set_mobile();

}



#
# Set the Platform
#
# @access	private
# @return	mixed
#
sub _set_platform
{
	my $self = shift; 
	
	if ('HASH' eq ref $self->{platforms} && scalar (keys %{ $self->{platforms} }) > 0)
	{
		for (keys %{ $self->{platforms} })
		{
			if ($self->{agent} =~ /$_/i)
			{
				$self->{platform} = $self->{platforms}->{$_};
				return 1; 
			}
		}
	}
	$self->{platform} = 'Unknown Platform';
	
	return 0; 
}



# --------------------------------------------------------------------
#
# Set the Browser
#
# @access	private
# @return	bool
#
sub _set_browser
{
	my $self = shift;
	
	if ('HASH' eq ref $self->{browsers} && scalar (keys %{ $self->{browsers} }) > 0)
	{
		for (keys %{ $self->{browsers} })
		{
			if ($self->{agent} =~ /$_.*?([0-9\.]+)/i)
			{
				$self->{is_browser} = 1; 
				$self->{version} = $1; 
				$self->{browser} = $self->{browsers}->{$_};
				$self->set_mobile();
				
				return 1; 
			}
		}
	}	

	return 0;
}


		

#
# Set the Robot
#
# @access	private
# @return	bool
#
sub _set_robot
{
	my $self = shift; 
	
	if ('HASH' eq ref $self->{robots} && scalar (keys %{ $self->{robots} }) > 0)
	{
		for (keys %{ $self->{robots} })
		{
			if ($self->{agent} =~ /$_/i)
			{
				$self->{is_robot} = 1; 
				$self->{robot} = $self->{robots}->{$_};
				
				return 1; 
			}
		}
	}	

	return 0;
}



#
# Set the Mobile Device
#
# @access	private
# @return	bool
#
sub _set_mobile
{
	my $self = shift; 
	
	if ('HASH' eq ref $self->{mobiles} && scalar (keys %{ $self->{mobiles} }) > 0)
	{
		for (keys %{ $self->{mobiles} })
		{
			if (index(lc($self->{agent}), $_) >= 0)
			{
				$self->{is_mobile} = 1; 
				$self->{mobiles} = $self->{mobiles}->{$_};
				
				return 1; 
			}
		}
	}	
	
	return 0;
}



#
# Set the accepted languages
#
# @access	private
# @return	void
#
sub _set_languages
{
	my $self = shift; 
	if (scalar @{ $self->{languages} } == 0 && $ENV{HTTP_ACCEPT_LANGUAGE})
	{
		my $str = lc $ENV{HTTP_ACCEPT_LANGUAGE};
		$str =~ s/^\s*|\s*$//g;
		$str =~ s/(;q=[0-9\.]+)//i;  
		
		@{ $self->{languages} } = split /,/, $str;
	}
	
	if (scalar @{ $self->{languages} } == 0)
	{
		push @{ $self->{languages} }, 'Undefined';
	}	
}



#
# Set the accepted character sets
#
# @access	private
# @return	void
#
sub _set_charsets
{
	my $self = shift; 
	
	if (scalar @{ $self->{charsets} } == 0 && $ENV{HTTP_ACCEPT_CHARSET})
	{
		my $str = lc $ENV{HTTP_ACCEPT_LANGUAGE};
		$str =~ s/^\s*|\s*$//g;
		$str =~ s/(;q=.+)//i;  
		@{ $self->{charsets} } = split /,/, $str;
	}
	
	if (scalar @{ $self->{charsets} } == 0)
	{
		push @{ $self->{charsets} }, 'Undefined';
	}	
	
}



# --------------------------------------------------------------------
#
# Is Browser
#
# @access	public
# @return	bool
#		
sub is_browser
{
	my $self = shift;
	return $self->{is_browser};
}



#
# Is Robot
#
# @access	public
# @return	bool
#
sub is_robot
{
	my $self = shift;
	return $self->{is_robot};
}



#
# Is Mobile
#
# @access	public
# @return	bool
#
sub is_mobile
{
	my $self = shift;
	return $self->{is_mobile};
}



#
# Is this a referral from another site?
#
# @access	public
# @return	bool
#
sub is_referral
{
	return $ENV{HTTP_REFERER} ne '' ? 1 : 0; 
}



# --------------------------------------------------------------------
#
# Agent String
#
# @access	public
# @return	string
#
sub agent_string
{
	my $self = shift;
	return $self->{agent};
}



#
# Get Platform
#
# @access	public
# @return	string
#
sub platform
{
	my $self = shift; 
	return $self->{platform};
}



#
# Get Browser Name
#
# @access	public
# @return	string
#
sub browser
{
	my $self = shift;
	return $self->{browser};
}



#
# Get the Browser Version
#
# @access	public
# @return	string
#
sub version
{
	my $self = shift;
	return $self->{version};
}



#
# Get The Robot Name
#
# @access	public
# @return	string
#
sub robot
{
	my $self = shift;
	return $self->{robot};
}



#
# Get the Mobile Device
#
# @access	public
# @return	string
#
sub mobile
{
	my $self = shift;
	return $self->{mobile};
}



#
# Get the referrer
#
# @access	public
# @return	bool
#
sub referrer
{
	my $string = $ENV{HTTP_REFERER};
	$string =~ s/^\s*|\s*$//g;
	return $string; 
}



#
# Get the accepted languages
#
# @access	public
# @return	array
#
sub languages
{
	my $self = shift;

	if (scalar @{ $self->{languages} } == 0)
	{
		$self->_set_languages();
	}

	return \$self->{languages};
}



#
# Get the accepted Character Sets
#
# @access	public
# @return	array
#
sub charsets
{
	my $self = shift; 
	
	if (scalar @{ $self->{charsets} } == 0)
	{
		$self->_set_charsets();
	}

	return \$self->{charsets};
}



#
# Test for a particular language
#
# @access	public
# @return	bool
#
sub accept_lang
{
	my $self = shift;
	my ($lang) = @_; 
	
	$lang ||= 'en';
	
	$lang = lc $lang;
	
	return grep /$lang/, @{ $self->languages() };
}



#
# Test for a particular character set
#
# @access	public
# @return	bool
#			
sub accept_charset
{
	my $self = shift; 
	my ($charset) = @_; 
	
	$charset ||= 'utf-8';
	$charset = lc $charset; 
	
	return grep /$charset/, @{ $self->charsets() };
}


1; 

__END__


=pod

=head1 NAME

user_agent - Identifies the platform, browser, robot, or mobile devise of the browsing agent

=head2 DESCRIPTION

 $self->load->library('user_agent');
 if ($self->agent->is_browser())
 {
     $agent = $self->agent->browser().' '.$self->agent->version();
 }
 elsif ($self->agent->is_robot())
 {
     $agent = $self->agent->robot();
 }
 elsif ($self->agent->is_mobile())
 {
     $agent = $self->agent->mobile();
 }
 else
 {
     $agent = 'Unidentified User Agent';
 }

 # print agent info
 $self->output->append_output($agent);

 # print platform info
 $self->output->append_output($self->agent->platform()); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
