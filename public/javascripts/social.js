$.fn.init_action_menus = function() {
  $("div.actions").click(function() {
    $(this).addClass('open')
  }).mouseleave(function() {
    $(this).removeClass('open')
  });
}

$(document).ready(function() {
  $(document).init_action_menus();
})