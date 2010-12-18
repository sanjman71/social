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
}

$(document).ready(function() {
  $(document).init_add_plans();
})