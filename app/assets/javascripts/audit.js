// Audit action
WulinMaster.actions.Audit = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'audit',

  handler: function() {
    // Remove all existing dialogs
    $("#audit_dialog").remove(); 

    var $dialog, $grid_container, currentGrid, selectedIds, recordUnit;

    currentGrid = this.getGrid();
    selectedIds = currentGrid.getSelectedIds();
    if (selectedIds.length > 0) {
      recordUnit = selectedIds.length > 1 ? 'records' : 'record';

      $grid_container = $('<div/>')
      .attr({'class': 'grid_record_audit'});


      $dialog = $('<div/>')
      .attr({'id': 'audit_dialog', 'title': 'Audit logs for ' + recordUnit + ' with id: ' + selectedIds})
      .css('display', 'none')
      .append($grid_container)
      .appendTo('body')

      .dialog({
        autoOpen: true,
        width: 700,
        height: 500,
        buttons: {
          "Ok": function() {
            $(this).dialog("destroy");
          } 
        },
        modal: true,
        create: function(event, ui) {
          $.ajax({
            type:'GET',
            data: {record_ids: selectedIds.join(","), class_name:currentGrid.model},
            url: '/record_audits'
          })
          .success(function(data) { $grid_container.html(data); });
        }
      });
    } else {
      displayErrorMessage("Please select a record to see it's audit log.");
    }
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Audit);