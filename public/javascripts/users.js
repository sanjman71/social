$(document).ready(function() {
  $("#pics").cycle({fx:'fade', timeout:5000, speed:1000, before:onBefore, after:onAfter});
  
  function onBefore() {
    $("#blurb").html('');
  }
  
  function onAfter() {
    var handle = $(this).attr('handle');
    var gender = $(this).attr('gender');
    var city   = $(this).attr('city');
    var blurb  = handle + " / " + gender + " / " + city;
    $("#blurb").html(blurb);
  }
})
