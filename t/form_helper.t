# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl kbzb.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 1;
#BEGIN { use_ok('kbzb::helpers::form', qw(
#form_open 
#form_open_multipart
#form_hidden
#form_input
#form_password
#form_upload
#form_textarea
#form_dropdown
#form_checkbox 
#form_radio
#form_submit
#form_reset
#form_button
#form_label
#form_fieldset
#form_fieldset_close
#form_prep
#set_select
#set_checkbox
#set_radio
#form_error
#validation_errors
#_parse_form_attributes
#_attributes_to_string
#_get_validation_object) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#is(form_open($action = '', $attributes = '', $hidden = array())('foo'), 'expected', 'testing form_open($action = '', $attributes = '', $hidden = array())');
#is(form_open_multipart($action, $attributes = array(), $hidden = array())('foo'), 'expected', 'testing form_open_multipart($action, $attributes = array(), $hidden = array())');
#is(form_hidden($name, $value = '')('foo'), 'expected', 'testing form_hidden($name, $value = '')');
#is(form_input($data = '', $value = '', $extra = '')('foo'), 'expected', 'testing form_input($data = '', $value = '', $extra = '')');
#is(form_password($data = '', $value = '', $extra = '')('foo'), 'expected', 'testing form_password($data = '', $value = '', $extra = '')');
#is(form_upload($data = '', $value = '', $extra = '')('foo'), 'expected', 'testing form_upload($data = '', $value = '', $extra = '')');
#is(form_textarea($data = '', $value = '', $extra = '')('foo'), 'expected', 'testing form_textarea($data = '', $value = '', $extra = '')');
#is(form_dropdown($name = '', $options = array(), $selected = array(), $extra = '')('foo'), 'expected', 'testing form_dropdown($name = '', $options = array(), $selected = array(), $extra = '')');
#is(form_checkbox($data = '', $value = '', $checked = FALSE, $extra = '')('foo'), 'expected', 'testing form_checkbox($data = '', $value = '', $checked = FALSE, $extra = '')');
#is(form_radio($data = '', $value = '', $checked = FALSE, $extra = '')('foo'), 'expected', 'testing form_radio($data = '', $value = '', $checked = FALSE, $extra = '')');
#is(form_submit($data = '', $value = '', $extra = '')('foo'), 'expected', 'testing form_submit($data = '', $value = '', $extra = '')');
#is(form_reset($data = '', $value = '', $extra = '')('foo'), 'expected', 'testing form_reset($data = '', $value = '', $extra = '')');
#is(form_button($data = '', $content = '', $extra = '')('foo'), 'expected', 'testing form_button($data = '', $content = '', $extra = '')');
#is(form_label($label_text = '', $id = '', $attributes = array())('foo'), 'expected', 'testing form_label($label_text = '', $id = '', $attributes = array())');
#is(form_fieldset($legend_text = '', $attributes = array())('foo'), 'expected', 'testing form_fieldset($legend_text = '', $attributes = array())');
#is(form_fieldset_close($extra = '')('foo'), 'expected', 'testing form_fieldset_close($extra = '')');
#is(form_close($extra = '')('foo'), 'expected', 'testing form_close($extra = '')');
#is(form_prep($str = '')('foo'), 'expected', 'testing form_prep($str = '')');
#is(set_value($field = '', $default = '')('foo'), 'expected', 'testing set_value($field = '', $default = '')');
#is(set_select($field = '', $value = '', $default = FALSE)('foo'), 'expected', 'testing set_select($field = '', $value = '', $default = FALSE)');
#is(set_checkbox($field = '', $value = '', $default = FALSE)('foo'), 'expected', 'testing set_checkbox($field = '', $value = '', $default = FALSE)');
#is(set_radio($field = '', $value = '', $default = FALSE)('foo'), 'expected', 'testing set_radio($field = '', $value = '', $default = FALSE)');
#is(form_error($field = '', $prefix = '', $suffix = '')('foo'), 'expected', 'testing form_error($field = '', $prefix = '', $suffix = '')');
#is(validation_errors($prefix = '', $suffix = '')('foo'), 'expected', 'testing validation_errors($prefix = '', $suffix = '')');
#is(_parse_form_attributes($attributes, $default)('foo'), 'expected', 'testing _parse_form_attributes($attributes, $default)');
#is(_attributes_to_string($attributes, $formtag = FALSE)('foo'), 'expected', 'testing _attributes_to_string($attributes, $formtag = FALSE)');
#is(&_get_validation_object()('foo'), 'expected', 'testing &_get_validation_object()');
