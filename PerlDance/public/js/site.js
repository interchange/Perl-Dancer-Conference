$(document).ready(function() {
  /* menu dropdowns */
  $("#navbar ul li ul :first-child").parent().siblings("a").addClass("dropdown-toggle").attr("data-toggle", "dropdown").attr("href", "#").attr("role", "button").attr("aria-haspopup", "true").attr("aria-expanded", "false").append(' <span class="caret"></span>');
  /* shrink nav bar on scroll */
  $(window).scroll(function() {
    if ($(document).scrollTop() > 150) {
      $('.navbar-fixed-top').addClass('shrink');
    } else {
      $('.navbar-fixed-top').removeClass('shrink');
    }
  });
  /* countdown timer */
  $('.countdown-timer').each(function(){
      this.finalDate = new Date("2015-10-19T09:00:00+01:00");
      this.now = new Date();
      this.totalSecsLeft = (this.finalDate.getTime() - this.now.getTime())/1000;

      var day_field = $(this).find('.gdlr-day');
      var day = Math.floor(this.totalSecsLeft / 60 / 60 / 24);
      day_field.text(day);
      
      var hrs_field = $(this).find('.gdlr-hrs');
      var hrs = Math.floor(this.totalSecsLeft / 60 / 60) % 24;
      hrs_field.text(hrs);
      
      var min_field = $(this).find('.gdlr-min');
      var min = Math.floor(this.totalSecsLeft / 60) % 60;
      min_field.text(min);
      
      var sec_field = $(this).find('.gdlr-sec');
      var sec = Math.floor(this.totalSecsLeft) % 60;
      sec_field.text(sec);    
      
      var i = setInterval(function(){
          if( sec > 0 ){
              sec--;          
          }else{
              sec = 59;
              if( min > 0 ){
                  min--;
              }else{
                  min = 59;
                  if( hrs > 0 ){
                      hrs--;
                  }else{
                      hrs = 24;
                      if( day > 0 ){
                          day--;
                      }else{
                          day = 0;
                          hrs = 0;
                          min = 0;
                          sec = 0;
                          clearInterval(i);
                      }
                      day_field.text(day);
                  }
                  hrs_field.text(hrs);
              }
              min_field.text(min);
          }
          sec_field.text(sec);    
      }, 1000);
  });
});
