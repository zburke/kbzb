package kbzb::libraries::profiler;

# -- $Id: profiler.pm 161 2009-07-28 20:49:55Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;



sub new
{
	my $class = shift; 
	my $self  = {}; 
	
	bless $self, $class; 
	
	$self->{logger} = kbzb::libraries::common::load_class('logger');
	$self->{kz} = kbzb::get_instance(); 
	$self->{kz}->load->language('profiler');
	
	$self->{logger}->debug('Profiler Class Initialized');
	
	return $self; 
}



#
# Auto Profiler
#
# This function cycles through the entire array of mark points and
# matches any two points that are named identically (ending in "_start"
# and "_end" respectively).  It then compiles the execution times for
# all points and returns it as an array
#
# @access	private
# @return	array
#
sub _compile_benchmarks
{
	my $self = shift; 
	
	my @profile = ();
	my $bm = kbzb::libraries::common::load_class('benchmark');

	for (keys %{ $bm->{marker} })
	{
		print STDERR "BENCHMARK KEY IS $_\n"; 
		# We match the "end" marker so that the list ends
		# up in the order that it was defined
		if ($_ =~ /(.+?)_end/i)
		{ 			
			if (exists $bm->{marker}->{$1 . '_end'} && exists $bm->{marker}->{$1 . '_start'})
			{
				push @profile, {'key' => $1, 'time' => $bm->elapsed_time($1 . '_start', $_)}; 
			}
		}
	}

	# Build a table containing the profile data.
	# Note: At some point we should turn this into a template that can
	# be modified.  We also might want to make this data available to be logged

	my $output  = "\n\n";
	$output .= '<fieldset style="border:1px solid #990000;padding:6px 10px 10px 10px;margin:0 0 20px 0;background-color:#eee">';
	$output .= "\n";
	$output .= '<legend style="color:#990000;">&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_benchmarks').'&nbsp;&nbsp;</legend>';
	$output .= "\n";			
	$output .= "\n\n<table cellpadding='4' cellspacing='1' border='0' width='100%'>\n";
	
	for (@profile)
	{
		$_->{key} =~ s/_|-/ /g; 
		$output .= "<tr><td width='50%' style='color:#000;font-weight:bold;background-color:#ddd;'>".$_->{key}."&nbsp;&nbsp;</td><td width='50%' style='color:#990000;font-weight:normal;background-color:#ddd;'>".$_->{time} . "</td></tr>\n";
	}
	
	$output .= "</table>\n";
	$output .= "</fieldset>";
	
	return $output;
}



