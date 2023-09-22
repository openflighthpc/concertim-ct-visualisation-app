import ViewModel from 'canvas/irv/ViewModel'
import AssetManager from 'canvas/irv/util/AssetManager'
import DragPolicy from 'canvas/irv/util/DragPolicy'
import Rack from 'canvas/irv/view/Rack'
import RackObject from 'canvas/irv/view/RackObject'
import Machine from 'canvas/irv/view/Machine'
import Profiler from 'Profiler'

import 'mia/contrib/knockout.js'

let rackData = {
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
}

let chassisData = {
        "template": {
            "id": 1,
            "name": "Large",
            "rackable": 1,
            "images": {
                "rear": "generic_rear_3u.png",
                "front": "generic_front_3u.png"
            },
            "height": 3,
            "rows": 1,
            "columns": 1,
            "depth": 2,
            "simple": true,
            "padding": {"left": 0, "right": 0, "top": 0, "bottom": 0}
        },
        "Slots": [rackData],
        "id":"1",
        "name":"Large-Rack-2-16953117339250503",
        "type":"RackChassis",
        "facing":"f",
        "rows":1,
        "slots":1,
        "cols":1,
        "uStart":0,
        "uEnd":3,
        "instances":[]
};

// circular logic?
rackData['chassis'] = [chassisData];

test('Make a rack', () => {
    let fakeImage = { height: 99 }
    Rack.IMAGES_BY_TEMPLATE[1] = {};
    Rack.IMAGES_BY_TEMPLATE[1].slices = {
        front: {
            top    : fakeImage,
            btm    : fakeImage,
            repeat : fakeImage,
        },
        rear: {
            top    : fakeImage,
            btm    : fakeImage,
            repeat : fakeImage,
        }
    };
    AssetManager.CACHE[RackObject.IMAGE_PATH + chassisData.template.images.front] = fakeImage;
    AssetManager.CACHE[RackObject.IMAGE_PATH + chassisData.template.images.rear] = fakeImage;

    RackObject.RACK_GFX = {"containerEl": {}};

   Profiler.makeCompatible();
   Profiler.LOG_LEVEL  = Profiler.INFO;
   Profiler.TRACE_ONLY = true;
   RackObject.MODEL = new ViewModel();
   RackObject.MODEL.deviceLookup({"racks": {}, "devices": {}, "chassis": {}})

   // dont try to draw image
   const mockedFunction = jest.fn();
   jest.spyOn(Rack.prototype, 'setImageCache').mockImplementation(mockedFunction);

   let rack = new Rack(rackData, "racks", 1);
});


