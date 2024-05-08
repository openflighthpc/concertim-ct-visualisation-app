//==============================================================================
// Copyright (C) 2024-present Alces Flight Ltd.
//
// This file is part of Concertim Visualisation App.
//
// This program and the accompanying materials are made available under
// the terms of the Eclipse Public License 2.0 which is available at
// <https://www.eclipse.org/legal/epl-2.0>, or alternative license
// terms made available by Alces Flight Ltd - please direct inquiries
// about licensing to licensing@alces-flight.com.
//
// Concertim Visualisation App is distributed in the hope that it will be useful, but
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
// IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
// OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
// PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
// details.
//
// You should have received a copy of the Eclipse Public License 2.0
// along with Concertim Visualisation App. If not, see:
//
//  https://opensource.org/licenses/EPL-2.0
//
// For more information on Concertim Visualisation App, please visit:
// https://github.com/openflighthpc/concertim-ct-visualisation-app
//==============================================================================


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
