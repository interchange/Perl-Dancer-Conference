$(document).ready(function() {
    $(".period").change(function() {
        $(this).closest('form').submit();
    });
});
