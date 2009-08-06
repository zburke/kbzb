package kbzb::libraries::session;

# -- $Id: session.pm 161 2009-07-28 20:49:55Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);


#
# Session Constructor
#
# The constructor runs the session routines automatically
# whenever the class is instantiated.
#
sub new
{
	my $class = shift; 
	my $input = shift; 
	
	my $self = {}; 
	
	bless($self, $class); 
	
	$self->{sess_encrypt_cookie}	= 0;
	$self->{sess_use_database}		= 0;
	$self->{sess_table_name}		= '';
	$self->{sess_expiration}		= 7200;
	$self->{sess_match_ip}			= 0;
	$self->{sess_match_useragent}	= 1;
	$self->{sess_cookie_name}		= 'kz_session';
	$self->{cookie_prefix}			= '';
	$self->{cookie_path}			= '';
	$self->{cookie_domain}			= '';
	$self->{sess_time_to_update}	= 300;
	$self->{encryption_key}			= 'this is just a random string to mix up the hash for non-encrypted cookies';
	$self->{flashdata_key} 			= 'flash';
	$self->{time_reference}			= 'time';
	$self->{gc_probability}			= 5;
	$self->{session_data}			= {};
	$self->{kz}                     = kbzb::get_instance();
	$self->{now}                    = undef;
	$self->{checksum_key}           = '[kzmd5]';
	
	
	kbzb::libraries::common::load_class('logger', undef, $self); 
	$self->logger->debug('Session Class Initialized');
	
	# Set all the session preferences, which can either be set
	# manually via the $params array above or via the config file
	for (('sess_encrypt_cookie', 'sess_use_database', 'sess_table_name', 'sess_expiration', 'sess_match_ip', 'sess_match_useragent', 'sess_cookie_name', 'cookie_path', 'cookie_domain', 'sess_time_to_update', 'time_reference', 'cookie_prefix', 'encryption_key'))
	{
		$self->{$_} = $input->{$_} || $self->{kz}->config->item($_); 
	}
	
	# Load the string helper so we can use the strip_slashes() function
	$self->{kz}->load->helper('string');

	# Do we need encryption? If so, load the encryption class
	if ($self->{sess_encrypt_cookie})
	{
		my $key =  $self->{kz}->config->item('encryption_key'); 
		$self->{kz}->load->library('encrypt', {key => $key, rounds => 12});
	}


	# Are we using a database?  If so, load it
	if ($self->{sess_use_database} && $self->{sess_table_name})
	{
		$self->{kz}->load->database();
	}
	
	
	# Set the "now" time.  Can either be GMT or server time, based on the
	# config prefs.  We use this to set the "last activity" time
	$self->{now} = $self->_get_time();

	# Set the session length. If the session expiration is
	# set to zero we'll set the expiration two years from now.
	if ($self->{sess_expiration} == 0)
	{
		$self->{sess_expiration} = (60 * 60 * 24 * 365 * 2);
	}
	 
	# Set the cookie name
	$self->{sess_cookie_name} = $self->{cookie_prefix} . $self->{sess_cookie_name};

	# Run the Session routine. If a session doesn't exist we'll
	# create a new one.  If it does, we'll update it.
	if ( ! $self->sess_read())
	{
		$self->sess_create();
	}
	else
	{
		$self->sess_update();
	}

	# Delete 'old' flashdata (from last request)
	$self->_flashdata_sweep();

	# Mark all new flashdata as old (data will be deleted before next request)
	$self->_flashdata_mark();

	# Delete expired sessions if necessary
	$self->_sess_gc();

	$self->logger->debug('Session routines successfully run');

	return $self; 

}



