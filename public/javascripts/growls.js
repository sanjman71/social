$(document).ready(function() {

  try {
    if (growls > 0) {
      $.ajax({url: '/growls.json', dataType: 'json', success: handle_growls});
    }
  } catch(error) {
    
  }

  function handle_growls(data) {
    jQuery.each(data, function() {
      $.Growl.show({'message':this['message'], 'timeout':this['timeout']});
    })
  }

})