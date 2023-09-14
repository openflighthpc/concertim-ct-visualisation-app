import NameLabel from 'canvas/irv/view/NameLabel';
import RackNameLabel from 'canvas/irv/view/RackNameLabel';

// Configures and displays the owner label for a Rack.
//
// XXX Consider if this would be better done with configuration on RackNameLabel?
class RackOwnerLabel extends RackNameLabel {
  static OFFSET_Y = -45

  labelText() {
    return this.rackObject.owner.name;
  }

  yPos() {
    return super.yPos() + RackOwnerLabel.OFFSET_Y;
  }
}

export default RackOwnerLabel;
