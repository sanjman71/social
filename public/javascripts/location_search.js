$.fn.init_search_places_autocomplete = function() {
  var search_field  = $("input#search_places_autocomplete");
  var search_url    = $(search_field).attr('data-search-url');
  var source_name   = 'foursquare';
  var searching     = false;

  $(search_field).autocomplete({
    minLength : 3,
    delay : 500,
    source : function(request, response) {
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
                // reset searching flag
                searching = false;
              }
      });
    },
    search : function(event, ui) {
      // ignore search if already searching
      if (searching) { return false; }
      // set searching flag
      searching = true;
      // reset selected flag
      $(this).siblings("#place").removeClass('selected');
      // set hint
      $(this).siblings('#hint').text("'" + $(this).val() + "'");
      return true;
    },
    open: function(event, ui) {
      // reset hint
      $(this).siblings("#hint").text('');
    },
    close : function(event, ui) {
      // reset hint
      $(this).siblings("#hint").text('');
    },
    select: function(event, ui) {
      // set place attributes
      place = $(this).siblings("#place");
      $(place).attr('data-source', ui.item.source);
      $(place).attr('data-name', ui.item.name).attr('data-address', ui.item.address);
      $(place).attr('data-city-state', ui.item.city + ":" + ui.item.state);
      $(place).attr('data-lat', ui.item.lat).attr('data-lng', ui.item.lng);
      $(place).addClass("selected");
    },
  });
}

$(document).ready(function() {
  $(document).init_search_places_autocomplete();
})