import NameLabel from 'canvas/irv/view/NameLabel';
import ViewModel from 'canvas/irv/ViewModel';

// Configures and displays the name label for a Rack.
class RackNameLabel extends NameLabel {

  // overwritten by config
  static CAPTION_FRONT = '[ front ]';
  static CAPTION_REAR  = '[ rear ]';

  fontSize() {
    let size = NameLabel.SIZE * this.gfxLayer.scale;
    if (size < NameLabel.MIN_SIZE) { size = NameLabel.MIN_SIZE; }
    return size;
  }

  labelText() {
    if (this.viewModel.showingRacks() && !this.viewModel.showingFullIrv()) {
      if ((this.rackObject.face === ViewModel.FACE_FRONT) || (this.rackObject.bothView === ViewModel.FACE_FRONT)) {
        return "Front View";
      } else {
        return "Rear View";
      }
    }

    let suffix;
    if (this.viewModel.face() === ViewModel.FACE_FRONT) {
      suffix = RackNameLabel.CAPTION_FRONT
    } else {
      suffix = RackNameLabel.CAPTION_REAR
    }
    let name = `${this.rackObject.nameToShow()} ${suffix}`;

    return name;
  }

  // Place the name label above the rack.
  yPos() {
    return this.rackObject.y + NameLabel.OFFSET_Y;
  }
}

export default RackNameLabel;
