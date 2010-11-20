$(document).ready(function() {
  
  $("input#user_city_name").change(function() {
    field         = $(this);
    query         = $(this).val();
    data_url      = $(this).attr('data-url');
    submit        = $("input#edit_user_submit");
    user_city_id  = $("input#user_city_attributes_id");
    hint          = $(this).next('.hint');

    // ignore empty query
    if (query == '') { return; }

    // disable city id to indicate city has changed
    $(user_city_id).attr('disabled', 'disabled');

    // disable submit, update hint
    $(submit).attr('disabled', 'disabled');
    $(hint).text("locating ...");

    $.getJSON(data_url, {q: query}, function(data) {
      if (data.status == 'ok') {
        $(field).attr('value', data.city + ", " + (data.state != '' ? data.state : data.country));
      } else {
        // error
      }
      // re-enable submit, update hint
      $(submit).attr('disabled', '');
      $(hint).text("hey, it's " + data.city);
    });
  })
})