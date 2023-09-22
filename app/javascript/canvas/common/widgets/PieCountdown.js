/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import Util from 'canvas/common/util/Util';

class PieCountdown {
  static initClass() {

    this.INTERVAL_STEP  = 1000;
    this.WIDTH_HEIGHT   = 20;
    this.BG_COLOR       = "rgba(165,196,224, 0.5)";
    this.PIE_COLOR      = "rgba(150,150,150, 0.4)";
    this.NUMBER_COLOR   = "rgba(70,70,70, 0.6)";
    this.BG_FACTOR      = 1.15;
  }

  constructor(gfx, originalSeconds) {
    this.executeStep = this.executeStep.bind(this);
    this.gfx = gfx;
    this.originalSeconds = originalSeconds;
    this.widthHeight = PieCountdown.WIDTH_HEIGHT;
    this.x = 0;
    this.y = 0;
    this.setSizes();
    this.ctx = this.gfx.cvs.getContext("2d");
    this.seconds = this.originalSeconds;
    this.total = this.seconds;
    this.color = PieCountdown.PIE_COLOR;
  }

  setSizes() {
    this.canvas_total_size = [
      this.widthHeight * PieCountdown.BG_FACTOR,
      this.widthHeight * PieCountdown.BG_FACTOR
    ];
    this.canvas_size = [
      this.widthHeight,
      this.widthHeight
    ];
    this.radius = Math.min(this.canvas_size[0], this.canvas_size[1]) / 2;
    this.bgRadius = this.radius * PieCountdown.BG_FACTOR;
    this.center = [
      this.bgRadius,
      this.bgRadius
    ];
    this.width = this.bgRadius * 2;
    return this.height = this.bgRadius * 2;
  }


  draw_next(step) {
    step = step || (1 - (this.seconds / this.total));
    if (step < 1) {
      this.ctx.beginPath();
      this.ctx.moveTo(this.center[0], this.center[1]);
      this.ctx.arc(this.center[0], this.center[1], this.radius, Math.PI * (-0.5 + 0), Math.PI * (-0.5 + (step * 2)), true); 
      this.ctx.lineTo(this.center[0], this.center[1]);
      this.ctx.closePath();
      this.ctx.fillStyle = this.color;
      return this.ctx.fill();
    }
  }

  drawBackground() {
    this.ctx.beginPath();
    this.ctx.arc(this.center[0], this.center[1], this.bgRadius, 0, Math.PI * 2, false);
    this.ctx.fillStyle = PieCountdown.BG_COLOR;
    return this.ctx.fill();
  }

  addTime(time) {
    this.seconds += time;
    return this.total += time;
  }

  changeSeconds(time) {
    return this.seconds = time;
  }

  stop() {
    if (this.interval != null) { return clearInterval(this.interval); }
  }

  hide() {
    this.stop();
    return this.clearCanvas();
  }

  start() {
    this.executeStep();
    return this.interval = setInterval(this.executeStep, PieCountdown.INTERVAL_STEP);
  }

  reStart(newTime) {
    if (newTime == null) { newTime = this.originalSeconds; }
    this.stop();
    this.seconds = newTime;
    this.total = this.seconds;
    return this.start();
  }

  updateNumber() {
    this.ctx.fillStyle = PieCountdown.NUMBER_COLOR;
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.font = "bold "+(this.widthHeight*0.65)+"px Arial";
    return this.ctx.fillText(this.seconds, this.center[0], this.center[1]);
  }

  clearCanvas() {
    return this.ctx.clearRect(0, 0, this.canvas_total_size[0], this.canvas_total_size[1]);
  }

  executeStep() {
    this.clearCanvas();
    this.drawBackground();
    this.draw_next();
    this.updateNumber();
    if (this.seconds-- === 0) {
      return clearInterval(this.interval);
    }
  }
    
  showHint(coords, hint) {
    if ((coords.x > this.x) && (coords.x < (this.x + this.width)) && (coords.y > this.y) && (coords.y < (this.y + this.height))) {
      return hint.showMessage("Refresh time remaining",coords.x,coords.y);
    } else {
      return hint.hide();
    }
  }
};
PieCountdown.initClass();
export default PieCountdown;
