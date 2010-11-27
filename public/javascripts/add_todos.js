$.fn.init_live_search_places = function() {
  $("a#show_live_search_places_form").live('click', function() {
    $(".live_search_places_form").show();
    $(this).hide();
  })

  $("a#hide_live_search_places_form").live('click', function() {
    $(".live_search_places_form").hide();
    $("a#show_live_search_places_form").show();
  })

  $("input#live_search_places").keyup(function () {
    var search_url  = $(this).attr('data-url');
    var search_term = this.value;
    if (search_term.length < 3) { return false; }
    // excecute search, throttle how often its called
    var search_execution = function () {
      // show search progress bar
      $('#search_places_hint').text("Searching '" + search_term + "'");
      $.get(search_url, {q : search_term}, null, "script");
    }.sleep(500);

    return false;
  })

  $(".place").live('mouseover mouseout', function(event) {
    if (event.type == 'mouseover') {
      $(this).find(".add_place").show();
    } else {
      $(this).find(".add_place").hide();
    }
  })

  $("a#add_place_to_todo_list").live('click', function(event) {
    url   = $(this).attr('data-url');
    loc   = {name:$(this).attr('data-name'), address:$(this).attr('data-address'), city:$(this).attr('data-city'),
             state:$(this).attr('data-state'), lat:$(this).attr('data-lat'), lng:$(this).attr('data-lng'),
             source:$(this).attr('data-source')}
    $(this).replaceWith('adding');
    $.put(url, {location:loc, return_to:$(this).attr('data-return-to')}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_live_search_places();
})