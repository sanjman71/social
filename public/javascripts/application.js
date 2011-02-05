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

$(document).ready(function() {
  $(document).init_get_points();
  $(document).init_shared_dialogs();
})