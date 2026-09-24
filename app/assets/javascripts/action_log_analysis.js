window.WulinAuditAnalysis = (function() {
  var charts = [];

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

  function renderActivity() {
    var canvas = document.getElementById('action-log-activity-chart');
    if (!canvas) return;

    var data = readData('action-log-activity-data');
    var showTime = data.length && new Date(data[data.length - 1].x) - new Date(data[0].x) < 172800000;
    charts.push(new Chart(canvas, {
      type: 'line',
      data: {
        labels: data.map(function(point) {
          return new Date(point.x).toLocaleString([], showTime
            ? { hour: '2-digit', minute: '2-digit' }
            : { month: 'short', day: 'numeric' });
        }),
        datasets: [{
          label: 'Requests',
          data: data.map(function(point) { return point.y; }),
          borderColor: systemColor(canvas),
          backgroundColor: 'rgba(142, 23, 55, 0.12)',
          fill: true,
          pointRadius: data.length > 60 ? 0 : 2,
          tension: 0.15
        }]
      },
      options: {
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { autoSkip: true, maxTicksLimit: 8, maxRotation: 0 } },
          y: { beginAtZero: true, ticks: { precision: 0 } }
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
          backgroundColor: systemColor(canvas),
          barThickness: 28
        }]
      },
      options: {
        indexAxis: 'y',
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { beginAtZero: true, grid: { display: false }, ticks: { precision: 0 } },
          y: { grid: { display: false } }
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
    History.pushState(null, document.title, form.action + '?' + params.toString());
  }

  function bindFilters() {
    var form = document.getElementById('action-log-analysis-filters');
    if (!form) return;

    // The server sends UTC instants; the fields show and submit browser-local
    // time, matching the chart labels.
    form.querySelectorAll('input[data-datetime]').forEach(function(input) {
      input.value = formatWulinDateTime(new Date(input.dataset.datetime));
    });

    $(form).find('input[data-datetime]')
      .inputmask('wulinDateTime')
      .flatpickr(fpConfigFormDateTime);

    form.addEventListener('submit', function(event) {
      event.preventDefault();
      submitFilters(form);
    });

    form.querySelectorAll('input[data-datetime]').forEach(function(input) {
      input.addEventListener('change', function() {
        delete form.dataset.range;
        form.querySelectorAll('.quick-range').forEach(function(button) {
          button.classList.remove('active');
        });
      });
    });

    form.querySelectorAll('.quick-range').forEach(function(button) {
      button.addEventListener('click', function() {
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

    form.querySelector('.reset-filters').addEventListener('click', function() {
      History.pushState(
        null,
        document.title,
        form.action + '?screen=ActionLogAnalysisScreen&range=24h'
      );
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

  // Delegated once at load because init runs again on every panel reload.
  document.addEventListener('click', function(event) {
    var button = event.target.closest('.copy-request');
    if (!button) return;

    // navigator.clipboard is undefined outside secure contexts; the promise
    // chain turns that into the failure branch.
    Promise.resolve().then(function() {
      return navigator.clipboard.writeText(button.dataset.copy);
    }).then(function() {
      button.textContent = 'Copied';
      setTimeout(function() { button.textContent = 'Copy'; }, 1500);
    }, function() {
      button.textContent = 'Failed';
      setTimeout(function() { button.textContent = 'Copy'; }, 1500);
    });
  });

  if (window.History && History.Adapter) {
    History.Adapter.bind(window, 'statechange', destroyCharts);
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
