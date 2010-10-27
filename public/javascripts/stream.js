var stream_location_ids = new Array();
var stream_timer_id     = 0;
var stream_updating     = false;

$.fn.init_stream_map = function() {
  // google docs: http://gmaps-utility-library.googlecode.com/svn/trunk/mapiconmaker/1.1/docs/reference.html
  if (mapping) {
    $('#map').jMapping({
      category_icon_options: {
        'hot': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '40', width: '40'},
        'async': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '32', width: '32'},
        'default': {primaryColor: '#465AE0', height: '32', width: '32'}
      }
    });
  }
}

$.fn.init_stream_objects = function() {
  $(".stream .location, .stream .match").live('mouseover mouseout', function(event) {
    if (event.type == 'mouseover') {
      $(this).addClass('hover');
      $(this).find("#plan_location_wrapper,#user_toggle").show();
    } else {
      $(this).removeClass('hover');
      $(this).find("#plan_location_wrapper,#user_toggle").hide();
    }
  })

  // initialize dialog
  $("#meet_user_dialog").dialog({modal: true, autoOpen: false, width: 350, height: 150, show: 'fadeIn(slow)'});
  $("#plan_location_dialog").dialog({modal: true, autoOpen: false, width: 350, height: 150, show: 'fadeIn(slow)'});

  // basic dialog for now
  $("a#meet_user").live('click', function() {
    handle = $(this).parents('.match').attr('data-handle');
    $("#meet_user_dialog #handle").text("We'll connect you with " + handle);
    $("#meet_user_dialog").dialog('open');
    return false;
  })

  // 
  $("a#plan_location").live('click', function() {
    parent = $(this).parents(".location");
    path   = $(this).attr('data-path');
    // console.log("path: " + path);
    $.put(path, {}, function(data) {
      // update interface
      $(parent).find("#plan_location_pending").remove();
      $(parent).find("#plan_location_added").removeClass('hide');
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
    }, 'json');
    // update interface
    $(parent).find("#plan_location_pending").removeClass('hide');
    $(parent).find("#plan_location_wrapper").remove();
    //$("#plan_location_dialog").dialog('open');
    return false;
  })
}

$.fn.init_stream_timer = function() {

  if ($("div.stream div.location").length > 0) {
    // initialize stream locations
    $("div.stream div.location").each(function() {
      id = $(this).attr('data-id');
      stream_location_ids.push(id);
    })
    // console.log("initial stream: " + stream_location_ids.join(','));
    // start interval timer
    stream_timer_id = setInterval(addLocations, 3000);
    // console.log("stream timer id: " + stream_timer_id);
  }

  // add unique locations
  function addLocations() {
    if (stream_updating) {
      // skip if stream is being updated
      // console.log("stream is updating");
      return;
    }
    stream_updating = true;
    $.getScript(geo_locations_path+"?limit=1&without_location_ids="+stream_location_ids.join(','), function() {
      // find the most recent location
      location_id = $("div.stream div.location").first().attr('data-id');
      stream_location_ids.push(location_id);
      // console.log("current stream: " + stream_location_ids.join(','));
      stream_updating = false;
      if (stream_location_ids.length >= max_locations) {
        // cancel timer
        // console.log("cancelling interval timer");
        clearInterval(stream_timer_id);
      }
    });
  }
}

$(document).ready(function() {
  $(document).init_stream_map();
  $(document).init_stream_objects();
  $(document).init_stream_timer();
})