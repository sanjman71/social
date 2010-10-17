$(document).ready(function() {
  
  if (mapping) { $('#map').jMapping({
    category_icon_options: {
      'async': {primaryColor: '#FF6600', cornerColor: '#EBEBEB'},
      'default': {primaryColor: '#465AE0'}
    }
  }); }

  if ($(".map-location").length > 0) {
    setTimeout(getLocations, 5000);
  }

  // get new, unique locations; setCurrentLocations is the callback used to update the current locations collection
  function getLocations() {
    removeLocationHighlights();
    if (cur_locations.length < max_locations) {
      $.getScript(geo_locations_path+"?without_location_ids="+cur_locations.join(',')+"&limit=1", setCurrentLocations);
      setTimeout(getLocations, 5000);
    }
  }

  function removeLocationHighlights() {
    $("a.map-link.highlight").removeClass('highlight');
  }

  // update the global cur_locations array
  function setCurrentLocations() {
    //console.log(cur_locations.join(','));
    // reset current locations array, build new list, then sort
    cur_locations = [];
    $("div.map-location").each(function() {
      location_id = $(this).attr('data-location-id');
      cur_locations.push(location_id);
    })
    cur_locations.sort(function (a,b) { return a-b });
    //console.log(cur_locations.join(','));
  }
})