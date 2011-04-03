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

$(document).ready(function() {
  $(document).init_live_user_search();
})
