$(document).ready(function() {

    // survey question templates
    var radioTemplate = $("#templates .radio-container").html();
    var checkboxTemplate = $("#templates .checkbox-container").html();
    var gridTemplate = $("#templates .grid-container").html();

    // convert simple html to radio/checkbox/grid display
    $("form.survey .options-container").each(function() {

        var optionsEl = $(this).children(".options").first(),
            questionId = optionsEl.data("question"),
            optionsType = optionsEl.data("type"),
            optionSpans = optionsEl.find("span.title");

        if ( optionsType === 'radio' || optionsType === 'checkbox' ) {
            var html = radioTemplate;
            if ( optionsType === 'checkbox' ) {
                html = checkboxTemplate;
            }
            optionSpans.each(function() {
                var id = $(this).data("id"),
                    title = $(this).text();
                var newEl = $(html).appendTo(optionsEl);
                newEl.find("input").val(id).attr("name", "q_" + questionId);
                newEl.find(".title").text(title);
                $(this).parent().remove();
            });
        }
        else if ( optionsType === 'grid' ) {
            var tbody = $(gridTemplate).appendTo(optionsEl).find('tbody');
            var html = "<tr>" + tbody.find('tr').remove().html() + "</tr>";
            optionSpans.each(function() {
                var id = $(this).data("id"),
                    title = $(this).text();
                var newEl = $(html).appendTo(tbody);
                newEl.find("input").attr("name", "q_"+ questionId + "_o_" + id);
                newEl.find(".title").text(title);
                $(this).parent().remove();
                optionsEl.addClass("table-responsive");
            });
        }
        else {
            console.log("options type not supported: " + optionsType);
        }
    });
});
