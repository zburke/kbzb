package kbzb::libraries::input;

# -- $Id: input.pm 161 2009-07-28 20:49:55Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict; 
use Digest::MD5;

# never allowed, string replacement 
our $never_allowed_str = {
								'document.cookie'	=> '[removed]',
								'document.write'	=> '[removed]',
								'.parentNode'		=> '[removed]',
								'.innerHTML'		=> '[removed]',
								'window.location'	=> '[removed]',
								'-moz-binding'		=> '[removed]',
								'<!--'				=> '&lt;!--',
								'-->'				=> '--&gt;',
								'<![CDATA['			=> '&lt;![CDATA['
};


# never allowed, regex replacement 
my $never_allowed_regex = {
									"javascript\\s*:"			=> '[removed]',
									"expression\\s*(\(|&\#40;)"	=> '[removed]', # CSS and IE
									"vbscript\\s*:"				=> '[removed]', # IE, surprise!
									"Redirect\\s+302"			=> '[removed]'
};


#
# constructor
# Sets whether to globally enable the XSS processing and whether to allow the $_GET array
sub new
{
	my $class = shift; 
	my $self = {}; 
	
	bless($self, $class); 
	
	$self->{use_xss_clean}   = 0;
	$self->{xss_hash}   = '';
	$self->{ip_address} = undef;
	$self->{user_agent} = undef;
	$self->{allow_get_array} = undef;

	$self->{logger} = kbzb::libraries::common::load_class('logger');
	
	my $cfg = kbzb::libraries::common::load_class('config');
	$self->{use_xss_clean}   = $cfg->item('global_xss_filtering') || 0;
	$self->{allow_get_array} = $cfg->item('enable_query_strings') || 0;
	$self->_sanitize_globals();
	
	$self->{logger}->debug('Input Class Initialized'); 
	
	return $self; 
}




#
# Sanitize Globals
#
# This function does the following:
#
# Unsets $_GET data (if query strings are not enabled)
#
# Unsets all globals if register_globals is enabled
#
# Standardizes newline characters to \n
#
# @access	private
# @return	void
#
sub _sanitize_globals()
{
	my $self = shift; 

	# Is $_GET data allowed? If not we'll set the $_GET to an empty array
	my $_GET = $self->_clean_input_data({$kbzb::cgi->Vars()});

	# Clean $_POST Data
	my $_POST = $self->_clean_input_data({$kbzb::cgi->Vars()});

	# Clean $_COOKIE Data
	# Also get rid of specially treated cookies that might be set by a server
	# or silly application, that are of no use to a CI application anyway
	# but that when present will trip our 'Disallowed Key Characters' alarm
	# http://www.ietf.org/rfc/rfc2109.txt
	# note that the key names below are single quoted strings, and are not PHP variables
#@	unset($_COOKIE['$Version']);
#	unset($_COOKIE['$Path']);
#	unset($_COOKIE['$Domain']);
	my @cookies = $kbzb::cgi->cookie();
	for (@cookies)
	{
		my $_COOKIE = $self->_clean_input_data($kbzb::cgi->cookie($_));
	}

	$self->{logger}->debug('Global POST and COOKIE data sanitized');
}

# --------------------------------------------------------------------



#
# Clean Input Data
#
# This is a helper function. It escapes data and
# standardizes newline characters to \n
#
# @access	private
# @param	string
# @return	string
#
sub _clean_input_data
{
	my $self = shift; 
	my $str = shift; 
	
	if ('HASH' eq ref $str)
	{
		my %hash = ();
		
		for (keys %$str)
		{
			$hash{$self->_clean_input_keys($_)} = $self->_clean_input_data($str->{$_});
		}
		
		return \%hash;
	}
	

	# We strip slashes if magic quotes is on to keep things consistent
#@	if (get_magic_quotes_gpc())
#	{
#		$str = stripslashes($str);
#	}

	# Should we filter the input data?
	if ($self->{use_xss_clean})
	{
		$str = $self->xss_clean($str);
	}

	# Standardize newlines
	if ($str =~ /\r/)
	{
		$str =~ s/\r/\n/g; 
		$str =~ s/\r\n/\n/g; 
	}

	return $str;
}



