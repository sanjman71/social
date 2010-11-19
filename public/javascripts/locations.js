$(document).ready(function() {
  
  $("input#user_location").change(function() {
    field     = $(this);
    query     = $(this).val();
    data_url  = $(this).attr('data-url');
    submit    = $("input#edit_user_submit");
    hint      = $(this).next('.hint');

    // ignore empty query
    if (query == '') { return; }

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
      $(hint).text("you moved to " + data.city);
    });
  })
})