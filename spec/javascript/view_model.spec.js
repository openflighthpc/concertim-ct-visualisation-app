import ViewModel from 'canvas/irv/ViewModel'

test('class init', () => {
    ViewModel.initClass();
    expect(ViewModel.INIT_SHOW_CHART).toBe(true);
});
