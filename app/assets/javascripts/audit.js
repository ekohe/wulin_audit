$(function() {
  var auditButton;
  auditButton = $('.toolbar_icon_audit');
  auditButton.live('click', function(){
    // Remove all existing dialogs
    $("#audit_dialog").remove();

    var $dialog, $grid_container, currentGrdi, selectedIds, recordUnit;
    currentGrid = Ui.findCurrentGrid();
    selectedIds = Ui.selectIds(currentGrid);
    if (selectedIds) {
      recordUnit = selectedIds.split(',').length > 1 ? 'records' : 'record';

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
            data: {record_ids: selectedIds, class_name:currentGrid.name},
            url: '/record_audits'
          })
          .success(function(data) { $grid_container.html(data); });
        }
      });
    } else {
      displayErrorMessage("Please select a record to see it's audit log.");
    }
  });

});