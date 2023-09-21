import ViewModel from 'canvas/irv/util/DragPolicy'
import Rack from 'canvas/irv/view/Rack'
import RackObject from 'canvas/irv/view/RackObject'
import Machine from 'canvas/irv/view/Machine'

import 'mia/contrib/knockout.js'

let data = {
    "owner": {
        "id": "5",
        "name": "turnip",
        "login": "turnip"
    },
    "template": {
        "id": "1",
        "name": "rack",
        "rackable": "3",
        "images": {
            "rack_rear_top": "misc_rack_600_rear_top.png",
            "rack_repeat_1": "misc_rack_600_repeat_1.png",
            "rack_front_top": "misc_rack_600_front_top.png",
            "rack_rear_bottom": "misc_rack_600_rear_bottom.png",
            "rack_front_bottom": "misc_rack_600_front_bottom.png"
        },
        "height": "42",
        "depth": "2",
        "padding_left": "0",
        "padding_right": "0",
        "padding_top": "0",
        "padding_bottom": "0",
        "simple": "true"
    },
    "id": "1",
    "name": "Rack-1",
    "uHeight": "42",
    "buildStatus": "IN_PROGRESS",
    "cost": "$0.00",
    "nextRackId": "2"
};

test('Make a rack', () => {
   RackObject.MODEL = new ViewModel();
   let rack = new Rack(data);
});


