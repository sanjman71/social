$(document).ready(function() {
  $("#pics").cycle({fx:'fade', timeout:5000, speed:1000, before:onBefore, after:onAfter});
  
  function onBefore() {
    $("#handle").html('');
    $("#city").html('');
  }
  
  function onAfter() {
    $("#handle").html($(this).attr('handle'));
    $("#city").html($(this).attr('city'));
  }
})
