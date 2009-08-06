package kbzb::helpers::text;

# -- $Id: text.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;

use Text::Wrap qw(wrap $columns);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use asdf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
word_limiter
character_limiter
ascii_to_entities
entities_to_ascii
word_censor
highlight_code
highlight_phrase
word_wrap
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
        
);




# ------------------------------------------------------------------------
# CodeIgniter Text Helpers
#
# @package		CodeIgniter
# @subpackage	Helpers
# @category	Helpers
# @author		ExpressionEngine Dev Team
# @link		http://codeigniter.com/user_guide/helpers/text_helper.html


# ------------------------------------------------------------------------
# Word Limiter
#
# Limits a string to X number of words.
#
# @access	public
# @param	string
# @param	integer
# @param	string	the end character. Usually an ellipsis
# @return	string
#
sub word_limiter
{
	my ($str, $limit, $end_char) = @_; 
	
	$limit = 100 unless $limit =~ /^[0-9]+$/ && $limit > 0; 
	$end_char ||= '&#8230;';
	
	$str =~ s/^\s*|\s*$//g; 
	
	if ($str eq '')
	{
		return $str;
	}
	
	$str =~ /(?:\S+\s*+){1,$limit}/;
	
	if (length $str == length $1)
	{
		$end_char = '';
	}
	
	return $1 . $end_char;
}



# ------------------------------------------------------------------------
# Character Limiter
#
# Limits the string based on the character count.  Preserves complete words
# so the character count may not be exactly as specified.
#
# @access	public
# @param	string
# @param	integer
# @param	string	the end character. Usually an ellipsis
# @return	string
#
sub character_limiter
{
	my ($str, $n, $end_char) = @_; 
	
	$n ||= 500;
	$end_char ||= '&#8230;';
	
	if (length $str < $n)
	{
		return $str;
	}
	
	$str =~ s/\s+/ /g;      # condense/convert spaces
	$str =~ s/\r\n/\n/g;    # condense newlines
	$str =~ s/\r/\n/g;      # convert new lines
	$str =~ s/^\s*|\s*$//g; # zap leading, trailing whitespace
	
	if (length $str < $n)
	{
		return $str;
	}

	my $out = '';
	
	for (split /\s/, $str)
	{
		$out .= $_ . ' ';
		
		if (length $out >= $n)
		{
			return (length $out == length $str) ? $out : $out.$end_char;
		}		
	}
}



