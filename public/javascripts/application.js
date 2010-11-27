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

function update_user_points(points) {
  field   = "span#user_points";
  cur_str =  $(field).text();
  $(field).text(cur_str.replace(/\d+/, points));
}

$.fn.init_add_bucks = function() {
  $("input#add_bucks").click(function() {
    var url = $(this).attr('data-url');
    // disable submit input
    $(this).attr('disabled', 'disabled');
    $(this).addClass('disabled');
    $.put(url, {}, function(data) {
      // update points
      update_user_points(data.points);
      // show growls
      if (data['growls']) {
        show_growls(data.growls);
      }
    }, 'json');
    return false;
  })
}

$(document).ready(function() {
  $(document).init_add_bucks();
})