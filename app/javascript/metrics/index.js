document.addEventListener("DOMContentLoaded", function () {
    let charts = {};
    let colours = ['#FF5733', '#12c432', '#5733FF', '#ffb833', '#FF33A1', '#0ef8f0'];

    document.querySelectorAll("input[type='radio']").forEach((el) => {
        el.addEventListener('change', updateDatePickerDisplay);
    })

    document.querySelectorAll(".metric-check-box").forEach((el) => {
        el.addEventListener('change', loadOrHideMetricData);
    })

    document.querySelectorAll(".reset-zoom-button").forEach((el) => {
        el.addEventListener('click', resetZoom);
    })

    function updateDatePickerDisplay(event) {
        const disabled = event.target.value !== 'range';
        document.querySelectorAll('.metric-date-picker').forEach((el) => {
            el.disabled = disabled;
        })
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

    function loadMetrics(metricId) {
        let deviceId = document.getElementById("device-id").dataset.deviceId;
        let timeframe = document.querySelector("input[name='metric-timeline-choice']:checked").value;
        let dateParams = '';
        if(timeframe === "range") {
            dateParams = `&start_date=${document.getElementById('metric_start_date').value}`;
            dateParams += `&end_date=${document.getElementById('metric_end_date').value}`;
        }
        fetch(`/api/v1/devices/${deviceId}/metrics/${metricId}?timeframe=${timeframe}${dateParams}`)
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(data => {
                populateChart(metricId, data);
            })
    }

    function populateChart(metricId, data) {
        let chartSection = document.getElementById(`${metricId}-chart-section`);
        let canvas = chartSection.getElementById(`${metricId}-canvas`);
        let noDataText = chartSection.getElementsByClassName('no-data-text')[0];
        let resetZoomRow = chartSection.getElementsByClassName('reset-zoom-row')[0];
        let chart = charts[metricId];
        const colour = colours[canvas.dataset.index % colours.length];

        let chartData = {
            labels: data.map(row => row.timestamp),
            datasets: [
                {
                    label: metricId,
                    data: data.map(row => row.value),
                    fill: false,
                    backgroundColor: colour,
                    borderColor: colour
                }
            ]
        };

        if(chart == null) {
            if(data.length === 0) {
                noDataText.style.display = 'block';
                chartSection.style.display = 'block';
                resetZoomRow.style.display = 'none';
                return;
            }

            noDataText.style.display = 'none';
            resetZoomRow.style.display = 'block';
            charts[metricId] = new Chart(
                canvas,
                {
                    type: 'line',
                    data: chartData,
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
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
                                    enabled: true,
                                    mode: 'xy',
                                    rangeMin: {
                                        y: 0
                                    }
                                },
                            },
                        },
                    }
                }
            )
            chartSection.style.display = 'block';
        } else if(data.length === 0) {
            chart.destroy();
            charts[metricId] = null;
            noDataText.style.display = 'block';
            resetZoomRow.style.display = 'none';
            chartSection.style.display = 'block';
        } else {
            noDataText.style.display = 'none';
            chart.data = chartData;
            chart.update();
            resetZoomRow.style.display = 'block';
            chartSection.style.display = 'block';
        }
    }

    function resetZoom(event) {
        const topLevelEl = event.target.tagName === "BUTTON" ? event.target : event.target.parentNode;  // in case icon is clicked
        let chart = charts[topLevelEl.dataset.metricId];
        if(chart != null) {
            chart.resetZoom();
        }
    }
});

