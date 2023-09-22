// This file is the entry point for loading the interactive rack view (IRV)
// javascript.  Options are retrieved from the DOM and a IRVController created.

import IRVController from 'canvas/irv/IRVController';

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
