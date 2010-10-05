$(document).ready(function() {
  
  if (mapping) { $('#map').jMapping({
    category_icon_options: {
      'async': {primaryColor: '#FF6600', cornerColor: '#EBEBEB'},
      'default': {primaryColor: '#465AE0'}
    }
  }); }

  if ($(".map-location").length > 0) {
    getLocationIds();
    setTimeout(updateLocations, 5000);
  }

  function updateLocations() {
    removeLocationHighlights();
    var ids = getLocationIds();
    if (ids.length < max_locations) {
      $.getScript(geo_locations_path+"?without_location_id="+ids.join(',')+"&limit=1");
      setTimeout(updateLocations, 5000);
    }
  }

  function removeLocationHighlights() {
    $("a.map-link.highlight").removeClass('highlight');
  }

  function getLocationIds() {
    // build, then sort
    location_ids = [];
    $("div.map-location").each(function() {
      location_id = $(this).attr('data-location-id');
      location_ids.push(location_id);
    })
    location_ids.sort(function (a,b) { return a-b });
    return location_ids;
  }
})