$(document).ready(function() {
  new Highcharts.Chart({
    chart: { renderTo: "checkins" },
    title: { text: "Checkins by Day" },
    xAxis: { type: "datetime", maxZoom: 48 * 3600 * 1000 },
    yAxis: {
      title: { text: "Checkins" }
    },
    series: [{name: 'Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: checkins},
             {name: 'Planned Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: todos}]
  });
})