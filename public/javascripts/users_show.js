$.fn.init_checkin_map = function() {
  // google docs: http://gmaps-utility-library.googlecode.com/svn/trunk/mapiconmaker/1.1/docs/reference.html
  if (map) {
    $('#map').jMapping({
      location_selector: ".map-location.visible",
      category_icon_options: {
        'hot': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '40', width: '40'},
        'async': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '32', width: '32'},
        'default': {primaryColor: '#465AE0', height: '32', width: '32'}
      }
    });
  }

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

$.fn.init_user_dialogs = function() {
  $("a#profile-meetup").fancybox({autoDimensions: false, height: 200, width: 500});
  $("a#profile-learn-more").fancybox({autoDimensions: false, height: 150, width: 400});
  $("a#whatis-social-dna").fancybox();
}

$.fn.init_user_learn_more = function() {
  $("#learn_more_ok").click(function() {
    url = $(this).attr('data-url');
    $.put(url, {}, function(data) {
      // close dialog
      $.fancybox.close();
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
    }, 'json');
    track_page('/action/learn/more');
    return false;
  })

  $("#learn_more_cancel").click(function() {
    // close dialog
    $.fancybox.close();
    return false;
  })
}

$.fn.init_user_invite = function() {
  $("a#profile-invite").live('click', function() {
    invitee_id  = $(this).attr('data-invitee-id');
    url         = $(this).attr('data-url');
    link        = $(this);

    link.css('opacity', 0.5);

    $.put(url, {invitee_id: invitee_id}, function(data) {
      // reset link opacity
      link.css('opacity', 1.0);
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
      if (data['poke_id']) {
        // user's friend will be poked
        // track invite poke
        track_page('/action/invite/poke');
      }
      if (data['goto']) {
        window.location = data['goto'];
      }
    }, 'json');

    return false;
  })
}

/*
$.fn.init_tooltips = function() {
  $("a#badges_tip").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "bottom right",
                             offset: [0,0]});
  $("a#badges_tip").click(function() { return false; })
}
*/

$(document).ready(function() {
  $(document).init_user_invite();
  $(document).init_user_dialogs();
  $(document).init_user_learn_more();
  $(document).init_checkin_map();
})
