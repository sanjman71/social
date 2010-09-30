$(document).ready(function() {
  $("#pics").cycle({fx:'fade', timeout:5000, speed:1000, before:onBefore, after:onAfter});
  
  function onBefore() {
    $("#handle,#data,#match").html('');
  }
  
  function onAfter() {
    var handle = $(this).attr('data-handle');
    var gender = $(this).attr('data-gender');
    var city   = $(this).attr('data-city');
    var match  = $(this).attr('data-match');
    var data   = gender + " / " + city;
    $("#handle").html(handle);
    $("#data").html(data);
    $("#match").html(match);
  }
})
