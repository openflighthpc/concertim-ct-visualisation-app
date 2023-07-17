import AssetManager from 'canvas/irv/util/AssetManager';
import NameLabel from 'canvas/irv/view/NameLabel';

// Configures and displays the label for a Chassis.
class ChassisLabel extends NameLabel {
  static FONT_SIZE = 24;
  static ICON_OFFSET_Y = 5;
  static ICON_OFFSET_X = 50;

  // Images loaded via AssetManager at the bottom of the file.
  static BUILD_STATE_IMAGES = {};
  static DEFAULT_IMG = null;

  static BUILD_STATE_COLOURS = {
    IN_PROGRESS: 'orange',
    ACTIVE: 'green',
    FAILED: 'red',
  };

  static buildStatusImage(buildStatus) {
    return ChassisLabel.BUILD_STATE_IMAGES[buildStatus] || ChassisLabel.DEFAULT_IMG;
  }

  fontSize() {
    let size = ChassisLabel.FONT_SIZE * this.gfxLayer.scale;
    if (size < NameLabel.MIN_SIZE) { size = NameLabel.MIN_SIZE; }
    return size;
  }

  draw() {
    super.draw();

    if (this.statusImg != null) { this.gfxLayer.remove(this.statusImg); }
    const imgSize = Math.floor(ChassisLabel.FONT_SIZE);
    const yPos = this.rackObject.y + imgSize/2 - ChassisLabel.ICON_OFFSET_Y;
    this.statusImg = this.gfxLayer.addImg({
      img: ChassisLabel.buildStatusImage(this.rackObject.buildStatus()),
      x: this.rackObject.x + (this.rackObject.width) - ChassisLabel.ICON_OFFSET_X,
      y: yPos,
      width: imgSize,
      height: imgSize,
    });
  }

  textBg() {
    return {};
  }

  textShadow() {
    return {
      shadowColour: 'white',
      shadowOffsetX: 1,
      shadowOffsetY: 1,
      shadowBlur: 0,
    };
  }

  remove() {
    super.remove();

    if (this.statusImg != null) {
      this.gfxLayer.remove(this.statusImg);
      this.statusImg = null;
    }
  }

  fill() {
    return ChassisLabel.BUILD_STATE_COLOURS[this.rackObject.buildStatus()] || "";
  }
}

AssetManager.get("/images/irv/tmp/inline-loading.gif", (img) => { ChassisLabel.DEFAULT_IMG = img; });
AssetManager.get("/images/irv/tmp/inline-loading.gif", (img) => { ChassisLabel.BUILD_STATE_IMAGES['IN_PROGRESS'] = img; });
AssetManager.get("/images/irv/tmp/green-tick.png", (img) => { ChassisLabel.BUILD_STATE_IMAGES['ACTIVE'] = img; });
AssetManager.get("/images/irv/tmp/red-cross.png", (img) => { ChassisLabel.BUILD_STATE_IMAGES['FAILED'] = img; });

export default ChassisLabel;
