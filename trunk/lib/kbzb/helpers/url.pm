package kbzb::helpers::url;

# -- $Id: url.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
site_url
base_url
current_url
uri_string
index_page
anchor
anchor_popup
mailto
safe_mailto
auto_link
prep_url
url_title
redirect
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );



# ------------------------------------------------------------------------
# URL Helpers
#


# ------------------------------------------------------------------------
# Site URL
#
# Create a local URL based on your basepath. Segments can be passed via the
# first parameter either as a string or an array.
#
# @access	public
# @param	string
# @return	string
#
sub site_url
{
	my $uri = shift; 
	
	return kbzb::get_instance()->config->site_url($uri);
}



# ------------------------------------------------------------------------
# Base URL
#
# Returns the "base_url" item from your config file
#
# @access	public
# @return	string
#
sub base_url
{
	return kbzb::get_instance()->config->slash_item('base_url');
}



# ------------------------------------------------------------------------
# Current URL
#
# Returns the full URL (including segments) of the page where this 
# function is placed
#
# @access	public
# @return	string
#
sub current_url
{
	my $kz = kbzb::get_instance();
	return $kz->config->site_url($kz->uri->uri_string());
}


# ------------------------------------------------------------------------
# URL String
#
# Returns the URI segments.
#
# @access	public
# @return	string
#
sub uri_string
{
	return kbzb::get_instance()->uri->uri_string();
}



# ------------------------------------------------------------------------
# Index page
#
# Returns the "index_page" from your config file
#
# @access	public
# @return	string
#
sub index_page
{
	return kbzb::get_instance()->config->item('index_page');
}



