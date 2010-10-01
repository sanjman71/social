$(document).ready(function() {
  $("#pics").cycle({fx:'fade', timeout:5000, speed:1000, before:onBefore, after:onAfter});
  
  function onBefore() {
    $("#match #handle,#match #data,#match #matchie").html('');
  }
  
  function onAfter() {
    var handle  = $(this).attr('data-handle');
    var gender  = $(this).attr('data-gender');
    var city    = $(this).attr('data-city');
    var matchie = $(this).attr('data-matchie');
    var data    = gender + " / " + city;
    $("#match #handle").html(handle);
    $("#match #data").html(data);
    $("#match #matchie").html(matchie);
  }
})
