$.fn.init_suggestion_date = function() {
  $(".datepicker").datepicker({minDate: '+0', maxDate: '+3m'});
  $(".timepicker").timepickr({convention:12});
  
  $("#pick_suggestion_date").click(function() {
    $("div#datetime").show();
    $("div#message").show();
    $("div#schedule_submit").show();
    $("div#options").hide();
    return false;
  })

  $("#pick_suggestion_date_nevermind").click(function() {
    $("div#datetime").hide();
    $("div#message").hide();
    $("div#schedule_submit").hide();
    $("div#options").show();
    return false;
  })

  $("#schedule_suggestion_date").click(function() {
    var form = "form#suggestion_form";
    
    // check date
    var date = $(form).find("input#suggestion_date").val();
    if (date == '') {
      alert("Please pick a date");
      return false;
    }

    var data = $(form).serialize();
    var url  = $(form).attr('data-schedule-url');

    // show progress text
    $(form).find("div#schedule_submit").hide();

    $.post(url, data)

    return false;
  })
}

$(document).ready(function() {
  $(document).init_suggestion_date();
})