#
# Clean Keys
#
# This is a helper function. To prevent malicious users
# from trying to exploit keys we make sure that keys are
# only named with alpha-numeric text and a few other items.
#
# @access	private
# @param	string
# @return	string
#
sub _clean_input_keys
{
	my $self = shift;
	my ($str) = @_;
	
	if ($str !~ /^[a-z0-9:_\/-]+$/i)
	{
		exit('Disallowed Key Characters.');
	}

	return $str;
}



#
# Fetch from array
#
# This is a helper function to retrieve values from global arrays
#
# @access	private
# @param	array
# @param	string
# @param	bool
# @return	string
#
sub _fetch_from_array
{
	my $self = shift; 
	my ($hash, $index, $xss_clean) = @_;
	
	if (! exists $hash->{$index})
	{
		return 0;
	}

	if ($xss_clean)
	{
		return $self->xss_clean($hash->{$index});
	}

	return $hash->{$index};
}



#
# Fetch an item from the GET array
#
# @access	public
# @param	string
# @param	bool
# @return	string
#
sub get
{
	my $self = shift; 
	my ($index, $xss_clean) = @_;
	
	return $self->_fetch_from_array($kbzb::cgi->Vars, $index, $xss_clean);
}



#
# Fetch an item from the POST array
#
# @access	public
# @param	string
# @param	bool
# @return	string
#
sub post
{
	my $self = shift; 
	my ($index, $xss_clean) = @_;
	
	return $self->_fetch_from_array($kbzb::cgi->Vars, $index, $xss_clean);
}



#
# Fetch an item from the COOKIE array
#
# @access	public
# @param	string
# @param	bool
# @return	string
#
sub cookie
{
	my $self = shift; 
	my ($index, $xss_clean) = @_;
	
	return $self->_fetch_from_array($kbzb::cgi->cookie(), $index, $xss_clean);
}



#
# Fetch an item from the SERVER array
#
# @access	public
# @param	string
# @param	bool
# @return	string
#
sub server
{
	my $self = shift; 
	my ($index, $xss_clean) = @_;
	
	return $self->_fetch_from_array(\%ENV, $index, $xss_clean);
}



#
# Fetch the IP Address
#
# @access	public
# @return	string
#
sub ip_address
{
	my $self = shift; 
	
	if ($self->{ip_address})
	{
		return $self->{ip_address};
	}
	
	if (kbzb::libraries::common::config_item('proxy_ips') && $self->server('HTTP_X_FORWARDED_FOR') && $self->server('REMOTE_ADDR'))
	{
		my @proxies = /[\s,]/, kbzb::libraries::common::config_item('proxy_ips');
		if (grep /$ENV{'REMOTE_ADDR'}/, @proxies)
		{
			$self->{ip_address} = $ENV{'HTTP_X_FORWARDED_FOR'};
		}
		else
		{
			$self->{ip_address} = $ENV{'REMOTE_ADDR'};
		}

	}
	elsif ($self->server('REMOTE_ADDR') && $self->server('HTTP_CLIENT_IP'))
	{
		$self->{ip_address} = $ENV{'HTTP_CLIENT_IP'};
	}
	elsif ($self->server('REMOTE_ADDR'))
	{
		$self->{ip_address} = $ENV{'REMOTE_ADDR'};
	}
	elsif ($self->server('HTTP_CLIENT_IP'))
	{
		$self->{ip_address} = $ENV{'HTTP_CLIENT_IP'};
	}
	elsif ($self->server('HTTP_X_FORWARDED_FOR'))
	{
		$self->{ip_address} = $ENV{'HTTP_X_FORWARDED_FOR'};
	}

	if (! defined $self->{ip_address})
	{
		$self->{ip_address} = '0.0.0.0';
		return $self->{ip_address};
	}

	if ($self->{ip_address} =~ /,/)
	{
		my @x = split /,/, $self->{ip_address};
		$self->{ip_address} = trim(pop(@x));
	}

	if ( ! $self->valid_ip($self->ip_address))
	{
		$self->{ip_address} = '0.0.0.0';
	}

	return $self->{ip_address};
}



