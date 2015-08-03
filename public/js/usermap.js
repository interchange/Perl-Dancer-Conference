$(document).ready(function() {

  var map = L.map('usermap').setView([20.00,0.00], 2);

  L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}', {
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
    minZoom: 2,
    maxZoom: 18,
    id: 'petermottram.mp1dpak2',
    accessToken: 'pk.eyJ1IjoicGV0ZXJtb3R0cmFtIiwiYSI6IjE1NWI5NjRjN2IxNjNkYTM1MzI3YzY5M2E0YjZjMDc0In0.T0bpnZGXCQBSW_SOv_nWHA'
  }).addTo(map);

  $("#user-list").children().each(function() {
    var marker = L.marker([
      $(this).find(".latitude").text(),
      $(this).find(".longitude").text()
    ]).addTo(map);
    marker.bindPopup($(this).find(".html").html());
  });
});
