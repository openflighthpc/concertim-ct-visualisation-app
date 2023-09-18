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
});


