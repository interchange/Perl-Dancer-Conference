/* map */
var map = L.map('map').setView([48.20078,16.36826], 13);
L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}', {
  attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
  maxZoom: 18,
  id: 'petermottram.mp1dpak2',
  accessToken: 'pk.eyJ1IjoicGV0ZXJtb3R0cmFtIiwiYSI6IjE1NWI5NjRjN2IxNjNkYTM1MzI3YzY5M2E0YjZjMDc0In0.T0bpnZGXCQBSW_SOv_nWHA'
}).addTo(map);
var marker2 = L.marker([48.18246, 16.38075]).addTo(map);
marker2.bindPopup("<b>Hotel Schani Wien</b><br>Karl-Popper-Straße 22<br>Conference Venue<br>21/22 Oct");
$("#marker2").click(function(){
    marker2.openPopup();
    return false;
});
