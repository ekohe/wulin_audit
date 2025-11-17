// Audit modal enhancement - Double-click for details
var currentAuditGrid = null;
var currentAuditRow = null;

// Helper to format consistent title
function formatAuditTitle(action, userEmail, timestamp) {
  var title = action.toUpperCase();
  if (userEmail) {
    title += ' by ' + userEmail;
  } else {
    title += ' by System';
  }
  if (timestamp) {
    title += ' • ' + timestamp;
  }
  title += ' • Use ← → to navigate';
  return title;
}

// Show audit detail modal with before/after comparison
function showAuditDetailModal(auditLog, grid, rowIndex) {
  currentAuditGrid = grid;
  currentAuditRow = rowIndex;
  // Handle both array format (from grid) and object format
  let action, userEmail, detailJsonStr, detailStr;
  
  if (Array.isArray(auditLog)) {
    // Grid data comes as array
    // For record_audit grid: [id, created_at, user_email, action, request_ip, detail, detail_json]
    action = auditLog[3];
    userEmail = auditLog[2] || 'System';
    detailStr = auditLog[5]; // The formatted detail string
    detailJsonStr = auditLog[6]; // The JSON data
  } else {
    // Object format
    action = auditLog.action;
    userEmail = auditLog.user_email || 'System';
    detailJsonStr = auditLog.detail_json;
    detailStr = auditLog.detail;
  }
  
  // If detail_json is not available, try to parse from detail string
  if (!detailJsonStr && detailStr) {
    detailJsonStr = detailStr;
  }
  
  // Get timestamp
  var timestamp = '';
  if (Array.isArray(auditLog)) {
    timestamp = auditLog[1]; // created_at
  } else {
    timestamp = auditLog.created_at;
  }
  
  const titleText = formatAuditTitle(action, userEmail, timestamp);
  
  // Parse the JSON string
  let detailJson;
  try {
    if (typeof detailJsonStr === 'string') {
      detailJson = JSON.parse(detailJsonStr);
    } else {
      detailJson = detailJsonStr;
    }
  } catch (e) {
    console.error('Failed to parse detail_json:', e);
    // Fallback: display the detail string in a readable format
    detailJson = { 
      _parseError: true,
      _message: 'Could not parse audit data. Please refresh the page to see updated format.',
      _rawPreview: String(detailJsonStr || '').substring(0, 500) + '...'
    };
  }
  
  let modalContent = '<div class="audit-detail-modal">';
  
  // Handle parse errors
  if (detailJson && detailJson._parseError) {
    modalContent += '<div class="audit-change-group">';
    modalContent += '<div class="audit-message" style="background: #fff3cd; border-color: #ffc107; color: #856404;">';
    modalContent += escapeHtml(detailJson._message);
    modalContent += '</div>';
    if (detailJson._rawPreview) {
      modalContent += '<pre style="max-height: 400px; overflow-y: auto;">' + escapeHtml(detailJson._rawPreview) + '</pre>';
    }
    modalContent += '</div>';
  } else if (action === 'update' && typeof detailJson === 'object' && !Array.isArray(detailJson)) {
    // For update actions, detailJson is an object with field names as keys
    Object.keys(detailJson).forEach(function(fieldName) {
      const values = detailJson[fieldName];
      if (!Array.isArray(values) || values.length !== 2) return;
      
      const oldValue = values[0];
      const newValue = values[1];
      
      modalContent += '<div class="audit-change-group">';
      modalContent += `<h4 class="audit-field-name">${escapeHtml(fieldName)}</h4>`;
      modalContent += '<div class="audit-comparison">';
      
      // Before value
      modalContent += '<div class="audit-before">';
      modalContent += '<div class="audit-label">Before:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof oldValue === 'object' && oldValue !== null) {
        modalContent += '<pre>' + escapeHtml(JSON.stringify(oldValue, null, 2)) + '</pre>';
      } else {
        modalContent += escapeHtml(String(oldValue === null || oldValue === '' ? 'NULL' : oldValue));
      }
      modalContent += '</div></div>';
      
      // Arrow
      modalContent += '<div class="audit-arrow">→</div>';
      
      // After value
      modalContent += '<div class="audit-after">';
      modalContent += '<div class="audit-label">After:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof newValue === 'object' && newValue !== null) {
        modalContent += '<pre>' + escapeHtml(JSON.stringify(newValue, null, 2)) + '</pre>';
      } else {
        modalContent += escapeHtml(String(newValue === null || newValue === '' ? 'NULL' : newValue));
      }
      modalContent += '</div></div>';
      
      modalContent += '</div></div>'; // close comparison and change-group
    });
  } else if (action === 'update' && Array.isArray(detailJson)) {
    detailJson.forEach(function(change) {
      const fieldName = change[0];
      const values = change[1];
      const oldValue = values[0];
      const newValue = values[1];
      
      modalContent += '<div class="audit-change-group">';
      modalContent += `<h4 class="audit-field-name">${fieldName}</h4>`;
      modalContent += '<div class="audit-comparison">';
      
      // Before value
      modalContent += '<div class="audit-before">';
      modalContent += '<div class="audit-label">Before:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof oldValue === 'object' && oldValue !== null) {
        modalContent += '<pre>' + JSON.stringify(oldValue, null, 2) + '</pre>';
      } else {
        modalContent += escapeHtml(String(oldValue || 'NULL'));
      }
      modalContent += '</div></div>';
      
      // Arrow
      modalContent += '<div class="audit-arrow">→</div>';
      
      // After value
      modalContent += '<div class="audit-after">';
      modalContent += '<div class="audit-label">After:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof newValue === 'object' && newValue !== null) {
        modalContent += '<pre>' + JSON.stringify(newValue, null, 2) + '</pre>';
      } else {
        modalContent += escapeHtml(String(newValue || 'NULL'));
      }
      modalContent += '</div></div>';
      
      modalContent += '</div></div>'; // close comparison and change-group
    });
  } else if (action === 'create') {
    modalContent += '<div class="audit-change-group">';
    modalContent += '<div class="audit-message">Record created</div>';
    if (typeof detailJson === 'object') {
      modalContent += '<pre>' + escapeHtml(JSON.stringify(detailJson, null, 2)) + '</pre>';
    }
    modalContent += '</div>';
  } else if (action === 'destroy') {
    modalContent += '<div class="audit-change-group">';
    modalContent += '<div class="audit-message">Record deleted</div>';
    if (typeof detailJson === 'object') {
      modalContent += '<pre>' + escapeHtml(JSON.stringify(detailJson, null, 2)) + '</pre>';
    }
    modalContent += '</div>';
  } else {
    modalContent += '<div class="audit-change-group">';
    if (typeof detailJson === 'object') {
      modalContent += '<pre>' + escapeHtml(JSON.stringify(detailJson, null, 2)) + '</pre>';
    } else {
      modalContent += '<pre>' + escapeHtml(String(detailJson)) + '</pre>';
    }
    modalContent += '</div>';
  }
  
  modalContent += '</div>';
  
  if (typeof Ui.headerModal === 'function') {
    Ui.headerModal(titleText, {
      onOpenStart: function(modal, trigger) {
        $(modal).find('.modal-content').css('padding', '0').html(modalContent);
        $(modal).find('.modal-dialog').css({'max-width': '90vw', 'width': '1200px'});
        
        // Store modal reference
        window._currentAuditModal = modal;
        
        // Add keyboard navigation
        $(document).off('keydown.auditNav').on('keydown.auditNav', function(e) {
          if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
            e.preventDefault();
            navigateAuditLog(e.key === 'ArrowLeft' ? -1 : 1);
          }
        });
      },
      onCloseEnd: function() {
        $(document).off('keydown.auditNav');
        window._currentAuditModal = null;
        currentAuditGrid = null;
        currentAuditRow = null;
      }
    });
  } else {
    window._currentAuditModal = $('<div/>')
      .attr({'title': titleText})
      .html(modalContent)
      .appendTo('body')
      .dialog({
        autoOpen: true,
        width: Math.min(1200, window.innerWidth * 0.9),
        maxHeight: Math.min(700, window.innerHeight * 0.85),
        modal: true,
        close: function() {
          $(document).off('keydown.auditNav');
          $(this).dialog('destroy').remove();
          window._currentAuditModal = null;
          currentAuditGrid = null;
          currentAuditRow = null;
        }
      });
    
    // Add keyboard navigation
    $(document).off('keydown.auditNav').on('keydown.auditNav', function(e) {
      if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
        e.preventDefault();
        navigateAuditLog(e.key === 'ArrowLeft' ? -1 : 1);
      }
    });
  }
}

