package kbzb::helpers::date;

# -- $Id: date.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;
use POSIX (); 

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
now
mdate
standard_date
timespan
days_in_month
local_to_gmt
gmt_to_local
mysql_to_unix
unix_to_human
human_to_unix
timezone_menu
timezones
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


# ------------------------------------------------------------------------
#  Date Helpers
#


# ------------------------------------------------------------------------
# Get "now" time
#
# Returns time() or its GMT equivalent based on the config file preference
#
# @access	public
# @return	integer
sub now
{
	my $kz = kbzb::get_instance();

	if (lc ($kz->config->item('time_reference')) eq 'gmt')
	{
		return gmtime(); 
	}
	else
	{
		return time();
	}
}



# ------------------------------------------------------------------------
# Standard Date
#
# Returns a date formatted according to the submitted standard.
#
# @access	public
# @param	string	the chosen format
# @param	integer	Unix timestamp
# @return	string
#
sub standard_date
{
	my ($fmt, $time) = @_; 
	
	$time ||= now(); 
	$fmt ||= 'RFC822';
	
	my %formats = (
 					ATOM	=>	'%Y-%m-%dT%T%z',
					COOKIE	=>	'%a, %d %b %Y %T UTC',
					ISO8601	=>	'%FT%T%z',
					RFC822	=>	'%a, %d %b %y %H:%M %Z',
					RFC850	=>	'%A %d-%b-%y %T UTC',
					RFC1036	=>	'%a, %d %b %y %T %z',
					RFC1123	=>	'%a, %d %B %Y %T %z',
					RSS		=>	'%a, %d %B %Y %T %z',
					W3C		=>	'%FT%T%z',
					);

	if ( ! $formats{uc $fmt})
	{
		return undef;
	}

	return POSIX::strftime($formats{$fmt}, localtime($time));
}



# ------------------------------------------------------------------------
# Timespan
#
# Returns a span of seconds in this format:
#	10 days 14 hours 36 minutes 47 seconds
#
# @access	public
# @param	integer	a number of seconds
# @param	integer	Unix timestamp
# @return	integer
#
sub timespan
{
	my ($seconds, $time) = @_; 
	
	$seconds ||= 1; 
	
	my $kz = kbzb::get_instance();
	$kz->lang->load('date');

	if ($seconds !~ /[0-9]+/)
	{
		$seconds = 1;
	}

	if ($time !~ /[0-9]+/)
	{
		$time = time();
	}

	if ($time <= $seconds)
	{
		$seconds = 1;
	}
	else
	{
		$seconds = $time - $seconds;
	}
	
	my $str = '';

	my $years = POSIX::floor($seconds / 31536000);
	if ($years > 0)
	{	
		$str .= $years.' '.$kz->lang->line((($years	> 1) ? 'date_years' : 'date_year')).', ';
	}	
	$seconds -= $years * 31536000;

	my $months = POSIX::floor($seconds / 2628000);
	if ($years > 0 || $months > 0)
	{
		if ($months > 0)
		{	
			$str .= $months.' '.$kz->lang->line((($months	> 1) ? 'date_months' : 'date_month')).', ';
		}	

		$seconds -= $months * 2628000;
	}

	my $weeks = POSIX::floor($seconds / 604800);

	if ($years > 0 || $months > 0 || $weeks > 0)
	{
		if ($weeks > 0)
		{	
			$str .= $weeks.' '.$kz->lang->line((($weeks	> 1) ? 'date_weeks' : 'date_week')).', ';
		}
	
		$seconds -= $weeks * 604800;
	}			

	my $days = POSIX::floor($seconds / 86400);
	if ($months > 0 || $weeks > 0 || $days > 0)
	{
		if ($days > 0)
		{	
			$str .= $days.' '.$kz->lang->line((($days	> 1) ? 'date_days' : 'date_day')).', ';
		}

		$seconds -= $days * 86400;
	}

	my $hours = POSIX::floor($seconds / 3600);
	if ($days > 0 || $hours > 0)
	{
		if ($hours > 0)
		{
			$str .= $hours.' '.$kz->lang->line((($hours	> 1) ? 'date_hours' : 'date_hour')).', ';
		}
	
		$seconds -= $hours * 3600;
	}

	my $minutes = POSIX::floor($seconds / 60);
	if ($days > 0 || $hours > 0 || $minutes > 0)
	{
		if ($minutes > 0)
		{	
			$str .= $minutes.' '.$kz->lang->line((($minutes	> 1) ? 'date_minutes' : 'date_minute')).', ';
		}
	
		$seconds -= $minutes * 60;
	}

	$str .= $seconds.' '.$kz->lang->line((($seconds	> 1 || $seconds == 0) ? 'date_seconds' : 'date_second'));
	
	return $str; 
}