#
# Validate IP Address
#
# Updated version suggested by Geert De Deckere
# 
# @access	public
# @param	string
# @return	string
#
sub valid_ip
{
	my $self = shift; 
	my $ip = shift; 
	
	my @ip_segments = split /\./, $ip;

	# Always 4 segments needed
	if (scalar @ip_segments != 4)
	{
		return 0;
	}
	
	# IP can not start with 0
	if ($ip_segments[0] =~ /^0/)
	{
		return 0;
	}
	
	# Check each segment
	for my $segment (@ip_segments)
	{
		# IP segments must be digits and can not be 
		# longer than 3 digits or greater then 255
		unless ($segment && $segment =~ /^[0-9]+$/ && $segment >= 0 && $segment <= 255)
		{
			return 0;
		}
	}

	return 1;
}



#
# User Agent
#
# @access	public
# @return	string
#
sub user_agent
{
	my $self = shift; 
	
	if ($self->{user_agent})
	{
		return $self->{user_agent};
	}

	($self->{user_agent} = $ENV{'HTTP_USER_AGENT'} || '') =~ s/^\s*|\s*$//g;

	return $self->{user_agent};
}



#
# Filename Security
#
# @access	public
# @param	string
# @return	string
#
sub filename_security
{
	my $self = shift; 
	my $str = shift; 
	
	my @bad = array(
					"../",
					"./",
					"<!--",
					"-->",
					"<",
					">",
					"'",
					'"',
					'&',
					'$',
					'#',
					'{',
					'}',
					'[',
					']',
					'=',
					';',
					'?',
					"%20",
					"%22",
					"%3c",		# <
					"%253c", 	# <
					"%3e", 		# >
					"%0e", 		# >
					"%28", 		# (  
					"%29", 		# ) 
					"%2528", 	# (
					"%26", 		# &
					"%24", 		# $
					"%3f", 		# ?
					"%3b", 		# ;
					"%3d"		# =
				);

#@	return stripslashes(str_replace($bad, '', $str));
	for (@bad)
	{
		$str =~ s/$_//g; 
	}
	
	return $str; 
}