function navigateAuditLog(direction) {
  if (!currentAuditGrid || currentAuditRow === null) return;
  
  var newRow = currentAuditRow + direction;
  var dataView = currentAuditGrid.getData ? currentAuditGrid.getData() : (currentAuditGrid.loader ? currentAuditGrid.loader.data : null);
  
  if (!dataView) return;
  
  var item = dataView[newRow];
  if (!item && currentAuditGrid.loader && currentAuditGrid.loader.data) {
    item = currentAuditGrid.loader.data[newRow];
  }
  
  if (item) {
    // Update the modal content in place instead of closing and reopening
    currentAuditRow = newRow;
    updateModalContent(item);
  }
}

function updateModalContent(auditLog) {
  // Extract data from audit log
  var action, userEmail, detailJsonStr, detailStr, timestamp;
  
  if (Array.isArray(auditLog)) {
    action = auditLog[3];
    userEmail = auditLog[2] || 'System';
    detailStr = auditLog[5];
    detailJsonStr = auditLog[6];
    timestamp = auditLog[1];
  } else {
    action = auditLog.action;
    userEmail = auditLog.user_email || 'System';
    detailJsonStr = auditLog.detail_json;
    detailStr = auditLog.detail;
    timestamp = auditLog.created_at;
  }
  
  if (!detailJsonStr && detailStr) {
    detailJsonStr = detailStr;
  }
  
  // Parse JSON
  var detailJson;
  try {
    if (typeof detailJsonStr === 'string') {
      detailJson = JSON.parse(detailJsonStr);
    } else {
      detailJson = detailJsonStr;
    }
  } catch (e) {
    console.error('Failed to parse detail_json:', e);
    detailJson = { 
      _parseError: true,
      _message: 'Could not parse audit data. Please refresh the page to see updated format.',
      _rawPreview: String(detailJsonStr || '').substring(0, 500) + '...'
    };
  }
  
  // Generate new content
  var modalContent = '<div class="audit-detail-modal">';
  
  if (detailJson && detailJson._parseError) {
    modalContent += '<div class="audit-change-group">';
    modalContent += '<div class="audit-message" style="background: #fff3cd; border-color: #ffc107; color: #856404;">';
    modalContent += escapeHtml(detailJson._message);
    modalContent += '</div>';
    if (detailJson._rawPreview) {
      modalContent += '<pre style="max-height: 400px; overflow-y: auto;">' + escapeHtml(detailJson._rawPreview) + '</pre>';
    }
    modalContent += '</div>';
  } else if (action === 'update' && typeof detailJson === 'object' && !Array.isArray(detailJson)) {
    Object.keys(detailJson).forEach(function(fieldName) {
      const values = detailJson[fieldName];
      if (!Array.isArray(values) || values.length !== 2) return;
      
      const oldValue = values[0];
      const newValue = values[1];
      
      modalContent += '<div class="audit-change-group">';
      modalContent += '<h4 class="audit-field-name">' + escapeHtml(fieldName) + '</h4>';
      modalContent += '<div class="audit-comparison">';
      
      modalContent += '<div class="audit-before">';
      modalContent += '<div class="audit-label">Before:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof oldValue === 'object' && oldValue !== null) {
        modalContent += '<pre>' + escapeHtml(JSON.stringify(oldValue, null, 2)) + '</pre>';
      } else {
        modalContent += escapeHtml(String(oldValue === null || oldValue === '' ? 'NULL' : oldValue));
      }
      modalContent += '</div></div>';
      
      modalContent += '<div class="audit-arrow">→</div>';
      
      modalContent += '<div class="audit-after">';
      modalContent += '<div class="audit-label">After:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof newValue === 'object' && newValue !== null) {
        modalContent += '<pre>' + escapeHtml(JSON.stringify(newValue, null, 2)) + '</pre>';
      } else {
        modalContent += escapeHtml(String(newValue === null || newValue === '' ? 'NULL' : newValue));
      }
      modalContent += '</div></div>';
      
      modalContent += '</div></div>';
    });
  } else if (action === 'update' && Array.isArray(detailJson)) {
    detailJson.forEach(function(change) {
      const fieldName = change[0];
      const values = change[1];
      const oldValue = values[0];
      const newValue = values[1];
      
      modalContent += '<div class="audit-change-group">';
      modalContent += '<h4 class="audit-field-name">' + escapeHtml(fieldName) + '</h4>';
      modalContent += '<div class="audit-comparison">';
      
      modalContent += '<div class="audit-before">';
      modalContent += '<div class="audit-label">Before:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof oldValue === 'object' && oldValue !== null) {
        modalContent += '<pre>' + escapeHtml(JSON.stringify(oldValue, null, 2)) + '</pre>';
      } else {
        modalContent += escapeHtml(String(oldValue || 'NULL'));
      }
      modalContent += '</div></div>';
      
      modalContent += '<div class="audit-arrow">→</div>';
      
      modalContent += '<div class="audit-after">';
      modalContent += '<div class="audit-label">After:</div>';
      modalContent += '<div class="audit-value">';
      if (typeof newValue === 'object' && newValue !== null) {
        modalContent += '<pre>' + escapeHtml(JSON.stringify(newValue, null, 2)) + '</pre>';
      } else {
        modalContent += escapeHtml(String(newValue || 'NULL'));
      }
      modalContent += '</div></div>';
      
      modalContent += '</div></div>';
    });
  } else if (action === 'create') {
    modalContent += '<div class="audit-change-group">';
    modalContent += '<div class="audit-message">Record created</div>';
    if (typeof detailJson === 'object') {
      modalContent += '<pre>' + escapeHtml(JSON.stringify(detailJson, null, 2)) + '</pre>';
    }
    modalContent += '</div>';
  } else if (action === 'destroy') {
    modalContent += '<div class="audit-change-group">';
    modalContent += '<div class="audit-message">Record deleted</div>';
    if (typeof detailJson === 'object') {
      modalContent += '<pre>' + escapeHtml(JSON.stringify(detailJson, null, 2)) + '</pre>';
    }
    modalContent += '</div>';
  } else {
    modalContent += '<div class="audit-change-group">';
    if (typeof detailJson === 'object') {
      modalContent += '<pre>' + escapeHtml(JSON.stringify(detailJson, null, 2)) + '</pre>';
    } else {
      modalContent += '<pre>' + escapeHtml(String(detailJson)) + '</pre>';
    }
    modalContent += '</div>';
  }
  
  modalContent += '</div>';
  
  // Update modal title and content
  var titleText = formatAuditTitle(action, userEmail, timestamp);
  
  if (window._currentAuditModal) {
    if (typeof Ui.headerModal === 'function') {
      // Update content
      $(window._currentAuditModal).find('.modal-content').html(modalContent);
      
      // Update title - try multiple selectors
      var $title = $(window._currentAuditModal).find('.modal-title');
      if ($title.length === 0) {
        $title = $(window._currentAuditModal).find('.modal-header h5, .modal-header h4, .modal-header .title');
      }
      if ($title.length > 0) {
        $title.text(titleText);
      } else {
        // If we can't find title element, update the header HTML
        $(window._currentAuditModal).find('.modal-header').html('<h5 class="modal-title">' + escapeHtml(titleText) + '</h5>');
      }
    } else {
      // jQuery UI dialog
      $(window._currentAuditModal).dialog('option', 'title', titleText);
      $(window._currentAuditModal).html(modalContent);
    }
  }
}