#
# Fetch the current session data if it exists
#
# @access	public
# @return	bool
#
sub sess_read
{
	my $self = shift; 
	
	# Fetch the cookie
	my $session = {$kbzb::cgi->cookie($self->{sess_cookie_name})};
	
	# No cookie?  Goodbye cruel world!...
	if (! $session)
	{
		$self->logger->debug('A session cookie was not found.');
		return undef;
	}
	
	$self->logger->debug('Found a session...');

	# Decrypt the cookie data
	if ($self->{sess_encrypt_cookie})
	{
		my $decrypted = {};
		while (my ($k, $v) = each(%$session))
		{
			$decrypted->{$self->{kz}->encrypt->decode($k)} = $self->{kz}->encrypt->decode($v);
		}
		
		$session = $decrypted; 
	}
	# encryption was not used, so we need to check the checksum
	else
	{
		my $string; 

		# keys MUST be sorted in order to compute a consistent checksum
		for (sort keys %$session)
		{
			next if $_ eq $self->{checksum_key};
			$string .= "$_:$session->{$_}";
		}

		# add salt to prevent the hacker from simply recomputing the checksum.
		# since $self->{encryption_key} is only known on the server-side, 
		# it's highly unlikely the hacker could regenerate a valid checksum.
		$string .= $self->{encryption_key};
		
		# Does the md5 hash match?  This is to prevent manipulation of session data in userspace
		if (Digest::MD5::md5_hex($string) eq $session->{$self->{checksum_key}})
		{
			delete $session->{$self->{checksum_key}}; 
		}
		else
		{
			$self->logger->error('The session cookie data did not match what was expected. This could be a possible hacking attempt.');
			$self->sess_destroy();
			return undef;
		}
	}

	# Is the session data an array with the correct format?
	unless ('HASH' eq ref $session && $session->{session_id} && $session->{ip_address} && $session->{user_agent} && $session->{last_activity})
	{
		$self->sess_destroy();
		return undef;
	}

	# Is the session current?
	if (($session->{last_activity} + $self->{sess_expiration}) < $self->{now})
	{
		$self->sess_destroy();
		return undef;
	}

	# Does the IP Match?
	if ($self->{sess_match_ip} && $session->{ip_address} != $self->{kz}->input->ip_address())
	{
		$self->sess_destroy();
		return undef;
	}

	# Does the User Agent Match?
	if ($self->{sess_match_useragent} && $session->{user_agent} ne $self->{kz}->input->user_agent())
	{
		$self->sess_destroy();
		return undef;
	}

	# Is there a corresponding session in the DB?
	if ($self->{sess_use_database})
	{
		$self->{kz}->db->where('session_id', $session->{session_id});

		if ($self->{sess_match_ip})
		{
			$self->{kz}->db->where('ip_address', $session->{ip_address});
		}

		if ($self->{sess_match_useragent})
		{
			$self->{kz}->db->where('user_agent', $session->{user_agent});
		}

		my $query = $self->{kz}->db->get($self->{sess_table_name});

		# No result?  Kill it!
		if ($query->num_rows() == 0)
		{
			$self->sess_destroy();
			return undef;
		}

		# Is there custom data?  If so, add it to the main session array
		my $row = $query->row();
		if ($row->{user_data} ne '')
		{
			my $custom_data = $row->{user_data};

			if ('HASH' eq ref $custom_data)
			{
				for (keys %$custom_data)
				{
					$session->{$_} = $custom_data->{$_};
				}
			}
		}
	}

	# Session is valid!
	$self->{session_data} = $session;
	
	$self->logger->debug('Session is valid!');
	

	return 1;
}



