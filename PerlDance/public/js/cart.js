$(document).ready(function() {
    $(".product .quantity").each(function() {
        $(this).data("oldValue", $(this).val());
    });
    $(document).on( "change", ".product .quantity", function() {
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
                data: { update: sku, quantity: qty },
                success: function(json) {
                    el.closest("table").replaceWith(json.html);
                }
            });
        }
    });
});
