$(document).ready(function() {
  var id = $('#usermap').data('id'),
    accessToken = $('#usermap').data('accesstoken'),
    map = L.map('usermap').setView([20.00,0.00], 2);
  L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}', {
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
    minZoom: 2,
    maxZoom: 18,
    id: id,
    accessToken: accessToken
  }).addTo(map);
  var markers = new L.MarkerClusterGroup();
  $("#user-list").children().each(function() {
    var marker = L.marker([
      $(this).find(".latitude").text(),
      $(this).find(".longitude").text()
    ]);
    marker.bindPopup($(this).find(".html").html());
    markers.addLayer(marker);
  });
  map.addLayer(markers);
});
