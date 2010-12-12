$.fn.init_tooltips = function() {
  $("a#map_wtf").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "bottom right",
                          offset: [-70, -250]});
  $("a#map_wtf").click(function() { return false; })
  $("a#suggestions_wtf").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "top right",
                                  offset: [0, 0]});
  $("a#suggestions_wtf").click(function() { return false; })
  $("a#outlately_wtf").tooltip({effect: 'fade', predelay: 100, fadeOutSpeed: 100, position: "top right",
                                offset: [0, 0]});
  $("a#outlately_wtf").click(function() { return false; })
}

$(document).ready(function() {
  $(document).init_tooltips();
})