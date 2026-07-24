// Show audit logs for the selected rows' requests
WulinMaster.actions.ShowAuditLogs = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'show_audit_logs',

  handler: function() {
    var self = this;
    var grid = this.getGrid();
    var selectedRows = grid.getSelectedRows();

    if (selectedRows.length < 1) {
      displayErrorMessage("Please select at least one row.");
      return false;
    }

    var requestIds = [];
    for (var i = 0; i < selectedRows.length; i++) {
      var row = grid.getData()[selectedRows[i]];
      if (row && row.request_id && requestIds.indexOf(row.request_id) === -1) {
        requestIds.push(row.request_id);
      }
    }

    if (requestIds.length === 0) {
      displayErrorMessage("Selected rows have no request IDs.");
      return false;
    }

    var title = 'Audit Logs for Request ID: ' + requestIds.join(', ');

    Ui.headerModal(title, {
      onOpenStart: function(modal, trigger) {
        $.ajax({
          type: 'GET',
          url: '/wulin_audit/audit_logs',
          data: {
            screen: 'AuditLogScreen',
            request_ids: requestIds.join(',')
          }
        }).success(function(data) {
          $(modal).find('.modal-content').css('padding', '0').html(data);
          self.setGridHeightInModal($(modal));
        });
      }
    });
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.ShowAuditLogs);
