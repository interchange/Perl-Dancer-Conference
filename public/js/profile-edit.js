$(document).ready(function() {
    var xsrfMeta = $('head meta[name="xsrf-meta"]').attr('content');
    $("#geocode").click(function() {
        $.ajax({
            type: "POST",
            url: "/profile/geocode",
            data: {
                address: $("#inputCity").val() + ', ' + $("#inputCountry").val(),
                xsrf_token: xsrfMeta
            },
            success: function(json) {
                console.log(json);
                $("#inputLatitude").val(json.latitude);
                $("#inputLongitude").val(json.longitude);
            }
        });
        return false;
    });
});
