document.addEventListener("DOMContentLoaded", function () {
  const fileInput = document.querySelector("#public-key-input");
  const textField = document.querySelector("#public_key_field");

  if(fileInput && textField) {
      fileInput.addEventListener("input", function (event) {
          event.preventDefault();
          const file = fileInput.files[0];
          if (file) {
              const reader = new FileReader();
              reader.onload = function (e) {
                  textField.value = e.target.result;
              };
              reader.readAsText(file);
          }
      });
  }
});
