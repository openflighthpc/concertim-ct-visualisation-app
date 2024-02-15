document.addEventListener("DOMContentLoaded", function () {
    // On the launch cluster page, toggling an optional parameter group
    // checkbox does the following:
    //
    // 1. The fields for that group are displayed/hidden as appropriate.
    // 2. The inputs are updated to be required or not as appropriate.

    const optionalGroups = document.querySelectorAll('[data-cluster-form-optional-field-group="toggle"]');
    optionalGroups.forEach((group) => {
        const checkBox = group.querySelector('input[type="checkbox"]');
        checkBox.addEventListener('change', toggleFieldGroup);
        toggleFieldGroup({target: checkBox});
    });

    function toggleFieldGroup(event) {
        const checkBox = event.target;
        const fieldGroup = checkBox.closest('[data-cluster-form-optional-field-group="field-group"]');
        const fields = fieldGroup.querySelector('[data-cluster-form-optional-field-group="fields"]');
        if (checkBox.checked) {
            fields.style.maxHeight = fields.scrollHeight + "px";
            fields.querySelectorAll('input').forEach((el) => {
                el.setAttribute('required', 'required');
            });
        } else {
            fields.style.maxHeight = 0;
            fields.querySelectorAll('input').forEach((el) => {
                el.removeAttribute('required');
            });
        }
    }
});
