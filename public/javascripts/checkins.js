$.fn.init_checkins_count = function() {
  $("a#facebook_checkins_count").click(function() {
    $(this).parents("#checkins_count_link").hide().siblings("#checkins_count_data").show();
    friend = $(this).parents('.friend')
    url    = $(this).attr('data-url');
    $.get(url, {}, function(data) {
      status = data['status'];
      if (status == 'ok') {
        text = data['count'];
      } else {
        text = data['message'];
      }
      $(friend).find("#checkins_count_data").html(text);
    }, 'json');
    return false;
  })
}

$(document).ready(function() {
  $(document).init_checkins_count();
})