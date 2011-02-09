$(document).ready(function() {
  new Highcharts.Chart({
    chart: { renderTo: "emails" },
    title: { text: "Emails by Day" },
    xAxis: { type: "datetime", maxZoom: 48 * 3600 * 1000 },
    yAxis: {
      title: { text: "Emails" }
    },
    series: [{pointInterval: 24 * 3600 * 1000, pointStart: dtime1, data: invites}]
  });
})