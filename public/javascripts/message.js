$.fn.init_message_overlay = function() {
  $("a.modal-trigger").overlay({
    mask: {
      color: '#eee',
      loadSpeed: 200,
      opacity: 0.9
    },
    closeOnClick: false,
    onBeforeClose: function() {
       $("div.titlebar, a.tile").css('opacity', 1.0);
    }
  });

  $("a.message.modal-trigger").click(function() {
    var modal = $("#message_overlay");
    modal.find("#header_to").text("To: " + $(this).attr('data-handle'));
    modal.find("input#message_to").val($(this).attr('data-id'));
    $("div.titlebar, a.tile").css('opacity', 0.1);
    return true;
  })

  $("a.wall-message.modal-trigger").click(function() {
    var modal = $("#wall-message-overlay");
    modal.find("#header_to").text("To: The Wall @ " + $(this).attr('data-name'));
    modal.find("input#wall_id").val($(this).attr('data-id'));
    $("div.titlebar, a.tile").css('opacity', 0.1);
    return true;
  })

  $("form#new_message").submit(function() {
    form  = $(this);
    body  = $(form).find("#message_body").val();
    url   = $(form).attr('data-url');

    if (body == '') {
      // alert("Please enter a message");
      return false;
    }

    // disable submit
    form.find("#message_send_submit").attr('disabled', 'disabled');

    $.post(url, $(form).serialize(), function(data) {
      // close dialog
      form.find("div.close").click();
      // reset dialog
      form.find("#message_send_submit").attr('disabled', '');
      form.find("#message_body").val('').trigger('keyup');
      if (data['track_page']) {
        // track page
        track_page(data['track_page']);
      }
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
      /// show any flash message
      if (data['message']) {
        console.log("message: " + data['message']);
        $("div#flash").append("<div class='notice'>" + data['message'] + "</div>");
      }
    }, 'json');

    return false;
  });}

$(document).ready(function() {
  $(document).init_message_overlay();
})