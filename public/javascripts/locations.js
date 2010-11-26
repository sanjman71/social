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

$.fn.init_live_search_places = function() {
  $("input#live_search_places").keyup(function () {
    var search_url  = $(this).attr('data-url');
    var search_term = this.value;
    if (search_term.length < 3) { return false; }
    // excecute search, throttle how often its called
    var search_execution = function () {
      $.get(search_url, {q : search_term}, null, "script");
      // show search progress bar
      $('#search_places_hint').text("Searching '" + search_term + "'");
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

}

$.fn.init_search_foursquare = function() {
  $("a#search_foursquare").click(function() {
    field     = $(this);
    url       = $(this).attr('data-url');
    query     = $(this).attr('data-query');
    lat       = $(this).attr('data-lat');
    lng       = $(this).attr('data-lng');
    form      = $("#search_results_form");
    results   = $("#" + $(this).attr('data-results'));
    hint      = $(results).next(".hint");
    
    // show results
    $(form).removeClass('hide');

    // update hint
    $(hint).text("searching ...");
    clear_select(results);

    $.getJSON(url, {q: query, lat: lat, lng: lng}, function(data) {
      if (data.status == 'ok') {
        count     = data.count;
        locations = data.locations;
        // populate select options
        fill_select(results, locations);
        $(hint).text("we found some stuff");
      } else {
        // error
        $(hint).text("whoops");
      }
    });

    return false;
  })
  
  function clear_select(results) {
    $(results).empty();
  }

  function fill_select(results, places) {
    for(i=0; i<places.length; i++) {
      place   = places[i];
      value   = place.name + ", " + place.address + ", " + place.city;
      option  = "<option value ='" + place.id + "'>" + value + "</option>"
      $(results).append(option);
    }
  }
}

$.fn.init_add_location_tags = function() {
  var add_tags        = [];
  var tag_name_field  = $("input#tag_name");
  var add_tags_field  = $("#add_tag_list");

  $("a#add_tag").click(function() {
    // add tag to list
    new_tag_name = $(tag_name_field).val();
    if (new_tag_name != '' && $.inArray(new_tag_name, add_tags) == -1) {
      add_tags.push(new_tag_name);
      // update display tag list
      show_tags(add_tags, add_tags_field)
    }
    // clear input field
    $(tag_name_field).val('');
    return false;
  })

  $("a.remove_tag").live('click', function() {
    remove_tag_name = $(this).attr('data-tag-name');
    add_tags = add_tags.filter(function(tag_name, index, array) {
      return (tag_name == remove_tag_name) ? false : true;
    })
    // update display tag list
    show_tags(add_tags, add_tags_field)
    return false;
  })
  
  $("a#submit_tags").click(function() {
    if (add_tags.length == 0) {
      alert("No tags to add");
      return false;
    }

    url           = $(this).attr('data-url');
    method        = $(this).attr('data-method');
    tags          = add_tags.join(',')
    return_to     = $(this).attr('data-return-to');
    disable_with  = $(this).attr('data-disable-with');
    
    if (disable_with != '') {
      $(this).replaceWith(disable_with);
    }

    $.put(url, {tags: tags, return_to: return_to});

    return false;
  })

  function show_tags(tag_array, field) {
    tag_array_mapped = tag_array.map(function(tag_name, index, array) {
      return tag_name + " " + "<a href='#' class='remove_tag' data-tag-name='" + tag_name + "'>x</a>";
    });
    $(field).html(tag_array_mapped.join(', '));
  }
}

$(document).ready(function() {
  $(document).init_change_user_city();
  $(document).init_live_search_places();
  $(document).init_search_foursquare();
  $(document).init_add_location_tags();
  
  try {
    // check growls
    if (growls.length > 0) { show_growls(growls); }
  } catch(e) { }
})