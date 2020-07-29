// Audit action
WulinMaster.actions.Audit = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'audit',

  handler: function() {
    var self = this;
    var $gridContainer, currentGrid, selectedIds, recordUnit;

    currentGrid = this.getGrid();
    selectedIds = currentGrid.getSelectedIds();
    recordUnit = selectedIds.length > 1 ? 'records' : 'record';
    title = 'Audit logs for ' + recordUnit + ' with id: ' + selectedIds;
    ajaxOption = {
      type:'GET',
      data: {record_ids: selectedIds.join(','), class_name: currentGrid.model},
      url: '/wulin_audit/record_audits'
    }

    if (selectedIds.length < 1) {
      displayErrorMessage("Please select a record to see it's audit log.");
      return false;
    }

    $gridContainer = $('<div/>').addClass('grid_record_audit');
    if (typeof Ui.headerModal === 'function') {
      Ui.headerModal(title, {
        onOpenStart: function (modal, trigger) {
          $.ajax(ajaxOption).success(function (data) {
            $(modal).find('.modal-content').css('padding', '0').html(data);
            self.setGridHeightInModal($(modal));
          });
        },
      });
    } else {
      $('<div/>')
        .attr({'title': title})
        .css('display', 'none')
        .append($gridContainer)
        .appendTo('body')
        .dialog({
          autoOpen: true,
          width: 700,
          height: 500,
          buttons: {
            'Ok': function() {
              $(this).dialog('destroy');
            }
          },
          modal: true,
          create: function(event, ui) {
            $.ajax(ajaxOption).success(function(data) { $gridContainer.html(data); });
          }
        });

    }

  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Audit);
