// Audit action
WulinMaster.actions.Audit = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'audit',

  handler: function() {
    var self = this;
    var $auditModal, $gridContainer, currentGrid, selectedIds, recordUnit;

    currentGrid = this.getGrid();
    selectedIds = currentGrid.getSelectedIds();
    recordUnit = selectedIds.length > 1 ? 'records' : 'record';
    modalTitle = 'Audit logs for ' + recordUnit + ' with id: ' + selectedIds;

    $gridContainer = $('<div/>').addClass('grid_record_audit');

    var $auditModal = Ui.headerModal(modalTitle, {
      ready: function(modal, trigger) {
        $.ajax({
          type:'GET',
          data: {record_ids: selectedIds.join(","), class_name: currentGrid.model},
          url: '/wulin_audit/record_audits'
        })
        .success(function(data) {
          modal.find('.modal-content').css('padding', '0').html(data);
          self.setGridHeightInModal(modal);
        });
      }
    });
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Audit);
