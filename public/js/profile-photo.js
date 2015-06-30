$(document).ready(function() {
    $("photo-upload").fileinput({
        uploadUrl: "/profile/photo/upload",
        allowedFileExtensions : ['jpg', 'png','gif'],
        overwriteInitial: false,
        maxFileSize: 1000,
        uploadAsync: true,
        maxFileCount: 1,
    });
});
