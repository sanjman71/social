$.fn.init_checkin_map = function() {
  // google docs: http://gmaps-utility-library.googlecode.com/svn/trunk/mapiconmaker/1.1/docs/reference.html
  $('#map').jMapping({
    location_selector: ".map-location.visible",
    category_icon_options: {
      'hot': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '40', width: '40'},
      'async': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '32', width: '32'},
      'default': {primaryColor: '#465AE0', height: '32', width: '32'}
    }
  });
  
  $("a#show_checkin_city").click(function() {
    // mark locations with the selected city as visible
    city_id = $(this).attr('data-city-id');
    $("#map-side-bar").find("div.map-location.visible").removeClass('visible');
    $("#map-side-bar").find("div.map-location[data-city-id='" + city_id + "']").addClass('visible');
    $("#map").jMapping('update');
    // mark link as current
    $("a#show_checkin_city").removeClass('current');
    $(this).addClass('current');
    return false;
  })

  // click on first city link
  $("a#show_checkin_city:first").click();
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

$.fn.init_tooltips = function() {
  $("a#badges_tip").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "bottom right",
                             offset: [0,0]});
  $("a#badges_tip").click(function() { return false; })
}

$(document).ready(function() {

  $(document).init_tooltips();

  $("a#show_my_spots").click(function() {
    $("div#checkin_map_prompt").hide();
    $("div#checkin_map_cities").show();
    $("div#checkin_map").show();
    $(document).init_checkin_map();
    return false;
  })

  try {
    // check growls
    if (growls.length > 0) { show_growls(growls); }
  } catch(e) { }
})
