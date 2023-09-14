// Configures and displays the name label for a RackObject, e.g., Rack,
// Chassis, Machine.
class NameLabel {

  // overwritten by config
  static OFFSET_MAX_WIDTH  = 0;
  static FONT              = 'Karla';
  static COLOUR            = 'white';
  static ALIGN             = 'center';
  static BG_FILL           = 'black';
  static BG_PADDING        = 4;
  static BG_ALPHA          = .4;
  static OFFSET_X          = 0;
  static OFFSET_Y          = 22;
  static MIN_SIZE          = 13;
  static SIZE              = 60;

  constructor(gfxLayer, rackObject, viewModel) {
    // The GFX layer onto which the label will be drawn.
    this.gfxLayer = gfxLayer;
    // The rack object that we are drawing the label for.
    this.rackObject = rackObject;
    // The knockout view model.
    this.viewModel = viewModel;
    // The GFX object that is added/removed to the gfxLayer.
    this.label = null;
  }

  redraw() {
    if (this.label != null) {
      this.draw();
    }
  }

  draw() {
    if (this.label != null) { this.gfxLayer.remove(this.label); }
    const fontSize = this.fontSize();
    const defn = {
      x         : this.rackObject.x + (this.rackObject.width / 2) + NameLabel.OFFSET_X,
      y         : this.yPos(),
      caption   : this.labelText(),
      font      : fontSize + 'px ' + NameLabel.FONT,
      align     : NameLabel.ALIGN,
      fill      : this.fill(),
      maxWidth  : this.rackObject.width - (NameLabel.BG_PADDING * 2),
    }
    Object.assign(defn, this.textBg(), this.textShadow());
    this.label = this.gfxLayer.addText(defn);
  }

  remove() {
    if (this.label != null) {
      this.gfxLayer.remove(this.label);
      this.label = null;
    }
  }

  textBg() {
    return {
      bgFill    : NameLabel.BG_FILL,
      bgAlpha   : NameLabel.BG_ALPHA,
      bgPadding : NameLabel.BG_PADDING,
    };
  }

  textShadow() {
    return {};
  }

  fill() {
    return NameLabel.COLOUR;
  }

  fontSize() {
    let size = NameLabel.SIZE * this.gfxLayer.scale;
    if (size < NameLabel.MIN_SIZE) { size = NameLabel.MIN_SIZE; }
    return size;
  }

  labelText() {
    return this.rackObject.nameToShow();
  }

  // Place the label vertically centered on the rack object.
  yPos() {
    const offset = 2 * this.gfxLayer.scale;
    return this.rackObject.y + this.rackObject.height/2 + this.fontSize()/2 - offset;
  }
}

export default NameLabel;
