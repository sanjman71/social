$.fn.init_suggestion_date = function() {
  $(".datepicker").datepicker({minDate: '+0', maxDate: '+3m'});
  $(".timepicker").timepickr({convention:12});
  
  // pick a date, used to 'schedule'
  $("#suggestion_pick_date").click(function() {
    $("div#datetime").show();
    $("div#message").show();
    $("div#schedule_submit").show();
    $("div#options").hide();
    return false;
  })

  // repick a date, used to 'reschedule'
  $("#suggestion_repick_date").click(function() {
    $("div#datetime").show();
    $("div#message").show();
    $("div#reschedule_submit").show();
    $("div#options").hide();
    return false;
  })

  // close the pick date option
  $("#suggestion_pick_date_nevermind").click(function() {
    $("div#datetime").hide();
    $("div#message").hide();
    $("div#schedule_submit").hide();
    $("div#options").show();
    return false;
  })

  // close the repick date option
  $("#suggestion_repick_date_nevermind").click(function() {
    $("div#datetime").hide();
    $("div#message").hide();
    $("div#reschedule_submit").hide();
    $("div#options").show();
    return false;
  })

  // schedule or re-schedule
  $("#suggestion_schedule_date, #suggestion_reschedule_date").click(function() {
    var form = "form#suggestion_form";
    
    // check date
    var date = $(form).find("input#suggestion_date").val();
    if (date == '') {
      alert("Please pick a date");
      return false;
    }

    var data = $(form).serialize();
    // pick schedule or reschedule url based on link that was clicked
    var id   = $(this).attr('id');
    var url  = id.match(/reschedule/) ? $(form).attr('data-reschedule-url') : $(form).attr('data-schedule-url');

    // show progress text
    $(form).find("div#schedule_submit").hide();

    $.post(url, data)

    return false;
  })
}

$(document).ready(function() {
  $(document).init_suggestion_date();
})