#
# XSS Clean
#
# Sanitizes data so that Cross Site Scripting Hacks can be
# prevented.  This function does a fair amount of work but
# it is extremely thorough, designed to prevent even the
# most obscure XSS attempts.  Nothing is ever 100% foolproof,
# of course, but I haven't been able to get anything passed
# the filter.
#
# Note: This function should only be used to deal with data
# upon submission.  It's not something that should
# be used for general runtime processing.
#
# This function was based in part on some code and ideas I
# got from Bitflux: http://blog.bitflux.ch/wiki/XSS_Prevention
#
# To help develop this script I used this great list of
# vulnerabilities along with a few other hacks I've
# harvested from examining vulnerabilities in other programs:
# http://ha.ckers.org/xss.html
#
# @access	public
# @param	string
# @return	string
#
sub xss_clean
{
	my $self = shift; 
	
	my ($str, $is_image) = @_; 
	
=pod
	# Is the string an array?
	if ('ARRAY' eq ref $str)
	{
		for (@$str)
		{
			$_ = $self->xss_clean($_); 
		}

		return $str;
	}

	# Remove Invisible Characters
	$str = $self->_remove_invisible_characters($str);

	# Protect GET variables in URLs

	# 901119URL5918AMP18930PROTECT8198

#@	$str = preg_replace('|\&([a-z\_0-9]+)\=([a-z\_0-9]+)|i', $self->xss_hash()."\\1=\\2", $str);

	# Validate standard character entities
	#
	# Add a semicolon if missing.  We do this to enable
	# the conversion of entities to ASCII later.
	$str =~ s#(&\#?[0-9a-z]{2,})([\x00-\x20])*;?#$1;$2#i;

	# Validate UTF16 two byte encoding (x00) 
	# Just as above, adds a semicolon if missing.
	$str =~ s#(&\#x?)([0-9A-F]+);?#$1$2;#i;

	# Un-Protect GET variables in URLs
#@	$str = str_replace($self->xss_hash(), '&', $str);

	# URL Decode
	# Just in case stuff like this is submitted:
	# <a href="http://%77%77%77%2E%67%6F%6F%67%6C%65%2E%63%6F%6D">Google</a>
	# Note: Use rawurldecode() so it does not remove plus signs
#@	$str = rawurldecode($str);

	# Convert character entities to ASCII 
	# This permits our tests below to work reliably.
	# We only convert entities that are within tags since
	# these are the ones that will pose security problems.
#@	$str = preg_replace_callback("/[a-z]+=([\'\"]).*?\\1/si", array($this, '_convert_attribute'), $str);

#@	$str = preg_replace_callback("/<\w+.*?(?=>|<|$)/si", array($this, '_html_entity_decode_callback'), $str);

	# Remove Invisible Characters Again!
	$str = $self->_remove_invisible_characters($str);

	# Convert all tabs to spaces
	# This prevents strings like this: ja	vascript
	# NOTE: we deal with spaces between characters later.
	$str =~ s/\t/ /g;

	# Capture converted string for later comparison
	my $converted_string = $str;

	# Not Allowed Under Any Conditions
	for (keys %{ $self->{never_allowed_str} })
	{
		$str =~ s/$_/$self->{never_allowed_str}->{$_}/g; 
	}

	for (keys %{ $self->{never_allowed_regex} })
	{
		$str =~ s#$_#$self->{never_allowed_str}->{$_}#ig;
	}

	# Makes PHP tags safe
	#  Note: XML tags are inadvertently replaced too:
	#	<?xml
	# But it doesn't seem to pose a problem.
	if ($is_image)
	{
		# Images have a tendency to have the PHP short opening and closing tags every so often
		# so we skip those and only do the long opening tags.
		$str = str_replace(array('<?php', '<?PHP'),  array('&lt;?php', '&lt;?PHP'), $str);
	}
	else
	{
		$str = str_replace(array('<?php', '<?PHP', '<?', '?'.'>'),  array('&lt;?php', '&lt;?PHP', '&lt;?', '?&gt;'), $str);
	}

	# Compact any exploded words
	# This corrects words like:  j a v a s c r i p t
	# These words are compacted back to their correct state.
	my @words = ('javascript', 'expression', 'vbscript', 'script', 'applet', 'alert', 'document', 'write', 'cookie', 'window');
	for my $word (@words)
	{
		my $temp = '';

		for (my $i = 0, my $wordlen = length $word; $i < $wordlen; $i++)
		{
			$temp .= substr($word, $i, 1) . '\s*';
		}

		# We only want to do this when it is followed by a non-word character
		# That way valid stuff like "dealer to" does not become "dealerto"
#@		$str = preg_replace_callback('#('.substr($temp, 0, -3).')(\W)#is', array($this, '_compact_exploded_words'), $str);
	}

	# Remove disallowed Javascript in links or img tags
	# We used to do some version comparisons and use of stripos for PHP5, but it is dog slow compared
	# to these simplified non-capturing preg_match(), especially if the pattern exists in the string
	my $original = $str;
	do
	{
		if (preg_match("/<a/i", $str))
		{
#@			$str = preg_replace_callback("#<a\s+([^>]*?)(>|$)#si", array($this, '_js_link_removal'), $str);
		}

		if (preg_match("/<img/i", $str))
		{
#@			$str = preg_replace_callback("#<img\s+([^>]*?)(\s?/?>|$)#si", array($this, '_js_img_removal'), $str);
		}

		if ($str =~ /script/i || $str =~ /xss/i)
		{
			$str = s#<(/*)(script|xss)(.*?)\>#[removed]#gsi;
		}
	}
	while($original ne $str);

	undef $original;

	# Remove JavaScript Event Handlers
	# Note: This code is a little blunt.  It removes
	# the event handler and anything up to the closing >,
	# but it's unlikely to be a problem.
	my @event_handlers = ('[^a-z_\-]on\w*','xmlns');

	if ($is_image)
	{
		# Adobe Photoshop puts XML metadata into JFIF images, including namespacing, 
		# so we have to allow this for images. -Paul
		unset($event_handlers[array_search('xmlns', $event_handlers)]);
	}

	$str = preg_replace("#<([^><]+?)(".implode('|', $event_handlers).")(\s*=\s*[^><]*)([><]*)#i", "<\\1\\4", $str);

	# Sanitize naughty HTML elements
	# If a tag containing any of the words in the list
	# below is found, the tag gets converted to entities.
	# So this: <blink>
	# Becomes: &lt;blink&gt;
	$naughty = 'alert|applet|audio|basefont|base|behavior|bgsound|blink|body|embed|expression|form|frameset|frame|head|html|ilayer|iframe|input|isindex|layer|link|meta|object|plaintext|style|script|textarea|title|video|xml|xss';
	$str = preg_replace_callback('#<(/*\s*)('.$naughty.')([^><]*)([><]*)#is', array($this, '_sanitize_naughty_html'), $str);

	# Sanitize naughty scripting elements
	# Similar to above, only instead of looking for
	# tags it looks for PHP and JavaScript commands
	# that are disallowed.  Rather than removing the
	# code, it simply converts the parenthesis to entities
	# rendering the code un-executable.
	# For example:	eval('some code')
	# Becomes:		eval&#40;'some code'&#41;
#	$str =~ #(alert|cmd|passthru|eval|exec|expression|system|fopen|fsockopen|file|file_get_contents|readfile|unlink)(\s*)\((.*?)\)#$1$2&\#40;$3&\#41;#si;

	# Final clean up
	# This adds a bit of extra precaution in case
	# something got through the above filters
#	for (keys %{ $self->{never_allowed_str} })
#	{
#		$str =~ s/$_/$self->{never_allowed_str}->{$_}/g;   
#	}

#	for (keys %{ $self->{never_allowed_regex} } )
#	{
#		$str =~ s/$_/$self->{never_allowed_regex}->{$_}/ig;
#	}

	#  Images are Handled in a Special Way
	#  - Essentially, we want to know that after all of the character conversion is done whether
	#  any unwanted, likely XSS, code was found.  If not, we return TRUE, as the image is clean.
	#  However, if the string post-conversion does not matched the string post-removal of XSS,
	#  then it fails, as there was unwanted XSS code found and removed/changed during processing.

	if ($is_image)
	{
		if ($str == $converted_string)
		{
			return 1;
		}
		else
		{
			return undef;
		}
	}

=cut

	$self->{logger}->debug('XSS Filtering completed');

	return $str;
}



