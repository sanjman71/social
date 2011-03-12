jQuery.extend({
  put: function(url, data, callback, type) {
    return $.ajax({type: 'PUT', url: url, data: data, success: callback, dataType: type});
  },
  delete_: function(url, data, callback, type) {
    return $.ajax({type: 'DELETE', url: url, data: data, success: callback, dataType: type});
  }
});

// Prevent a method from being called too often, e.g. throttle live search requests
Function.prototype.sleep = function (millisecond_delay) {
  if(window.sleep_delay != undefined) clearTimeout(window.sleep_delay);
  var function_object = this;
  window.sleep_delay  = setTimeout(function_object, millisecond_delay);
};

// show grows specified by data collection
// data: e.g. [{'message': 'growl message', 'timeout': 1000}]
function show_growls(data) {
  jQuery.each(data, function() {
    $.Growl.show({'message':this['message'], 'timeout':this['timeout']});
  })
}

// check growls
function check_growls() {
  $.get("/growls", {}, function(data) {
    if (data['growls'].length > 0) {
      show_growls(data['growls']);
    }
  }, 'json');
}

// track google analytics

function track_event(category, action) {
  try {
    _gaq.push(['_trackEvent', category, action]);
  } catch(e) {}
}

function track_page(page) {
  try {
    _gaq.push(['_trackPageview', page]);
  } catch(e) {}
}

$.fn.init_get_points = function() {
  var points_field    = $("a#get-more-points");
  var points_text     = $(points_field).text();
  var points_disabled = "Getting ...";

  $(points_field).click(function() {
    var url = $(this).attr('data-url');
    disable_points();
    $.put(url, {}, function(data) {
      // update points
      update_points(data.points);
      enable_points();
      // show growls
      if (data['growls']) {
        show_growls(data.growls);
      }
    }, 'json');
    return false;
  })

  function disable_points() {
    $(points_field).text(points_disabled);
    $(points_field).addClass('disabled');
  }

  function enable_points() {
    $(points_field).text(points_text);
    $(points_field).removeClass('disabled');
  }

  function update_points(points) {
    field = "div#my-points div#screen";
    $(field).text(points);
  }
}

$.fn.init_shared_dialogs = function() {
  $("a#what-is-outlately").fancybox();
  $("a#points-info").fancybox();
}

$.fn.init_tooltips = function() {
  try {
    // tooltip
    $('.tipsy a').tipsy({
      gravity: 'n',
      fade: true
    });
  } catch(e) {}
}

$.fn.init_textarea_autoresize = function() {
  $('textarea.autoresize').autoResize({
      // On resize:
      onResize : function() {
        $(this).css({opacity:0.8});
      },
      // After resize:
      animateCallback : function() {
        $(this).css({opacity:1});
      },
      // Quite slow animation:
      animateDuration : 300,
      // Extra space in pixels:
      extraSpace : 10,
      limit: 200
  });
}

$.fn.init_character_counter = function() {
  function textCounting(field, limit) {
    if (field.value.length > limit) {
      // over the limit, truncate field
      field.value = field.value.substring(0, limit);
    } else {
      // update counter
      $(field).siblings("#message_count").text(limit-field.value.length);
    }
  }

  // character counter
  $('textarea.countdown').keyup(function() {
    textCounting(this, 140);
  });
}

$(document).ready(function() {
  $(document).init_get_points();
  $(document).init_shared_dialogs();
  $(document).init_tooltips();
  $(document).init_textarea_autoresize();
  $(document).init_character_counter();
})