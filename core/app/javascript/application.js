// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails"
// import "controllers"

// The old asset pipeline way of doing things.  We should remove the old JS
// libraries and remove use of the old asset pipeline mechanism.
//
//= require mia/contrib/mootools/mootools
//= require mia/contrib/mootools/request.json.js
//= require mia/contrib/mootools/morebinds
//= require mia/contrib/mootools/fxcss
//= require mia/contrib/mootools/fxtween
//
//= require mia/contrib/MochiKit/Base
//= require mia/contrib/MochiKit/Iter
//= require mia/contrib/MochiKit/DOM
//= require mia/contrib/MochiKit/Style
//= require mia/contrib/MochiKit/Signal
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
