#!/usr/local/bin/perl -T

# --
# -- $Id: kbzb.cgi 160 2009-07-28 02:56:47Z zburke $
# --

# -----------------------------------------------------------------
# -- BASEPATH
# -----------------------------------------------------------------
#
# -- Full path to the directory containing kbzb.pm, i.e. where you
# -- installed kbzb, if you ran "make; make test; make install". 
# -- 
# -- NO TRAILING SLASH!

$config->{'BASEPATH'} = '/Users/zburke/workspace/kbzb/lib';



# ---------------------------------------------------------------
# APPLICATION PACKAGE NAME
# ---------------------------------------------------------------
#
# -- Name of your application package, i.e., name of the directory
# -- containing the application's config, controllers, errors, etc.
# -- directories. 
# -- 
# -- NO TRAILING SLASH!

$config->{'APPPKG'} = 'app';



# ---------------------------------------------------------------
# APPLICATION FOLDER PATH
# ---------------------------------------------------------------
#
# -- Full path to your application package, i.e. the directory
# -- containing the application package directory listed above.
# -- 
# -- NO TRAILING SLASH!

$config->{'APPPATH'} = '/Users/zburke/workspace/kbzb';



################################################################
#         END OF USER CONFIGURABLE SETTINGS                    #
################################################################

BEGIN 
{
	use strict; 
	use warnings; 
	use CGI;
	
	# -- container for config parameters
	our $config = {};

	# -- globally useful CGI object
	$config->{'cgi'} = $ENV{'MOD_PERL'} ? CGI->new(shift @_) : CGI->new();

	# -- full server path to this file, e.g. /var/httpd/www.somesite.org/htdocs/index.cgi
	$config->{'FCPATH'} = $ENV{SCRIPT_FILENAME} || '';

	# -- name of this file, e.g. index.cgi
	($config->{'INDEX_FILE'} = $config->{'FCPATH'}) =~ s/.*\///g;
	
	# Make %ENV safer
	delete @ENV{qw(IFS CDPATH ENV BASH_ENV PATH)};
}



# tack the kbzb libraries onto the front of Perl's include path,
# then start running
unshift @INC, $config->{'BASEPATH'};
require $config->{'BASEPATH'} . '/kbzb.pm';

kbzb::run($config); 



__END__

=pod

=head1 NAME

index.cgi - gather config parameters then run the framework workflow

=head1 DESCRIPTION

This script gathers configuration parameters (paths to the framework and 
application libraries) then passes control to the framework, which begins
by loading libraries and the requested controller, calling the requested
method on this controller, collecting output, and finally sending it to
the browser. 

To inject your own method calls at various points in this process without
hacking this core workflow, see L<kbzb::libraries::hooks>; to write your 
own controller see L<kbzb::libraries::controller>; to control how URLs are
routed, see L<kbzb::libraries::uri>. 

=head1 AUTHORS

Zak Burke (kbzbfw@gmail.com)

=head1 LICENSE

This script is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut