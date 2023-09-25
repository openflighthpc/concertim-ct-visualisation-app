import ViewModel from 'canvas/irv/ViewModel'
import 'contrib/knockout.js'

test('class init', () => {
    ViewModel.initClass();
    expect(ViewModel.INIT_VIEW_MODE).toBe('Images and bars');
});

test('class init inherits from CanvasViewModel', () => {
    ViewModel.initClass();
    expect(expect(ViewModel.INIT_FACE).toBe('front'));
});

test('inherits defaults from CanvasViewModel', () => {
    let model = new ViewModel();
    expect(model.showingFullIrv()).toBe(false);
    expect(model.showingRacks()).toBe(false);
    expect(model.showingRackThumbnail()).toBe(false);
    expect(model.deviceLookup()).toEqual({});
    expect(model.racks()).toEqual([]);
    expect(model.groups()).toEqual(['racks', 'chassis', 'devices']);
    expect(model.face()).toBe('front');
    expect(model.faces()).toEqual(['front', 'rear', 'both']);
    expect(model.assetList()).toEqual([]);
});

test('inherits faceBoth function from CanvasViewModel', () => {
    let model = new ViewModel();
    expect(model.faceBoth()).toBe(false);
    model.face("both");
    expect(model.faceBoth()).toBe(true);
});

test('preset names', () => {
    let model = new ViewModel();
    expect(model.presetNames()).toEqual([])
    model.presetsById({"one": {"name": "testing"}, "two": {"name": "testing2"}})
    expect(model.presetNames()).toEqual(["testing", "testing2"])
});

test('enablePresetSelection', () => {
    let model = new ViewModel();
    expect(model.enablePresetSelection()).toBe(false);
    model.presetsById({"one": {"name": "testing"}, "two": {"name": "testing2"}})
    expect(model.enablePresetSelection()).toBe(true);
});

test('metric ids', () => {
    let model = new ViewModel();
    expect(model.metricIds()).toEqual([]);
    model.metricTemplates({"one": {"name": "testing", "id": 1}, "two": {"name": "testing2", "id": 2},
                           "excluded": {"name": "ct.capacity.rack", "id": 3}});
    expect(model.metricIds()).toEqual([1, 2]);
});

test('enableMetricSelection', () => {
    let model = new ViewModel();
    model.metricTemplates({"excluded": {"name": "ct.capacity.rack", "id": 3}});
    expect(model.enableMetricSelection()).toBe(false);
    model.metricTemplates({"one": {"name": "testing", "id": 1}});
    expect(model.enableMetricSelection()).toBe(true);
});
