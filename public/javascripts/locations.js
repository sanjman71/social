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
    $.getScript(geo_locations_path+"?without_location_id="+getLocationIds()+"&limit=1");
    setTimeout(updateLocations, 5000);
  }

  function getLocationIds() {
    location_ids = [];
    $("div.map-location").each(function() {
      location_id = $(this).attr('data-location-id');
      location_ids.push(location_id);
    })
    return location_ids;
  }
})