import CanvasViewModel from 'canvas/common/CanvasViewModel'
import 'mia/contrib/knockout.js'

test('class init sets expected values', () => {
    CanvasViewModel.initClass();
    expect(CanvasViewModel.INIT_FACE).toBe('front');
    expect(CanvasViewModel.FACE_FRONT).toBe('front');
    expect(CanvasViewModel.FACE_REAR).toBe('rear');
    expect(CanvasViewModel.FACE_BOTH).toBe('both');
    expect(CanvasViewModel.FACES).toEqual(['front', 'rear', 'both']);
});

test('new object has expected defaults', () => {
    let model = new CanvasViewModel();
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

test('faceBoth function', () => {
    let model = new CanvasViewModel();
    expect(model.faceBoth()).toBe(false);
    model.face = "both";
    expect(model.faceBoth()).toBe(true);
});
