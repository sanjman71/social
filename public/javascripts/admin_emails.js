$(document).ready(function() {
  new Highcharts.Chart({
    chart: { renderTo: "emails" },
    title: { text: "Emails by Day" },
    xAxis: { type: "datetime", maxZoom: 48 * 3600 * 1000 },
    yAxis: {
      title: { text: "Emails" }
    },
    series:
      [{name: 'Badge Added', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['badge_added']},
       {name: 'Daily Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['daily_checkins']},
       {name: 'Imported Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['imported_checkin']},
       {name: 'Invite', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['invite']},
       {name: 'Message', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['message']},
       {name: 'Realtime Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['realtime_checkins']},
       {name: 'Share Drink', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['share_drink']},
       {name: 'Todo Added', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['todo_added']},
       {name: 'Todo Expired', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['todo_expired']},
      ]
  });
})