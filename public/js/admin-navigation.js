$(document).ready(function() {
  var xsrfMeta = $('head meta[name="xsrf-meta"]').attr('content');
  $(".nav-item").each(function() {
    var navid = $(this).find(".navigation_id");
    $(this).data("ttId", navid.text());
    navid.remove();
    var navpid = $(this).find(".parent_id");
    if ( navpid.text() ) {
      $(this).data("ttParentId", navpid.text());
    }
    navpid.remove();
  });

  $("#createModal").on('show.bs.modal', function(event) {
    var button = $(event.relatedTarget);
    var action = button.attr('class');
    var parentId = button.data('parent');
    var type = button.data('type');
    var scope = button.data('scope');
    var modal = $(this);
    // cleanup active whatever we do next
    modal.find("input[name='active']").removeAttr('checked');
    if ( action === 'edit' ) {
      /* edit */
      modal.find("h4").text('Edit Navigation Item');
      modal.find("form").attr('action', '/admin/navigation/edit');
      var tr = button.closest('tr.nav-item');
      $.each([
          'type', 'scope', 'name', 'uri', 'description', 'alias', 'priority'
        ], function(i,v) {
        var text = tr.find("." + v).text();
        modal.find("input[name='" + v + "']").val(text);
      });
      var navigation_id = tr.data("ttId");
      modal.find("input[name='navigation_id']").val(navigation_id);
      var parent_id = tr.data("ttParentId");
      modal.find("input[name='parent_id']").val(parent_id);
      if ( tr.find(".isactive").text() === "Yes" ) {
        modal.find("input.isactive").attr('checked', true);
      }
      else {
        modal.find("input.inactive").attr('checked', true);
      }
    }
    else {
      /* create */
      modal.find("form").attr('action', '/admin/navigation/create');
      // reset form
      modal.find("input:not([name='xsrf_token'], [name='active'])").val('');
      modal.find("input.isactive").attr('checked', true);

      if ( parentId ) {
        // creating a child so pre-fill some values
        modal.find("input[name='parent_id']").val(parentId);
        modal.find("input[name='type']").val(type);
        modal.find("input[name='scope']").val(scope);
      }
    }
  });

  $("#submit")

  $(".treetable").treetable({
    expandable: true,
    initialState: "expanded"
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
