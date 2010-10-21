$(document).ready(function() {

  $(".stream .location, .stream .match").live('mouseover mouseout', function(event) {
    if (event.type == 'mouseover') {
      $(this).addClass('hover');
      $(this).find("#location_toggle,#user_toggle").show();
    } else {
      $(this).removeClass('hover');
      $(this).find("#location_toggle,#user_toggle").hide();
    }
  })

  // initialize dialog
  $("#meet_user_dialog").dialog({modal: true, autoOpen: false, width: 350, height: 150, show: 'fadeIn(slow)'});
  $("#plan_location_dialog").dialog({modal: true, autoOpen: false, width: 350, height: 150, show: 'fadeIn(slow)'});

  $("a#meet_user").live('click', function() {
    handle = $(this).parents('.match').attr('data-handle');
    $("#meet_user_dialog #handle").text("We'll connect you with " + handle);
    $("#meet_user_dialog").dialog('open');
    return false;
  })

  $("a#plan_location").live('click', function() {
    $("#plan_location_dialog").dialog('open');
    return false;
  })

})