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
       {name: 'Friend Realtime Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['friend_realtime_checkin']},
       {name: 'Imported Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['imported_checkin']},
       {name: 'Invite', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['invite']},
       {name: 'Message', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['message']},
       {name: 'Share Drink', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: email_hash['share_drink']},
      ]
  });
})