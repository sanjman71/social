$(document).ready(function() {
  new Highcharts.Chart({
    chart: { renderTo: "checkins" },
    title: { text: "Checkins by Day" },
    xAxis: { type: "datetime", maxZoom: 48 * 3600 * 1000 },
    yAxis: {
      title: { text: "Checkins", tickInterval: 5, min: 0.6 }
    },
    series: [{name: 'Non-Member Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: non_checkins},
             {name: 'Member Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: mem_checkins},
             {name: 'Guy Member Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: mem_guy_checkins},
             {name: 'Gal Member Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: mem_gal_checkins},
             {name: 'Guy Non-Member Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: non_guy_checkins},
             {name: 'Gal Non-Member Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: non_gal_checkins},
             {name: 'Planned Checkins', pointInterval: 24 * 3600 * 1000, pointStart: dstart, data: todos}]
  });
})