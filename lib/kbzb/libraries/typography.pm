package kbzb::libraries::typography;

# -- $Id: typography.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --



use strict;

my $table = {}; 


#
# Nothing to do here...
#
sub new
{
	my $class = shift; 
	my $self = {}; 
	
	bless $self, $class; 
	
	kbzb::libraries::common::load_class('logger', undef, $self);
	
	# Block level elements that should not be wrapped inside <p> tags
	$self->{block_elements} = qr/address|blockquote|div|dl|fieldset|form|h\d|hr|noscript|object|ol|p|pre|script|table|ul/;
	
	# Elements that should not have <p> and <br /> tags within them.
	$self->{skip_elements}	= qr/p|pre|ol|ul|dl|object|table/;
	
	# Tags we want the parser to completely ignore when splitting the string.
	$self->{inline_elements} = qr/a|abbr|acronym|b|bdo|big|br|button|cite|code|del|dfn|em|i|img|ins|input|label|map|kbd|q|samp|select|small|span|strong|sub|sup|textarea|tt|var/;
	
	# array of block level elements that require inner content to be within another block level element
	$self->{inner_block_required} = ('blockquote');
	
	# the last block element parsed
	$self->{last_block_element} = '';
	
	# whether or not to protect quotes within { curly braces }
	$self->{protect_braced_quotes} = 0;
	
	$self->logger->debug('Typography Class Loaded');
	
	return $self; 

}



