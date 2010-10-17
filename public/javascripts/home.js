$(document).ready(function() {

  $(".home.location,.home.match").live('mouseover mouseout', function(event) {
    if (event.type == 'mouseover') {
      $(this).addClass('hover');
    } else {
      $(this).removeClass('hover');
    }
  })

})