var stream_picks        = ['checkins', 'todos'];
var stream_current      = '';
var stream_checkin_ids  = [];
var stream_todo_ids     = [];
var stream_shout_ids    = [];
var stream_timer_id     = 0;
var stream_updating     = false;
var stream_paused       = false;

function pauseTimer() {
  // console.log("pausing interval timer");
  stream_paused = true;
}

function unpauseTimer() {
  // console.log("unpausing interval timer");
  stream_paused = false;
}

$.fn.init_stream_invites = function() {
  $("a#invite_user").live('click', function() {
    invitee_id  = $(this).attr('data-invitee-id');
    url         = $(this).attr('data-url');

    pauseTimer();
    $(this).css('opacity', 0.5);

    $.put(url, {invitee_id: invitee_id}, function(data) {
      // restart timer
      unpauseTimer();
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
      if (data['poke_id']) {
        // user's friend will be poked
        // track invite poke event
        track_event('Invite', 'Poke');
      }
      if (data['goto']) {
        window.location = data['goto'];
      }
    }, 'json');

    return false;
  })
}

$.fn.init_stream_todos = function() {

  $("a#pick_todo_date").live('click', function() {
    modal = $(this).closest("li").find("div.planning-modal");

    if ($(this).hasClass('added')) {
      return false;
    }

    if (!modal.is(':visible')) {
      // dim button, show dialog, pause timer
      $(this).css('opacity', 0.5);
      modal.show();
      pauseTimer();
    } else {
      // un-dim button, hide dialog, restart timer
      $(this).css('opacity', 1.0);
      modal.hide();
      unpauseTimer();
    }

    return false;
  })

  $("input[name='todo_date']").change(function() {
    // date was selected

    // enable submit
    $(this).closest('li').find("input#add_todo").attr('disabled', '');
    return true;
  })

  $("input#add_todo").live('click', function() {
    input   = $(this);
    url     = $(this).attr('data-url');
    modal   = $(this).closest("li").find("div.planning-modal");
    abutton = $(this).closest("li").find("a#pick_todo_date");

    if (input.hasClass('added')) {
      // already added
      return false;
    }

    // find selected date
    date = $(this).closest('li').find("input:checked").val();

    // update interface, disable button
    input.val("Adding ...").addClass('disabled').attr('disabled', '');

    $.put(url, {going: date}, function(data) {
      // update interface
      input.val("Added").addClass('added');
      // close dialog
      modal.hide();
      // change link/button opacity
      abutton.css('opacity', 0.5).addClass('added');
      // restart timer
      unpauseTimer();
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
    }, 'json');

    return false;
  })

  // join an existing plan
  $("a#join_todo").live('click', function() {
    link  = $(this);
    path  = $(this).attr('data-url');

    if ($(this).hasClass('added')) {
      // already added
      return false;
    }
    
    // pause timer
    pauseTimer();
    
    // update interface
    link.text("Adding ...");
  
    $.put(path, {}, function(data) {
      // update interface
      link.text("Added").css('opacity', 0.5).addClass('added');
      // restart timer
      unpauseTimer();
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
    }, 'json');

    return false;
  })
}

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

$.fn.init_stream_timer = function() {

  function startTimer() {
    stream_timer_id = setInterval(addObjects, 5000);
    // console.log("stream timer id: " + stream_timer_id);
  }

  function stopTimer() {
    // console.log("cancelling interval timer");
    clearInterval(stream_timer_id);
  }

  if ($("#social-stream li").length > 0) {
    // initialize stream objects
    trackNotCountedObjects();
    // start interval timer
    startTimer();
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
    $("#social-stream li.not-counted.hide:last").slideDown(2000).addClass('visible').removeClass('hide').css('display', 'visible');
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

    if (stream_paused) {
      // skip if stream is paused
      // console.log("stream paused");
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
  $(document).init_stream_todos();
  $(document).init_stream_invites();
  $(document).init_stream_map();
  $(document).init_stream_timer();
})