// live users search
$.fn.init_live_user_search = function () {
  $("input#live_user_search").keyup(function () {
    var search_url  = $(this).attr('data-url');
    var search_term = $(this).val();
    // excecut search, throttle how often its called
    var search_execution = function () {
      if (search_term != 'x') {
        // show search progress bar
        $('#search-hint').text("searching " + search_term + " ...");
        $.get(search_url, {q : search_term}, null, "script");
      }
    }.sleep(500);
    return false;
  })
}

$.fn.init_follow_actions = function () {
  $("a.follow, a.unfollow").live('click', function() {
    var url   = $(this).attr('data-url');
    var link  = $(this);

    $.ajax({
      url: url,
      type: 'put',
      dataType: "json",
      data: {},
      success: function(data) {
        if (data.status == 'ok') {
          if (data.action == 'follow') {
            $("a[data-id="+data.id+"]").html("Following").removeClass('follow').addClass('unfollow').
              attr('data-url', "/users/"+data.id+"/unfollow");
          }
          if (data.action == 'unfollow') {
            $("a[data-id="+data.id+"]").html("Follow").removeClass('unfollow').addClass('follow').
              attr('data-url', "/users/"+data.id+"/follow");
          }
        } else {
          // error
        }
      }
    })

    return false;
  })
}

$(document).ready(function() {
  $(document).init_live_user_search();
  $(document).init_follow_actions();
})