#
# Compile Queries
#
# @access	private
# @return	string
#	
sub _compile_queries
{
	my $self = shift; 
=cut	
	my @dbs = ();
	
	# Let's determine which databases are currently connected to
	foreach (get_object_vars($self->{kz}) as $CI_object)
	{
		if ( is_subclass_of(get_class($CI_object), 'CI_DB') )
		{
			$dbs[] = $CI_object;
		}
	}
				
	if (count($dbs) == 0)
	{
		$output  = "\n\n";
		$output .= '<fieldset style="border:1px solid #0000FF;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#eee">';
		$output .= "\n";
		$output .= '<legend style="color:#0000FF;">&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_queries').'&nbsp;&nbsp;</legend>';
		$output .= "\n";		
		$output .= "\n\n<table cellpadding='4' cellspacing='1' border='0' width='100%'>\n";
		$output .="<tr><td width='100%' style='color:#0000FF;font-weight:normal;background-color:#eee;'>".$self->{kz}->lang->line('profiler_no_db')."</td></tr>\n";
		$output .= "</table>\n";
		$output .= "</fieldset>";
		
		return $output;
	}
	
	# Load the text helper so we can highlight the SQL
	$self->{kz}->load->helper('text');

	# Key words we want bolded
	$highlight = array('SELECT', 'DISTINCT', 'FROM', 'WHERE', 'AND', 'LEFT&nbsp;JOIN', 'ORDER&nbsp;BY', 'GROUP&nbsp;BY', 'LIMIT', 'INSERT', 'INTO', 'VALUES', 'UPDATE', 'OR', 'HAVING', 'OFFSET', 'NOT&nbsp;IN', 'IN', 'LIKE', 'NOT&nbsp;LIKE', 'COUNT', 'MAX', 'MIN', 'ON', 'AS', 'AVG', 'SUM', '(', ')');

	$output  = "\n\n";
		
	foreach ($dbs as $db)
	{
		$output .= '<fieldset style="border:1px solid #0000FF;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#eee">';
		$output .= "\n";
		$output .= '<legend style="color:#0000FF;">&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_database').':&nbsp; '.$db->database.'&nbsp;&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_queries').': '.count($self->{kz}->db->queries).'&nbsp;&nbsp;&nbsp;</legend>';
		$output .= "\n";		
		$output .= "\n\n<table cellpadding='4' cellspacing='1' border='0' width='100%'>\n";
	
		if (count($db->queries) == 0)
		{
			$output .= "<tr><td width='100%' style='color:#0000FF;font-weight:normal;background-color:#eee;'>".$self->{kz}->lang->line('profiler_no_queries')."</td></tr>\n";
		}
		else
		{				
			foreach ($db->queries as $key => $val)
			{					
				$time = number_format($db->query_times[$key], 4);

				$val = highlight_code($val, ENT_QUOTES);

				foreach ($highlight as $bold)
				{
					$val = str_replace($bold, '<strong>'.$bold.'</strong>', $val);	
				}
				
				$output .= "<tr><td width='1%' valign='top' style='color:#990000;font-weight:normal;background-color:#ddd;'>".$time."&nbsp;&nbsp;</td><td style='color:#000;font-weight:normal;background-color:#ddd;'>".$val."</td></tr>\n";
			}
		}
		
		$output .= "</table>\n";
		$output .= "</fieldset>";
		
	}
	
	return $output;

=cut

	return ''; 
}


# --------------------------------------------------------------------

#
# Compile $_GET Data
#
# @access	private
# @return	string
#	
sub _compile_input
{
	my $self = shift; 
	
	my $output  = "\n\n";
	$output .= '<fieldset style="border:1px solid #cd6e00;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#eee">';
	$output .= "\n";
	$output .= '<legend style="color:#cd6e00;">&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_get_data').'&nbsp;&nbsp;</legend>';
	$output .= "\n";
	
	my $params = $kbzb::cgi->Vars; 
	if (! keys %$params)
	{
		$output .= "<div style='color:#cd6e00;font-weight:normal;padding:4px 0 4px 0'>".$self->{kz}->lang->line('profiler_no_get')."</div>";
	}
	else
	{
		$output .= "\n\n<table cellpadding='4' cellspacing='1' border='0' width='100%'>\n";
	
		for (sort keys %$params)
		{
			if ($_ !~ /^[0-9]+$/)
			{
				$_ = "'".$_."'";
			}
		
			$output .= "<tr><td width='50%' style='color:#000;background-color:#ddd;'>&#36;_GET[".$_."]&nbsp;&nbsp; </td><td width='50%' style='color:#cd6e00;font-weight:normal;background-color:#ddd;'>";
			if ('ARRAY' eq ref $params->{$_})
			{
				$output .= '<pre>' . (map { $self->escape_html($_) } @{ $params->{$_} } ) . '</pre>';
				
#@				htmlspecialchars(stripslashes(print_r($val, true))) . "</pre>";
			}
			else
			{
				$output .= $self->escape_html($params->{$_});
			}
			$output .= "</td></tr>\n";
		}
		
		$output .= "</table>\n";
	}
	$output .= "</fieldset>";

	return $output;	
}


