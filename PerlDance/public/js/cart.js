$(document).ready(function() {
    var xsrfMeta = $('head meta[name="xsrf-meta"]').attr('content');
    $(".product .quantity").each(function() {
        $(this).data("oldValue", $(this).val());
    });

    // cart product quantity change
    $(".cart-container").on( "change keypress", ".product .quantity", function() {
        var el = $(this);
        var qty = el.val();
        var sku = el.closest(".product").find("input.sku").val();

        if ( el.is("input") ) {
            el.parent().children(".hide").removeClass("hide");
        }
        else {
            // a select list
            if ( qty === '10+' ) {
                // switch from select to input field
                var html = '<input size="3" class="form-control quantity" type="text" name="quantity" class="quantity" value="'
                    + el.data("oldValue")
                    + '"><div class="spacing-top-small hide"><button class="update-quantity btn btn-small btn-primary">Update</button></div>';
                el.replaceWith(html);
        
            }
            else {
                $.ajax({
                    type: "POST",
                    url: "/cart",
                    data: { update: sku, quantity: qty, xsrf_token: xsrfMeta },
                    success: function(json) {
                        el.closest("table").replaceWith(json.html);
                        $(".product .quantity").each(function() {
                            $(this).data("oldValue", $(this).val());
                        });
                    }
                });
            }
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
                $(".product .quantity").each(function() {
                    $(this).data("oldValue", $(this).val());
                });
            }
        });
        return false;
    });
});
