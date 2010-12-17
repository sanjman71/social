$.fn.init_live_search_places = function() {
  $("a#show_live_search_places_form").live('click', function() {
    $(".live_search_places_form").show();
    $(this).hide();
    return false;
  })

  $("a#hide_live_search_places_form").live('click', function() {
    $(".live_search_places_form").hide();
    $("a#show_live_search_places_form").show();
    return false;
  })

  var search_field  = $("input#live_search_places");
  var search_url    = $(search_field).attr('data-search-url');
  var search_query  = '';
  var source_name   = 'foursquare';
  var submit_text   = $(search_field).attr('data-submit-text');
  var submit_url    = $(search_field).attr('data-submit-url');
  var pending_text  = $(search_field).attr('data-pending-text');
  var return_to     = $(search_field).attr('data-return-to');

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
      $('#search_places_hint').text("searching '" + $(search_field).val() + "'");
      return true;
    },
    open: function(event, ui) {
      // clear hint text when dropdown list is opened
      $('#search_places_hint').text("");
    },
    close : function(event, ui) {
      // $('#search_places_hint').text("");
    },
    select: function(event, ui) {
      a = "<a href='#' id='add_location' class='admin' data-source='" + ui.item.source + "' " +
          "data-name='" + ui.item.name + "' " +
          "data-address='" + ui.item.address + "' " +
          "data-city-state='" + ui.item.city + ":" + ui.item.state + "' " +
          "data-lat='" + ui.item.lat + "' " +
          "data-lng='" + ui.item.lng + "' " +
          "data-url='" + submit_url + "' " +
          "data-return-to='" + return_to + "' " +
          ">" + submit_text + "</a>";
      $('#search_places_hint').html(a);
    },
  });

  $("a#add_location").live('click', function(event) {
    url   = $(this).attr('data-url');
    loc   = {name:$(this).attr('data-name'), address:$(this).attr('data-address'),
             city_state:$(this).attr('data-city-state'),
             lat:$(this).attr('data-lat'), lng:$(this).attr('data-lng'),
             source:$(this).attr('data-source')}
    $(this).replaceWith(pending_text);
    $.put(url, {location:loc, return_to:$(this).attr('data-return-to')}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_live_search_places();
})