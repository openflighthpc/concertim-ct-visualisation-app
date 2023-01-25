// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails"
// import "controllers"

// The old asset pipeline way of doing things.  This exists to support an old
// version of foundation.
//= require jquery
//= require foundation

jQuery(document).ready(function() {
  jQuery(document).foundation();
});
