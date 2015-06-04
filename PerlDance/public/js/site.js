$(window).scroll(function() {
  if ($(document).scrollTop() > 150) {
    $('.navbar').addClass('shrink');
  }
  else {
    $('.navbar').removeClass('shrink'); }
});
