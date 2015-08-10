$(document).ready(function() {
  // move active class from nav-pills a to li
  var myId = $("ul.nav_days li.active a").attr("aria-controls");
  $("#" + myId).addClass("active");
});
