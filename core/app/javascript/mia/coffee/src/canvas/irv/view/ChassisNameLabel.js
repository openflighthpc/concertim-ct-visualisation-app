import NameLabel from 'canvas/irv/view/NameLabel';
import Rack from 'canvas/irv/view/Rack';
import RackObject from 'canvas/irv/view/RackObject';

// Configures and displays the name label for a Chassis.
class ChassisNameLabel extends NameLabel {
  static FONT_SIZE = 24;

  fontSize() {
    let size = ChassisNameLabel.FONT_SIZE * this.gfxLayer.scale;
    if (size < NameLabel.MIN_SIZE) { size = NameLabel.MIN_SIZE; }
    return size;
  }

}

export default ChassisNameLabel;
