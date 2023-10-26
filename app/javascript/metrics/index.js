document.addEventListener("DOMContentLoaded", function () {
    let charts = {};
    let requestControllers = {};
    const colours = ['#FF5733', '#12c432', '#5733FF', '#ffb833', '#FF33A1', '#0ef8f0'];

    document.querySelectorAll("input[type='radio']").forEach((el) => {
        el.addEventListener('change', updateDatePickerDisplay);
    });

    document.querySelectorAll(".metric-timeframe-input").forEach((el) => {
        el.addEventListener('change', loadAllMetricsData);
    });

    document.querySelectorAll(".reset-zoom-button").forEach((el) => {
        el.addEventListener('click', resetZoom);
    });

    let startDate = document.querySelector('#metric_start_date');
    if(startDate != null) { startDate.addEventListener('change', updateMinMetricEndDate); }

    let endDate = document.querySelector('#metric_end_date');
    if(endDate != null) { endDate.addEventListener('change', updateMaxMetricStartDate); }

    document.querySelectorAll(".metric-check-box").forEach((el) => {
        el.addEventListener('change', loadOrHideMetricData);
        el.disabled = false;
    });

    document.addEventListener('keydown', maybeEnableZoom);
    document.addEventListener('keyup', maybeDisableZoom);


    function updateDatePickerDisplay(event) {
        const disabled = event.target.value !== 'range';
        document.querySelectorAll('.metric-date-picker').forEach((el) => {
            el.disabled = disabled;
        })
    }

    function updateMaxMetricStartDate(event) {
        document.getElementById('metric_start_date').max = event.target.value;
    }

    function updateMinMetricEndDate(event) {
        const newMin = event.target.value !== '' ? event.target.value : new Date(new Date().setDate(new Date().getDate() - 90));
        document.getElementById('metric_end_date').min = newMin;
    }

    function loadOrHideMetricData(event) {
        const metricId = event.target.value;
        if(event.target.checked) {
            loadMetrics(metricId);
        } else {
            document.getElementById(`${metricId}-chart-section`).style.display = "none";
            let chart = charts[metricId];
            if(chart != null) {
                chart.destroy();
                charts[metricId] = null;
            }
        }
    }

    function loadAllMetricsData() {
        document.querySelectorAll(".metric-check-box:checked").forEach((el) => {
            loadMetrics(el.value);
        })
    }

    function loadMetrics(metricId) {
        if(requestControllers[metricId] != null) {
            requestControllers[metricId].abort();
        }

        requestControllers[metricId] = new AbortController();
        let deviceId = document.getElementById("device-id").dataset.deviceId;
        let timeframe = document.querySelector("input[name='metric-timeline-choice']:checked").value;
        let dateParams = '';
        if(timeframe === "range") {
            let startDate = document.getElementById('metric_start_date').value;
            let endDate = document.getElementById('metric_end_date').value;
            if(startDate === '' || endDate === '') { return; }
            dateParams = `&start_date=${startDate}&end_date=${endDate}`;
        }
        let chartSection = document.getElementById(`${metricId}-chart-section`);
        let loadingSpinner = chartSection.getElementsByClassName('loading-metrics')[0];
        loadingSpinner.style.visibility = 'visible';

        fetch(`/api/v1/devices/${deviceId}/metrics/${metricId}?timeframe=${timeframe}${dateParams}`, 
               {signal: requestControllers[metricId].signal} )
            .then(response => {
                if (!response.ok) {
                    loadingSpinner.style.visibility = 'hidden';
                    let errorMessage = `Unable to load ${metricId} metric data: ${response.status} ${response.statusText}`;
                    alert(errorMessage);
                    throw new Error(errorMessage);
                }
                return response.json();
            })
            .then(data => {
                populateChart(metricId, data);
            }).catch(error => {
              if (error.name !== 'AbortError') {
                  console.log(error.message);
              }
            });
    }

    function populateChart(metricId, data) {
        let chartSection = document.getElementById(`${metricId}-chart-section`);
        let canvas = chartSection.getElementById(`${metricId}-canvas`);
        let loadingSpinner = chartSection.getElementsByClassName('loading-metrics')[0];
        let noDataText = chartSection.getElementsByClassName('no-data-text')[0];
        let resetZoomRow = chartSection.getElementsByClassName('reset-zoom-row')[0];
        let chart = charts[metricId];
        const colour = colours[canvas.dataset.index % colours.length];

        if(chart != null) {
            chart.destroy();
            charts[metricId] = null;
        }

        loadingSpinner.style.visibility = 'hidden';

        if(data.length === 0) {
            noDataText.style.display = 'block';
            chartSection.style.height = "5rem";
            chartSection.style.display = 'block';
            resetZoomRow.style.display = 'none';
            return;
        }

        noDataText.style.display = 'none';
        resetZoomRow.style.display = 'block';
        chartSection.style.height = "20rem";
        charts[metricId] = new Chart(
            canvas,
            {
                type: 'line',
                data: {
                    labels: data.map(row => row.timestamp),
                    datasets: [
                        {
                            label: metricId,
                            data:  data.map(row => row.value),
                            fill: false,
                            backgroundColor: colour,
                            borderColor: colour
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        xAxes: [
                            {
                                type: "time",
                                ticks: {
                                    maxTicksLimit: 50
                                }
                            }
                        ],
                        yAxes: [
                            {
                                beforeBuildTicks: function(scale) {
                                    const onlyZeroes =  scale.chart.data.datasets[0].data.every((value) => { return value === 0 || value === null; });
                                    if(onlyZeroes) { scale.min = 0; } // without this y axis goes negative
                                },
                            }
                        ]
                    },
                    title: {
                        display: true,
                        fontSize: 16,
                        text: metricId
                    },
                    legend: {
                        display: false
                    },
                    plugins: {
                        zoom: {
                            pan: {
                                enabled: true,
                                mode: 'xy',
                                rangeMin: {
                                    y: 0
                                }
                            },
                            zoom: {
                                enabled: false,
                                mode: 'xy',
                                rangeMin: {
                                    y: 0
                                }
                            },
                        },
                    },
                }
            }
        );
        chartSection.style.display = 'block';
    }

    function resetZoom(event) {
        const topLevelEl = event.target.tagName === "BUTTON" ? event.target : event.target.parentNode;  // in case icon is clicked
        let chart = charts[topLevelEl.dataset.metricId];
        if(chart != null) {
            chart.resetZoom();
        }
    }

    function maybeEnableZoom(event) {
        if (event.shiftKey) {
            for (let chart of Object.values(charts)) {
                chart.options.plugins.zoom.zoom.enabled = true;
                chart.update();
            }
        }
    }

    function maybeDisableZoom(event) {
        if (event.key === "Shift") {
            for (let chart of Object.values(charts))  {
                chart.options.plugins.zoom.zoom.enabled = false;
                chart.update();
            }
        }
    }
});