#
# Write the session data
#
# @access	public
# @return	void
#
sub sess_write
{
	my $self = shift; 
	
	# Are we saving custom data to the DB?  If not, all we do is update the cookie
	if (! $self->{sess_use_database})
	{
		$self->_set_cookie();
		return;
	}

	# set the custom userdata, the session data we will set in a second
	my $custom_userdata = $self->{session_data};
	my $cookie_userdata = {};

	# Before continuing, we need to determine if there is any custom data to deal with.
	# Let's determine this by removing the default indexes to see if there's anything left in the array
	# and set the session data while we're at it
	for (('session_id','ip_address','user_agent','last_activity'))
	{
		undef $custom_userdata->{$_};
		$cookie_userdata->{$_} = $self->{session_data}->{$_};
	}

	# Did we find any custom data?  If not, we turn the empty array into a string
	# since there's no reason to serialize and store an empty array in the DB
	if (scalar keys %$custom_userdata == 0)
	{
		$custom_userdata = '';
	}

	# Run the update query
	$self->{kz}->db->where('session_id', $self->{session_data}->{session_id});
	$self->{kz}->db->update($self->{sess_table_name}, {'last_activity' => $self->{session_data}->{last_activity}, 'user_data' => $custom_userdata});

	# Write the cookie.  Notice that we manually pass the cookie data array to the
	# _set_cookie() function. Normally that function will store $self->userdata, but
	# in this case that array contains custom data, which we do not want in the cookie.
	$self->_set_cookie($cookie_userdata);
}



#
# Create a new session
#
# @access	public
# @return	void
#
sub sess_create
{
	my $self = shift; 
	
	my $sessid = '';
	while (length $sessid < 32)
	{
		$sessid .= substr(rand, 2); 
	}

	# To make the session ID even more secure we'll combine it with the user's IP
	$sessid .= $self->{kz}->input->ip_address();

	$self->{session_data} = {
						'session_id' 	=> $sessid,
						'ip_address' 	=> $self->{kz}->input->ip_address(),
						'user_agent' 	=> $self->{kz}->input->user_agent(),
						'last_activity'	=> $self->{now}
						};


	# Save the data to the DB if needed
	if ($self->{sess_use_database})
	{
		$self->{kz}->db->query($self->{kz}->db->insert_string($self->{sess_table_name}, $self->{session_data}));
	}

	# Write the cookie
	$self->_set_cookie();
}



# --------------------------------------------------------------------
#
# Update an existing session
#
# @access	public
# @return	void
#
sub sess_update
{
	my $self = shift; 
	
	# We only update the session every five minutes by default
	if (($self->{session_data}->{last_activity} + $self->{sess_time_to_update}) >= $self->{now})
	{
		return;
	}

	# Save the old session id so we know which record to
	# update in the database if we need it
	my $old_sessid = $self->{session_data}->{session_id};
	my $new_sessid = '';
	while (length $new_sessid < 32)
	{
		$new_sessid .= substr(rand, 2); 
	}

	# To make the session ID even more secure we'll combine it with the user's IP
	$new_sessid .= $self->{kz}->input->ip_address();

	# Update the session data in the session data array
	$self->{session_data}->{session_id} = $new_sessid;
	$self->{session_data}->{last_activity} = $self->{now};

	# _set_cookie() will handle this for us if we aren't using database sessions
	# by pushing all userdata to the cookie.
	my $cookie_data = {};

	# Update the session ID and last_activity field in the DB if needed
	if ($self->{sess_use_database})
	{
		# set cookie explicitly to only have our session data
		foreach (('session_id','ip_address','user_agent','last_activity'))
		{
			$cookie_data->{$_} = $self->{session_data}->{$_};
		}

		$self->{kz}->db->query($self->{kz}->db->update_string($self->{sess_table_name}, {'last_activity' => $self->{now}, 'session_id' => $new_sessid}, {'session_id' => $old_sessid}));
	}

	# Write the cookie
	$self->_set_cookie($cookie_data);
}



#
# Destroy the current session
#
# @access	public
# @return	void
#
sub sess_destroy()
{
	my $self = shift; 
	# Kill the session DB row
	if ($self->{sess_use_database} && $self->{session_data}->{session_id})
	{
		$self->{kz}->db->where('session_id', $self->{session_data}->{session_id});
		$self->{kz}->db->delete($self->{sess_table_name});
	}
	

	# Kill the cookie
	$self->{kz}->output->set_cookie(
				$self->{sess_cookie_name},
				'',
				($self->{now} - 31500000),
				$self->{cookie_path},
				$self->{cookie_domain},
				0
			);
}



