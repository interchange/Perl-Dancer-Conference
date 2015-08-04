$(document).ready(function() {
  var xsrfMeta = $('head meta[name="xsrf-meta"]').attr('content');
  $(".nav-item").each(function() {
    var navid = $(this).find(".navigation_id");
    $(this).attr("data-tt-id", navid.text());
    navid.remove();
    var navpid = $(this).find(".parent_id");
    if ( navpid.text() ) {
      $(this).attr("data-tt-parent-id", navpid.text());
    }
    navpid.remove();
  });

  $("#createModal").on('show.bs.modal', function(event) {
      var button = $(event.relatedTarget);
      var parentId = button.data('parent');
      var type = button.data('type');
      var scope = button.data('scope');
      var modal = $(this);
      modal.find('input').val('');
      if ( parentId ) {
          modal.find("input[name='parent_id']").val(parentId);
          modal.find("input[name='type']").val(type);
          modal.find("input[name='scope']").val(scope);
      }
  });

  $(".treetable").treetable({
    expandable: true
  });
  $("#expand").click(function(){
    $(".treetable").treetable('expandAll');
  });
  $("#collapse").click(function(){
    $(".treetable").treetable('collapseAll');
  });


  // Highlight selected row
  $(".treetable tbody").on("mousedown", "tr", function() {
    $(".selected").not(this).removeClass("selected");
    $(this).toggleClass("selected");
  });

  // Drag & Drop
  $(".treetable .folder").draggable({
    helper: "clone",
    opacity: .75,
    refreshPositions: true,
    revert: "invalid",
    revertDuration: 300,
    scroll: true
  });

  $(".treetable .folder").each(function() {
    $(this).parents(".treetable tr").droppable({
      accept: ".folder",
      drop: function(e, ui) {
        var droppedId = ui.draggable.parents("tr").data("ttId");
        var targetId = $(this).data("ttId");
        $.ajax({
          type: "GET",
          url: "/admin/navigation/move/" + droppedId + "/" + targetId,
          success: function(json) {
            if ( json.response === 1 ) {
              $(".treetable").treetable("move", droppedId, targetId);
            }
          }
        });
      },
      hoverClass: "accept",
      over: function(e, ui) {
        var droppedEl = ui.draggable.parents("tr");
        if(this != droppedEl[0] && !$(this).is(".expanded")) {
          $(".treetable").treetable("expandNode", $(this).data("ttId"));
        }
      }
    });
  });
});
