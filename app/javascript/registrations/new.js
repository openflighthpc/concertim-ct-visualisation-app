document.addEventListener("DOMContentLoaded", function () {
  const haveProjectSwitch = document.querySelector("#have_project_id");
  const projectIdWrapper = document.querySelector("#user_project_id_wrapper");
  if (haveProjectSwitch && projectIdWrapper) {

    function toggleProjectId() {
      if (haveProjectSwitch.checked) {
        projectIdWrapper.removeClass('hidden');
      } else {
        projectIdWrapper.addClass('hidden');
      }
    }

    haveProjectSwitch.addEventListener("change", toggleProjectId);
    toggleProjectId();
  }
});
