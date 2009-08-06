package kbzb::libraries::upload;

# -- $Id: upload.pm 156 2009-07-27 20:10:52Z zburke $

# --
# -- This code originally derived from CodeIgniter 1.7.1,
# -- Copyright (c) 2008, EllisLab, Inc.
# --



use strict;


#
# Constructor
#
# @access	public
#
sub new
{
	my $class = shift; 
	my $props = shift; 
	my $self  = {}; 
	
	bless $self, $class; 
	
	$self->{max_size}		= 0;
	$self->{max_width}		= 0;
	$self->{max_height}		= 0;
	$self->{max_filename}	= 0;
	$self->{allowed_types}	= "";
	$self->{file_temp}		= "";
	$self->{file_name}		= "";
	$self->{orig_name}		= "";
	$self->{file_type}		= "";
	$self->{file_size}		= "";
	$self->{file_ext}		= "";
	$self->{upload_path}	= "";
	$self->{overwrite}		= 0;
	$self->{encrypt_name}	= 0;
	$self->{is_image}		= 0;
	$self->{image_width}	= '';
	$self->{image_height}	= '';
	$self->{image_type}		= '';
	$self->{image_size_str}	= '';
	$self->{error_msg}		= ();
	$self->{mimes}			= ();
	$self->{remove_spaces}	= 1;
	$self->{xss_clean}		= 0;
	$self->{temp_prefix}	= "temp_file_";
	
	if ($props)
	{
		$self->initialize($props);
	}
	
	log_message('debug', "Upload Class Initialized");
	
	return $self; 
}

# --------------------------------------------------------------------
#
# Initialize preferences
#
# @access	public
# @param	array
# @return	void
#	
sub initialize($config = array())
{
	my $self = shift;
	my ($config) = @_; 
	
	my $defaults = {
						'max_size'			=> 0,
						'max_width'			=> 0,
						'max_height'		=> 0,
						'max_filename'		=> 0,
						'allowed_types'		=> "",
						'file_temp'			=> "",
						'file_name'			=> "",
						'orig_name'			=> "",
						'file_type'			=> "",
						'file_size'			=> "",
						'file_ext'			=> "",
						'upload_path'		=> "",
						'overwrite'			=> 0,
						'encrypt_name'		=> 0,
						'is_image'			=> 0,
						'image_width'		=> '',
						'image_height'		=> '',
						'image_type'		=> '',
						'image_size_str'	=> '',
						'error_msg'			=> (),
						'mimes'				=> (),
						'remove_spaces'		=> 1,
						'xss_clean'			=> 0,
						'temp_prefix'		=> "temp_file_"
					};	


	for (keys %{ $defaults })
	{
		if (exists $config->{$_})
		{
			my $callable = __PACKAGE__ . '::set_'.$_;
			
			if (defined &$callable)
			{
				$self->$callable($config->{$_});
			}
			else
			{
				$self->{$_} = $config->{$_};
			}			
		}
		else
		{
			$self->{$_} = $defaults->{$_};
		}
	}
}

