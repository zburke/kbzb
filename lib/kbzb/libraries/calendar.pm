package kbzb::libraries::calendar;

# -- $Id: calendar.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict;
use POSIX; 


#
# new
# load the calendar's language file and set the default time reference
sub new
{
	my $class = shift; 
	
	my $self = {}; 
	my $input = shift; 
	
	bless $self, $class;
	
	$self->{logger} = kbzb::libraries::common::load_class('logger');
	
	$self->{kz} = kbzb::get_instance(); 

	$self->{kz}->lang->load('calendar');

	$self->{local_time} = time; 
	
	$self->{template}       = $input->{template}; 
	$self->{start_day}      = $input->{start_day} || 'sunday'; 
	$self->{month_type}     = $input->{month_type} || 'long'; 
	$self->{day_type}       = $input->{day_type} || 'abr'; 
	$self->{show_next_prev} = $input->{show_next_prev}; 
	$self->{next_prev_url}  = $input->{next_prev_url} ; 

	
	$self->{logger}->debug('Calendar Class Initialized'); 
	
	return $self; 
}




#
# generate
# return an HTML string containing a calendar
#
# arguments
#    $int year
#    $int month
#    $hashref data for calendar cells, with dates as keys
#
# return 
#     $string HTML calendar
#
sub generate
{
	my $self = shift; 
	my ($year, $month, $data) = @_; 
	
	my @list = localtime();
	
	my ($lsec,$lmin,$lhour,$lmday,$lmon,$lyear,$lwday,$lyday,$lisdst) = localtime; 
	
	$year  ||= $lyear + 1900;
	$month ||= $lmon + 1; 
	if (1 == length "$month") { $month = '0' . $month; }
	
	($month, $year) = $self->adjust_date($month, $year);
	
	# Determine the total days in the month
	my $total_days = $self->get_total_days($month, $year);
					
	# Set the starting day of the week
	my $start_days = {'sunday' => 0, 'monday' => 1, 'tuesday' => 2, 'wednesday' => 3, 'thursday' => 4, 'friday' => 5, 'saturday' => 6};
	my $start_day = $start_days->{$self->{start_day}} || 0;
	
	# Set the starting day offset
	my @start_list = localtime(POSIX::mktime(0, 0, 12, 1, $month, $year)); 
	my $day = $start_day + 1 - $start_list[6];
	
	while ($day > 1)
	{
		$day -= 7;
	}
	
	# Set the current month/year/day
	# We use this to determine the "today" date
	my ($cur_sec,$cur_min,$cur_hour,$cur_day,$cur_month,$cur_year,$cur_wday,$cur_yday,$cur_isdst) = localtime($self->{local_time}); 
	$cur_year += 1900; 
	$cur_month += 1; 
	
	my $is_current_month = ($cur_year == $year && $cur_month == $month) ? 1 : 0;

	# Generate the template data array
	$self->parse_template();
	
	
	# Begin building the calendar output
	my $out = $self->{temp}->{table_open} . "\n\n" . $self->{temp}->{heading_row_start} . "\n";
	
	# "previous" month link
	if ($self->{show_next_prev})
	{
		# Add a trailing slash to the  URL if needed
		$self->{next_prev_url} =~ s/(.+?)\/*$/$1/;
	
		my ($a_month, $a_year) = $self->adjust_date($month - 1, $year);
		
		(my $tmp = $self->temp->{heading_previous_cell}) =~ s/\{previous_url\}/$self->next_prev_url$a_year\/$a_month/; 
		$out .= "$tmp\n";
	}

	# Heading containing the month/year
	my $colspan = $self->{show_next_prev} ? 5 : 7;
	
	my $month_name = $self->get_month_name($month);
	
	$self->{temp}->{heading_title_cell} =~ s/\{colspan\}/$colspan/;
	$self->{temp}->{heading_title_cell} =~ s/\{heading\}/$month_name&nbsp;$year/;
	
	$out .= $self->{temp}->{heading_title_cell} . "\n";

	# "next" month link
	if ($self->{show_next_prev})
	{
		my ($a_month, $a_year) = $self->adjust_date($month + 1, $year);
		(my $tmp = $self->{temp}->{heading_next_cell}) =~ s/\{next_url\}/$self->next_prev_url$a_year\/$a_month/; 

		$out .= $tmp;
	}

	$out .= "\n" . $self->{temp}->{heading_row_end} . "\n";

	# Write the cells containing the days of the week
	$out .= "\n" . $self->{temp}->{week_row_start} . "\n";

	my $day_names = $self->get_day_names();

	for (my $i = 0; $i < 7; $i ++)
	{
		my $name = $$day_names[($start_day + $i) %7];
		(my $tmp = $self->{temp}->{week_day_cell}) =~ s/\{week_day\}/$name/; 
		$out .= $tmp;
	}

	$out .= "\n" . $self->{temp}->{week_row_end} . "\n";

	# Build the main body of the calendar
	while ($day <= $total_days)
	{
		$out .= "\n";
		$out .= $self->{temp}->{cal_row_start};
		$out .= "\n";

		for (my $i = 0; $i < 7; $i++)
		{
			$out .= ($is_current_month && $day == $cur_day) ? $self->{temp}->{cal_cell_start_today} : $self->{temp}->{cal_cell_start};

			if ($day > 0 && $day <= $total_days)
			{ 					
				if ($data->{$day})
				{	
					# Cells with content
					my $temp = ($is_current_month && $day == $cur_day) ? $self->{temp}->{cal_cell_content_today} : $self->{temp}->{cal_cell_content};
					$temp =~ s/\{content\}/$data->{$i}/; 
					$temp =~ s/\{day\}/$day/; 
				}
				else
				{
					# Cells with no content
					my $temp = ($is_current_month && $day == $cur_day) ? $self->{temp}->{cal_cell_no_content_today} : $self->{temp}->{cal_cell_no_content};
					$temp =~ s/\{day\}/$day/; 
					$out .= $temp;
				}
			}
			else
			{
				# Blank cells
				$out .= $self->{temp}->{cal_cell_blank};
			}
			
			$out .= ($is_current_month && $day == $cur_day) ? $self->{temp}->{cal_cell_end_today} : $self->{temp}->{cal_cell_end};
			$day++;
		}
		
		$out .= "\n";		
		$out .= $self->{temp}->{cal_row_end};
		$out .= "\n";		
	}

	$out .= "\n";		
	$out .= $self->{temp}->{table_close};

	return $out;

}



#
# get_month_name
# get a month's name given its number, 1-based
#
# arguments
#    $int month
#
# return
#     $string name of the month, from the language file
#
sub get_month_name
{
	my $self = shift; 
	
	my ($month) = @_; 
	
	my $month_names = {};
	if ('short' eq $self->{month_type})
	{
		$month_names = {'01' => 'cal_jan', '02' => 'cal_feb', '03' => 'cal_mar', '04' => 'cal_apr', '05' => 'cal_may', '06' => 'cal_jun', '07' => 'cal_jul', '08' => 'cal_aug', '09' => 'cal_sep', '10' => 'cal_oct', '11' => 'cal_nov', '12' => 'cal_dec'};
	}
	else
	{
		$month_names = {'01' => 'cal_january', '02' => 'cal_february', '03' => 'cal_march', '04' => 'cal_april', '05' => 'cal_may', '06' => 'cal_june', '07' => 'cal_july', '08' => 'cal_august', '09' => 'cal_september', '10' => 'cal_october', '11' => 'cal_november', '12' => 'cal_december'};
	}
	
	$month = $month_names->{$month};
	
	if (! $self->{kz}->lang->line($month))
	{
		$month =~ s/cal_//; 
		return ucfirst $month; 
	}

	return $self->{kz}->lang->line($month);
}



#
# get_day_names
# returns a list of daynames
#
# arguments
#     $string enum(long, short, abrev)
#
# return
#     $arrayref
#
sub get_day_names
{
	my $self = shift;
	
	my ($day_type) = @_; 	

	my $day_names; 
	if ('long' eq $day_type)
	{
		$self->{day_type} = $day_type;
		$day_names = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
	}
	elsif ('short' eq $day_type)
	{
		$self->{day_type} = $day_type;
		$day_names = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
	}
	else
	{
		$self->{day_type} = 'abrev';
		$day_names = ['su', 'mo', 'tu', 'we', 'th', 'fr', 'sa'];
	}

	my $days = [];
	foreach (@$day_names)
	{
		push @$days, $self->{kz}->lang->line('cal_'.$_) || ucfirst $_;
	}

	return $days;
}



#
# adjust_date
# make sure all date parameters are valid, e.g. if month is 13, 
# increment year and set month to 1.
#
# arguments
#     $int month
#     $int year
#
# return
#     list containing two values: month, year
#
sub adjust_date
{
	my $self = shift;
	my ($month, $year) = @_; 
	
	my $date = {};
	
	$date->{month}	= $month;
	$date->{year}	= $year;

	while ($date->{month} > 12)
	{
		$date->{month} -= 12;
		$date->{year}++;
	}

	while ($date->{month} <= 0)
	{
		$date->{month} += 12;
		$date->{year}--;
	}

	if (1 eq length $date->{month})
	{
		$date->{month} = '0' . $date->{month};
	}

	return ($date->{month}, $date->{year});
}



#
# get_total_days_in_month
# arguments
#     $int month, 1-indexed
#     $int year
sub get_total_days
{
	my $self = shift; 
	my ($month, $year) = @_; 
	

	if ($month < 1 || $month > 12)
	{
		return 0;
	}

	# Is the year a leap year?
	if ($month == 2)
	{
		if ($year % 400 == 0 || ($year % 4 == 0 && $year % 100 != 0))
		{
			return 29;
		}
	}

	my @days_in_month = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	return $days_in_month[$month - 1];
}



#
# default_template
# set template data, in the case that a template is not provided
#
# return
#     $hashref 
#
sub default_template
{
	my $self = shift;
	return  {
					'table_open' 				=> '<table border="0" cellpadding="4" cellspacing="0">',
					'heading_row_start' 		=> '<tr>',
					'heading_previous_cell'		=> '<th><a href="{previous_url}">&lt;&lt;</a></th>',
					'heading_title_cell' 		=> '<th colspan="{colspan}">{heading}</th>',
					'heading_next_cell' 		=> '<th><a href="{next_url}">&gt;&gt;</a></th>',
					'heading_row_end' 			=> '</tr>',
					'week_row_start' 			=> '<tr>',
					'week_day_cell' 			=> '<td>{week_day}</td>',
					'week_row_end' 				=> '</tr>',
					'cal_row_start' 			=> '<tr>',
					'cal_cell_start' 			=> '<td>',
					'cal_cell_start_today'		=> '<td>',
					'cal_cell_content'			=> '<a href="{content}">{day}</a>',
					'cal_cell_content_today'	=> '<a href="{content}"><strong>{day}</strong></a>',
					'cal_cell_no_content'		=> '{day}',
					'cal_cell_no_content_today'	=> '<strong>{day}</strong>',
					'cal_cell_blank'			=> '&nbsp;',
					'cal_cell_end'				=> '</td>',
					'cal_cell_end_today'		=> '</td>',
					'cal_row_end'				=> '</tr>',
					'table_close'				=> '</table>'
	};	
}



#
# parse_template
# harvest templates placeholders, e.g. {key}, for display
#
sub parse_template
{
	my $self = shift; 
	
	$self->{temp} = $self->default_template();

	if (! $self->{template})
	{
		return;
	}
	
	my @today = ('cal_cell_start_today', 'cal_cell_content_today', 'cal_cell_no_content_today', 'cal_cell_end_today');
	
	foreach (('table_open', 'table_close', 'heading_row_start', 'heading_previous_cell', 'heading_title_cell', 'heading_next_cell', 'heading_row_end', 'week_row_start', 'week_day_cell', 'week_row_end', 'cal_row_start', 'cal_cell_start', 'cal_cell_content', 'cal_cell_no_content',  'cal_cell_blank', 'cal_cell_end', 'cal_row_end', 'cal_cell_start_today', 'cal_cell_content_today', 'cal_cell_no_content_today', 'cal_cell_end_today'))
	{
		if ($self->{template} =~ /\{$_\}(.*?)\{\/$_\}/si)
		{
			$self->{temp}->{$_} = $1;
		}
		else
		{
			if (grep /^$_$/, @today)
			{
				(my $content = $_) =~ s/_today//g; 
				$self->{temp}->{$_} = $content;
			}
		}
	} 	
}



1;

__END__


=pod

=head1 NAME

calendar - display an HTML calendar for a given month

=head1 DESCRIPTION

 # from within a controller ... 
 $self->load->library('calendar');

 # print this month's calendar, with a note on the 10th
 %hash{10} = "information for the 10th"; 	
 $self->output->append_output($self->calendar->generate(undef, undef, \%hash));
 
 # print December 2006 calendar, with a note on the 14th
 %hash{14} = "information for the 14th"; 	
 $self->output->append_output($self->calendar->generate(2006, 12, \%hash));
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
