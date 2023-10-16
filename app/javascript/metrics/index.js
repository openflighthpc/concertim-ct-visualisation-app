document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("input[type='radio']").forEach((el) => {
        el.addEventListener('change', updateDatePickerDisplay);
    })
});

function updateDatePickerDisplay(event) {
    const disabled = event.target.value !== 'range';
    document.querySelectorAll('.metric-date-picker').forEach((el) => {
        el.disabled = disabled;
    })
}

