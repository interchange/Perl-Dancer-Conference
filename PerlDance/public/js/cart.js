// cart product quantity change
$(".cart-container").on( "change", ".product .quantity", function() {
    var el = $(this);
    var qty = el.val();
    var sku = el.closest(".product").find("input.sku").val();
    if ( qty === '10+' ) {
        // switch from select to input field

    }
    else {
        $.ajax({
            type: "POST",
            url: "/cart",
            data: { update: sku, quantity: qty, xsrf_token: xsrfMeta },
            success: function(json) {
                el.closest("table").replaceWith(json.html);
            }
        });
    }
});
// delete product from cart
$(".cart-container").on( "click", ".product .remove-sku", function() {
    var el = $(this);
    $.ajax({
        type: "GET",
        url: el.attr("href"),
        success: function(json) {
            el.closest("table").replaceWith(json.html);
        }
    });
    return false;
});
$(document).ready(function() {
    $(".product .quantity").each(function() {
        $(this).data("oldValue", $(this).val());
    });
});
