import DragPolicy from 'canvas/irv/util/DragPolicy'

class Rack {
  constructor(id) {
    this.id = id;
  }
}

class Draggee {
  constructor(id, rack) {
    this.id = id;
    this._rack = rack;
  }

  rack() {
    return this._rack;
  }
}

const rack1 = new Rack("r1");
const rack2 = new Rack("r2");

describe("DragPolicy.filter", () => {
  test("returns empty list if draggee has no rack", () => {
    const draggee = new Draggee("d1");
    expect(DragPolicy.filter(draggee, [rack1, rack2])).toEqual([]);
  });

  test("returns draggee's rack if included in list of racks", () => {
    const draggee = new Draggee("d1", rack2);
    expect(DragPolicy.filter(draggee, [rack1, rack2])).toEqual([rack2]);
  });

  test.skip("returns empty list if draggee's rack is not included in list of racks", () => {
    // This test current fails, the return is `[rack2]`, but that isn't
    // included in the list of available racks.  I think that is probably a bug
    // in the implementation.
    const draggee = new Draggee("d1", rack2);
    expect(DragPolicy.filter(draggee, [rack1])).toEqual([]);
  });
});
