window.WulinAuditAnalysis = (function() {
  var charts = [];
  var request;

  function readData(id) {
    var element = document.getElementById(id);
    return element ? JSON.parse(element.textContent) : [];
  }

  function destroyCharts() {
    charts.forEach(function(chart) { chart.destroy(); });
    charts = [];
  }

  function systemColor(element) {
    return getComputedStyle(element).getPropertyValue('--action-log-analysis-color').trim();
  }

  function hexToRgba(color, alpha) {
    var match = color.match(/^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i);
    if (!match) return color;
    return 'rgba(' + [1, 2, 3].map(function(i) { return parseInt(match[i], 16); }).join(', ') + ', ' + alpha + ')';
  }

  var axisStyle = { color: '#666', font: { size: 11 } };

  function renderActivity() {
    var canvas = document.getElementById('action-log-activity-chart');
    if (!canvas) return;

    var data = readData('action-log-activity-data');
    var color = systemColor(canvas);
    var spanMs = data.length > 1 ? new Date(data[1].x) - new Date(data[0].x) : 0;
    var showTime = data.length && new Date(data[data.length - 1].x) - new Date(data[0].x) < 172800000;
    function label(date) {
      return date.toLocaleString([], showTime
        ? { hour: '2-digit', minute: '2-digit', timeZone: 'UTC' }
        : { month: 'short', day: 'numeric', timeZone: 'UTC' });
    }
    function bucketTitle(date) {
      var options = { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', timeZone: 'UTC' };
      var end = new Date(date.getTime() + spanMs);
      return date.toLocaleString([], options) + ' – ' + end.toLocaleString([], options);
    }
    var dates = data.map(function(point) { return new Date(point.x); });

    // Bars, one per interval bucket: sparse counts stay visible, where a
    // line drew 1px spikes on a flat zero line. Empty buckets are null so
    // minBarLength lifts small counts without drawing a bar for zero.
    charts.push(new Chart(canvas, {
      type: 'bar',
      data: {
        labels: dates.map(label),
        datasets: [{
          label: 'Requests',
          data: data.map(function(point) { return point.y || null; }),
          backgroundColor: hexToRgba(color, 0.75),
          hoverBackgroundColor: color,
          barPercentage: 1,
          categoryPercentage: 0.9,
          minBarLength: 2
        }]
      },
      options: {
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              title: function(items) { return bucketTitle(dates[items[0].dataIndex]); },
              label: function(item) { return item.parsed.y + (item.parsed.y === 1 ? ' request' : ' requests'); }
            }
          }
        },
        scales: {
          x: { grid: { display: false }, ticks: Object.assign({ autoSkip: true, maxTicksLimit: 8, maxRotation: 0 }, axisStyle) },
          y: { beginAtZero: true, grid: { color: '#eef0f2' }, border: { display: false }, ticks: Object.assign({ precision: 0, maxTicksLimit: 6 }, axisStyle) }
        }
      }
    }));
  }

  function renderUsers() {
    var canvas = document.getElementById('action-log-users-chart');
    if (!canvas) return;

    var data = readData('action-log-users-data');
    charts.push(new Chart(canvas, {
      type: 'bar',
      data: {
        labels: data.map(function(row) { return row.label; }),
        datasets: [{
          label: 'Requests',
          data: data.map(function(row) { return row.count; }),
          backgroundColor: hexToRgba(systemColor(canvas), 0.75),
          hoverBackgroundColor: systemColor(canvas),
          maxBarThickness: 18
        }]
      },
      options: {
        indexAxis: 'y',
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { beginAtZero: true, grid: { color: '#eef0f2' }, border: { display: false }, ticks: Object.assign({ precision: 0, maxTicksLimit: 6 }, axisStyle) },
          y: { grid: { display: false }, ticks: axisStyle }
        }
      }
    }));
  }

  function submitFilters(form) {
    var params = new URLSearchParams(new FormData(form));
    if (form.dataset.range) params.set('range', form.dataset.range);
    ['from', 'to'].forEach(function(name) {
      var value = params.get(name);
      var date = parseWulinDateTime(value);
      if (date) params.set(name, date.toISOString());
    });
    Array.from(params.entries()).forEach(function(entry) {
      if (!entry[1]) params.delete(entry[0]);
    });
    refreshDashboard(form, form.action + '?' + params.toString());
  }

  // History.pushState fires statechange, and wulin_master then reloads the
  // whole screen. Replace only the dashboard panels and keep the filters.
  // The native replaceState keeps the URL for a page reload; its null state
  // makes History.js rebuild the state from the URL on back and forward.
  function refreshDashboard(form, url) {
    if (request) request.abort();
    history.replaceState(null, document.title, url);
    // Same loading bar as the wulin_master grids. Each request removes its
    // own bar, also when a newer filter change aborts it.
    var progress = $('<div class="progress analysis-progress"><div class="indeterminate"></div></div>').prependTo(form);
    request = $.get(url, { xhr: 1 }, function(html) {
      var page = new DOMParser().parseFromString(html, 'text/html');
      var filters = page.getElementById('action-log-analysis-filters');

      // The options depend on the range, and the server can clamp the range.
      form.querySelectorAll('select').forEach(function(select) {
        select.innerHTML = filters.querySelector('select[name="' + select.name + '"]').innerHTML;
      });
      form.querySelectorAll('input[data-datetime]').forEach(function(input) {
        setDateTime(input, new Date(filters.querySelector('[name="' + input.name + '"]').dataset.datetime));
      });

      page.querySelectorAll('.panel_container').forEach(function(panel) {
        if (!panel.contains(filters)) document.getElementById(panel.id).innerHTML = panel.innerHTML;
      });
      destroyCharts();
      renderActivity();
      renderUsers();
    });
    request.always(function() { progress.remove(); });
  }

  function bindFilters() {
    var form = document.getElementById('action-log-analysis-filters');
    if (!form) return;

    // The server sends UTC instants; the fields show and submit browser-local
    // time, matching the chart labels.
    form.querySelectorAll('input[data-datetime]').forEach(function(input) {
      input.value = formatWulinDateTime(new Date(input.dataset.datetime));
    });

    // wulin_master's flatpickr build does not position the calendar itself;
    // onCalendarOpenClose places it under the input, as in wulin forms.
    // Without it the calendar opens at the top left and covers the From field.
    $(form).find('input[data-datetime]')
      .inputmask('wulinDateTime')
      .flatpickr(fpMergeConfigs({}, fpConfigFormDateTime, onCalendarOpenClose));

    form.addEventListener('submit', function(event) {
      event.preventDefault();
      submitFilters(form);
    });

    form.querySelectorAll('select').forEach(function(select) {
      select.addEventListener('change', function() { submitFilters(form); });
    });

    // Inputmask fires change through jQuery only, which addEventListener
    // does not receive; jQuery also gets flatpickr's native change.
    $(form).find('input[data-datetime]').each(function() {
      $(this).on('change', function() {
        delete form.dataset.range;
        form.querySelectorAll('.quick-range').forEach(function(button) {
          button.classList.remove('active');
        });

        // Wait until both dates are complete and in order; the server
        // replaces an invalid range with the last 24 hours.
        var from = parseWulinDateTime(form.querySelector('[name="from"]').value);
        var to = parseWulinDateTime(form.querySelector('[name="to"]').value);
        if (from && to && from < to) submitFilters(form);
      });
    });

    form.querySelectorAll('.quick-range').forEach(function(button) {
      button.addEventListener('click', function() {
        // Clicking the active range again keeps its dates as a fixed range.
        if (button.classList.contains('active')) {
          button.classList.remove('active');
          delete form.dataset.range;
          submitFilters(form);
          return;
        }

        var to = new Date();
        var from = new Date(to.getTime() - Number(button.dataset.seconds) * 1000);
        setDateTime(form.querySelector('[name="from"]'), from);
        setDateTime(form.querySelector('[name="to"]'), to);
        form.querySelectorAll('.quick-range').forEach(function(rangeButton) {
          rangeButton.classList.toggle('active', rangeButton === button);
        });
        form.dataset.range = button.dataset.range;
        submitFilters(form);
      });
    });
  }

  function parseWulinDateTime(value) {
    var match = value && value.match(/^(\d{2})\/(\d{2})\/(\d{4}) (\d{2}):(\d{2})$/);
    return match && new Date(match[3], Number(match[2]) - 1, match[1], match[4], match[5]);
  }

  function formatWulinDateTime(date) {
    function pad(value) { return String(value).padStart(2, '0'); }
    return [
      pad(date.getDate()),
      pad(date.getMonth() + 1),
      date.getFullYear()
    ].join('/') + ' ' + pad(date.getHours()) + ':' + pad(date.getMinutes());
  }

  function setDateTime(input, date) {
    if (input._flatpickr) {
      input._flatpickr.setDate(date, false);
    } else {
      input.value = formatWulinDateTime(date);
    }
  }

  function showCopyResult(button, icon, title) {
    var iconElement = button.querySelector('.material-icons');
    button.classList.add('copy-result');
    iconElement.textContent = icon;
    button.title = title;
    setTimeout(function() {
      button.classList.remove('copy-result');
      iconElement.textContent = 'content_copy';
      button.title = 'Copy URL';
    }, 1500);
  }

  // Delegated once at load because init runs again on every panel reload.
  document.addEventListener('click', function(event) {
    var button = event.target.closest('.copy-request');
    if (!button) return;

    // navigator.clipboard is undefined outside secure contexts; the promise
    // chain turns that into the failure branch.
    Promise.resolve().then(function() {
      return navigator.clipboard.writeText(button.dataset.copy);
    }).then(function() {
      showCopyResult(button, 'check', 'Copied');
    }, function() {
      showCopyResult(button, 'error_outline', 'Copy failed');
    });
  });

  if (window.History && History.Adapter) {
    History.Adapter.bind(window, 'statechange', function() {
      if (request) request.abort();
      destroyCharts();
    });
  }

  return {
    init: function() {
      destroyCharts();
      bindFilters();
      renderActivity();
      renderUsers();
    }
  };
})();
