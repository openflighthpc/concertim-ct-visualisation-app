import "jquery";
import IRVController from './mia/coffee/src/canvas/irv/IRVController';

// Overwrite jquery's `$` to one that is closer to prototype's `$`.
// We don't have prototype installed, because my sanity wouldn't survive
// porting that too.
//
// This may result in breaking changes in behaviour.
document.$ = function(id) {
  return document.getElementById(id);
}

document.addEventListener("DOMContentLoaded", function () {
  jQuery.noConflict()

  const options = {};
  options.parent_div_id = 'rack_view';
  options.show = document.getElementById(options.parent_div_id).dataset['show'];
  const _irv = new IRVController(options);
});
