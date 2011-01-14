$(document).ready(function() {
  new Highcharts.Chart({
    chart: { renderTo: "invitations" },
    title: { text: "Invites by Day" },
    xAxis: { type: "datetime", maxZoom: 48 * 3600 * 1000 },
    yAxis: {
      title: { text: "Invites" }
    },
    series: [{pointInterval: 24 * 3600 * 1000, pointStart: dtime1, data: invites}]
  });
})