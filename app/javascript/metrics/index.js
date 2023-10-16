document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("input[type='radio']").forEach((el) => {
        el.addEventListener('change', updateDatePickerDisplay);
    })

    document.querySelectorAll(".metric-check-box").forEach((el) => {
        el.addEventListener('change', loadOrHideMetricData);
    })
});

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
    }
}

function loadMetrics(metricId) {
    let deviceId = document.getElementById("device-id").dataset.deviceId;
    let timeframe = document.querySelector("input[name='metric-timeline-choice']").value;
    fetch(`/api/v1/devices/${deviceId}/metrics/${metricId}?timeframe=${timeframe}`)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            console.log(data);
        })
        .catch(error => {
            console.error(error);
        });
}
