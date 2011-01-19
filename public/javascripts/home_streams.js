var stream_picks        = ['checkins', 'todos'];
var stream_current      = '';
var stream_checkin_ids  = [];
var stream_todo_ids     = [];
var stream_shout_ids    = [];
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

$.fn.init_plan_checkin = function() {
  /*
  $(".stream .location, .stream .match, .stream .checkin").live('mouseover mouseout', function(event) {
    if (event.type == 'mouseover') {
      $(this).addClass('hover');
      // always show checkin links
      // $(this).find("#plan_location_wrapper,#user_toggle,#checkin_action_wrapper").show();
    } else {
      $(this).removeClass('hover');
      // $(this).find("#plan_location_wrapper,#user_toggle,#checkin_action_wrapper").hide();
    }
  })
  */

  // add checkin to todo list
  $("a#plan_checkin").live('click', function() {
    link  = $(this);
    path  = $(this).attr('data-path');

    if ($(this).hasClass('disabled')) {
      // already added
      return false;
    }

    // update interface
    $(link).text("Adding ...").addClass('disabled');
  
    $.put(path, {}, function(data) {
      // update interface
      $(link).text("Added");
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
    }, 'json');

    return false;
  })
}

$.fn.init_stream_timer = function() {

  if ($("#social-stream li").length > 0) {
    // initialize stream objects
    trackNotCountedObjects();
    // start interval timer
    startTimer();
  }

  function startTimer() {
    stream_timer_id = setInterval(addObjects, 5000);
    // console.log("stream timer id: " + stream_timer_id);
  }
  
  function stopTimer() {
    // console.log("cancelling interval timer");
    clearInterval(stream_timer_id);
  }

  // track not-counted visible objects
  function trackNotCountedObjects() {
    tracked = 0
    $("#social-stream li.checkin.visible.not-counted").each(function() {
      id = $(this).attr('data-id');
      stream_checkin_ids.push(id);
      $(this).removeClass('not-counted').addClass('counted');
      tracked += 1;
    })
    $("#social-stream li.todo.visible.not-counted").each(function() {
      id = $(this).attr('data-id');
      stream_todo_ids.push(id);
      $(this).removeClass('not-counted').addClass('counted');
      tracked += 1;
    })
    $("#social-stream li.shout.visible.not-counted").each(function() {
      id = $(this).attr('data-id');
      stream_shout_ids.push(id);
      $(this).removeClass('not-counted').addClass('counted');
      tracked += 1;
    })
    return tracked;
  }

  function numTotalCountedObjects() {
    return stream_checkin_ids.length + stream_todo_ids.length + stream_shout_ids.length;
  }

  function numCountedVisibleObjects() {
    return $("#social-stream li.counted").filter(":visible").length;
  }

  function numNotCountedHiddenObjects() {
    return $("#social-stream li.not-counted.hide").length;
  }

  function showNotCountedHiddenObject() {
    // show the last not counted hidden object with slidedown effect
    $("#social-stream li.not-counted.hide:last").slideDown(2000).addClass('visible').removeClass('hide');
  }

  function hideCountedVisibleObject() {
    // hide the last visible counted object
    $("#social-stream li.counted:visible:last").hide(1000);
  }

  // add unique objects
  function addObjects() {
    if (stream_updating) {
      // skip if stream is being updated
      // console.log("stream is updating");
      return;
    }
    // set updating flag
    stream_updating = true;

    // console.log("not-counted hidden: " + numNotCountedHiddenObjects());
    // console.log("counted visible: " + numCountedVisibleObjects());
    // console.log("counted total: " + numTotalCountedObjects());
    
    if (numNotCountedHiddenObjects() > 0) {
      // show a hidden not counted object
      showNotCountedHiddenObject();
      tracked = trackNotCountedObjects();
    } else {
      // no more objects, stop timer
      // console.log("stopping timer");
      stopTimer();
    }

    // check visible object count
    if (numCountedVisibleObjects() > max_visible) {
      // hide the last counted visible object
      hideCountedVisibleObject();
    }

    stream_updating = false;
    return;

    /*
    // pick the next stream url
    url = pickStream();

    $.getScript(url, function() {
      // track the un-counted objects
      tracked = trackNotCountedObjects();

      // remove the stream if there were no results
      if (tracked == 0) { removeStream(stream_current); }

      // check visible object count
      if (numCountedVisibleObjects() > max_visible) {
        // hide the last counted visible object
        hideCountedVisibleObject();
      }

      // reset updating flag
      stream_updating = false;

      // check total object count
      if (numTotalCountedObjects() >= max_objects) {
        // cancel timer
        stopTimer();
      }
    });
    */
  }

  function pickStream() {
    // randomly select the next object stream
    random = Math.floor(Math.random()*stream_picks.length)
    stream = stream_picks[random];

    if (stream == 'checkins') {
      url = geo_checkins_path+"?limit=1&sort_females=1&max_user_set=3&without_ids="+stream_checkin_ids.join(',');
    } else if (stream == 'todos') {
      url = geo_todos_path+"?limit=1&sort_females=1&max_user_set=3&without_ids="+stream_todo_ids.join(',');
    }

    // set current stream
    stream_current = stream;

    return url;
  }

  function removeStream(name) {
    // remove the selected stream
    stream_picks = $.grep(stream_picks, function(val) { return val != name; });
  }
}

$(document).ready(function() {
  $(document).init_plan_checkin();
  $(document).init_stream_map();
  $(document).init_stream_timer();
})