function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, function(m) { return map[m]; });
}

// Attach double-click handler to audit log grids - using multiple approaches
$(document).ready(function() {
  // Try to intercept grid creation
  var originalGetGrid = window.gridManager && window.gridManager.getGrid;
  if (originalGetGrid) {
    window.gridManager.getGrid = function(name) {
      var grid = originalGetGrid.apply(this, arguments);
      if (grid && (grid.name === 'audit_log' || grid.name === 'record_audit')) {
        setupAuditGridHandler(grid);
      }
      return grid;
    };
  }
  
  // Continuous checking for audit grids
  setInterval(function() {
    if (window.gridManager) {
      var grids = window.gridManager.grids || [];
      grids.forEach(function(grid) {
        if (grid && (grid.name === 'audit_log' || grid.name === 'record_audit')) {
          // Check if handler is still attached (canvas might have been replaced)
          var slickGrid = grid.grid || grid.slickgrid || grid;
          if (slickGrid && slickGrid.getCanvasNode) {
            var canvasElement = $(slickGrid.getCanvasNode()).get(0);
            // If we have a canvas but no handler attached, set it up
            if (canvasElement && !grid._auditHandlerAttached) {
              setupAuditGridHandler(grid);
            }
          }
        }
      });
    }
  }, 1000);
});

