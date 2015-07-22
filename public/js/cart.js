function updateCartQuantityDisplay() {
  $(".product .quantity-input .quantity").each(function() {
    var td = $(this).closest("td");
    if ( $(this).val() > 9 ) {
      td.find(".quantity-input").removeClass("hide");
    }
    else {
      td.find(".quantity-select").removeClass("hide");
    }
  });
};
$(document).ready(function() {
  var xsrfMeta = $('head meta[name="xsrf-meta"]').attr('content');
  updateCartQuantityDisplay();

  // cart product quantity change
  $(".cart-container").on( "change keypress", ".product .quantity", function() {
    var el = $(this);
    var td = el.closest("td");
    var qty = el.val();
    if ( el.is("input") ) {
      // text input make sure 'Update' is made visible
      td.find(".quantity-update").removeClass("hide");
    }
    else {
      // a select list
      if ( qty === '10+' ) {
        // switch from select to input field
        el.closest(".quantity-select").addClass("hide");
        td.find(".quantity-input").removeClass("hide");
      }
      else {
        var sku = el.closest(".product").find("input.sku").val();
        $.ajax({
          type: "POST",
          url: "/cart",
          data: { update: sku, quantity: qty, xsrf_token: xsrfMeta },
          success: function(json) {
            el.closest("div.cart-fragment").replaceWith(json.html);
            updateCartQuantityDisplay();
          }
        });
      }
    }
  });

  // click on qty update button (qty>=10)
  $(".cart-container").on( "click", ".quantity-update-button", function() {
    var el = $(this);
    var qty = el.closest(".quantity-input").children(".quantity").first().val();
    var sku = el.closest(".product").find("input.sku").val();
    $.ajax({
      type: "POST",
      url: "/cart",
      data: { update: sku, quantity: qty, xsrf_token: xsrfMeta },
      success: function(json) {
        el.closest("div.cart-fragment").replaceWith(json.html);
        updateCartQuantityDisplay();
      }
    });
  });

  // delete product from cart
  $(".cart-container").on( "click", ".product .remove-sku", function() {
    var el = $(this);
    $.ajax({
      type: "GET",
      url: el.attr("href"),
      success: function(json) {
        el.closest("table").replaceWith(json.html);
        updateCartQuantityDisplay();
      }
    });
    return false;
  });
});