# ------------------------------------------------------------------------
# Number of days in a month
#
# Takes a month/year as input and returns the number of days
# for the given month/year. Takes leap years into consideration.
#
# @access	public
# @param	integer a numeric month
# @param	integer	a numeric year
# @return	integer
	
sub days_in_month
{
	my ($month, $year) = @_; 
	
	$month ||= 0;
	
	if ($month < 1 || $month > 12)
	{
		return 0;
	}

	unless ($year =~ /^[0-9]+$/ && length "$year" == 4)
	{
		my ($sec,$min,$hour,$mday,$mon,$l_year,$wday,$yday,$isdst) = localtime(time);
		$year = $l_year + 1900;
	}

	if ($month == 2)
	{
		if ($year % 400 == 0 || ($year % 4 == 0 && $year % 100 != 0))
		{
			return 29;
		}
	}

	my @days_in_month	= (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	return $days_in_month[$month - 1];
}



# ------------------------------------------------------------------------
# Converts a local Unix timestamp to GMT
#
# @access	public
# @param	integer Unix timestamp
# @return	integer
sub local_to_gmt
{
	my ($time) = @_; 

	return POSIX::mktime(gmtime($time || time())); 
}



# ------------------------------------------------------------------------
# Converts GMT time to a localized value
#
# Takes a Unix timestamp (in GMT) as input, and returns
# at the local value based on the timezone and DST setting
# submitted
#
# @access	public
# @param	integer Unix timestamp
# @param	string	timezone
# @param	bool	whether DST is active
# @return	integer
#
sub gmt_to_local
{
	my ($time, $timezone, $dst) = @_; 
	
	return now() unless $time; 

	$timezone ||= 'UTC';
	
	$time += timezones($timezone) * 3600;

	# adjust for daylight saving time
	$time += 3600 if $dst; 

	return $time;
}



# ------------------------------------------------------------------------
# Converts a MySQL Timestamp to Unix
#
# @access	public
# @param	integer Unix timestamp
# @return	integer
#
sub mysql_to_unix
{
	my ($time) = @_; 
	
	return undef unless ($time =~ /^[0-9]+$|^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/); 
	# We'll remove certain characters for backward compatibility
	# since the formatting changed with MySQL 4.1
	# YYYY-MM-DD HH:MM:SS

	$time =~ s/-//g; 
	$time =~ s/://g; 
	$time =~ s/ //g; 

	# YYYYMMDDHHMMSS
	return POSIX::mktime(
					substr($time, 12, 2),
					substr($time, 10, 2),
					substr($time, 8, 2),
					substr($time, 6, 2),
					substr($time, 4, 2) - 1,
					substr($time, 0, 4) - 1900
					);
}



# ------------------------------------------------------------------------
# Unix to "Human"
#
# Formats Unix timestamp to the following prototype: 2006-08-21 11:35 PM
#
# @access	public
# @param	integer Unix timestamp
# @param	bool	whether to show seconds
# @param	string	format: us or euro
# @return	string
#
sub unix_to_human
{
	my ($time, $seconds, $fmt) = @_; 
	
	my $format = undef; 
	if (lc $fmt eq 'us')
	{
		$format = $seconds ? '%F %l:%M:%S %p' : '%F %l:%M %p';
	}
	else
	{
		$format = $seconds ? '%F %T' : '%F %H:%M'; 
	}
	
	return POSIX::strftime($format, localtime($time)); 
}



# ------------------------------------------------------------------------
# Convert "human" date to GMT, i.e. convert "2006-08-21 11:35 PM" to
# the number of seconds since the Unix epoch.
#
# @access	public
# @param	string	format: us or euro
# @return	integer
#
sub human_to_unix
{
	my ($datestr) = @_; 
	
	return undef unless $datestr;  

	$datestr =~ s/^\s*|\s*$//g; # trim leading/trailing whitespace
	$datestr =~ s/\s+/ /g;      # condense whitespace to a single space

	if ($datestr !~ /^[0-9]{2,4}-[0-9]{1,2}-[0-9]{1,2}\s[0-9]{1,2}:[0-9]{1,2}(?::[0-9]{1,2})?(?:\s[AP]M)?$/i)
	{
		return undef;
	}

	my @pieces = split / /, $datestr;

	my @ex = split /-/, $pieces[0];

	my $year  = (length($ex[0]) == 2) ? '20'.$ex[0] : $ex[0];
	my $month = (length($ex[1]) == 1) ? '0'.$ex[1]  : $ex[1];
	my $day   = (length($ex[2]) == 1) ? '0'.$ex[2]  : $ex[2];

	@ex = split /:/, $pieces['1'];

	my $hour = $ex[0];
	my $min  = $ex[1];
	my $sec = '00';

	if ($ex[2] && $ex[2] =~ /[0-9]{1,2}/)
	{
		$sec = $ex[2];
	}

	if ($pieces[2])
	{
		my $ampm = lc $pieces[2];
	
		if ((substr($ampm, 0, 1) eq 'p') && $hour < 12)
		{
			$hour += 12;
		}
		
		if (substr($ampm, 0, 1) eq 'a' && $hour == 12)
		{
			$hour = '00';
		}
		
	}

	return POSIX::mktime($sec, $min, $hour, $day, $month - 1, $year - 1900);
}



# ------------------------------------------------------------------------
# Timezone Menu
#
# Generates a drop-down menu of timezones.
#
# @access	public
# @param	string	timezone
# @param	string	classname
# @param	string	menu name
# @return	string
#
sub timezone_menu
{
	my ($default, $class, $name) = @_; 
	
	$default ||= 'UTC';
	$name ||= 'timezones';
	
	my $kz = kbzb::get_instance()->lang->load('date');

	if ($default eq 'GMT')
	{
		$default = 'UTC';
	}

	my $menu = '<select name="'.$name.'"';

	if ($class)
	{
		$menu .= ' class="'.$class.'"';
	}

	$menu .= ">\n";

	my $tz = timezones(); 
	for (keys %{ $tz })
	{
		my $selected = ($default eq $_) ? " selected='selected'" : '';
		$menu .= "<option value='{$_}'{$selected}>".$kz->lang->line($_)."</option>\n";
	}

	$menu .= "</select>";

	return $menu;
}



# ------------------------------------------------------------------------
# Timezones
#
# Returns an hash of timezones to their GMT offsets.  This is a helper function
# for various other ones in this library
#
# @access	public
# @param	string	timezone
# @return	string
#
sub timezones
{
	my ($tz) = @_; 
	
	$tz = uc $tz; 
	
	my $zones = { 
					'UM12'		=> -12,
					'UM11'		=> -11,
					'UM10'		=> -10,
					'UM95'		=> -9.5,
					'UM9'		=> -9,
					'UM8'		=> -8,
					'UM7'		=> -7,
					'UM6'		=> -6,
					'UM5'		=> -5,
					'UM45'		=> -4.5,
					'UM4'		=> -4,
					'UM35'		=> -3.5,
					'UM3'		=> -3,
					'UM2'		=> -2,
					'UM1'		=> -1,
					'UTC'		=> 0,
					'UP1'		=> +1,
					'UP2'		=> +2,
					'UP3'		=> +3,
					'UP35'		=> +3.5,
					'UP4'		=> +4,
					'UP45'		=> +4.5,
					'UP5'		=> +5,
					'UP55'		=> +5.5,
					'UP575'		=> +5.75,
					'UP6'		=> +6,
					'UP65'		=> +6.5,
					'UP7'		=> +7,
					'UP8'		=> +8,
					'UP875'		=> +8.75,
					'UP9'		=> +9,
					'UP95'		=> +9.5,
					'UP10'		=> +10,
					'UP105'		=> +10.5,
					'UP11'		=> +11,
					'UP115'		=> +11.5,
					'UP12'		=> +12,
					'UP1275'	=> +12.75,
					'UP13'		=> +13,
					'UP14'		=> +14
	};
	
	return $zones unless $tz;

	if ($tz eq 'GMT')
	{
		$tz = 'UTC';
	}

	return exists $zones->{$tz} ? $zones->{$tz} : undef;
}


1;

__END__


=pod

=head1 NAME

date - help formatting dates. 

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('date');
 
 # how many days are in a month? 1-based-months
 $int = days_in_month($int_month, $year); 
 
 # convert a GMT unix timestamp to a local unix timestamp
 $int = gmt_to_local($int, $tz, $is_dst);

 # convert a time formatted as "2006-08-21 11:35 PM" to a unix timestamp 
 $int = human_to_unix($time_string);

 # convert a local unix timestamp to a GMT unix timestamp
 $int = local_to_gmt($int); 
 
 # convert Mysql timestamp to unix seconds
 $seconds = mysql_to_unix('YYYYMMDD HH:MM:SS'); 

 # Returns time() or its GMT equivalent based on the config file preference
 $seconds = now(); 
 
 # get a timestamp in several common formats, RFC 822 being the default
 # DATE_ATOM, DATE_COOKIE, DATE_ISO8601, DATE_RFC822, DATE_RFC850, 
 # DATE_RFC1036, DATE_RFC1123, DATE_RSS, DATE_W3C 
 $formatted_date = standard_date(FORMAT_NAME, now()); 
 
 # human-readable string of elapsed times
 $string = timespan($elapsed_seconds, $timestamp); 
 
 # generate an HTML form pop-up menu of timezones
 $html = timezone_menu($tz, $css_class, $field_name);
 
 # list of timezone codes and their GMT offsets
 $hash = timezones(); 
 
 # retrieve the hour-offset for a timezone from GMT
 $float = timeszones($tz) 
  
 # format a unix timestamp as "2006-08-21 11:35 PM"
 $string = unix_to_human($seconds); 
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
