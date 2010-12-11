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
  var todo_url      = $(search_field).attr('data-todo-url');
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
      a = "<a href='#' id='add_todo_location' class='admin' data-source='" + ui.item.source + "' " +
          "data-name='" + ui.item.name + "' " +
          "data-address='" + ui.item.address + "' " +
          "data-city-state='" + ui.item.city + ":" + ui.item.state + "' " +
          "data-lat='" + ui.item.lat + "' " +
          "data-lng='" + ui.item.lng + "' " +
          "data-url='" + todo_url + "' " +
          "data-return-to='" + return_to + "' " +
          ">Add</a>";
      $('#search_places_hint').html(a);
    },
  });

  /*
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
  */

  /*
  $(".place").live('mouseover mouseout', function(event) {
    if (event.type == 'mouseover') {
      $(this).find(".add_place").show();
    } else {
      $(this).find(".add_place").hide();
    }
  })
  */

  $("a#add_todo_location").live('click', function(event) {
    url   = $(this).attr('data-url');
    loc   = {name:$(this).attr('data-name'), address:$(this).attr('data-address'),
             city_state:$(this).attr('data-city-state'),
             lat:$(this).attr('data-lat'), lng:$(this).attr('data-lng'),
             source:$(this).attr('data-source')}
    $(this).replaceWith('adding');
    $.put(url, {location:loc, return_to:$(this).attr('data-return-to')}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_live_search_places();
})