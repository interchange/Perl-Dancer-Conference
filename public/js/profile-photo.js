$(document).ready(function() {
    var xsrfMeta = $('head meta[name="xsrf-meta"]').attr('content');
    $("#photo-upload").fileinput({
        uploadExtraData: { xsrf_token: xsrfMeta }
    });
});