#
# Random Hash for protecting URLs
#
# @access	public
# @return	string
#
sub xss_hash
{
	my $self = shift; 
	
	if ($self->{xss_hash} eq '')
	{
		$self->{xss_hash} = md5(time() + rand(1999999999));
	}

	return $self->{xss_hash};
}



#
# Remove Invisible Characters
#
# This prevents sandwiching null characters
# between ascii characters, like Java\0script.
#
# @access	public
# @param	string
# @return	string
#
sub _remove_invisible_characters
{
	my $self = shift; 
	my $str = shift; 

	my $cleaned = $str;
	do
	{
		# every control character except newline (dec 10), 
		# carriage return (dec 13), and horizontal tab (dec 09),
		$str =~ s/%0[0-8bcef]//go;  # url encoded 00-08, 11, 12, 14, 15
		$str =~ s/%1[0-9a-f]//go;   # url encoded 16-31
		$str =~ s/[\x00-\x08]//go;  # 00-08
		$str =~ s/\x0b//go;        # 11
		$str =~ s/\x0c//go;        # 12
		$str =~ s/[\x0e-\x1f]//go;  # 14-31

	}
	while ($cleaned != $str);

	return $str;
}



#
# Compact Exploded Words
#
# Callback function for xss_clean() to remove whitespace from
# things like j a v a s c r i p t
#
# @access	public
# @param	type
# @return	type
#
#sub _compact_exploded_words($matches)
#{
#	return preg_replace('/\s+/s', '', $matches[1]).$matches[2];
#}



