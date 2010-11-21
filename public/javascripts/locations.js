$.fn.init_change_user_city = function() {
  // handle user setting/changing their city
  $("input#user_city_name").change(function() {
    field         = $(this);
    url           = $(this).attr('data-url');
    query         = $(this).val();
    submit        = $("input#edit_user_submit");
    user_city_id  = $("input#user_city_attributes_id");
    hint          = $(this).next('.hint');

    // ignore empty query
    if (query == '') { return; }

    // disable city id to indicate city has changed
    $(user_city_id).attr('disabled', 'disabled');

    // disable submit, update hint
    $(submit).attr('disabled', 'disabled');
    $(hint).text("searching ...");

    $.getJSON(url, {q: query}, function(data) {
      if (data.status == 'ok') {
        loc = data.locations[0]
        fill_city(field, loc)
      } else {
        // error
      }
      // re-enable submit, update hint
      $(submit).attr('disabled', '');
      $(hint).text("we found " + loc.city);
    });
  })
  
  function fill_city(field, loc) {
    // fill with city, state or city, country
    value = loc.city + ", " + (loc.state != '' ? loc.state : loc.country);
    $(field).attr('value', value);
  }
}

$.fn.init_search_foursquare = function() {
  $("a#search_foursquare").click(function() {
    field     = $(this);
    url       = $(this).attr('data-url');
    query     = $(this).attr('data-query');
    lat       = $(this).attr('data-lat');
    lng       = $(this).attr('data-lng');
    results   = $("#" + $(this).attr('data-results'));
    hint      = $(results).next(".hint");
    
    // update hint
    $(hint).text("searching ...");
    clear_select(results);

    $.getJSON(url, {q: query, lat: lat, lng: lng}, function(data) {
      if (data.status == 'ok') {
        count     = data.count;
        locations = data.locations;
        // populate select options
        fill_select(results, locations);
      } else {
        // error
      }
      // re-enable submit, update hint
      //$(submit).attr('disabled', '');
      $(hint).text("we found some stuff");
    });

    return false;
  })
  
  function clear_select(results) {
    $(results).empty();
  }

  function fill_select(results, places) {
    console.log("filling select menu");
    for(i=0; i<places.length; i++) {
      place   = places[i];
      value   = place.name + ", " + place.address + ", " + place.city;
      option  = "<option value ='" + place.id + "'>" + value + "</option>"
      $(results).append(option);
    }
  }
}

$(document).ready(function() {
  $(document).init_change_user_city();
  $(document).init_search_foursquare();
})