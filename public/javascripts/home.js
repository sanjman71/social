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

})