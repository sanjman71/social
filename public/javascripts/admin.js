$(document).ready(function() {
  // initialize datepicker
  $("#member_at_datepicker, #created_at_datepicker, #checkin_at_datepicker").datepicker({dateFormat: "yymmdd", maxDate: "+0"});
})