$.fn.init_search_places_autocomplete = function() {
  var search_field  = $("input#search_places_autocomplete");
  var search_url    = $(search_field).attr('data-search-url');
  var search_query  = '';
  var source_name   = 'foursquare';
  var searching     = false;

  $(search_field).autocomplete({
    source : function(request, response) {
      // cache the most recent query string
      search_query = request.term;
      $.ajax({url: search_url, dataType: "json", data : {q: request.term},
              success: function(data) {
                count   = data.count;
                places  = data.locations;
                response($.map(places, function(place) {
                  name_address = place.name + ", " + place.address + ", " + place.city;
                  return { label: name_address,   // list value
                           value: name_address,   // selected value
                           name: place.name,
                           source: source_name + ":" + place.id,
                           address: place.address,
                           city: place.city,
                           state: place.state,
                           lat: place.geolat,
                           lng: place.geolong,
                         }
                }));
              }
      });
    },
    minLength : 3,
    delay : 500,
    search : function(event, ui) {
      // ignore search if already searching
      if (searching) { return false; }
      // set searching flag
      searching = true;
      $(this).siblings('#search_places_hint').text("searching '" + $(this).val() + "'");
      return true;
    },
    open: function(event, ui) {
      // reset searching flag
      searching = false;
      // clear hint text when dropdown list is opened
      $(this).siblings('#search_places_hint').text("");
    },
    close : function(event, ui) {
      // nothing for now
    },
    select: function(event, ui) {
      a = "<a href='#' id='add_location' class='admin' data-source='" + ui.item.source + "' " +
          "data-name='" + ui.item.name + "' " +
          "data-address='" + ui.item.address + "' " +
          "data-city-state='" + ui.item.city + ":" + ui.item.state + "' " +
          "data-lat='" + ui.item.lat + "' " +
          "data-lng='" + ui.item.lng + "' " +
          "data-url='" + $(this).attr('data-submit-url') + "' " +
          "data-waiting='" + $(this).attr('data-waiting') + "' " +
          "data-return-to='" + $(this).attr('data-return-to') + "' " +
          ">" + $(this).attr('data-submit-text') + "</a>";
      $(this).siblings('#search_places_hint').html(a);
    },
  });

  $("a#add_location").live('click', function(event) {
    url   = $(this).attr('data-url');
    loc   = {name:$(this).attr('data-name'), address:$(this).attr('data-address'),
             city_state:$(this).attr('data-city-state'),
             lat:$(this).attr('data-lat'), lng:$(this).attr('data-lng'),
             source:$(this).attr('data-source')}
    $(this).replaceWith($(this).attr('data-waiting'));
    $.put(url, {location:loc, return_to:$(this).attr('data-return-to')}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_search_places_autocomplete();
})