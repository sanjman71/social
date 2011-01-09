function validate_email_address(email_address) {
  var email_regex = /^[a-zA-Z0-9\+._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
  if (email_regex.test(email_address) == false) { return false; }
  return true;
}

$.fn.init_invite_autocomplete = function() {
  var invitee_field   = $("input#search_invitee_autocomplete");
  var search_url      = $(invitee_field).attr('data-search-url');
  var searching       = false;
  var added           = false;

  // disable autocomplete
  $(invitee_field).autocomplete({
    disabled: true,
    minLength : 3,
    delay : 500,
    search : function(event, ui) {
      // ignore search if already searching
      if (searching) { return false; }
      // set searching flag
      searching = true;
      $(this).siblings('#search_invitees_hint').text("searching '" + $(this).val() + "'");
      return true;
    },
    source : function(request, response) {
      $.ajax({url: search_url, dataType: "json", data : {q: request.term},
              success: function(data) {
                invitees  = data.invitees;
                response($.map(invitees, function(invitee) {
                  if (invitee.source == 'Member' || invitee.source == 'User') {
                    // show handle and email address
                    list_value      = invitee.handle + " <" + invitee.email + ">";
                    selected_value  = invitee.handle + " &lt;" + invitee.email + "&gt;";
                  } else {
                    // just show email address
                    list_value      = invitee.email;
                    selected_value  = invitee.email;
                  }
                  return { label: list_value,
                           value: selected_value,
                           handle: invitee.handle,
                           email: invitee.email,
                           source: invitee.source,
                         }
                }));
                // reset searching flag
                searching = false;
                if (invitees.length == 0) {
                  $(invitee_field).siblings('#search_invitees_hint').text("no results");
                } else {
                  $(invitee_field).siblings('#search_invitees_hint').text("");
                }
              }
      });
    },
    select: function(event, ui) {
      if (ui.item.source == 'Member') {
        alert(ui.item.handle + " is already registered")
        return false;
      }
      // add to 'to' list
      add_email(ui.item.value, ui.item.email);
      change_submit(true);
      // prevent input value from being updated
      return false;
    },
    focus: function(event, ui) {
      // prevent input value from being updated
      return false;
    },
    open: function(event, ui) {
      added = false;
    },
    close: function(event, ui) {
      // clear the field if something was added
      if (added) { clear_autocomplete(); }
    },
  });

  function add_email(display, email) {
    $("#invitees").append("<div class='email' style='margin-bottom: 5px;'>" +
                    "<span id='display'>" + display + "</span>" +
                    "<span id='address' style='display: none;'>" + email + "</span>" +
                    "<a href='#' id='remove_invitee' class='admin' style='margin-left: 7px;'>Remove</a>" +
                    "</div>");
    added = true;
  }

  function change_submit(enable) {
    if (enable) {
      $("input#invitation_submit").attr('disabled', '');
    } else {
      $("input#invitation_submit").attr('disabled', 'disabled');
    }
  }

  function close_autocomplete() {
    $(invitee_field).autocomplete('close');
  }

  function clear_autocomplete() {
    // clear search field
    $(invitee_field).val('');
  }

  function set_hint(s) {
    $(invitee_field).siblings('#search_invitees_hint').text(s);
  }

  $("a#remove_invitee").live('click', function(event) {
    $(this).parents("div.email").remove();
    if ($("div#invitees div.email").length == 0) {
      // no invitees, disable submit
      change_submit(false);
    }
    return false;
  })

  $(invitee_field).bind('keyup', function(e) {
    // check input field for a valid email address
    text  = $(invitee_field).val();
    email = false;
    if (validate_email_address(text)) {
      set_hint("press return to add");
      email = true
    } else {
      set_hint('');
      email = false;
    }

    if(e.keyCode==13){
      // enter pressed
      // check that input field is a valid email address
      if (email) {
        // add email
        add_email(text, text);
        // enable submit
        change_submit(true);
        // close selection list
        close_autocomplete();
        // clear search field
        clear_autocomplete();
        // cleaer hint
        set_hint('');
      }
      return false;
    }
  });
}

$.fn.init_invite_submit = function() {
  $("form#new_invitation").submit(function() {
    emails   = [];
    
    // filter invitees for valid emails
    invitee_field = $("textarea#invitees");
    invitees      = $(invitee_field).val().split(',');
    $.map(invitees, function(email) {
      if (validate_email_address(email)) {
        emails.push(email);
      }
    })

    if (emails.length == 0) {
      alert("Please add a valid email address");
      return false;
    }

    // reset invitees field with validated email addresses
    $(invitee_field).val(emails.join(','));

    return true;
  })
}

$.fn.init_invite_autoresize = function() {
  $('textarea#invitees').autoResize({
      // On resize:
      onResize : function() {
          $(this).css({opacity:0.8});
      },
      // After resize:
      animateCallback : function() {
          $(this).css({opacity:1});
      },
      // Quite slow animation:
      animateDuration : 300,
      // More extra space:
      extraSpace : 20,
      limit: 200
  });
}

$(document).ready(function() {
  // $(document).init_invite_autocomplete();
  $(document).init_invite_autoresize();
  $(document).init_invite_submit();
})