function validate_email_address(email_address) {
  var email_regex = /^[a-zA-Z0-9\+._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
  if (email_regex.test(email_address) == false) { return false; }
  return true;
}

$.fn.init_invite_autocomplete = function() {
  var invitee_field   = $("input#search_invitee_autocomplete");
  var search_url      = $(invitee_field).attr('data-search-url');
  var searching       = false;
  var selecting       = false;

  $(invitee_field).autocomplete({
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
                  if (invitee.source == 'Outlately') {
                    // show handle and email address
                    list_value      = invitee.handle + " <" + invitee.email + ">";
                    selected_value  = invitee.handle + " <" + invitee.email + ">";
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
      // add to 'to' list
      add_email(ui.item.email);
      change_submit(true);
    },
    open: function(event, ui) {
      selecting = true;
    },
    close: function(event, ui) {
      selecting = false;
      // clear search field
      clear_search();
    },
  });

  function add_email(email) {
    $("#to").append("<div id='email' style='margin-bottom: 5px;'>" +
                    "<span id='address'>" + email + "</span>" +
                    "<a href='#' id='remove_invitee' class='admin' style='margin-left: 7px;'>Remove</a>" +
                    "</div>");
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

  function clear_search() {
    // clear search field
    $(invitee_field).val('');
  }

  $("a#remove_invitee").live('click', function(event) {
    $(this).parents("div#email").remove();
    if ($("div#to div#email").length == 0) {
      // no invitees, disable submit
      change_submit(false);
    }
    return false;
  })

  $(invitee_field).bind('keypress', function(e) {
    if(e.keyCode==13 && selecting){
      // enter pressed while in the selecting state
      // check that input field is a valid email address
      text = $(invitee_field).val();
      if (validate_email_address(text)) {
        // add email
        add_email(text);
        // enable submit
        change_submit(true);
        // close selection list
        close_autocomplete();
        // clear search
        clear_search();
      }
      return false;
    }
  });
}

$.fn.init_invite_submit = function() {
  $("form#new_invitation").submit(function() {
    emails   = [];
    invitees = $("div#to").find("span#address");
    $.map(invitees, function(invitee) {
      email = $(invitee).text();
      emails.push(email);
    })

    if (emails.length == 0) {
      alert("Please select at least one invitee");
      return false;
    }

    // set invitees
    $(this).find("#invitees").val(emails.join(','));

    return true;
  })
}

$(document).ready(function() {
  $(document).init_invite_autocomplete();
  $(document).init_invite_submit();
})