#
# Fetch a specific item from the session array
#
# @access	public
# @param	string
# @return	string
#
sub userdata
{
	my $self = shift;
	my ($item) = @_; 
	
	return exists $self->{session_data}->{$item} ? $self->{session_data}->{$item} : undef;
}



#
# Fetch all session data
#
# @access	public
# @return	mixed
#
sub all_userdata
{
	my $self = shift; 
	return exists $self->{session_data} ? $self->{session_data} : undef;
}




#
# Add or change data in the "userdata" array
#
# @access	public
# @param	mixed
# @param	string
# @return	void
#
sub set_userdata
{
	my $self = shift; 
	my ($newdata, $newval) = @_; 
	
	if (! ref $newdata)
	{
		$newdata = {$newdata => $newval};
	}

	if (scalar keys %$newdata)
	{
		for (keys %$newdata)
		{
			$self->{session_data}->{$_} = $newdata->{$_};
		}
	}

	$self->sess_write();
}



#
# Delete a session variable from the "userdata" array
#
# @access	array
# @return	void
#
sub unset_userdata
{
	my $self = shift; 
	my ($newdata) = @_;
	 
	if (! ref $newdata)
	{
		$newdata = {$newdata => ''};
	}

	if (scalar keys %$newdata)
	{
		for (keys %$newdata)
		{
			delete $self->{session_data}->{$_};
		}
	}

	$self->sess_write();
}



#
# Add or change flashdata, only available
# until the next request
#
# @access	public
# @param	mixed
# @param	string
# @return	void
#
sub set_flashdata
{
	my $self = shift; 
	my ($newdata, $newval) = @_;
	
	if (! ref $newdata)
	{
		$newdata = {$newdata => $newval};
	}

	if (scalar keys %$newdata)
	{
		for (keys %$newdata)
		{
			my $flashdata_key = $self->{flashdata_key} . ':new:' . $_;
			$self->set_userdata($flashdata_key, $newdata->{$_});
		}
	}
}



#
# Keeps existing flashdata available to next request.
#
# @access	public
# @param	string
# @return	void
#
sub keep_flashdata
{
	my $self = shift; 
	my ($key) = @_; 
	
	# 'old' flashdata gets removed.  Here we mark all
	# flashdata as 'new' to preserve it from _flashdata_sweep()
	# Note the function will return FALSE if the $key
	# provided cannot be found
	my $old_flashdata_key = $self->{flashdata_key} . ':old:' . $key;
	my $value = $self->userdata($old_flashdata_key);

	my $new_flashdata_key = $self->{flashdata_key} . ':new:' . $key;
	$self->set_userdata($new_flashdata_key, $value);
}



#
# Fetch a specific flashdata item from the session array
#
# @access	public
# @param	string
# @return	string
#
sub flashdata
{
	my $self = shift; 
	my ($key) = @_; 
	
	my $flashdata_key = $self->{flashdata_key} . ':old:' . $key;
	return $self->userdata($flashdata_key);
}



