package kbzb::helpers::language;

# -- $Id: language.pm 156 2009-07-27 20:10:52Z zburke $

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
our %EXPORT_TAGS = ( 'all' => [ qw(lang) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
        
);




# ------------------------------------------------------------------------
# Language Helpers


# ------------------------------------------------------------------------
# Lang
#
# Fetches a language variable and optionally outputs a form label
#
# @access	public
# @param	string	the language line
# @param	string	the id of the form element
# @return	string
#
sub lang
{
	my ($line, $id) = @_;
	
	$id && return '<label for="'.$id.'">'.kbzb::get_instance()->lang->line($line).'</label>';

	return $line;
}


1;


__END__




=pod

=head1 NAME

language - fetch values from a language file.

=head2 USAGE

 # load the helper from within a controller ... 
 $self->load->helper('language');
 
 # retrieve value from a language file
 $string = lang('some_key'); 
 
 # retrieve value from a language file, wrapped in an HTML <label for="id"> tag
 $string = lang('some_key', 'id_1234');
 
=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut
