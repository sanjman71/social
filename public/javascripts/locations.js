$(document).ready(function() {
  
  // google docs: http://gmaps-utility-library.googlecode.com/svn/trunk/mapiconmaker/1.1/docs/reference.html
  if (mapping) { $('#map').jMapping({
    category_icon_options: {
      'hot': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '40', width: '40'},
      'async': {primaryColor: '#FF6600', cornerColor: '#EBEBEB', height: '32', width: '32'},
      'default': {primaryColor: '#465AE0', height: '32', width: '32'}
    }
  }); }

  if ($(".map-location").length > 0) {
    // start the timer
    setTimeout(addObjects, 5000);
  }

  function addObjects() {
    // add locations
    addLocations();
    //addUsers();
    if (cur_locations.length < max_locations-1) {
      // reset timer
      setTimeout(addObjects, 5000);
    }
  }

  // add unique locations
  function addLocations() {
    $.getScript(geo_locations_path+"?without_location_ids="+cur_locations.join(',')+"&limit=1", setCurrentLocations);
  }

  // add unique users
  function addUsers() {
    if (cur_locations.length < max_locations) {
      $.getScript(geo_users_path+"?without_user_ids="+cur_users.join(',')+"&limit=1", setCurrentUsers);
    }
  }

  // update the global cur_locations array
  function setCurrentLocations() {
    //console.log(cur_locations.join(','));
    // reset current locations array, build new list, then sort
    cur_locations = [];
    /*
    $("div.map-location").each(function() {
      location_id = $(this).attr('data-location-id');
      cur_locations.push(location_id);
    })
    */
    $("div.stream .location").each(function() {
      id = $(this).attr('data-id');
      cur_locations.push(id);
    })
    cur_locations.sort(function (a,b) { return a-b });
    //console.log(cur_locations.join(','));
  }
  
  // update the global cur_users array
  function setCurrentUsers() {
    //console.log(cur_users.join(','));
    // reset current users array, build new list, then sort
    cur_users = [];
    $("div.stream .match").each(function() {
      id = $(this).attr('data-id');
      cur_users.push(id);
    })
    cur_users.sort(function (a,b) { return a-b });
    //console.log(cur_users.join(','));
  }
})