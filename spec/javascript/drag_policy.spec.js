import ViewModel from 'canvas/irv/ViewModel'
import AssetManager from 'canvas/irv/util/AssetManager'
import DragPolicy from 'canvas/irv/util/DragPolicy'
import Rack from 'canvas/irv/view/Rack'
import RackObject from 'canvas/irv/view/RackObject'
import 'contrib/knockout.js'

// I've taken this from some live front end data, there may be some unnecessary fields
const deviceData = {
    "id": 1,
    "name": "comp102",
    "buildStatus": "IN_PROGRESS",
    "cost": "$0.00",
    "instances": [],
    "column": 0,
    "row": 0,
    "facing": "f",
    "template": {
        "images": {},
        "width": 1,
        "height": 1,
        "rotateClockwise": true
    },
    "focused": false
}

const chassisData = {
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
        "Slots": [{"Machine": deviceData}],
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

const rackData = {
    "owner": {
        "id": 5,
        "name": "bilbo",
        "login": "bilbo"
    },
    "template": {
        "id": 1,
        "name": "rack",
        "rackable": 3,
        "images": {
            "rack_rear_top": "misc_rack_600_rear_top.png",
            "rack_repeat_1": "misc_rack_600_repeat_1.png",
            "rack_front_top": "misc_rack_600_front_top.png",
            "rack_rear_bottom": "misc_rack_600_rear_bottom.png",
            "rack_front_bottom": "misc_rack_600_front_bottom.png"
        },
        "height": 42,
        "depth": 2,
        "padding_left": 0,
        "padding_right": 0,
        "padding_top": 0,
        "padding_bottom": 0,
        "simple": "true"
    },
    "id": 1,
    "name": "Rack-1",
    "uHeight": 42,
    "buildStatus": "IN_PROGRESS",
    "cost": "$0.00",
    "nextRackId": 2,
    "chassis": [chassisData]
}

// lots of class variables that require values before instantiating objects works
beforeAll(() => {
    // Pretend images, with minimal required data
    const fakeImage = { height: 99 }
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

    // Pretend front end element
    RackObject.RACK_GFX = {"containerEl": {}};

    RackObject.MODEL = new ViewModel();
    RackObject.MODEL.deviceLookup({"racks": {}, "devices": {}, "chassis": {}})

    // Dont try to draw images, as no canvas to draw. We could mock/ manually set one, but not really
    // relevant to this test.
    const mockedFunction = jest.fn();
    jest.spyOn(Rack.prototype, 'setImageCache').mockImplementation(mockedFunction);
});

afterAll(() => {
    Rack.IMAGES_BY_TEMPLATE = {};
    AssetManager.CACHE = {};
    RackObject.RACK_GFX = null;
    RackObject.MODEL = null;
    jest.restoreAllMocks();
});

test("filter function returns array containing just device's rack", () => {
   // There may be an easier or better way to generate a machine directly, but there are so, so many dependencies
   const rack = new Rack(rackData, "racks", 1);
   const machine = rack.children[0].children[0];
   expect(DragPolicy.filter(machine)).toEqual([rack]);
});
