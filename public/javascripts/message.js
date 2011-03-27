$.fn.init_message_overlay = function() {
  $("a.modal-trigger").overlay({
    mask: {
      color: '#666',
      loadSpeed: 200,
      closeSpeed: 0,
      opacity: 0.5
    },
    closeOnClick: false,
    onBeforeClose: function() {
       $("div.mask").css('opacity', 1.0);
    }
  });

  $("a.message.modal-trigger").click(function() {
    var modal = $("#user-message-overlay");
    modal.find("#header_to").text("To: " + $(this).attr('data-handle'));
    modal.find("input#message_to_id").val($(this).attr('data-id'));
    $("div.mask").css('opacity', 0.1);
    return true;
  })

  $("a.wall-message.modal-trigger").click(function() {
    var modal = $("#wall-message-overlay");
    modal.find("#header_to").text("To: The Chalkboard @ " + $(this).attr('data-name'));
    modal.find("input#message_wall_id").val($(this).attr('data-id'));
    $("div.mask").css('opacity', 0.1);
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
      if (data['goto']) {
        window.location = data['goto'];
      }
      // show any growls
      if (data['growls']) {
        show_growls(data['growls']);
      }
      /// show any flash message
      if (data['message']) {
        $("div#flash").append("<div class='notice'>" + data['message'] + "</div>");
      }
    }, 'json');

    return false;
  });}

$(document).ready(function() {
  $(document).init_message_overlay();
})