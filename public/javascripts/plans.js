$.fn.init_add_plans = function() {
  $("a#show_search_places_autocomplete_form").live('click', function() {
    $("div.search_places_autocomplete_form").show();
    $(this).hide();
    return false;
  })

  $("a#hide_search_places_autocomplete_form").live('click', function() {
    $("div.search_places_autocomplete_form").hide();
    $("a#show_search_places_autocomplete_form").show();
    return false;
  })

 $(".datepicker").datepicker({minDate: '+0', maxDate: '+5d'});
 
  $("a#add_todo").live('click', function(event) {
    place_elem  = $(this).closest("#todo_search").find("#place");
    going_elem  = $(this).closest("#todo_search").find("#going");
    going       = going_elem.val();

    if (!$(place_elem).hasClass('selected')) {
      alert("Please select a location");
      return false;
    }

    if (going == '') {
      alert("Please select a date");
      return false;
    }

    if ($(this).hasClass('disabled')) {
      return false;
    }

    loc = {name:$(place_elem).attr('data-name'),
           address:$(place_elem).attr('data-address'),
           city_state:$(place_elem).attr('data-city-state'),
           lat:$(place_elem).attr('data-lat'),
           lng:$(place_elem).attr('data-lng'),
           source:$(place_elem).attr('data-source')}
    url = $(this).attr('data-url');
    // disable link
    disable_text  = $(this).attr('data-disable-with');
    $(this).text(disable_text).addClass('disabled');
    // send request
    return_to     = $(this).attr('data-return-to');
    $.put(url, {location:loc, going:going, return_to:return_to}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_add_plans();
})