# --------------------------------------------------------------------
#
# Perform the file upload
#
# @access	public
# @return	bool
#	
sub do_upload($field = 'userfile')
{
	# Is $_FILES[$field] set? If not, no reason to continue.
	if ( ! isset($_FILES[$field]))
	{
		$self->set_error('upload_no_file_selected');
		return FALSE;
	}
	
	# Is the upload path valid?
	if ( ! $self->validate_upload_path())
	{
		# errors will already be set by validate_upload_path() so just return FALSE
		return FALSE;
	}

	# Was the file able to be uploaded? If not, determine the reason why.
	if ( ! is_uploaded_file($_FILES[$field]['tmp_name']))
	{
		$error = ( ! isset($_FILES[$field]['error'])) ? 4 : $_FILES[$field]['error'];

		switch($error)
		{
			case 1:	// UPLOAD_ERR_INI_SIZE
				$self->set_error('upload_file_exceeds_limit');
				break;
			case 2: // UPLOAD_ERR_FORM_SIZE
				$self->set_error('upload_file_exceeds_form_limit');
				break;
			case 3: // UPLOAD_ERR_PARTIAL
			   $self->set_error('upload_file_partial');
				break;
			case 4: // UPLOAD_ERR_NO_FILE
			   $self->set_error('upload_no_file_selected');
				break;
			case 6: // UPLOAD_ERR_NO_TMP_DIR
				$self->set_error('upload_no_temp_directory');
				break;
			case 7: // UPLOAD_ERR_CANT_WRITE
				$self->set_error('upload_unable_to_write_file');
				break;
			case 8: // UPLOAD_ERR_EXTENSION
				$self->set_error('upload_stopped_by_extension');
				break;
			default :   $self->set_error('upload_no_file_selected');
				break;
		}

		return FALSE;
	}

	# Set the uploaded data as class variables
	$self->file_temp = $_FILES[$field]['tmp_name'];		
	$self->file_name = $self->_prep_filename($_FILES[$field]['name']);
	$self->file_size = $_FILES[$field]['size'];		
	$self->file_type = preg_replace("/^(.+?);.*$/", "\\1", $_FILES[$field]['type']);
	$self->file_type = strtolower($self->file_type);
	$self->file_ext	 = $self->get_extension($_FILES[$field]['name']);
	
	# Convert the file size to kilobytes
	if ($self->file_size > 0)
	{
		$self->file_size = round($self->file_size/1024, 2);
	}

	# Is the file type allowed to be uploaded?
	if ( ! $self->is_allowed_filetype())
	{
		$self->set_error('upload_invalid_filetype');
		return FALSE;
	}

	# Is the file size within the allowed maximum?
	if ( ! $self->is_allowed_filesize())
	{
		$self->set_error('upload_invalid_filesize');
		return FALSE;
	}

	# Are the image dimensions within the allowed size?
	# Note: This can fail if the server has an open_basdir restriction.
	if ( ! $self->is_allowed_dimensions())
	{
		$self->set_error('upload_invalid_dimensions');
		return FALSE;
	}

	# Sanitize the file name for security
	$self->file_name = $self->clean_file_name($self->file_name);
	
	# Truncate the file name if it's too long
	if ($self->max_filename > 0)
	{
		$self->file_name = $self->limit_filename_length($self->file_name, $self->max_filename);
	}

	# Remove white spaces in the name
	if ($self->remove_spaces == TRUE)
	{
		$self->file_name = preg_replace("/\s+/", "_", $self->file_name);
	}

	/*
# Validate the file name
# This function appends an number onto the end of
# the file if one with the same name already exists.
# If it returns false there was a problem.
#
	$self->orig_name = $self->file_name;

	if ($self->overwrite == FALSE)
	{
		$self->file_name = $self->set_filename($self->upload_path, $self->file_name);
		
		if ($self->file_name === FALSE)
		{
			return FALSE;
		}
	}

	/*
# Move the file to the final destination
# To deal with different server configurations
# we'll attempt to use copy() first.  If that fails
# we'll use move_uploaded_file().  One of the two should
# reliably work in most environments
#
	if ( ! @copy($self->file_temp, $self->upload_path.$self->file_name))
	{
		if ( ! @move_uploaded_file($self->file_temp, $self->upload_path.$self->file_name))
		{
			 $self->set_error('upload_destination_error');
			 return FALSE;
		}
	}
	
	/*
# Run the file through the XSS hacking filter
# This helps prevent malicious code from being
# embedded within a file.  Scripts can easily
# be disguised as images or other file types.
#
	if ($self->xss_clean == TRUE)
	{
		$self->do_xss_clean();
	}

	/*
# Set the finalized image dimensions
# This sets the image width/height (assuming the
# file was an image).  We use this information
# in the "data" function.
#
	$self->set_image_properties($self->upload_path.$self->file_name);

	return TRUE;
}

# --------------------------------------------------------------------
#
# Finalized Data Array
#	
# Returns an associative array containing all of the information
# related to the upload, allowing the developer easy access in one array.
#
# @access	public
# @return	array
#	
sub data()
{
	return array (
					'file_name'			=> $self->file_name,
					'file_type'			=> $self->file_type,
					'file_path'			=> $self->upload_path,
					'full_path'			=> $self->upload_path.$self->file_name,
					'raw_name'			=> str_replace($self->file_ext, '', $self->file_name),
					'orig_name'			=> $self->orig_name,
					'file_ext'			=> $self->file_ext,
					'file_size'			=> $self->file_size,
					'is_image'			=> $self->is_image(),
					'image_width'		=> $self->image_width,
					'image_height'		=> $self->image_height,
					'image_type'		=> $self->image_type,
					'image_size_str'	=> $self->image_size_str,
				);
}

# --------------------------------------------------------------------
#
# Set Upload Path
#
# @access	public
# @param	string
# @return	void
#	
sub set_upload_path($path)
{
	# Make sure it has a trailing slash
	$self->upload_path = rtrim($path, '/').'/';
}

# --------------------------------------------------------------------
#
# Set the file name
#
# This function takes a filename/path as input and looks for the
# existence of a file with the same name. If found, it will append a
# number to the end of the filename to avoid overwriting a pre-existing file.
#
# @access	public
# @param	string
# @param	string
# @return	string
#	
sub set_filename($path, $filename)
{
	if ($self->encrypt_name == TRUE)
	{		
		mt_srand();
		$filename = md5(uniqid(mt_rand())).$self->file_ext;	
	}

	if ( ! file_exists($path.$filename))
	{
		return $filename;
	}

	$filename = str_replace($self->file_ext, '', $filename);
	
	$new_filename = '';
	for ($i = 1; $i < 100; $i++)
	{			
		if ( ! file_exists($path.$filename.$i.$self->file_ext))
		{
			$new_filename = $filename.$i.$self->file_ext;
			break;
		}
	}

	if ($new_filename == '')
	{
		$self->set_error('upload_bad_filename');
		return FALSE;
	}
	else
	{
		return $new_filename;
	}
}

# --------------------------------------------------------------------
#
# Set Maximum File Size
#
# @access	public
# @param	integer
# @return	void
#	
sub set_max_filesize($n)
{
	$self->max_size = ((int) $n < 0) ? 0: (int) $n;
}

# --------------------------------------------------------------------
#
# Set Maximum File Name Length
#
# @access	public
# @param	integer
# @return	void
#	
sub set_max_filename($n)
{
	$self->max_filename = ((int) $n < 0) ? 0: (int) $n;
}

# --------------------------------------------------------------------
#
# Set Maximum Image Width
#
# @access	public
# @param	integer
# @return	void
#	
sub set_max_width($n)
{
	$self->max_width = ((int) $n < 0) ? 0: (int) $n;
}

# --------------------------------------------------------------------
#
# Set Maximum Image Height
#
# @access	public
# @param	integer
# @return	void
#	
sub set_max_height($n)
{
	$self->max_height = ((int) $n < 0) ? 0: (int) $n;
}

# --------------------------------------------------------------------
#
# Set Allowed File Types
#
# @access	public
# @param	string
# @return	void
#	
sub set_allowed_types($types)
{
	$self->allowed_types = explode('|', $types);
}

# --------------------------------------------------------------------
#
# Set Image Properties
#
# Uses GD to determine the width/height/type of image
#
# @access	public
# @param	string
# @return	void
#	
sub set_image_properties($path = '')
{
	if ( ! $self->is_image())
	{
		return;
	}

	if (function_exists('getimagesize'))
	{
		if (FALSE !== ($D = @getimagesize($path)))
		{	
			$types = array(1 => 'gif', 2 => 'jpeg', 3 => 'png');

			$self->image_width		= $D['0'];
			$self->image_height		= $D['1'];
			$self->image_type		= ( ! isset($types[$D['2']])) ? 'unknown' : $types[$D['2']];
			$self->image_size_str	= $D['3'];  // string containing height and width
		}
	}
}

# --------------------------------------------------------------------
#
# Set XSS Clean
#
# Enables the XSS flag so that the file that was uploaded
# will be run through the XSS filter.
#
# @access	public
# @param	bool
# @return	void
#
sub set_xss_clean($flag = FALSE)
{
	$self->xss_clean = ($flag == TRUE) ? TRUE : FALSE;
}

# --------------------------------------------------------------------
#
# Validate the image
#
# @access	public
# @return	bool
#	
sub is_image()
{
	# IE will sometimes return odd mime-types during upload, so here we just standardize all
	# jpegs or pngs to the same file type.

	$png_mimes  = array('image/x-png');
	$jpeg_mimes = array('image/jpg', 'image/jpe', 'image/jpeg', 'image/pjpeg');
	
	if (in_array($self->file_type, $png_mimes))
	{
		$self->file_type = 'image/png';
	}
	
	if (in_array($self->file_type, $jpeg_mimes))
	{
		$self->file_type = 'image/jpeg';
	}

	$img_mimes = array(
						'image/gif',
						'image/jpeg',
						'image/png',
					   );

	return (in_array($self->file_type, $img_mimes, TRUE)) ? TRUE : FALSE;
}

# --------------------------------------------------------------------
#
# Verify that the filetype is allowed
#
# @access	public
# @return	bool
#	
sub is_allowed_filetype()
{
	if (count($self->allowed_types) == 0 OR ! is_array($self->allowed_types))
	{
		$self->set_error('upload_no_file_types');
		return FALSE;
	}

	$image_types = array('gif', 'jpg', 'jpeg', 'png', 'jpe');

	foreach ($self->allowed_types as $val)
	{
		$mime = $self->mimes_types(strtolower($val));

		# Images get some additional checks
		if (in_array($val, $image_types))
		{
			if (getimagesize($self->file_temp) === FALSE)
			{
				return FALSE;
			}
		}

		if (is_array($mime))
		{
			if (in_array($self->file_type, $mime, TRUE))
			{
				return TRUE;
			}
		}
		else
		{
			if ($mime == $self->file_type)
			{
				return TRUE;
			}	
		}		
	}
	
	return FALSE;
}

# --------------------------------------------------------------------
#
# Verify that the file is within the allowed size
#
# @access	public
# @return	bool
#	
sub is_allowed_filesize()
{
	if ($self->max_size != 0  AND  $self->file_size > $self->max_size)
	{
		return FALSE;
	}
	else
	{
		return TRUE;
	}
}

# --------------------------------------------------------------------
#
# Verify that the image is within the allowed width/height
#
# @access	public
# @return	bool
#	
sub is_allowed_dimensions()
{
	if ( ! $self->is_image())
	{
		return TRUE;
	}

	if (function_exists('getimagesize'))
	{
		$D = @getimagesize($self->file_temp);

		if ($self->max_width > 0 AND $D['0'] > $self->max_width)
		{
			return FALSE;
		}

		if ($self->max_height > 0 AND $D['1'] > $self->max_height)
		{
			return FALSE;
		}

		return TRUE;
	}

	return TRUE;
}

# --------------------------------------------------------------------
#
# Validate Upload Path
#
# Verifies that it is a valid upload path with proper permissions.
#
#
# @access	public
# @return	bool
#	
sub validate_upload_path()
{
	if ($self->upload_path == '')
	{
		$self->set_error('upload_no_filepath');
		return FALSE;
	}
	
	if (function_exists('realpath') AND @realpath($self->upload_path) !== FALSE)
	{
		$self->upload_path = str_replace("\\", "/", realpath($self->upload_path));
	}

	if ( ! @is_dir($self->upload_path))
	{
		$self->set_error('upload_no_filepath');
		return FALSE;
	}

	if ( ! is_really_writable($self->upload_path))
	{
		$self->set_error('upload_not_writable');
		return FALSE;
	}

	$self->upload_path = preg_replace("/(.+?)\/*$/", "\\1/",  $self->upload_path);
	return TRUE;
}

# --------------------------------------------------------------------
#
# Extract the file extension
#
# @access	public
# @param	string
# @return	string
#	
sub get_extension($filename)
{
	$x = explode('.', $filename);
	return '.'.end($x);
}	

# --------------------------------------------------------------------
#
# Clean the file name for security
#
# @access	public
# @param	string
# @return	string
#		
sub clean_file_name($filename)
{
	$bad = array(
					"<!--",
					"-->",
					"'",
					"<",
					">",
					'"',
					'&',
					'$',
					'=',
					';',
					'?',
					'/',
					"%20",
					"%22",
					"%3c",		// <
					"%253c", 	// <
					"%3e", 		// >
					"%0e", 		// >
					"%28", 		// (
					"%29", 		// )
					"%2528", 	// (
					"%26", 		// &
					"%24", 		// $
					"%3f", 		// ?
					"%3b", 		// ;
					"%3d"		// =
				);
				
	$filename = str_replace($bad, '', $filename);

	return stripslashes($filename);
}

# --------------------------------------------------------------------
#
# Limit the File Name Length
#
# @access	public
# @param	string
# @return	string
#		
sub limit_filename_length($filename, $length)
{
	if (strlen($filename) < $length)
	{
		return $filename;
	}

	$ext = '';
	if (strpos($filename, '.') !== FALSE)
	{
		$parts		= explode('.', $filename);
		$ext		= '.'.array_pop($parts);
		$filename	= implode('.', $parts);
	}

	return substr($filename, 0, ($length - strlen($ext))).$ext;
}

# --------------------------------------------------------------------
#
# Runs the file through the XSS clean function
#
# This prevents people from embedding malicious code in their files.
# I'm not sure that it won't negatively affect certain files in unexpected ways,
# but so far I haven't found that it causes trouble.
#
# @access	public
# @return	void
#	
sub do_xss_clean()
{		
	$file = $self->upload_path.$self->file_name;
	
	if (filesize($file) == 0)
	{
		return FALSE;
	}

	if (($data = @file_get_contents($file)) === FALSE)
	{
		return FALSE;
	}
	
	if ( ! $fp = @fopen($file, FOPEN_READ_WRITE))
	{
		return FALSE;
	}

	$kz = kbzb::get_instance();	
	$data = $CI->input->xss_clean($data);
	
	flock($fp, LOCK_EX);
	fwrite($fp, $data);
	flock($fp, LOCK_UN);
	fclose($fp);
}

# --------------------------------------------------------------------
#
# Set an error message
#
# @access	public
# @param	string
# @return	void
#	
sub set_error($msg)
{
	$kz = kbzb::get_instance();	
	$CI->lang->load('upload');
	
	if (is_array($msg))
	{
		foreach ($msg as $val)
		{
			$msg = ($CI->lang->line($val) == FALSE) ? $val : $CI->lang->line($val);				
			$self->error_msg[] = $msg;
			log_message('error', $msg);
		}		
	}
	else
	{
		$msg = ($CI->lang->line($msg) == FALSE) ? $msg : $CI->lang->line($msg);
		$self->error_msg[] = $msg;
		log_message('error', $msg);
	}
}

# --------------------------------------------------------------------
#
# Display the error message
#
# @access	public
# @param	string
# @param	string
# @return	string
#	
sub display_errors($open = '<p>', $close = '</p>')
{
	$str = '';
	foreach ($self->error_msg as $val)
	{
		$str .= $open.$val.$close;
	}

	return $str;
}

# --------------------------------------------------------------------
#
# List of Mime Types
#
# This is a list of mime types.  We use it to validate
# the "allowed types" set by the developer
#
# @access	public
# @param	string
# @return	string
#	
sub mimes_types($mime)
{
	global $mimes;

	if (count($self->mimes) == 0)
	{
		if (@require_once(APPPATH.'config/mimes'.EXT))
		{
			$self->mimes = $mimes;
			unset($mimes);
		}
	}

	return ( ! isset($self->mimes[$mime])) ? FALSE : $self->mimes[$mime];
}

# --------------------------------------------------------------------
#
# Prep Filename
#
# Prevents possible script execution from Apache's handling of files multiple extensions
# http://httpd.apache.org/docs/1.3/mod/mod_mime.html#multipleext
#
# @access	private
# @param	string
# @return	string
#
sub _prep_filename($filename)
{
	if (strpos($filename, '.') === FALSE)
	{
		return $filename;
	}
	
	$parts		= explode('.', $filename);
	$ext		= array_pop($parts);
	$filename	= array_shift($parts);
			
	foreach ($parts as $part)
	{
		if ($self->mimes_types(strtolower($part)) === FALSE)
		{
			$filename .= '.'.$part.'_';
		}
		else
		{
			$filename .= '.'.$part;
		}
	}
	
	$filename .= '.'.$ext;
	
	return $filename;
}