#
# Identifies flashdata as 'old' for removal
# when _flashdata_sweep() runs.
#
# @access	private
# @return	void
#
sub _flashdata_mark
{
	my $self = shift; 
	
	my $userdata = $self->all_userdata();
	for my $name (keys %$userdata)
	{
		my @parts = split /:new:/, $name;
		if ($#parts == 1)
		{
			my $new_name = $self->{flashdata_key}.':old:'.$parts[1];
			$self->set_userdata($new_name, $userdata->{$name});
			$self->unset_userdata($name);
		}
	}
}



#
# Removes all flashdata marked as 'old'
#
# @access	private
# @return	void
#
sub _flashdata_sweep
{
	my $self = shift; 
	
	for (keys %{ $self->all_userdata() })
	{
		if (index($_, ':old:') >= 0)
		{
			$self->unset_userdata($_);
		}
	}

}



#
# Get the "now" time
#
# @access	private
# @return	string
#
sub _get_time
{
	my $self = shift; 
	
	my $time = undef; 
#@	if (lc ($self->{time_reference}) == 'gmt')
#	{
#		$now = time();
#		$time = mktime(gmdate("H", $now), gmdate("i", $now), gmdate("s", $now), gmdate("m", $now), gmdate("d", $now), gmdate("Y", $now));
#	}
#	else
#	{
		$time = time();
#	}

	return $time;
}



#
# Write the session cookie
#
# @access	public
# @return	void
#
sub _set_cookie
{
	my $self = shift; 
	my ($cookie_data) = @_; 

	if (! scalar keys %$cookie_data)
	{
		$cookie_data = $self->{session_data};
	}


	if ($self->{sess_encrypt_cookie})
	{
		my $encrypted = {};
		while (my ($k, $v) = each(%$cookie_data))
		{
			$encrypted->{$self->{kz}->encrypt->encode($k)} = $self->{kz}->encrypt->encode($v);
		}
		
		$cookie_data = $encrypted; 
	}
	# if encryption is not used, we provide an md5 hash to prevent userside tampering
	else
	{
		# keys MUST be sorted in order to compute a consistent checksum
		my $string = ""; 
		for (sort keys %$cookie_data)
		{
			next if $_ eq $self->{checksum_key};
			$string .= "$_:$cookie_data->{$_}";
		}
		
		# add salt to prevent the hacker from simply recomputing the checksum.
		# since $self->{encryption_key} is only known on the server-side, 
		# it's highly unlikely the hacker could regenerate a valid checksum.
		$string .= $self->{encryption_key};

		$cookie_data->{$self->{checksum_key}} = Digest::MD5::md5_hex($string); 
	}


	# Set the cookie
	$self->{kz}->output->set_cookie(
				$self->{sess_cookie_name},
				$cookie_data,
				$self->{sess_expiration} + time(),
				$self->{cookie_path},
				$self->{cookie_domain},
				0
			);
}



#
# Garbage collection
#
# This deletes expired session rows from database
# if the probability percentage is met
#
# @access	public
# @return	void
#
sub _sess_gc
{
	my $self = shift; 
	if (! $self->{sess_use_database})
	{
		return;
	}

	if ((rand() % 100) < $self->{gc_probability})
	{
		my $expire = $self->{now} - $self->{sess_expiration};

		$self->{kz}->db->where("last_activity < {$expire}");
		$self->{kz}->db->delete($self->{sess_table_name});

		$self->logger->debug('Session garbage collection performed.');
	}
}

1; 

__END__


=pod

=head1 NAME

session - maintain state for a user by tracking a session cookie

=head1 DESCRIPTION

The Session class permits you maintain a user's "state" and track 
their activity while they browse your site. The Session class stores 
session information for each user as serialized (and optionally 
encrypted) data in a cookie. It can also store the session data in a 
database table for added security, as this permits the session ID in 
the user's cookie to be matched against the stored session ID. By 
default only the cookie is saved. If you choose to use the database 
option you'll need to create the session table as indicated below. 

To encrypt the data stored in the cookie, you must set the following
parameters in the config.properties file in your app's config directory:

 encryption_key = $hex_value 
 sess_encrypt_cookie = $true_value

The session class supports "flash data", key-value pairs that are 
retained in the session for a single server-request cycle only; after
that they are discarded. Flash data values can be useful for providing
informational or status messages such as "item 135-246 updated". 

=head1 SYNOPSIS

 # load and initialize the session
 $self->load->library('session');

 # add a key-value pair to the session
 $self->session->set_userdata('key', 'value');
 
 # retrieve a value from the session
 $value = $self->session->userdata('key');
 
 # remove a key-value pair from the session
 $self->session->unset_userdata('key');

 # set a key-value pair that will be retained through only ONE
 # server request cycle. after the next request, it will be 
 # erased. 
 $self->session->set_flashdata('key', 'value');
 
 # retrieve a flash-data value
 $value = $self->session->flashdata('key'); 
 
 # retain a flash-data pair for one more server request cycle.
 $self->session->keep_flashdata('key');

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

