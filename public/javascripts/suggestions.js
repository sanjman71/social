$.fn.init_suggestion_details_toggle = function() {
  $("a#suggestion_details").click(function() {
    // show details, hide link
    suggestion_id = $(this).attr('data-suggestion-id');
    $("div#suggestion_" + suggestion_id + "_details_link_wrapper").hide();
    $("div#suggestion_" + suggestion_id + "_details").show();
    // disable all other suggestions
    $("div.suggestion[data-suggestion-id!="+suggestion_id+"]").fadeTo('slow', 0.3);
    $("div.suggestion[data-suggestion-id!="+suggestion_id+"]").find("a#suggestion_details").hide('slow');
    // $("div.suggestion[data-suggestion-id!="+suggestion_id+"]").hide();
    return false;
  })
  
  $("a#suggestion_nevermind").click(function() {
    // the inverse of show details
    suggestion_id = $(this).attr('data-suggestion-id');
    $("div#suggestion_" + suggestion_id + "_details_link_wrapper").show();
    $("div#suggestion_" + suggestion_id + "_details").hide();
    // enable other suggestions
    $("div.suggestion").fadeTo('slow', 1);
    $("div.suggestion").find("a#suggestion_details").show();
    // $("div.suggestion").show();
    return false;
  })
  
  $("a#suggestion_relocate").click(function() {
    // hide options
    options  = $(this).parents("div#options");
    $(options).hide();
    // show change location form
    relocate = $(options).siblings("div#relocate");
    $(relocate).show();
    return false;
  })
  
  $("a#suggestion_relocate_nevermind").click(function() {
    // hide change location form
    relocate = $(this).parents("div#relocate")
    $(relocate).hide();
    // show all options
    options  = $(relocate).siblings("div#options")
    $(options).show();
    return false;
  })
}

$.fn.init_suggestion_dates = function() {
  // find all suggestions and enable each datepicker
  $("div#suggestion").each(function() {
    suggestion_id = $(this).attr('data-suggestion-id');
    $("#suggestion_" + suggestion_id + "_date").datepicker({minDate: '+0', maxDate: '+3m'});
  })
  //$(".timepicker").timepickr({convention:12});
  
  // pick a date, used to 'schedule'
  $("a#suggestion_pick_date").click(function() {
    suggestion_id   = $(this).attr('data-suggestion-id');
    suggestion_div  = "div#suggestion_" + suggestion_id + "_";
    $(suggestion_div + "datetime").show();
    $(suggestion_div + "message").show();
    $(suggestion_div + "schedule_submit").show();
    $("div#options").hide();
    return false;
  })

  // repick a date, used to 'reschedule'
  $("a#suggestion_repick_date").click(function() {
    suggestion_id   = $(this).attr('data-suggestion-id');
    suggestion_div  = "div#suggestion_" + suggestion_id + "_";
    $(suggestion_div + "datetime").show();
    $(suggestion_div + "message").show();
    $(suggestion_div + "reschedule_submit").show();
    $("div#options").hide();
    return false;
  })

  // close the (re-)pick date option
  $("a#suggestion_pick_date_nevermind, a#suggestion_repick_date_nevermind").click(function() {
    suggestion_id   = $(this).attr('data-suggestion-id');
    suggestion_div  = "div#suggestion_" + suggestion_id + "_";
    $(suggestion_div + "datetime").hide();
    $(suggestion_div + "message").hide();
    $(suggestion_div + "schedule_submit").hide();
    $(suggestion_div + "reschedule_submit").hide();
    $("div#options").show();
    return false;
  })

  // close the repick date option
  /*
  $("#suggestion_repick_date_nevermind").click(function() {
    suggestion_id = $(this).attr('data-suggestion-id');
    $("div#datetime").hide();
    $("div#message").hide();
    $("div#reschedule_submit").hide();
    $("div#options").show();
    return false;
  })
  */

  // schedule or re-schedule
  $("#suggestion_schedule_date, #suggestion_reschedule_date").click(function() {
    var form = $(this).parents("form#suggestion_form");
    
    // check date
    var date = $(form).find("input.datepicker").val();
    if (date == '') {
      alert("Please pick a date");
      return false;
    }

    var data = $(form).serialize();
    // pick schedule or reschedule url based on link that was clicked
    var id   = $(this).attr('id');
    var url  = id.match(/reschedule/) ? $(form).attr('data-reschedule-url') : $(form).attr('data-schedule-url');

    // disable submit
    $(this).attr('disabled', 'disabled');
    $(this).val($(this).attr('data-disable-with'));

    // post data
    $.post(url, data)
    return false;
  })

  // re-locate
  $("#suggestion_relocate_date").click(function() {
    // check location
    relocate      = $(this).closest("#relocate");
    place_elem    = $(relocate).find("#place");
    msg_elem      = $(relocate).find("input.message");

    if (!$(place_elem).hasClass('selected')) {
      alert("Please select a new location");
      return false;
    }

    // build place, message data
    url       = $(place_elem).attr('data-url');
    place     = {name : $(place_elem).attr('data-name'),
                 address : $(place_elem).attr('data-address'),
                 city_state : $(place_elem).attr('data-city-state'),
                 lat : $(place_elem).attr('data-lat'),
                 lng : $(place_elem).attr('data-lng'),
                 source : $(place_elem).attr('data-source')};
    message   = $(msg_elem).val();
    return_to = $(place_elem).attr('data-return-to');

    // disable submit
    $(this).attr('disabled', 'disabled');
    $(this).val($(this).attr('data-disable-with'));

    $.put(url, {location:place, message:message, return_to:return_to}, null, "script");

    return false;
  })
}

$.fn.init_suggestion_message_counter = function() {
  function textCounting(field, limit) {
    if (field.value.length > limit) { // if too long...trim it!
      // over the limit, truncate field
      field.value = field.value.substring(0, limit);
    } else {
      // update counter
      $(field).siblings("span#message_count").text(limit-field.value.length);
    }
  }

  // test character counter
  $('input.message').keyup(function() {
    textCounting(this, 50);
  });
}

$(document).ready(function() {
  $(document).init_suggestion_details_toggle();
  $(document).init_suggestion_dates();
  $(document).init_suggestion_message_counter();
})