#
# Sanitize Naughty HTML
#
# Callback function for xss_clean() to remove naughty HTML elements
#
# @access	private
# @param	array
# @return	string
#
#sub _sanitize_naughty_html($matches)
#{
#	# encode opening brace
#	$str = '&lt;'.$matches[1].$matches[2].$matches[3];
#
#	# encode captured opening or closing brace to prevent recursive vectors
#	$str .= str_replace(array('>', '<'), array('&gt;', '&lt;'), $matches[4]);
#
#	return $str;
#}



#
# JS Link Removal
#
# Callback function for xss_clean() to sanitize links
# This limits the PCRE backtracks, making it more performance friendly
# and prevents PREG_BACKTRACK_LIMIT_ERROR from being triggered in
# PHP 5.2+ on link-heavy strings
#
# @access	private
# @param	array
# @return	string
#
sub _js_link_removal
{
	my $self = shift; 
	my ($match) = @_; 
	
#	my $attributes = $self->_filter_attributes(str_replace(array('<', '>'), '', $match[1]));
#	return str_replace($match[1], preg_replace("#href=.*?(alert\(|alert&\#40;|javascript\:|charset\=|window\.|document\.|\.cookie|<script|<xss|base64\s*,)#si", "", $attributes), $match[0]);
}



#
# JS Image Removal
#
# Callback function for xss_clean() to sanitize image tags
# This limits the PCRE backtracks, making it more performance friendly
# and prevents PREG_BACKTRACK_LIMIT_ERROR from being triggered in
# PHP 5.2+ on image tag heavy strings
#
# @access	private
# @param	array
# @return	string
#
sub _js_img_removal
{
	my $self = shift; 
	my ($match) = @_; 
#	$attributes = $self->_filter_attributes(str_replace(array('<', '>'), '', $match[1]));
#	return str_replace($match[1], preg_replace("#src=.*?(alert\(|alert&\#40;|javascript\:|charset\=|window\.|document\.|\.cookie|<script|<xss|base64\s*,)#si", "", $attributes), $match[0]);
}



#
# Attribute Conversion
#
# Used as a callback for XSS Clean
#
sub _convert_attribute
{
	my $self = shift; 
	my ($match) = @_; 
#	return str_replace(array('>', '<', '\\'), array('&gt;', '&lt;', '\\\\'), $match[0]);
}

# --------------------------------------------------------------------



=pod
/**
* HTML Entity Decode Callback
*
* Used as a callback for XSS Clean
*
* @access	public
* @param	array
* @return	string
*/
=cut
sub _html_entity_decode_callback
{
	my $self = shift; 
	my ($match) = @_; 
	
	my $cfg = kbzb::libraries::common::load_class('Config');
	my $charset = $cfg->item('charset');

	return $self->_html_entity_decode($$match[0], uc($charset));
}



