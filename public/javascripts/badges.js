$.fn.init_search_tags_autocomplete = function() {
  var search_field  = $("input#search_tags_autocomplete");
  var search_url    = $(search_field).attr('data-search-url');
  var searching     = false;

  $(search_field).autocomplete({
    minLength : 3,
    delay : 500,
    source : function(request, response) {
      $.ajax({url: search_url, dataType: "json", data : {q: request.term},
              success: function(data) {
                count = data.count;
                tags  = data.tags;
                response($.map(tags, function(tag) {
                  return { label: tag,   // list value
                           value: tag,   // selected value
                         }
                }));
                // reset searching flag
                searching = false;
              }
      });
    },
    search : function(event, ui) {
      // ignore search if already searching
      if (searching) { return false; }
      // set searching flag
      searching = true;
      // set hint
      $(this).siblings('#hint').text("...");
      return true;
    },
    open: function(event, ui) {
      // reset hint
      $(this).siblings("#hint").text('');
    },
    close : function(event, ui) {
      // reset hint
      $(this).siblings("#hint").text('');
    },
    select: function(event, ui) {
      // add selected tag
      add_tag(ui.item.value, $(this).closest("#badge").find("#add_tags"));
      show_apply_button($(this).closest("#badge").find("#apply_tags"));
      // clear field
      clear_field($(this));
    },
  });

  function clear_field(field) {
    field.val('');
  }

  function add_tag(tag, field) {
    tokens = field.text().split(',');
    tokens = jQuery.grep(tokens, function(s) {s!=''});
    tokens.push(tag);
    field.html(tokens.join(","));
  }
  
  function show_apply_button(field) {
    field.show();
  }
}

$(document).ready(function() {
  $(document).init_search_tags_autocomplete();

  // validate form
  $("form.badge").validate({});

  $("a#show_search_tags").click(function() {
    // show selected search tags
    $(this).closest("#badge").find("#search_tags").toggle();
    return false;
  })

  $("#apply_tags a").click(function() {
    url   = $(this).attr('data-url');
    tags  = $(this).closest("#badge").find("#add_tags").text();
    $.put(url, {tags:tags}, null, "script");
    return false;
  })
})
