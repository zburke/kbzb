package kbzb::libraries::language; 

# -- $Id: language.pm 169 2009-08-05 12:56:17Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --


use strict; 

sub new
{
	my $class = shift; 
	my $self = {};
	
	bless($self, $class); 
	
	$self->{language} = {};
	$self->{is_loaded} = {}; 
	
	$self->{logger} = kbzb::libraries::common::load_class('logger');
	
	$self->{logger}->debug('Language Class Initialized');
	return $self;
}



#
# Load a language file
#
# arguments
#    the name of the language file to be loaded. Can be an array
#     string	the language (english, etc.)
sub load
{
	my $self = shift;
	my ($langfile, $idiom, $return) = @_; 
	
	$langfile .= '_lang.properties';
	
	if ($self->{is_loaded}->{$langfile})
	{
		return;
	}
	if (! $idiom)
	{
		my $kz = kbzb::get_instance();
		$idiom = $kz->config->item('language') || 'english';
	}
	
	my $lang = undef;
	if (-f kbzb::PKGPATH() . 'language/' . $idiom . '/' . $langfile)
	{
		$lang = $self->read_lang(kbzb::PKGPATH() . 'language/' . $idiom . '/' . $langfile);
	}
	else
	{
		if (-f kbzb::BASEPATH() . 'kbzb/language/' . $idiom . '/' . $langfile)
		{
			$lang = $self->read_lang(kbzb::BASEPATH() . 'kbzb/language/' . $idiom . '/' . $langfile);
		}
		else
		{
			die('Unable to load the requested language file: language/'.$langfile);
		}
	}
	
	if (! scalar keys %{ $lang })
	{
		$self->{logger}->error('Language file contains no data: language/'.$idiom.'/'.$langfile);
		return;	
	}
	
	if ($return)
	{
		return $lang;
	}

	$self->{is_loaded}->{$langfile} = 1; 
	
	for (keys %{ $lang })
	{
		$self->{language}->{$_} = $lang->{$_};
	}
	
	$self->{logger}->debug('Language file loaded: language/'.$idiom.'/'.$langfile);
	return 1;
	
}



#
# read_lang
# parse and return a language file
#
sub read_lang
{
	my $self = shift; 
	my $filepath = shift; 
	
	my $hash = {};
	
	open(CONFIG, "<$filepath") or die "The configuration file '$filepath' does not exist. $!\n";
	while (<CONFIG>)
	{
		chomp;
		next if $_ =~ /^#/;	
		next if $_ =~ /^\s*$/;

		my ($key, $val) = split(/\s*=\s*/, $_); 
		$hash->{$key} = $val;

	}
	close CONFIG;
	
	return $hash;
}


	

#
# line
# retrieve a single entry from a loaded language file
#
sub line
{
	my $self = shift; 
	my $line = shift; 
	
	return $self->{language}->{$line} || undef;
}

1; 

__END__


=pod

=head1 NAME

language - provide easy access to language config files

=head1 DESCRIPTION

This package is automatically loaded by the controller parent class and
is available on the controller as $self->lang so there is no need to 
re-instantiate it yourself. 


 # load the calendar_lang.properties language file
 $self->load->language('calendar'); 

 # load the french calendar_lang.properties language file
 $self->load->language('calendar', 'french'); 

 # retrieve a value
 $string = $self->language->line('some_key'); 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
