import CanvasController from 'canvas/common/CanvasController'
import IRVController from 'canvas/irv/IRVController'
import Configurator from 'canvas/irv/util/Configurator'
import 'mia/contrib/knockout.js'
let config;

beforeAll(() => {
   config = require('../../app/views/interactive_rack_views/_configuration.json');
});

test('does summit', () => {
    console.log(config)
});

