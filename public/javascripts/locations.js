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

  var search_url      = $(tag_name_field).attr('data-search-url');
  var searching       = false;

  $(tag_name_field).autocomplete({
    minLength : 3,
    delay : 500,
    source : function(request, response) {
      $.ajax({url: search_url, dataType: "json", data : {q: request.term},
              success: function(data) {
                count = data.count;
                tags  = data.tags;
                response($.map(tags, function(tag) {
                  return { label: tag,   // list value
                           value: tag,   // selected value
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
      // set hint
      set_hint('searching...');
      return true;
    },
    open: function(event, ui) {
      // reset hint
      set_hint('');
    },
    close : function(event, ui) {
      // reset hint
      set_hint('');
    },
    select: function(event, ui) {
      // add selected tag
      add_tag(ui.item.value);
      // clear input field
      tag_name_field.val('');
      return false;
    },
  });

  function close_autocomplete() {
    tag_name_field.autocomplete('close');
  }

  function set_hint(s) {
    tag_name_field.siblings('#hint').text(s);
  }

  $(tag_name_field).bind('keyup', function(e) {
    // get tag name
    tag_name = tag_name_field.val();

    if(e.keyCode==13){
      // enter pressed
      // add tag
      add_tag(tag_name);
      // close autocomplete
      close_autocomplete();
      set_hint('');
      // clear input field
      tag_name_field.val('');
      return false;
    }
  });

  /*
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
  */

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

  function add_tag(tag_name) {
    if (tag_name != '' && $.inArray(tag_name, add_tags) == -1) {
      add_tags.push(tag_name);
      // update display tag list
      show_tags(add_tags, add_tags_field)
    }
  }

  function show_tags(tag_array, field) {
    tag_array_mapped = tag_array.map(function(tag_name, index, array) {
      return tag_name + " " + "<a href='#' class='remove_tag' data-tag-name='" + tag_name + "'>x</a>";
    });
    field.html(tag_array_mapped.join(', '));
  }
}

$.fn.init_change_city = function() {
  $("select#select_city").change(function() {
    window.location = this.value;
    return false;
  })
}

$.fn.init_more_locations = function() {
  $("a#more_locations").live('click', function() {
    a     = $(this);
    // build request params
    url   = $(this).attr('data-url');
    page  = parseInt($(this).attr('data-page'));
    // show progress
    $(a).hide();
    $(a).next("#progress").show();
    $.getScript(url+"?page="+(page+1), function() {
      // show more link
      $(a).show();
      $(a).next("#progress").hide();
      // increment page number
      $(a).attr('data-page', page+1);
    });
    return false;
  })
}

$(document).ready(function() {
  // $(document).init_live_search_places();
  // $(document).init_search_foursquare();
  $(document).init_add_location_tags();
  $(document).init_more_locations();
  $(document).init_change_city();
  
  try {
    // check growls
    if (growls.length > 0) { show_growls(growls); }
  } catch(e) { }
})