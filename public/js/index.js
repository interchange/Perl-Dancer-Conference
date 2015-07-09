/* amerikahaus map */
var confinfoWindows=[];
function conf_closeAllInfoWindows(){
    for (var i=0;i<confinfoWindows.length;i++){
        confinfoWindows[i].close();
    }
    confinfoWindows=[];
};
function init_confmap(){
    var conflatlng = new google.maps.LatLng(48.1824134,16.3812668);
    var confmapOptions={
        zoom: 16,
        scrollwheel:false,
        panControl:true,
        zoomControl:true,
        mapTypeControl:true,
        scaleControl:true,
        streetViewControl:true,
        overviewMapControl:true,
        overviewMapControlOptions:{opened:true},
        center: conflatlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    confmap=new google.maps.Map(document.getElementById("confmap"),confmapOptions);
    marker0confmap=new google.maps.Marker({
        map: confmap,
        draggable:false,
        position: conflatlng,
        title:"Hotel Schani Wien",
        clickable:true,
        icon:""
    });
    infowindow0confmap =new google.maps.InfoWindow({
        content:"Karl-Popper-Straße 22, 1100 Wien, Austria"
    });
    google.maps.event.addListener(marker0confmap,'click',function(){ 
        conf_closeAllInfoWindows();
        confinfoWindows.push(infowindow0confmap);
        infowindow0confmap.open(confmap,marker0confmap);
        google.maps.event.addListener(confmap,'click',function(){
            infowindow0confmap.close();
        });
    });
};
google.maps.event.addDomListener(window, 'load', init_confmap);

var infoWindows=[];
function wgmp_closeAllInfoWindows(){
    for (var i=0;i<infoWindows.length;i++){
        infoWindows[i].close();
    }
    infoWindows=[];
};
function init_map(){
    var latlng = new google.maps.LatLng(48.210047,16.355743699999948);
    var mapOptions={
        zoom: 16,
        scrollwheel:false,
        panControl:true,
        zoomControl:true,
        mapTypeControl:true,
        scaleControl:true,
        streetViewControl:true,
        overviewMapControl:true,
        overviewMapControlOptions:{opened:true},
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    wgmpmap=new google.maps.Map(document.getElementById("wgmpmap"),mapOptions);
    marker0wgmpmap=new google.maps.Marker({
        map: wgmpmap,
        draggable:false,
        position: latlng,
        title:"Amerikahaus, Wien",
        clickable:true,
        icon:""
    });
    infowindow0wgmpmap =new google.maps.InfoWindow({
        content:"Friedrich-Schmidt-Platz 2 1010 Wien, Austria"
    });
    google.maps.event.addListener(marker0wgmpmap,'click',function(){ 
        wgmp_closeAllInfoWindows();
        infoWindows.push(infowindow0wgmpmap);
        infowindow0wgmpmap.open(wgmpmap,marker0wgmpmap);
        google.maps.event.addListener(wgmpmap,'click',function(){
            infowindow0wgmpmap.close();
        });
    });
};
google.maps.event.addDomListener(window, 'load', init_map);

$(document).ready(function() {
  /* newsletter */
  if (typeof newsletter_check !== "function") {
    window.newsletter_check = function (f) {
      var re = /^([a-zA-Z0-9_\.\-\+])+\@(([a-zA-Z0-9\-]{1,})+\.)+([a-zA-Z0-9]{2,})+$/;
      if (!re.test(f.elements["ne"].value)) {
        alert("The email is not correct");
        return false;
      }
      if (f.elements["ny"] && !f.elements["ny"].checked) {
        alert("You must accept the privacy statement");
        return false;
      }
      return true;
    }
  };
  $( "#newsletter-subscribe" ).submit(function( event ) {
    return newsletter_check(this);
  });
});