sub escape_html
{
	my $self = shift;
	my ($html) = @_;
	
	my $escaped = $html; 
	
	$escaped =~ s/&/&amp;/g; 
	$escaped =~ s/"/&quot;/g; 
	$escaped =~ s/'/&#039;/g; 
	$escaped =~ s/</&lt;/g; 
	$escaped =~ s/>/&gt;/g; 
	
	return $escaped; 
	
}



#
# Show query string
#
# @access	private
# @return	string
#
sub _compile_uri_string
{
	my $self = shift; 
	
	my $output  = "\n\n";
	$output .= '<fieldset style="border:1px solid #000;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#eee">';
	$output .= "\n";
	$output .= '<legend style="color:#000;">&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_uri_string').'&nbsp;&nbsp;</legend>';
	$output .= "\n";
	
	if ($self->{kz}->uri->{uri_string} eq '')
	{
		$output .= "<div style='color:#000;font-weight:normal;padding:4px 0 4px 0'>".$self->{kz}->lang->line('profiler_no_uri')."</div>";
	}
	else
	{
		$output .= "<div style='color:#000;font-weight:normal;padding:4px 0 4px 0'>".$self->{kz}->uri->{uri_string} . "</div>";				
	}
	
	$output .= "</fieldset>";

	return $output;	
}



#
# Show the controller and function that were called
#
# @access	private
# @return	string
#	
sub _compile_controller_info
{
	my $self = shift; 
	
	my $output  = "\n\n";
	$output .= '<fieldset style="border:1px solid #995300;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#eee">';
	$output .= "\n";
	$output .= '<legend style="color:#995300;">&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_controller_info').'&nbsp;&nbsp;</legend>';
	$output .= "\n";
	
	$output .= "<div style='color:#995300;font-weight:normal;padding:4px 0 4px 0'>".$self->{kz}->router->fetch_class()."/".$self->{kz}->router->fetch_method()."</div>";				

	
	$output .= "</fieldset>";

	return $output;	
}



#
# Compile memory usage
#
# Display total used memory
#
# @access	public
# @return	string
#
sub _compile_memory_usage
{
	my $self = shift; 
	
	my $output  = "\n\n";
	$output .= '<fieldset style="border:1px solid #5a0099;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#eee">';
	$output .= "\n";
	$output .= '<legend style="color:#5a0099;">&nbsp;&nbsp;'.$self->{kz}->lang->line('profiler_memory_usage').'&nbsp;&nbsp;</legend>';
	$output .= "\n";
	
#@	if (function_exists('memory_get_usage') && ($usage = memory_get_usage()) != '')
#	{
#		$output .= "<div style='color:#5a0099;font-weight:normal;padding:4px 0 4px 0'>".number_format($usage).' bytes</div>';
#	}
#	else
#	{
		$output .= "<div style='color:#5a0099;font-weight:normal;padding:4px 0 4px 0'>".$self->{kz}->lang->line('profiler_no_memory_usage')."</div>";				
#	}
	
	$output .= "</fieldset>";

	return $output;
}



#
# Run the Profiler
#
# @access	private
# @return	string
#
sub run
{
	my $self = shift; 
	
	my $output = "<div id='codeigniter_profiler' style='clear:both;background-color:#fff;padding:10px;'>";

	$output .= $self->_compile_uri_string();
	$output .= $self->_compile_controller_info();
	$output .= $self->_compile_memory_usage();
	$output .= $self->_compile_benchmarks();
	$output .= $self->_compile_input();
	$output .= $self->_compile_queries();

	$output .= '</div>';

	return $output;
}

1;

__END__

=pod

=head1 NAME

profiler - display benchmark information to assist with debugging and optimization

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->input so there is no need to 
re-instantiate it yourself. 

The profiler is used internally by the L<kbzb::libraries::output> package to 
generate an HTML string containing various profile information, including all
benchmark values, the controller package and the method called on it, POST keys
and values, and the query string. Memory usage and database query profiling are 
not yet available. 

To include profile information in the pages rendered for the browser, enable the 
profiler on the output class: 

 $self->output->enable_profiler(1);	

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
