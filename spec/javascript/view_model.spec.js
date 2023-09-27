import ViewModel from 'canvas/irv/ViewModel'
import 'contrib/knockout.js'

test('class init', () => {
    ViewModel.initClass();
    expect(ViewModel.INIT_VIEW_MODE).toBe('Images and bars');
    expect(expect(ViewModel.INIT_FACE).toBe('front'));
});

test('model defaults', () => {
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

test('faceBoth returns true if current facing is "both"', () => {
    let model = new ViewModel();
    expect(model.faceBoth()).toBe(false);
    model.face("both");
    expect(model.faceBoth()).toBe(true);
});

describe("presetNames", () => {
    test('returns list of preset names', () => {
        let model = new ViewModel();
        expect(model.presetNames()).toEqual([])
        model.presetsById({"one": {"name": "testing"}, "two": {"name": "testing2"}})
        expect(model.presetNames()).toEqual(["testing", "testing2"])
    });

    test('order list case insensitively', () => {
        let model = new ViewModel();
        expect(model.presetNames()).toEqual([])
        model.presetsById({
            "one": {"name": "testing1"},
            "three": {"name": "TESTING3"},
            "two": {"name": "testing2"},
            "ten": {"name": "TeStInG10"},
        })
        expect(model.presetNames()).toEqual(["testing1", "TeStInG10", "testing2", "TESTING3"])
    });
});

describe('enablePresetSelection', () => {
    test('returns false if there are no presets', () => {
        let model = new ViewModel();
        model.presetsById({});
        expect(model.enablePresetSelection()).toBe(false);
    });

    test('returns true if there are any presets', () => {
        let model = new ViewModel();
        model.presetsById({"one": {"name": "testing"}, "two": {"name": "testing2"}});
        expect(model.enablePresetSelection()).toBe(true);
    });
});

describe('metricIds', () => {
    let model = new ViewModel();
    test('returns empty list if there are no metric templates', () => {
        model.metricTemplates([]);
        expect(model.metricIds()).toEqual([]);
    });
    test('does not include id of excluded metrics', () => {
        model.metricTemplates([
            {"name": "ct.capacity.rack", "id": 3},
            {"name": "ct.capacity.rack.suffix", "id": 4},
        ]);
        expect(model.metricIds()).toEqual([]);
    });
    test('includes id of all non-excluded metrics', () => {
        model.metricTemplates([
            {"name": "testing", "id": 1},
            {"name": "testing2", "id": 2},
        ]);
        expect(model.metricIds()).toEqual([1, 2]);
    });
});

describe('enableMetricSelection', () => {
    let model = new ViewModel();
    test('returns false if there are no metric templates', () => {
        model.metricTemplates([]);
        expect(model.enableMetricSelection()).toBe(false);
    });
    test('returns false if only excluded metrics are registered', () => {
        model.metricTemplates([{"name": "ct.capacity.rack", "id": 3}]);
        expect(model.enableMetricSelection()).toBe(false);
    });
    test('returns true if non-excluded metrics are registered', () => {
        model.metricTemplates([{"name": "testing", "id": 1}]);
        expect(model.enableMetricSelection()).toBe(true);
    });
});
