import "jquery";
import IRVController from './mia/coffee/src/canvas/irv/IRVController';

document.addEventListener("DOMContentLoaded", function () {
    const options = {};
    options.parent_div_id = 'rack_view';
    options.show = document.getElementById(options.parent_div_id).dataset['show'];
    // console.log("options", options);
    const _irv = new IRVController(options);
    console.log("_irv", _irv)
});
