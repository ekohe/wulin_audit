// Audit action
WulinMaster.actions.Audit = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'audit',

  handler: function() {
    var self = this;
    var $auditModal, $gridContainer, currentGrid, selectedIds, recordUnit;

    currentGrid = this.getGrid();
    selectedIds = currentGrid.getSelectedIds();
    recordUnit = selectedIds.length > 1 ? 'records' : 'record';

    $gridContainer = $('<div/>').addClass('grid_record_audit');

    var $auditModal = $('<div/>')
      .attr({'id': 'audit_dialog'})
      .addClass('modal modal-fixed-footer')
      .css({overflow: 'hidden'})
      .appendTo($('body'));
    var $modalHeader = $('<div/>')
      .addClass('modal-header')
      .append($('<span/>').text('Audit logs for ' + recordUnit + ' with id: ' + selectedIds))
      .append($('<i/>').text('close').addClass('modal-close material-icons right'))
      .appendTo($auditModal);
    var $modalContent = $('<div/>')
      .addClass('modal-content')
      .appendTo($auditModal);
    var $modalFooter = $('<div/>')
      .addClass('modal-footer')
      .append($('<div/>').addClass('btn-flat modal-close').text('Cancel'))
      .appendTo($auditModal);

    $auditModal.modal({
      ready: function(modal, trigger) {
        $.ajax({
          type:'GET',
          data: {record_ids: selectedIds.join(","), class_name: currentGrid.model},
          url: '/wulin_audit/record_audits'
        })
        .success(function(data) {
          $modalContent.html(data);
          self.setGridHeightInModal($modalContent.parent());
        });
      },
      complete: function() {
        $auditModal.remove();
      }
    });

    $auditModal.modal('open');
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Audit);
