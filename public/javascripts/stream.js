var stream_checkin_ids  = [];
var stream_timer_id     = 0;
var stream_updating     = false;

$.fn.init_stream_map = function() {
  // google docs: http://gmaps-utility-library.googlecode.com/svn/trunk/mapiconmaker/1.1/docs/reference.html
  if (stream_map) {
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
  $(".stream .location, .stream .match, .stream .checkin").live('mouseover mouseout', function(event) {
    if (event.type == 'mouseover') {
      $(this).addClass('hover');
      $(this).find("#plan_location_wrapper,#user_toggle,#checkin_action_wrapper").show();
    } else {
      $(this).removeClass('hover');
      $(this).find("#plan_location_wrapper,#user_toggle,#checkin_action_wrapper").hide();
    }
  })

  // deprecated: dialogs are deprecated on home page
  // initialize dialog
  //$("#meet_user_dialog").dialog({modal: true, autoOpen: false, width: 350, height: 150, show: 'fadeIn(slow)'});
  //$("#plan_location_dialog").dialog({modal: true, autoOpen: false, width: 350, height: 150, show: 'fadeIn(slow)'});

  // basic dialog for now
  /*
  $("a#meet_user").live('click', function() {
    handle = $(this).parents('.match').attr('data-handle');
    $("#meet_user_dialog #handle").text("We'll connect you with " + handle);
    $("#meet_user_dialog").dialog('open');
    return false;
  })
  */

  // 
  $("a#checkin_plan").live('click', function() {
    parent = $(this).parents(".checkin");
    path   = $(this).attr('data-path');
    // console.log("path: " + path);
    $.put(path, {}, function(data) {
      // update interface
      $(parent).find("#checkin_plan_pending").addClass('hide')
      $(parent).find("#checkin_plan_added").removeClass('hide');
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
    }, 'json');
    // update interface
    $(parent).find("#checkin_plan_pending").removeClass('hide');
    $(this).hide();
    //$("#plan_location_dialog").dialog('open');
    return false;
  })
}

$.fn.init_stream_timer = function() {

  if ($("div.stream div.checkin").length > 0) {
    // initialize stream checkins
    countCheckins();
    // console.log("initial stream: " + stream_checkin_ids.join(','));
    // start interval timer
    stream_timer_id = setInterval(addCheckins, 5000);
    // console.log("stream timer id: " + stream_timer_id);
  }

  function countCheckins() {
    $("div.stream div.checkin.not-counted").each(function() {
      id = $(this).attr('data-id');
      stream_checkin_ids.push(id);
      $(this).removeClass('not-counted').addClass('counted');
    })
  }

  // add unique checkins
  function addCheckins() {
    if (stream_updating) {
      // skip if stream is being updated
      // console.log("stream is updating");
      return;
    }
    stream_updating = true;
    $.getScript(geo_checkins_path+"?limit=1&order=default&without_checkin_ids="+stream_checkin_ids.join(','), function() {
      // find the most recent checkin(s)
      countCheckins();
      // console.log("current stream: " + stream_checkin_ids.join(','));
      stream_updating = false;
      if (stream_checkin_ids.length >= max_locations) {
        // cancel timer
        // console.log("cancelling interval timer");
        clearInterval(stream_timer_id);
      }
    });
  }
}

$.fn.init_tooltips = function() {
  $("a#map_wtf").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "bottom right",
                          offset: [-70, -250]});
  $("a#map_wtf").click(function() { return false; })
  $("a#suggestions_wtf").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "top right",
                                  offset: [0, 0]});
  $("a#suggestions_wtf").click(function() { return false; })
  $("a#outlately_wtf").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "top right",
                                offset: [0, 0]});
  $("a#outlately_wtf").click(function() { return false; })
}

$(document).ready(function() {
  $(document).init_stream_map();
  $(document).init_stream_objects();
  $(document).init_stream_timer();
  $(document).init_tooltips();
})