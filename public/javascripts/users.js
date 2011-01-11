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
  
  /*
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
  */
}

/*
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
*/

$.fn.init_user_dialogs = function() {
  $("a#profile-meetup").fancybox({autoDimensions: false, height: 200, width: 500});
  $("a#whatis-social-dna").fancybox();
}

$.fn.init_user_message_autoresize = function() {
  $('textarea#message_body').autoResize({
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

$.fn.init_user_message_counter = function() {
  function textCounting(field, limit) {
    if (field.value.length > limit) {
      // over the limit, truncate field
      field.value = field.value.substring(0, limit);
    } else {
      // update counter
      $(field).siblings("#message_count").text(limit-field.value.length);
    }
  }

  // test character counter
  $('textarea#message_body').keyup(function() {
    textCounting(this, 140);
  });
}

$.fn.init_user_message_submit = function() {
  $("form#new_message").submit(function() {
    form  = $(this);
    body  = $(form).find("#message_body").val();
    url   = $(form).attr('data-url');

    if (body == '') {
      alert("Please enter a message");
      return false;
    }

    // disable submit
    $(form).find("#message_send_submit").attr('disabled', 'disabled');

    $.post(url, $(form).serialize(), function(data) {
      // close dialog
      $.fancybox.close();
      // reset dialog
      $(form).find("#message_send_submit").attr('disabled', '');
      $(form).find("#message_body").val('').trigger('keyup');
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
    }, 'json');

    return false;
  });
}

/*
$.fn.init_tooltips = function() {
  $("a#badges_tip").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "bottom right",
                             offset: [0,0]});
  $("a#badges_tip").click(function() { return false; })
}
*/

$.fn.init_growls = function() {
  try {
    // check growls
    if (growls.length > 0) { show_growls(growls); }
  } catch(e) { }
}

$(document).ready(function() {
  // $(document).init_tooltips();
  $(document).init_user_dialogs();
  $(document).init_user_message_autoresize();
  $(document).init_user_message_counter();
  $(document).init_user_message_submit();
  $(document).init_checkin_map();
  $(document).init_growls();
})
