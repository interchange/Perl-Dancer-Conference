function updateStates(inputCountry, inputState, selectedState){
    var countryIsoCode = inputCountry.val();
    var stateDiv = inputState.closest(".form-group");
    if ( !(countryIsoCode in countryStates) ) {
        stateDiv.hide();
    }
    else {
        var options = '';
        $.each(countryStates[countryIsoCode], function( i, v ) {
            options += '<option value="' + v.states_id + '"'
            console.log( selectedState + " " + v.states_id );
            if ( selectedState && selectedState == v.states_id ) {
                options += ' selected="selected"';
            }
            options += '>' + v.name + '</option>';
        });
        inputState.html(options);
        stateDiv.show();
    }
};

$(document).ready(function() {
    var xsrfMeta = $('head meta[name="xsrf-meta"]').attr('content');
    // update states dropdown on ready and on country change
    var selectedState = $('#inputState').data("state");
    updateStates($("#inputCountry"), $('#inputState'), selectedState);
    $("#inputCountry").change(function(){
        updateStates($("#inputCountry"), $('#inputState'), false);
    });
    // geocode
    $("#geocode").click(function() {
        var countryIsoCode = $("#inputCountry").val();
        var states_id = $('#inputState').val();
        var address = $("#inputCity").val();
        if ( countryIsoCode in countryStates ) {
            address += ', ' + statesById[states_id];
        }
        address += ', ' + countryIsoCode;

        $.ajax({
            type: "POST",
            url: "/profile/geocode",
            data: {
                address: address,
                xsrf_token: xsrfMeta
            },
            success: function(json) {
                $("#inputLatitude").val(json.latitude);
                $("#inputLongitude").val(json.longitude);
            }
        });
        return false;
    });

});