# ------------------------------------------------------------------------
# Anchor Link
#
# Creates an anchor based on the local URL.
#
# @access	public
# @param	string	the URL
# @param	string	the link title
# @param	mixed	any attributes
# @return	string
#
sub anchor
{
	my ($uri, $title, $attributes) = @_;

	my $site_url = undef; 
	
	if ('ARRAY' ne ref $uri)
	{
		$site_url = ($uri =~ m!^\w+://!i) ? $uri : site_url($uri);
	}
	else
	{
		$site_url = site_url($uri);
	}

	if (! $title)
	{
		$title = $site_url;
	}

	if ($attributes)
	{
		$attributes = _parse_attributes($attributes);
	}

	return '<a href="'.$site_url.'"'.$attributes.'>'.$title.'</a>';
}



# ------------------------------------------------------------------------
# Anchor Link - Pop-up version
#
# Creates an anchor based on the local URL. The link
# opens a new window based on the attributes specified.
#
# @access	public
# @param	string	the URL
# @param	string	the link title
# @param	mixed	any attributes
# @return	string
#
sub anchor_popup
{
	my ($uri, $title, $attributes) = @_; 
	
	my $site_url = ($uri =~ m!^\w+://!i) ? $uri : site_url($uri);

	if (! $title)
	{
		$title = $site_url;
	}

	if (! $attributes)
	{
		return "<a href='javascript:void(0);' onclick=\"window.open('".$site_url."', '_blank');\">".$title."</a>";
	}

	if ( ! 'HASH' eq ref $attributes)
	{
		$attributes = {};
	}

	my $atts = 	{'width' => '800', 'height' => '600', 'scrollbars' => 'yes', 'status' => 'yes', 'resizable' => 'yes', 'screenx' => '0', 'screeny' => '0'} ;
	
	for (keys %{ $atts } )
	{
		$atts->{$_} = exists $attributes->{$_} ? $attributes->{$_} : $atts->{$_};
		delete $attributes->{$_}; 
	}

	if ($attributes)
	{
		$attributes = _parse_attributes($attributes);
	}

	return "<a href='javascript:void(0);' onclick=\"window.open('".$site_url."', '_blank', '"._parse_attributes($atts, 1)."');\"$attributes>".$title."</a>";
}



# ------------------------------------------------------------------------
# Mailto Link
#
# @access	public
# @param	string	the email address
# @param	string	the link title
# @param	mixed 	any attributes
# @return	string
#
sub mailto
{
	my ($email, $title, $attributes) = @_; 

	if (! $title)
	{
		$title = $email;
	}

	$attributes = _parse_attributes($attributes);

	return '<a href="mailto:'.$email.'"'.$attributes.'>'.$title.'</a>';
}



# ------------------------------------------------------------------------
# Encoded Mailto Link
#
# Create a spam-protected mailto link written in Javascript
#
# @access	public
# @param	string	the email address
# @param	string	the link title
# @param	mixed 	any attributes
# @return	string
#
sub safe_mailto
{
	my ($email, $title, $attributes) = @_; 

	if (! $title)
	{
		$title = $email;
	}

	my @x = (); 
	for (my $i = 0; $i < 16; $i++)
	{
		$x[$i] = substr('<a href="mailto:', $i, 1);
	}

	for (my $i = 0; $i < length($email); $i++)
	{
		push @x, '|' . ord(substr($email, $i, 1));
	}

	push @x, '"';

	if ($attributes)
	{
		if ('HASH' eq ref $attributes)
		{
			for my $key (keys %{ $attributes })
			{
				push @x, ' ' . $key . '="';
				
				for (my $i = 0; $i < length($attributes->{$key}); $i++)
				{
					push @x, '|' . ord(substr($attributes->{$key}, $i, 1));
				}
				push @x, '"';
			}
		}
		else
		{
			for (my $i = 0; $i < length($attributes); $i++)
			{
				push @x, substr($attributes, $i, 1);
			}
		}
	}

	push @x, '>';

	my @temp = ();
	my $count = 0; 
	for (my $i = 0; $i < length($title); $i++)
	{
		my $ordinal = ord(substr $title, $i, 1);

		if ($ordinal < 128)
		{
			push @x, '|'.$ordinal;
		}
		else
		{
			if (scalar @temp == 0)
			{
				$count = ($ordinal < 224) ? 2 : 3;
			}

			push @temp, $ordinal;
			if (scalar @temp == $count)
			{
				my $number = ($count == 3) ? (($temp[0] % 16) * 4096) + (($temp[1] % 64) * 64) + ($temp[2] % 64) : (($temp[0] % 32) * 64) + ($temp[1] % 64);
				push @x, '|' . $number;
				$count = 1;
				@temp = ();
			}
		}
	}

	push @x, '<'; 
	push @x, '/'; 
	push @x, 'a'; 
	push @x, '>'; 

	@x = reverse(@x);
	
	my $buffer = "<script type=\"text/javascript\">\n#<![CDATA[\nvar l=new Array();\n";
	
	my $i = 0; 
	for my $val (@x)
	{
		$buffer .= "l[$i] = '$val';"; 
		$i++; 
	}
	
	$buffer .= <<EOT;
for (var i = l.length-1; i >= 0; i=i-1){
if (l[i].substring(0, 1) == '|') document.write("&#"+unescape(l[i].substring(1))+";");
else document.write(unescape(l[i]));}
#]]>
</script>
EOT
	
	return $buffer; 
}



# ------------------------------------------------------------------------
# Auto-linker
#
# Automatically links URL and Email addresses.
# Note: There's a bit of extra code here to deal with
# URLs or emails that end in a period.  We'll strip these
# off and add them after the link.
#
# @access	public
# @param	string	the string
# @param	string	the type: email, url, or both
# @param	bool 	whether to create pop-up links
# @return	string
#
sub auto_link
{
	my ($str, $type, $popup) = @_; 
	
	my $copy = $str; 
	$type ||= 'both';
	
	if ($type ne 'email')
	{
		while ($str =~ m#(^|\s|\()((http(s?)://)|(www\.))(\w+[^\s\)\<]+)#i)
		{
			my $link = $1;  # the whole link
			my $junk = $2;  # http:// or www.
			my $asdf = $3;
			my $http = $4;  # https? 
			my $url  = $5;  # the URL
			my $end  = $6;  #

			my $pop = ($popup) ? " target=\"_blank\" " : "";
			my $period = '';
			if ($end =~ /\.$/)
			{
				$period = '.';
				$end = substr($end, 0, -1); 
			}
	
			$copy =~ s/$link/<a href="http$http:\/\/$url$end\"$pop>http$http:\/\/$url$end<\/a>$period/g;
		}
	}

	if ($type ne 'url')
	{
		while ($str =~ /(([a-zA-Z0-9_\.\-\+]+)@([a-zA-Z0-9\-]+)\.([a-zA-Z0-9\-\.]*))/i)
		{
			my $address = $1; 
			my $name = $2; 
			my $period = ''; 
			my $end = $4; 
			if ($end =~ /\.$/)
			{
				$period = '.';
				$end = substr($end, 0, -1); 
			}
			
			my $safe_email = safe_mailto("$name\@$3.$end$period"); 
			$copy =~ s/$address/$safe_email/g; 
		}
	}

	return $str;
}



# ------------------------------------------------------------------------
# Prep URL
#
# Simply adds the http:// part if missing
#
# @access	public
# @param	string	the URL
# @return	string
#
sub prep_url
{
	my ($str) = @_; 
	
	if ($str eq 'http://' || $str eq '')
	{
		return '';
	}

	if (substr($str, 0, 7) ne 'http://' && substr($str, 0, 8) ne 'https://')
	{
		$str = 'http://'.$str;
	}

	return $str;
}


# ------------------------------------------------------------------------
# Create URL Title
#
# Takes a "title" string as input and creates a
# human-friendly URL string with either a dash
# or an underscore as the word separator.
#
# @access	public
# @param	string	the string
# @param	string	the separator: dash, or underscore
# @return	string
#
sub url_title
{
	my ($str, $separator, $lowercase) = @_; 
	
	$separator ||= 'dash';
	
	my ($search, $replace) = undef; 
	if ($separator eq 'dash')
	{
		$search		= '_';
		$replace	= '-';
	}
	else
	{
		$search		= '-';
		$replace	= '_';
	}

	my $trans = {
					qr/&\#\d+?;/			=> '',
					qr/&\S+?;/				=> '',
					qr/\s+/					=> $replace,
					qr/[^a-z0-9\-\._]/		=> '',
					qr/$replace+/			=> $replace,
					qr/$replace$/			=> $replace,
					qr/^$replace/			=> $replace,
					qr/\.+$/				=> ''
	};

#@	# simple HTML tag stripper
	$str =~ s/<[^>]*>//g;  
	
	for (keys %$trans)
	{
		$str =~ s/$_/$trans->{$_}/gi; 
	}

	if ($lowercase)
	{
		$str = lc $str;
	}
	
	$str =~ s/^\s*|\s*$//g; 
	
	return $str; 
#@	return stripslashes($str);
}



# ------------------------------------------------------------------------
# Header Redirect
#
# Header redirect in two flavors
# For very fine grained control over headers, you could use the Output
# Library's set_header() function.
#
# @access	public
# @param	string	the URL
# @param	string	the method: location or redirect
# @return	string
#
sub redirect
{
	my ($uri, $method, $http_response_code) = @_; 
	
	$method ||= 'location';
	$http_response_code ||= 302; 
	
	if ($uri !~ m#^https?://#i)
	{
		$uri = site_url($uri);
	}
	
	if ($method eq 'refresh')
	{
		kbzb::get_instance()->output->set_header("Refresh:0;url=$uri"); 
	}
	else
	{
		print $kbzb::cgi->redirect(-uri => $uri, -status => $http_response_code); 
		exit; 
	}
}



# ------------------------------------------------------------------------
# Parse out the attributes
#
# Some of the functions use this
#
# @access	private
# @param	array
# @param	bool
# @return	string
#
sub _parse_attributes
{
	my ($attributes, $javascript) = @_; 
	
	if (! ref $attributes)
	{
		return ($attributes != '') ? ' '.$attributes : '';
	}

	my $att = '';
	for (%$attributes)
	{
		if ($javascript)
		{
			$att .= $_ . '=' . $attributes->{$_} . ',';
		}
		else
		{
			$att .= ' ' . $_ . '="' . $attributes->{$_} . '"';
		}
	}

	if ($javascript && $att ne '')
	{
		$att = substr($att, 0, -1);
	}

	return $att;
}

1;

__END__


=pod

=head1 NAME

url - functions for manipulating URLs, HREFs, etc.

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('url');

 # create a fully-qualified link to a page within the site
 $html = anchor('/some/url');
 
 # javascript popup link to a page within the site
 $html = anchor_popup('/some/url');
 
 # link items that look like links and email addresses
 $html = auto_link('string with http://someurl.org or user@somedomain.org'); 
 
 # retrieve base_url item from config.properties
 $url = base_url(); 
 
 # retrieve current URL wherever this functio
 $url = current_url(); 
 
 # retrieve index_page item from config.properties 
 $page = index_page(); 
 
 # create a mailto link, including any attributes
 $html = mailto('user@domain.org', \%properties);
 
 # add http:// to a URL if it is missing
 $link = prep_url('domain.org'); 
 
 # send a header or meta-refresh redirect
 redirect('domain.org', undef, 302);
 redirect('domain.org', 'refresh');
 
 # create a spam-protected link using javascript
 $js = safe_mailto('user@domain.org');
 
 # retrieve the site_url item from config.properties
 $url = site_url(); 
 
 # retrieve URI segments, e.g. /controller/method/param-1/../param-n
 $string = uri_string(); 
 
 # translate a string into an href-friendly string, 
 # e.g. "What's wrong with CSS?" -> "whats-wrong-with-css" 
 $string = url_title('What\'s wrong with CSS?'); 
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
