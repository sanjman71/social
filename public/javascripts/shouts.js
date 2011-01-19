$.fn.init_add_shouts = function() {
  var search_form = $("div.search_places_autocomplete_form");
  $("a#show_search_places_autocomplete_form").live('click', function() {
    $(search_form).show();
    $(this).hide();
    return false;
  })

  $("a#hide_search_places_autocomplete_form").live('click', function() {
    $(search_form).hide();
    $("a#show_search_places_autocomplete_form").show();
    return false;
  })

  $("a#add_shout").live('click', function(event) {
    place_elem  = $(this).closest("#shout_search").find("#place");
    shout_text  = $(this).closest("#shout_search").find("#text").val();

    if (!$(place_elem).hasClass('selected')) {
      alert("Please select a location");
      return false;
    }

    if ($(this).hasClass('disabled')) {
      return false;
    }

    if (shout_text == '') {
      alert("Please enter a comment");
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
    $.put(url, {location: loc, return_to: return_to, text: shout_text}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_add_shouts();
})