#/**
#* HTML Entities Decode
#*
#* This function is a replacement for html_entity_decode()
#*
#* In some versions of PHP the native function does not work
#* when UTF-8 is the specified character set, so this gives us
#* a work-around.  More info here:
#* http://bugs.php.net/bug.php?id=25670
#*
#* @access	private
#* @param	string
#* @param	string
#* @return	string
#*/
#
#/* -------------------------------------------------
#/*  Replacement for html_entity_decode()
#/* -------------------------------------------------*/
#
#/*
#NOTE: html_entity_decode() has a bug in some PHP versions when UTF-8 is the
#character set, and the PHP developers said they were not back porting the
#fix to versions other than PHP 5.x.
#*/
#=cut
#
#sub _html_entity_decode($str, $charset='UTF-8')
#{
#	if (stristr($str, '&') === FALSE) return $str;
#
#	# The reason we are not using html_entity_decode() by itself is because
#	# while it is not technically correct to leave out the semicolon
#	# at the end of an entity most browsers will still interpret the entity
#	# correctly.  html_entity_decode() does not convert entities without
#	# semicolons, so we are left with our own little solution here. Bummer.
#
#	if (function_exists('html_entity_decode') && (strtolower($charset) != 'utf-8' OR version_compare(phpversion(), '5.0.0', '>=')))
#	{
#		$str = html_entity_decode($str, ENT_COMPAT, $charset);
#		$str = preg_replace('~&#x(0*[0-9a-f]{2,5})~ei', 'chr(hexdec("\\1"))', $str);
#		return preg_replace('~&#([0-9]{2,4})~e', 'chr(\\1)', $str);
#	}
#
#	# Numeric Entities
#	$str = preg_replace('~&#x(0*[0-9a-f]{2,5});{0,1}~ei', 'chr(hexdec("\\1"))', $str);
#	$str = preg_replace('~&#([0-9]{2,4});{0,1}~e', 'chr(\\1)', $str);
#
#	# Literal Entities - Slightly slow so we do another check
#	if (stristr($str, '&') === FALSE)
#	{
#		$str = strtr($str, array_flip(get_html_translation_table(HTML_ENTITIES)));
#	}
#
#	return $str;
#}



#
# Filter Attributes
#
# Filters tag attributes for consistency and safety
sub _filter_attributes
{
	my $self = shift; 
	my ($str) = @_; 
	
	my $out = $str;

	while ($str =~ /\s*[a-z\-]+\s*=\s*(\042|\047)([^\\1]*?)\\1/is)
	{
		$out =~ s/\/\*.*?\*\///s;
	}

	return $out;
}


1; 

__END__



=pod

=head1 NAME

input - Pre-processes global input data for security

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->input so there is no need to 
re-instantiate it yourself. 

Rather than accessing form, URL, environment and cookie variables through
different mechanisms, use the input class to provide a consistent interface
and consistent security. Post and cookie keys are filtered to be alpha-
numeric, and values may optionally be pulled through a Cross Site Scripting
(XSS) filter. 

To filter all values for XSS hacks, edit the config.properties file to 
include a true value for the key global_xss_filtering. If global XSS 
filtering is not enabled, you can filter on request by sending a true
value as an optional second parameter to the cookie, get, post and server
methods described below. 

 # retrieve data from a cookie. returns undef if a value for the 
 # key does not exist. a true value in the optional second parameter runs 
 # the data through the XSS filter. 
 $value = $self->input->cookie('key', $boolean);
 
 # retrieve data from a GET parameter. returns undef if a value for the 
 # key does not exist. a true value in the optional second parameter runs 
 # the data through the XSS filter. 
 $value = $self->input->get('key', $boolean);
 
 # get the remote user's IP address, or 0.0.0.0 if no address is available
 $value = $self->input->ip_address();
 
 # retrieve data from a POST parameter. returns undef if a value for the 
 # key does not exist. a true value in the optional second parameter runs 
 # the data through the XSS filter. 
 $value = $self->input->post('key', $boolean);

 # retrieve data from the environment. returns undef if a value for the 
 # key does not exist. a true value in the optional second parameter runs 
 # the data through the XSS filter. 
 $value = $self->input->server();
 
 # retrieve the User Agent string from the environment.
 $value = $self->input->user_agent();
 
 # validate an IP address; returns true if the given IP is valid;
 # false otherwise.
 $boolean = $self->input->valid_ip($ip);
 
 # NOT YET IMPLEMENTED
 $value = $self->input->xss_clean();
 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
