package kbzb::libraries::pagination;

# -- $Id: pagination.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --

use strict;
use POSIX; 


sub new
{
	my $class = shift;
	my $params = shift; 
	my $self = {}; 
	
	bless $self, $class; 
	
	$self->{logger} = kbzb::libraries::common::load_class('logger'); 
	
	if ($params)
	{
		$self->initialize($params);		
	}
	
	$self->{base_url}			= ''; # The page we are linking to
	$self->{total_rows}  		= ''; # Total number of items (database results)
	$self->{per_page}	 		= 10; # Max number of items you want shown per page
	$self->{num_links}			=  2; # Number of "digit" links to show before/after the currently viewed page
	$self->{cur_page}	 		=  0; # The current page being viewed
	$self->{first_link}   		= '&lsaquo; First';
	$self->{next_link}			= '&gt;';
	$self->{prev_link}			= '&lt;';
	$self->{last_link}			= 'Last &rsaquo;';
	$self->{uri_segment}		= 3;
	$self->{full_tag_open}		= '';
	$self->{full_tag_close}		= '';
	$self->{first_tag_open}		= '';
	$self->{first_tag_close}	= '&nbsp;';
	$self->{last_tag_open}		= '&nbsp;';
	$self->{last_tag_close}		= '';
	$self->{cur_tag_open}		= '&nbsp;<strong>';
	$self->{cur_tag_close}		= '</strong>';
	$self->{next_tag_open}		= '&nbsp;';
	$self->{next_tag_close}		= '&nbsp;';
	$self->{prev_tag_open}		= '&nbsp;';
	$self->{prev_tag_close}		= '';
	$self->{num_tag_open}		= '&nbsp;';
	$self->{num_tag_close}		= '';
	$self->{page_query_string}	= 0;
	$self->{query_string_segment} = 'per_page';

	$self->{logger}->debug('Pagination Class Initialized');
	
	return $self; 
}



#
# Initialize Preferences
#
# @access	public
# @param	array	initialization parameters
# @return	void
#
sub initialize
{
	my $self = shift;
	my ($config) = @_; 
	
	for (keys %$config)
	{
		if (exists $self->{$_})
		{
			$self->{$_} = $config->{$_};
		}
	}
}



#
# Generate the pagination links
#
# @access	public
# @return	string
#	
sub create_links
{
	my $self = shift; 
	
	# If our item count or per-page total is zero there is no need to continue.
	if ($self->{total_rows} == 0 || $self->{per_page} == 0)
	{
	   return '';
	}

	# Calculate the total number of pages
	my $num_pages = POSIX::ceil($self->{total_rows} / $self->{per_page});

	# nothing to do for a single page
	if ($num_pages == 1)
	{
		return '';
	}

	# Determine the current page number.		
	my $kz = kbzb::get_instance();
	
	if ($kz->config->item('enable_query_strings') || $self->{page_query_string})
	{
		if ($kz->input->get($self->{query_string_segment}))
		{
			$self->{cur_page} = $kz->input->get($self->{query_string_segment});
			
			# Prep the current page - no funny business!
			$self->{cur_page} = int $self->{cur_page};
		}
	}
	else
	{
		if ($kz->uri->segment($self->{uri_segment}))
		{
			$self->{cur_page} = $kz->uri->segment($self->{uri_segment});
			
			# Prep the current page - no funny business!
			$self->{cur_page} = int $self->{cur_page};
		}
	}

	$self->{num_links} = int $self->{num_links};
	
	if ($self->{num_links} < 1)
	{
		die('Your number of links must be a positive number.');
	}
			
	if ($self->{cur_page} !~ /[0-9]+/)
	{
		$self->{cur_page} = 0;
	}
	
	# Is the page number beyond the result range?
	# If so we show the last page
	if ($self->{cur_page} > $self->{total_rows})
	{
		$self->{cur_page} = ($num_pages - 1) * $self->{per_page};
	}
	
	my $uri_page_number = $self->{cur_page};
	$self->{cur_page} = floor(($self->{cur_page}/$self->{per_page}) + 1);

	# Calculate the start and end numbers. These determine
	# which number to start and end the digit links with
	my $start = (($self->{cur_page} - $self->{num_links}) > 0) ? $self->{cur_page} - ($self->{num_links} - 1) : 1;
	my $end   = (($self->{cur_page} + $self->{num_links}) < $num_pages) ? $self->{cur_page} + $self->{num_links} : $num_pages;

	# Is pagination being used over GET or POST?  If get, add a per_page query
	# string. If post, add a trailing slash to the base URL if needed
	if ($kz->config->item('enable_query_strings') || $self->{page_query_string})
	{
		$self->{base_url} =~ s/\s*$//g;
		$self->{base_url} .= '&amp;' . $self->{query_string_segment} . '=';
	}
	else
	{
		$self->{base_url} =~ s/\/*$//g;
		$self->{base_url} .= '/';
	}

	# And here we go...
	my $output = '';

	# Render the "First" link
	if  ($self->{cur_page} > ($self->{num_links} + 1))
	{
		$output .= $self->{first_tag_open}.'<a href="'.$self->{base_url}.'">'.$self->{first_link}.'</a>'.$self->{first_tag_close};
	}

	# Render the "previous" link
	my $i = 0; 
	if ($self->{cur_page} != 1)
	{
		$i = $uri_page_number - $self->{per_page};
		if ($i == 0) 
		{
			$i = '';
		}
		$output .= $self->{prev_tag_open}.'<a href="'.$self->{base_url}.$i.'">'.$self->{prev_link}.'</a>'.$self->{prev_tag_close};
	}

	# Write the digit links
	for (my $loop = $start -1; $loop <= $end; $loop++)
	{
		$i = ($loop * $self->{per_page}) - $self->{per_page};
				
		if ($i >= 0)
		{
			if ($self->{cur_page} == $loop)
			{
				$output .= $self->{cur_tag_open}.$loop.$self->{cur_tag_close}; # Current page
			}
			else
			{
				my $n = ($i == 0) ? '' : $i;
				$output .= $self->{num_tag_open}.'<a href="'.$self->{base_url}.$n.'">'.$loop.'</a>'.$self->{num_tag_close};
			}
		}
	}

	# Render the "next" link
	if ($self->{cur_page} < $num_pages)
	{
		$output .= $self->{next_tag_open}.'<a href="'.$self->{base_url}.($self->{cur_page} * $self->{per_page}).'">'.$self->{next_link}.'</a>'.$self->{next_tag_close};
	}

	# Render the "Last" link
	if (($self->{cur_page} + $self->{num_links}) < $num_pages)
	{
		$i = (($num_pages * $self->{per_page}) - $self->{per_page});
		$output .= $self->{last_tag_open}.'<a href="'.$self->{base_url}.$i.'">'.$self->{last_link}.'</a>'.$self->{last_tag_close};
	}

	# Kill double slashes.  Note: Sometimes we can end up with a double slash
	# in the penultimate link so we'll kill all double slashes.
	$output =~ s/([^:])\/\/+/$1/;  

	# Add the wrapper HTML if exists
	$output = $self->{full_tag_open} . $output . $self->{full_tag_close};
	
	return $output;		
}


1;

__END__


=pod

=head1 NAME

pagination - create HTML links to navigate through a multi-page result set

=head1 DESCRIPTION

 $self->load->library('pagination');

 my $config = {}; 
 $config->{base_url} = 'http://example.org/index.cgi/test/page/';
 $config->{total_rows} = '800';
 $config->{per_page} = '20';

 $self->pagination->initialize($config);

 $self->output->append_output($self->pagination->create_links());

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
