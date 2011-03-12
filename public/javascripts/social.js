$.fn.init_action_menus = function() {
  $("div.actions").click(function() {
    $(this).addClass('open');
  });
  
  $("div.actions ul").mouseleave(function() {
    console.log("mouseleave");
    $(this).parents("div").removeClass('open');
  });
}

$(document).ready(function() {
  $(document).init_action_menus();
})