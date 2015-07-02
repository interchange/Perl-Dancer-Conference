$(document).on('ready', function(){
    $("#photo-upload").fileinput({
        uploadExtraData: { xsrf_token:
            $('head meta[name="xsrf-meta"]').attr('content') },
        uploadUrl: '/profile/photo',
        uploadAsync: true,
        maxFileCount: 1,
        allowedFileTypes: ['image'],
        allowedFileExtensions: ['jpg', 'gif', 'png'],
        minImageHeight: 300,
        minImageWidth: 300,
        maxFileSize: 1024
    });
    $("#photo-upload").on('fileuploaded', function(e, data) {
        $(".upload-panel").addClass('hidden');
        $(".crop-panel").removeClass('hidden');
    });
});

