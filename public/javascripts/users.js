$.fn.init_checkin_map = function() {
  // google docs: http://gmaps-utility-library.googlecode.com/svn/trunk/mapiconmaker/1.1/docs/reference.html
  if (checkin_map) {
    $('#map').jMapping({
      category_icon_options: {
        'hot': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '40', width: '40'},
        'async': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '32', width: '32'},
        'default': {primaryColor: '#465AE0', height: '32', width: '32'}
      }
    });
  }
}

$.fn.init_match_pictures = function() {
  $("#pics").cycle({fx:'fade', timeout:5000, speed:1000, before:onBefore, after:onAfter});

  function onBefore() {
    $("#match #handle,#match #data,#match #matchby").html('');
  }
  
  function onAfter() {
    var handle  = $(this).attr('data-handle');
    var gender  = $(this).attr('data-gender');
    var city    = $(this).attr('data-city');
    var matchby = $(this).attr('data-matchby');
    var data    = gender + " / " + city;
    $("#match #handle").html(handle);
    $("#match #data").html(data);
    $("#match #matchby").html(matchby);
  }
}

$(document).ready(function() {
  $(document).init_checkin_map();

  try {
    // check growls
    if (growls.length > 0) { show_growls(growls); }
  } catch(e) { }
})
