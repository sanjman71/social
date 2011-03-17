$.fn.init_message_overlay = function() {
  $(".modal-trigger").overlay({
    mask: {
      color: '#efefef',
      loadSpeed: 200,
      opacity: 0.9
    },
    closeOnClick: false
  });
  
  $(".message.modal-trigger").click(function() {
    var modal = $("div.modal#message_overlay");
    modal.find("#header_to").text("To: " + $(this).attr('data-handle')); 
    modal.find("input#message_to").val($(this).attr('data-id')); 
    return true;
  })

  $("form#new_message").submit(function() {
    form  = $(this);
    body  = $(form).find("#message_body").val();
    url   = $(form).attr('data-url');

    if (body == '') {
      alert("Please enter a message");
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
    }, 'json');

    return false;
  });}

$(document).ready(function() {
  $(document).init_message_overlay();
})