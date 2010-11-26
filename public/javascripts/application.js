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

// check growls
function check_growls() {
  $.get("/growls", {}, function(data) {
    if (data['growls'].length > 0) {
      show_growls(data['growls']);
    }
  }, 'json');
}

// show grows specified by data collection
// data: e.g. [{'message': 'growl message', 'timeout': 1000}]
function show_growls(data) {
  jQuery.each(data, function() {
    $.Growl.show({'message':this['message'], 'timeout':this['timeout']});
  })
}

