$(document).ready(function() {
    $("photo-upload").fileinput({
        uploadUrl: "/profile/photo/upload",
        allowedFileExtensions : ['jpg', 'png','gif'],
        maxFileSize: 1000,
        uploadAsync: true,
        minImageWidth: 300,
        minImageHeight: 300,
        maxFileCount: 1
    });
});
