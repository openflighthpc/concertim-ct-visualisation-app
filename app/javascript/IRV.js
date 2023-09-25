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
  const parent_div = document.getElementById(options.parent_div_id)
  options.show = parent_div.dataset['show'];
  if (parent_div.dataset['rackids']) {
    options.rackIds = parent_div.dataset['rackids'].split(',');
  }
  const _irv = new IRVController(options);
});
