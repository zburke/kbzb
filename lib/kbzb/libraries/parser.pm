package kbzb::libraries::parser; 

# -- $Id: parser.pm 161 2009-07-28 20:49:55Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;


sub new
{
	my $class = shift;
	my $self = {}; 
	
	bless $self, $class; 
	
	$self->{l_delim} = '{';
	$self->{r_delim} = '}';
	$self->{object} = undef; 
	
	$self->{logger} = kbzb::libraries::common::load_class('logger'); 
	
	return $self; 
}



#
# parse - push hash values into a template with corresponding keys
#
# arguments
#     $string - view file to use
#     $hashref - hash of value to push into the template
#     $boolean - whether to append parsed template to output (default) or return it
#
sub parse
{
	my $self = shift; 
	my ($template, $data, $return) = @_; 
	
	if (! $template)
	{
		return 0;
	}
	
	# template parsing: load include files
	$self->_parse_includes(\$template); 
	
	# variable parsing: push data into template
	for my $key (keys %{ $data })
	{
		if (ref $data->{$key} eq 'ARRAY')
		{
			$template = $self->_parse_pair($key, $data->{$key}, $template);
		}
		else
		{
			$template = $self->_parse_single($key, $data->{$key}, $template);
		}
	}
	
	# template parsing: parse method requests
	$self->_parse_helpers(\$template); 
	
	if (! $return)
	{
		kbzb::get_instance()->output->append_output($template);
	}
	
	return $template; 
}




#
# set_delimiters
# set the left and right variable delimiters, i.e. the characters
# that serve as boundaries for variable subsitution. Default left
# and right delimiters are curly braces, {}. 
#
sub set_delimiters
{
	my $self = shift;
	my ($left, $right) = @_; 
	
	$self->{l_delim} = $left || '{';
	$self->{r_delim} = $right = $right || '}';
}


#
# parse_single
# substitute in a variable
sub _parse_single
{
	my $self = shift;
	my ($key, $val, $string) = @_; 
	
	$string =~ s/$self->{l_delim}$key$self->{r_delim}/$val/g; 
	return $string; 
}


#
# _parse_pair
# substitute in an array of values
sub _parse_pair
{
	my $self = shift;
	my ($variable, $data, $string) = @_; 

	if (my @list = $self->_match_pair($string, $variable))
	{
		my $str = '';
		for my $row (@{ $data })
		{
			my $temp = $list[1];
			for my $key (keys %{ $row })
			{
				if (ref $row->{$key} eq 'ARRAY')
				{
					$temp = $self->_parse_pair($key, $row->{$key}, $temp);
				}
				else
				{
					$temp = $self->_parse_single($key, $row->{$key}, $temp);
				}
			}
		
			$str .= $temp;
		}
		
		$string =~ s/$list[0]/$str/; 
	
		return $string;
	}
	else
	{
		return $string;
	}

}



#
# _match_pair
# match a pair of delimiters, e.g.
# 
sub _match_pair
{
	my $self = shift;
	
	my ($string, $variable) = @_; 
	
	if ($string =~ /($self->{l_delim}$variable$self->{r_delim}(.+?)$self->{l_delim}\/$variable$self->{r_delim})/s)
	{
		return ($1, $2); 
	}
	
	return undef; 
}



#
# _parse_helpers
# given a template, replace embedded references to helper functions
# with the result of those function calls. helper blocks look like this: 
# <delimiter>$full::package::function(av1, av2 .. avn)<delimiter>
#
# arguments
#    \$string - a template file containing items to be replaced
#
sub _parse_helpers
{
	my $self = shift;
	my ($template) = @_; 
	
	# need this to load the helper packages
	my $kz = kbzb::get_instance(); 
	
	# make a copy we can use for replacements
	my $parsed = $$template; 
	
	# helper blocks look like this: 
	# <delimiter>$full::package::function(av1, av2 .. avn)<delimiter>
	while ($$template =~ /($self->{l_delim}\$(.+)::(\w+)::(\w+)\(([^\)]*)?\)$self->{r_delim})/g)
	{
		my $fc = $1; 
		my $pkg = $2;
		my $helper = $3; 
		my $function = $4; 
		
		$kz->load->helper($helper);
		
		no strict 'refs';
		my $result = $5 ? &{"$pkg\::$helper\::$function"}( split(/\s*,\s*/, $5) ) : &{"$pkg\::$helper\::$function"}();  
		
		$parsed =~ s/$self->{l_delim}\$.+::\w+::\w+\([^\)]*?\)$self->{r_delim}/$result/g;
	}
	
	$$template = $parsed; 
}



#
# _parse_includes
# given a template, replace embedded references to other files 
# with the contents of those files. this process may be recursive.
#
# arguments
#    \$template - contents of a template file containing items to be replaced
#
sub _parse_includes
{
	my $self = shift;
	my ($template) = @_; 
	
	# need this to load the helper packages
	my $kz = kbzb::get_instance(); 
	
	# make a copy we can use for replacements
	my $parsed = $$template; 
	
	# include blocks look like this: 
	# <delimiter>INCLUDE filename<delimiter>
	while ($$template =~ /($self->{l_delim}\s*INCLUDE\s+(\S+)\s*$self->{r_delim})/g)
	{
		my $replace_me = $1; 
		my $content = $kz->load->file($2, 1); 
		
		$content = $self->_parse_includes(\$content); 
		
		$parsed =~ s/$replace_me/$content/g;
	}
	
	$$template = $parsed; 
	
}



1; 

__END__

=pod

=head1 NAME

parser - parse view templates

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->parser so there is no need to 
re-instantiate it yourself. 

This package is responsible for substituting variables into templates. 
It is used internally by the L<kbzb::libraries::loader> package and there
is generally no need to interact with it yourself, except to change the
variable delimiters if you so choose. 

Variables in a template are delimited, by default, by curly braces, { and }, 
with the string between them being replaced by the value of the matching key
from the given hash. For example, given the following template: 

 $template = "I love {flavor} ice cream.";

and the following hash: 

 $hash = { flavor => 'chocolate' };

the following call: 

 $html = $self->parser->parse($template, $hash, 1); 
 
would result in the following being assigned to $html: 

 I love chocolate ice cream. 

=head1 SYNOPSIS

 # replace variables in $template with values from $hash. 
 # automatically append the result to the output stream.
 my $html = $self->parser->parse($template, $hash); 

 # same as above, except the result is returned only instead of
 # being tacked on to the output stream.
 my $html = $self->parser->parse($template, $hash, 1); 
 
 # set the left and right delimeters to something other than 
 # left and right curly braces, { }, respectively. 
 $self->parser->set_delimiters($l_delim, $r_delim)

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
