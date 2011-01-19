$(document).ready(function() {
  new Highcharts.Chart({
    chart: { renderTo: "container", zoomType: 'xy' },
    title: { text: "Tag Histogram" },
    xAxis: { categories: tag_names },
    yAxis:
      [
       {title: { text: "Tag Counts" }},
       {title: { text: "Badges"}, opposite: true}
      ],
    series:
      [
        {name: 'Tags', data: tag_counts, type: 'column'},
        {name: 'Badges', data: badge_counts, type: 'bar'}
      ]
  });
})