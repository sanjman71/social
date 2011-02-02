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

    // enable location name to indicate its changed
    $("input#location_changed").val(1);

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
      $(hint).text("hey, its " + loc.city);
    });
  })
  
  function fill_city(field, loc) {
    // fill with city, state or city, country
    value = loc.city + ", " + (loc.state != '' ? loc.state : loc.country);
    $(field).attr('value', value);
  }
  
  $("form.simple_form.user").submit(function() {
    try {
      // check if location field changed
      changed = $("input#location_changed").val();
      if (changed == 0) { 
        $("input#user_city_name,input#user_city_attributes_id").attr('disabled', 'disabled');
      }
    } catch(e) {}

    return true;
  })
}

$(document).ready(function() {
  $(document).init_change_user_city();

  // validate form
  $("form.user").validate({});
})