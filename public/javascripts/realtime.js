$(document).ready(function() {
  var jug = new Juggernaut;
  jug.subscribe("realtime", function(data){
    var li = $("<li />");
    li.text(data);
    $("#realtime").append(li);
  });
})