# ------------------------------------------------------------------------
# High ASCII to Entities
#
# Converts High ascii text and MS Word special characters to character entities
#
# @access	public
# @param	string
# @return	string
#
sub ascii_to_entities
{
	my ($str) = @_; 
	
	my $count = 1;
	my $out   = '';
	my @temp  = ();
	
	for (my $i = 0, my $s = length $str; $i < $s; $i++)
	{
		my $ordinal = ord substr($str, $i, 1); 
		if ($ordinal < 128)
		{
			if ($#temp == 0) 
			{
				$out .= '&#' . (shift @temp) . ';';
				$count = 1; 
			}
			
			$out .= substr($str, $i, 1);
		}
		else
		{
			if ($#temp == -1)
			{
				$count = ($ordinal < 224) ? 2 : 3;
			}
			
			push @temp, $ordinal;
			
			if (scalar @temp == $count)
			{
				my $number = ($count == 3) ? (($temp[0] % 16) * 4096) + (($temp[1] % 64) * 64) + ($temp[2] % 64) : (($temp[0] % 32) * 64) + ($temp[1] % 64);

				$out .= '&#'.$number.';';
				$count = 1;
				@temp = ();
			}
		}
	}

	return $out;
}



# ------------------------------------------------------------------------
# Entities to ASCII
#
# Converts character entities back to ASCII
#
# @access	public
# @param	string
# @param	bool
# @return	string
#
sub entities_to_ascii
{
	my ($str, $all) = @_; 
	
	if ('' eq $all) 
	{
		$all = 1; 
	}
	
	my $match = $str; 
	
	while ($str =~ /\&#(\d+)\;/g)
	{
		my $out = ''; 
		if ($1 < 128)
		{
			$out .= chr $1; 
		}
		elsif ($1 < 2048)
		{
			$out .= chr(192 + (($1 - ($1 % 64)) / 64));
			$out .= chr(128 + ($1 % 64));
		}
		else
		{
			$out .= chr(224 + (($1 - ($1 % 4096)) / 4096));
			$out .= chr(128 + ((($1 % 4096) - ($1 % 64)) / 64));
			$out .= chr(128 + ($1 % 64));
		}
		
		my $substring = $1;
		$match =~ s/\&#$substring;/$out/g; 

#@		   $str = str_replace($matches['0'][$i], $out, $str);				
		
	}
	
	$str = $match; 

	if ($all)
	{
		$str =~ s/&amp;/&/g; 
		$str =~ s/&lt;/</g; 
		$str =~ s/&gt;/>/g; 
		$str =~ s/&quot;/"/g; 
		$str =~ s/&apos;/'/g; 
		$str =~ s/&#45;/-/g; 
   }

   return $str;
}



# ------------------------------------------------------------------------
# Word Censoring Function
#
# Supply a string and an array of disallowed words and any
# matched words will be converted to #### or to the replacement
# word you've submitted.
#
# @access	public
# @param	string	the text string
# @param	string	the array of censored words
# @param	string	the optional replacement value
# @return	string
#
sub word_censor
{
	my ($str, $censored, $replacement) = @_; 
	
	if ('ARRAY' ne ref $censored)
	{
		return $str;
	}
	
	$str = ' '.$str.' ';

	# \w, \b and a few others do not match on a unicode character
	# set for performance reasons. As a result words like über
	# will not match on a word boundary. Instead, we'll assume that
	# a bad word will be bookended by any of these characters.
	my $delim = '[-_\'\"`(){}<>\[\]|!?@#%&,.:;^~*+=\/ 0-9\n\r\t]';

	for my $badword (@$censored)
	{
		if ($replacement != '')
		{
			$str =~ s/($delim)($badword)($delim)/$1$replacement$3/i;
		}
		else
		{
			$str = s/($delim)($badword)($delim)/$1XXXXX$3/i; #", "'\\1'.str_repeat('#', strlen('\\2')).'\\3'", $str);
		}
	}

	return trim($str);
}



# ------------------------------------------------------------------------
# Code Highlighter
#
# Colorizes code strings
#
# @access	public
# @param	string	the text string
# @return	string
#
sub highlight_code
{
#@ maybe enscript the output? 
	return $_[0];
}


# ------------------------------------------------------------------------
# Phrase Highlighter
#
# Highlights a phrase within a text string
#
# @access	public
# @param	string	the text string
# @param	string	the phrase you'd like to highlight
# @param	string	the openging tag to precede the phrase with
# @param	string	the closing tag to end the phrase with
# @return	string
	
sub highlight_phrase
{
	my ($str, $phrase, $tag_open, $tag_close) = @_; 
	
	$tag_open ||= '<strong>';
	$tag_close ||= '</strong>';
	
	if ($str eq '')
	{
		return '';
	}

	if ($phrase ne '')
	{
		$str =~ s/($phrase)/$tag_open$1$tag_close/ig; 
	}

	return $str;
}



# ------------------------------------------------------------------------
# Word Wrap
#
# Wraps text at the specified character.  Maintains the integrity of words.
# Anything placed between {unwrap}{/unwrap} will not be word wrapped, nor
# will URLs.
#
# @access	public
# @param	string	the text string
# @param	integer	the number of characters to wrap at
# @return	string
#
sub word_wrap
{
#@ what about {unwrap}{/unwrap}?
	my ($str, $charlim) = @_; 
	
	$columns = $charlim || 76;
	
	return wrap('', '', $str); 
}


1;


__END__

=pod

=head1 NAME

text - functions for manipulating text blocks

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('text');
 
 ascii_to_entities
 character_limiter
 entities_to_ascii
 highlight_code
 highlight_phrase
 word_censor
 word_limiter
 word_wrap
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

 
=cut
