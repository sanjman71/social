$(document).ready(function() {
  new Highcharts.Chart({
    chart: { renderTo: "users", defaultSeriesType: 'column' },
    title: { text: "Members vs Non-Members" },
    xAxis: { categories: ['Members', 'Non-Members'] },
    yAxis: {
      min: 0,
      title: { text: "Gender Breakdown" }
    },
    series: [{name: 'Males', data: [mem_males, non_males]},
             {name: 'Females', data: [mem_females, non_females]}
             ]
  });
})