function setupAuditGridHandler(grid) {
  // Get the actual SlickGrid instance
  var slickGrid = grid.grid || grid.slickgrid || grid;
  
  if (!slickGrid || !slickGrid.getCanvasNode) {
    return;
  }
  
  // Get the canvas element where SlickGrid binds events
  var $canvas = $(slickGrid.getCanvasNode());
  var canvasElement = $canvas.get(0);
  
  if (!canvasElement) return;
  
  // Remove previous handler if exists
  if (grid._auditDblClickCapture) {
    canvasElement.removeEventListener('dblclick', grid._auditDblClickCapture, true);
  }
  
  // Create handler
  grid._auditDblClickCapture = function(e) {
    // Get cell from event
    var cell = slickGrid.getCellFromEvent(e);
    if (!cell) {
      return;
    }
    
    // Stop all propagation immediately before SlickGrid sees it
    e.stopPropagation();
    e.stopImmediatePropagation();
    e.preventDefault();
    
    // Get the data
    var dataView = grid.getData ? grid.getData() : (grid.loader ? grid.loader.data : null);
    var item = dataView ? dataView[cell.row] : null;
    
    if (!item && dataView && typeof dataView.getItem === 'function') {
      item = dataView.getItem(cell.row);
    }
    
    if (!item && grid.loader && grid.loader.data) {
      item = grid.loader.data[cell.row];
    }
    
    if (item) {
      showAuditDetailModal(item, grid, cell.row);
    }
    
    return false;
  };
  
  // Add handler in capture phase (runs before bubble phase where SlickGrid listens)
  canvasElement.addEventListener('dblclick', grid._auditDblClickCapture, true);
  
  // Mark as attached
  grid._auditHandlerAttached = true;
  
  // Also hook into data load events to ensure handler persists
  if (grid.loader && grid.loader.onDataLoaded && !grid._auditDataLoadSubscribed) {
    grid.loader.onDataLoaded.subscribe(function() {
      // Small delay to ensure DOM is updated
      setTimeout(function() {
        var currentCanvas = $(slickGrid.getCanvasNode()).get(0);
        // If canvas changed, reattach
        if (currentCanvas && currentCanvas !== canvasElement) {
          grid._auditHandlerAttached = false;
          setupAuditGridHandler(grid);
        }
      }, 100);
    });
    grid._auditDataLoadSubscribed = true;
  }
}

// Audit action
WulinMaster.actions.Audit = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'audit',

  handler: function() {
    var self = this;
    var $gridContainer, currentGrid, selectedIds, recordUnit;

    currentGrid = this.getGrid();
    selectedIds = currentGrid.getSelectedIds();
    recordUnit = selectedIds.length > 1 ? 'records' : 'record';
    title = 'ID: ' + selectedIds + ' の ' + recordUnit + ' に対する監査ログ';
    ajaxOption = {
      type:'GET',
      data: {record_ids: selectedIds.join(','), class_name: currentGrid.model},
      url: '/wulin_audit/record_audits'
    }

    if (selectedIds.length < 1) {
      displayErrorMessage("監査ログを表示するには、レコードを選択してください。");
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
