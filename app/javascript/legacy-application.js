// Entry point for legacy loaded javascript.  That is the stuff loaded via the
// asset pipeline instead of via the new importmaps.

// The old asset pipeline way of doing things.  We should remove the old JS
// libraries and remove use of the old asset pipeline mechanism.
//
//= require mootools/mootools
//= require mootools/request.json.js
//= require mootools/morebinds
//= require mootools/fxcss
//= require mootools/fxtween
//
//= require MochiKit/Base
//= require MochiKit/Iter
//
//= require jquery
//= require modernizr
//= require foundation

jQuery(document).ready(function() {
  jQuery(document).foundation();
});

// Setup .copyToClipboard buttons to copy their given text to the clipboard.
document.addEventListener("DOMContentLoaded", function () {
  const copyToClipboardButtons = document.querySelectorAll(".copyToClipboard");
  copyToClipboardButtons.forEach((button) => {
    button.addEventListener("click", (ev) => {
      navigator.clipboard.writeText(button.dataset.text).
        then(() => { button.innerHTML = 'Copied'; });
      setTimeout(() => { button.innerHTML = 'Copy'; }, 1000);
    });
  });
});