#
# Auto Typography
#
# This function converts text, making it typographically correct:
# 	- Converts double spaces into paragraphs.
# 	- Converts single line breaks into <br /> tags
# 	- Converts single and double quotes into correctly facing curly quote entities.
# 	- Converts three dots into ellipsis.
# 	- Converts double dashes into em-dashes.
#   - Converts two spaces into entities
#
# @access	public
# @param	string
# @param	bool	whether to reduce more then two consecutive newlines to two
# @return	string
#
sub auto_typography
{
	my $self = shift; 
	my ($str, $reduce_linebreaks) = @_; 
	
	if ($str eq '')
	{
		return '';
	}

	# Standardize Newlines to make matching easier
	$str =~ s/\r\n|\r/\n/g; 

	# Reduce line breaks.  If there are more than two consecutive linebreaks
	# we'll compress them down to a maximum of two since there's no benefit to more.
	if ($reduce_linebreaks)
	{
		$str =~ s/\n\n+/\n\n/g;
	}
	
	# substitutions will operate on the copy
	my $copy = $str; 

#	# HTML comment tags don't conform to patterns of normal tags, so pull them out separately, only if needed
	my @html_comments = ();
#	if (index($str, '<!--') >= 0)
#	{
#		if (preg_match_all("#(<!\-\-.*?\-\->)#s", $str, $matches))
#		{
#			for ($i = 0, $total = count($matches[0]); $i < $total; $i++)
#			{
#				$html_comments[] = $matches[0][$i];
#				$str = str_replace($matches[0][$i], '{@HC'.$i.'}', $str);
#			}
#		}
#	}
	
	# match and yank <pre> tags if they exist.  It's cheaper to do this separately since most content will
	# not contain <pre> tags, and it keeps the PCRE patterns below simpler and faster
#	if (index($str, '<pre') >= 0)
#	{
#		$str = preg_replace_callback("#<pre.*?>.*?</pre>#si", array($this, '_protect_characters'), $str);
#	}
	
	# Convert quotes within tags to temporary markers.
	while ($str =~ /<(.+?)>/)
	{
		my $match = $1;
		my $protected = $self->_protect_characters($1); 
		$copy =~ s/$match/$protected/; 
	}

	# Do the same with braces if necessary
	if ($self->{protect_braced_quotes})
	{
		while ($str =~ /\{(.+?)\}/)
		{
			my $match = $1;
			my $protected = $self->_protect_characters($1); 
			$copy =~ s/$match/$protected/; 
		}
	}
			
	# Convert "ignore" tags to temporary marker.  The parser splits out the string at every tag 
	# it encounters.  Certain inline tags, like image tags, links, span tags, etc. will be 
	# adversely affected if they are split out so we'll convert the opening bracket < temporarily to: {@TAG}
	$copy =~ s#<(/*)($self->{inline_elements})([ >])#{\@TAG}$1$2$3#i;

	# Split the string at every tag.  This expression creates an array with this prototype:
	# 
	# 	[array]
	# 	{
	# 		[0] = <opening tag>
	# 		[1] = Content...
	# 		[2] = <closing tag>
	# 		Etc...
	# 	}	
	my @chunks = split /(<(?:[^<>]+(?:"[^"]*"|\'[^\']*\')?)+>)/, $copy; #, -1, PREG_SPLIT_DELIM_CAPTURE|PREG_SPLIT_NO_EMPTY);
	
	# Build our finalized string.  We cycle through the array, skipping tags, and processing the contained text	
	$str = '';
	my $process = 1;
	my $paragraph = 0;
	my $current_chunk = 0;
	my $total_chunks = scalar @chunks;
	
	for my $chunk (@chunks)
	{ 
		$current_chunk++;
		
		# Are we dealing with a tag? If so, we'll skip the processing for this cycle.
		# Well also set the "process" flag which allows us to skip <pre> tags and a few other things.
		if ($chunk =~ m#<(/*)($self->{block_elements}).*?>#)
		{
			my $one = $1; 
			my $two = $2; 
			if ($two =~ /$self->{skip_elements}/)
			{
				$process =  ($one eq '/') ? 1 : 0;
			}
			
			if ($one eq '')
			{
				$self->{last_block_element} = $2;
			}

			$str .= $chunk;
			next;
		}
		
		if (! $process)
		{
			$str .= $chunk;
			next;
		}
		
		#  Force a newline to make sure end tags get processed by _format_newlines()
		if ($current_chunk == $total_chunks)
		{
			$chunk .= "\n";  
		}
		
		#  Convert Newlines into <p> and <br /> tags
		$str .= $self->_format_newlines($chunk);
	}
	
	# No opening block level tag?  Add it if needed.
	if ($str !~ /^\s*<(?:$self->{block_elements})/i)
	{
		$str =~ s/^(.*?)<($self->{block_elements})/<p>$1<\/p><$2/i; 
	}
	
	# Convert quotes, elipsis, em-dashes, non-breaking spaces, and ampersands
	$str = $self->format_characters($str);
	
	# restore HTML comments
#	for (my $i = 0, my $total = scalar @html_comments; $i < $total; $i++)
#	{
#		# remove surrounding paragraph tags, but only if there's an opening paragraph tag
#		# otherwise HTML comments at the ends of paragraphs will have the closing tag removed
#		# if '<p>{@HC1}' then replace <p>{@HC1}</p> with the comment, else replace only {@HC1} with the comment
#		$str = preg_replace('#(?(?=<p>\{@HC'.$i.'\})<p>\{@HC'.$i.'\}(\s*</p>)|\{@HC'.$i.'\})#s', $html_comments[$i], $str);
#	}
			
	# Final clean up
	my %table = (
	
					# If the user submitted their own paragraph tags within the text
					# we will retain them instead of using our tags.
					qr/(<p[^>*?]>)<p>/		=> '$1', # <?php BBEdit syntax coloring bug fix
					
					# Reduce multiple instances of opening/closing paragraph tags to a single one
					qr/(<\/p>)+/			=> '</p>',
					qr/(<p>\W*<p>)+/	=> '<p>',
					
					# Clean up stray paragraph tags that appear before block level elements
					qr/<p><\/p><($self->{block_elements})/	=> '<$1',

					# Clean up stray non-breaking spaces preceeding block elements
					qr/(&nbsp;\s*)+<($self->{block_elements})/	=> '  <$2',

					# Replace the temporary markers we added earlier
					qr/\{\@TAG\}/		=> '<',
					qr/\{\@DQ\}/			=> '"',
					qr/\{\@SQ\}/			=> "'",
					qr/\{\@DD\}/			=> '--',
					qr/\{\@NBS\}/		=> '  '
					);
	
	# Do we need to reduce empty lines?
	if ($reduce_linebreaks)
	{
		$table{qr/<p>\n*<\/p>/} = '';
	}
	else
	{
		# If we have empty paragraph tags we add a non-breaking space
		# otherwise most browsers won't treat them as true paragraphs
		$table{qr/<p><\/p>/} = '<p>&nbsp;</p>';
	}
	
	for (keys %table)
	{
		$str =~ s/$_/$table{$_}/g;
	}
	
	return $str;
}


#
# Format Characters
#
# This function mainly converts double and single quotes
# to curly entities, but it also converts em-dashes,
# double spaces, and ampersands
#
# @access	public
# @param	string
# @return	string
#
sub format_characters
{
	my $self = shift; 
	my ($str) = @_; 
	
	# nested smart quotes, opening and closing
	# note that rules for grammar (English) allow only for two levels deep
	# and that single quotes are _supposed_ to always be on the outside
	# but we'll accommodate both
	# Note that in all cases, whitespace is the primary determining factor
	# on which direction to curl, with non-word characters like punctuation
	# being a secondary factor only after whitespace is addressed.
	$str =~ s/\'"(\s|$)/&#8217;&#8221;$1/go;
	$str =~ s/(^|\s|<p>)\'"/$1&#8216;&#8220;/go;
	$str =~ s/\'"(\W)/&#8217;&#8221;$1/go;
	$str =~ s/(\W)\'"/$1&#8216;&#8220;/go;
	$str =~ s/"\'(\s|$)/&#8221;&#8217;$1/go;
	$str =~ s/(^|\s|<p>)"\'/$1&#8220;&#8216;/go;
	$str =~ s/"\'(\W)/&#8221;&#8217;$1/go;
	$str =~ s/(\W)"\'/$1&#8220;&#8216;/go;

	
	# single quote smart quotes
	$str =~ s/\'(\s|$)/&#8217;$1/go;
	$str =~ s/(^|\s|<p>)\'/$1&#8216;/go;
	$str =~ s/\'(\W)/&#8217;$1/go;
	$str =~ s/(\W)\'/$1&#8216;/go;

	# double quote smart quotes
	$str =~ s/"(\s|$)/&#8221;$1/go;
	$str =~ s/(^|\s|<p>)"/$1&#8220;/go;
	$str =~ s/"(\W)/&#8221;$1/go;
	$str =~ s/(\W)"/$1&#8220;/go;

	# apostrophes
	$str =~ s/(\w)'(\w)/$1&#8217;$2/go;
	
	# Em dash and ellipses dots
	$str =~ s/\s?\-\-\s?/&#8212;/go;
	$str =~ s/(\w)\.{3}/$1&#8230;/go;

	# double space after sentences
	$str =~ s/(\W)  /$1&nbsp; /go;

	# ampersands, if not a character entity
	$str =~ s/&(?!#?[a-zA-Z0-9]{2,};)/&amp;/go;
	
	return $str; 
}



# --------------------------------------------------------------------
#
# Format Newlines
#
# Converts newline characters into either <p> tags or <br />
#
# @access	public
# @param	string
# @return	string
#
sub _format_newlines
{
	my $self = shift; 
	
	my ($str) = @_; 
	
	if ($str eq '')
	{
		return $str;
	}
	
	if (index($str, "\n") == -1  && ! grep (/$self->{last_block_element}/, @{ $self->{inner_block_required} }))
	{
		return $str;
	}
	
	# Convert two consecutive newlines to paragraphs
	$str =~ s/\n\n/<\/p>\n\n<p>/g;

	
	# Convert single spaces to <br /> tags
	$str =~ s/([^\n])(\n)([^\n])/$1<br \/>$2$3/g; 
	
	# Wrap the whole enchilada in enclosing paragraphs
	if ($str eq "\n")
	{
		$str =  '<p>'.$str.'</p>';
	}

	# Remove empty paragraphs if they are on the first line, as this
	# is a potential unintended consequence of the previous code
	$str =~ s/<p><\/p>(.*)/$1/; 
	
	return $str;
}



#
# Protect Characters
#
# Protects special characters from being formatted later
# We don't want quotes converted within tags so we'll temporarily convert them to {@DQ} and {@SQ}
# and we don't want double dashes converted to emdash entities, so they are marked with {@DD}
# likewise double spaces are converted to {@NBS} to prevent entity conversion
#
# @access	public
# @param	array
# @return	string
#
sub _protect_characters
{
	my $self = shift; 
	my ($match) = @_; 
	
	$match =~ s/'/{\@SQ}/; 
	$match =~ s/"/{\@DQ}/; 
	$match =~ s/--/{\@DD}/; 
	$match =~ s/  /{\@NBS}/; 
	
	return $match; 
}



# --------------------------------------------------------------------
#
# Convert newlines to HTML line breaks except within PRE tags
#
# @access	public
# @param	string
# @return	string
#
sub nl2br_except_pre
{
	my $self = shift;
	my ($str) = @_; 
	
	my @ex = split /pre>/, $str;
	
	my $ct = scalar @ex; 

	my $newstr = "";
	for (my $i = 0; $i < $ct; $i++)
	{
		if (($i % 2) == 0)
		{
			(my $temp = $ex[$i]) =~ s/\n/<br \/>\n/g;
			$newstr .= $temp;
		}
		else
		{
			$newstr .= $ex[$i];
		}
	
		if ($ct - 1 != $i)
		{
			$newstr .= "pre>";
		}
	}

	return $newstr;
}

1;

__END__


=pod

=head1 NAME

typography - format text so that it is semantically and typographically correct HTML. 

=head2 USAGE

 # from within a controller ... 
 $self->load->library('typography');

 $paragraphs = [...]; 
 $self->output->append_output($self->typography->auto_typography($paragraphs);

 $string = "It's a shame people use 'quotes' incorrectly.  I abhor m--dashes and elipses..."; 
 $self->output->append_output($self->typography->format_characters($string);


=head1 DESCRIPTION

=head2 auto_typography 

takes a string as input and returns it with the following formatting:

=over

=item Surrounds paragraphs within <p></p> (looks for double line breaks to identify paragraphs).

=item Single line breaks are converted to <br />, except those that appear within <pre> tags.

=item Block level elements, like <div> tags, are not wrapped within paragraphs, but their contained text is if it contains paragraphs.

=item Quotes are converted to correctly facing curly quote entities, except those that appear within tags.

=item Apostrophes are converted to curly apostrophe entities.

=item Double dashes (either like -- this or like--this) are converted to em—dashes.

=item Three consecutive periods either preceding or following a word are converted to ellipsis…

=item Double spaces following sentences are converted to non-breaking spaces to mimic double spacing.

=item Surrounds paragraphs within <p></p> (looks for double line breaks to identify paragraphs).

=item Single line breaks are converted to <br />, except those that appear within <pre> tags.

=item Block level elements, like <div> tags, are not wrapped within paragraphs, but their contained text is if it contains paragraphs.

=item Quotes are converted to correctly facing curly quote entities, except those that appear within tags.

=item Apostrophes are converted to curly apostrophe entities.

=item Double dashes (either like -- this or like--this) are converted to em-dashes.

=item Three consecutive periods either preceding or following a word are converted to ellipsis...

=item Double spaces following sentences are converted to non-breaking spaces to mimic double spacing.

=back

=head2 format_characters 

does character conversion only; it takes a string as input and returns it with the following formatting: 

=over

=item Quotes are converted to correctly facing curly quote entities, except those that appear within tags.

=item Apostrophes are converted to curly apostrophe entities.

=item Double dashes (either like -- this or like--this) are converted to em-dashes.

=item Three consecutive periods either preceding or following a word are converted to ellipsis

=item Double spaces following sentences are converted to non-breaking spaces to mimic double spacing.

=back

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
