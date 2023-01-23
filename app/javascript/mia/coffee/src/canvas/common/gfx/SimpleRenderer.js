/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Easing from './Easing';
import Primitives from './Primitives';
import Validator from './Validator';

// optimise not organise
// A simple canvas rendering engine. LIMITATIONS: doesn't support layers, it
// assumes no objects will overlap each other for this reason multiple
// SimpleRenderers should be overlayed to give the effect. Animations will
// always override any animation currently playing on the given asset.
class SimpleRenderer {
  static initClass() {
    this.UNSUPPORTED        = 'Erk! Your browser doesn\'t support canvas :(';
    this.DEFAULT_FRAME_RATE = 24;

    this.CVS_IDX = 0;
  }


  constructor(containerEl, width, height, scale, frame_rate) {
    this.queueFrame = this.queueFrame.bind(this);
    this.animateCVS = this.animateCVS.bind(this);
    this.runAnims = this.runAnims.bind(this);
    this.drawFrame = this.drawFrame.bind(this);
    this.containerEl = containerEl;
    this.width = width;
    this.height = height;
    if (scale == null) { scale = 1; }
    this.scale = scale;
    if (frame_rate == null) { frame_rate = SimpleRenderer.DEFAULT_FRAME_RATE; }
    this.cvs = document.createElement('canvas');
    if (!this.cvs.getContext) {
      console.log(SimpleRenderer.UNSUPPORTED);
      return SimpleRenderer.UNSUPPORTED;
    }

    this.cvs.setAttribute('id', 'SR' + SimpleRenderer.CVS_IDX);
    this.cvs.setAttribute('name', 'SR' + SimpleRenderer.CVS_IDX);
    this.cvs.width  = this.width * this.scale;
    this.cvs.height = this.height * this.scale;

    ++SimpleRenderer.CVS_IDX;

    this.ctx           = this.cvs.getContext('2d');
    this.frameInterval = 1000 / frame_rate;
    this.assetDir      = {};
    this.assetId       = 0;
    this.anims         = [];
    this.clearList     = [];
    this.drawList      = [];
    this.animsById     = {};
    this.scaling       = false;
    this.paused        = false;
    this.containerEl.appendChild(this.cvs);

    if (frame_rate > 0) {
      // requestAnimation frame (where supported) tells the browser that animation is occurring
      // this allows for optimisation, e.g. rendering is ignored when viewing a different tab
      window.requestAnimationFrame = this.setAnimFrame();
      // queue initial draw
      window.requestAnimationFrame(this.drawFrame);
      // requestAnimationFrame runs at 60fps, the setInterval overrides this
      this.drawId = setInterval(this.queueFrame, this.frameInterval);
      this;
    }
  }


  setAnimFrame() {
    // return browser specific requestAnimationFrame routine with fallback where unsupported
    let left, left1, left2, left3;
    const fallback = callback => window.setTimeout(callback, 1000 / 60);
    return (left = (left1 = (left2 = (left3 = window.requestAnimationFrame != null ? window.requestAnimationFrame : window.webkitRequestAnimationFrame) != null ? left3 : window.mozRequestAnimationFrame) != null ? left2 : window.oRequestAnimationFrame) != null ? left1 : window.msRequestAnimationFrame) != null ? left : fallback;
  }


  queueFrame() {
    return window.requestAnimationFrame(this.drawFrame);
  }


  destroy() {
    if (this.drawId != null) { clearInterval(this.drawId); }
    if (this.scaleId != null) { clearInterval(this.scaleId); }
    return this.containerEl.removeChild(this.cvs);
  }


  clearCVS() {
    return this.ctx.clearRect(0, 0, this.cvs.width, this.cvs.height);
  }


  removeAll() {
    this.clearCVS();
    this.anims     = [];
    this.animsById = {};
    return this.assetDir  = {};
  }


  setDims(width, height) {
    this.width = width;
    this.height = height;
    this.cvs.width  = this.width * this.scale;
    this.cvs.height = this.height * this.scale;
    return this.redraw();
  }


  // redraw one or all assets
  redraw(asset_id) {
    if (asset_id != null) {
      return this.drawList.push(asset_id);
    } else {
      this.clearCVS();
      for (var asset in this.assetDir) { this.assetDir[asset].draw(this.scale); }
      this.clearList = [];
      return this.drawList  = [];
    }
  }


  setScale(scale, duration, ease, on_complete) {
    if (duration != null) {
      if (ease == null) { ease       = Easing.Linear.easeIn; }
      const num_frames = Math.ceil(duration / this.frameInterval);
      this.cvsAnim = {
        frameIdx: 0,
        sequence: this.getSequence(this.scale, scale, num_frames, ease),
        onComplete: on_complete
      };

      if (!this.scaling) {
        this.scaleId = setInterval(this.animateCVS, this.frameInterval);
        return this.scaling = true;
      }
    } else {
      return this.scaleCVS(scale);
    }
  }


  scaleCVS(scale) {
    this.cvs.width  = this.width * scale;
    this.cvs.height = this.height * scale;
    this.scale      = scale;
    return this.redraw();
  }


  animateCVS() {
    this.scaleCVS(this.cvsAnim.sequence[this.cvsAnim.frameIdx]);
    ++this.cvsAnim.frameIdx;
    if(this.cvsAnim.frameIdx === this.cvsAnim.sequence.length) {
      if (this.cvsAnim.onComplete != null) { this.cvsAnim.onComplete(); }
      clearInterval(this.scaleId);
      return this.scaling = false;
    }
  }


  pauseAnims() {
    //clearInterval(@drawId)
    return this.paused = true;
  }


  resumeAnims() {
    return this.paused = false;
  }
    //if @anims.length > 0
    //  @drawId = setInterval(@runAnims, @frameInterval)


  // append asset region to clear list
  remove(asset_id) {
    const asset = this.assetDir[asset_id];
    if (asset != null) {
      this.clearList.push(asset.getBoundaries(this.scale));
      this.stopAnim(asset_id);
      return delete this.assetDir[asset_id];
    }
  }


  // clear from the canvas
  clear(asset) {
    const bounds = asset.getBoundaries(this.scale);
    return this.ctx.clearRect(bounds.x - 1, bounds.y - 1, bounds.width + 2, bounds.height + 2);
  }


  // tests if the bounding boxes of two assets overlap
  hitTest(asset_a, asset_b) {
    let asset = this.assetDir[asset_a];

    if (asset == null) { return false; }

    const bounds_a        = asset.getBoundaries(this.scale);
    bounds_a.right  = bounds_a.x + bounds_a.width;
    bounds_a.bottom = bounds_a.y + bounds_a.height;

    asset = this.assetDir[asset_b];

    if (asset == null) { return false; }

    const bounds_b = asset.getBoundaries(this.scale);
    bounds_b.right  = bounds_b.x + bounds_b.width;
    bounds_b.bottom = bounds_b.y + bounds_b.height;

    // ugly! but a little more performant than splitting this up
    // into more legible pieces.
    return (((bounds_b.x >= bounds_a.x) && (bounds_b.x <= bounds_a.right)) || ((bounds_b.right >= bounds_a.x) && (bounds_b.right <= bounds_a.right)) || ((bounds_b.x < bounds_a.x) && (bounds_b.right > bounds_a.right))) && (((bounds_b.y >= bounds_a.y) && (bounds_b.y <= bounds_a.bottom)) || ((bounds_b.bottom > bounds_a.y) && (bounds_b.bottom < bounds_a.bottom)) || ((bounds_b.y < bounds_a.y) && (bounds_b.bottom > bounds_a.bottom)));
  }

  // add line
  addLine(def) {
    const asset_id = ++this.assetId;
    def.id   = asset_id;
    const asset    = new Primitives.Line(def, this.scale, this.ctx);
    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }

  // add arrow
  addArrow(def) {
    const asset_id = ++this.assetId;
    def.id   = asset_id;
    const asset    = new Primitives.Arrow(def, this.scale, this.ctx);
    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }

  // add circle to canvas, returns asset id
  addCircle(def) {
    const asset_id = ++this.assetId;
    def.id   = asset_id;
    const asset    = new Primitives.Circle(def, this.scale, this.ctx);

    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }

  // add rectangle to canvas, returns asset id
  addRect(def) {
    let asset, asset_id;
    if ((def.fill != null) && (def.stroke != null)) {
      Validator.FullRect(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.FullRect(def, this.scale, this.ctx);
    } else if (def.fill != null) {
      Validator.FilledRect(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.FilledRect(def, this.scale, this.ctx);
    } else {
      Validator.LineRect(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.LineRect(def, this.scale, this.ctx);
    }

    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }


  // add polygon to canvas, returns asset id
  addPoly(def) {
    let asset, asset_id;
    if ((def.fill != null) && (def.stroke != null)) {
      Validator.FullPoly(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.FullPoly(def, this.scale, this.ctx);
    } else if (def.fill != null) {
      Validator.FilledPoly(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.FilledPoly(def, this.scale, this.ctx);
    } else {
      Validator.LinePoly(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.LinePoly(def, this.scale, this.ctx);
    }

    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }


  // add ellipse to canvas, returns asset id
  addEllipse(def) {
    let asset, asset_id;
    if ((def.fill != null) && (def.stroke != null)) {
      Validator.FullEllipse(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.FullEllipse(def, this.scale, this.ctx);
    } else if (def.fill != null) {
      Validator.FilledEllipse(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.FilledEllipse(def, this.scale, this.ctx);
    } else {
      Validator.LineEllipse(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.LineEllipse(def, this.scale, this.ctx);
    }

    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }


  // add image to canvas, returns asset id
  addImg(def) {
    Validator.Image(def);
    const asset_id = ++this.assetId;
    def.id   = asset_id;
    const asset    = new Primitives.Image(def, this.scale, this.ctx);

    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }


  // add text to canvas, returns asset id
  addText(def) {
    let asset, asset_id;
    if (def.bgFill || def.bgStroke) {
      Validator.LabelText(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.LabelText(def, this.scale, this.ctx);
    } else if(def.shadowColour != null) {
      Validator.ShadowText(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.ShadowText(def, this.scale, this.ctx);
    } else if(def.borderColour != null) {
      Validator.BorderText(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.BorderText(def, this.scale, this.ctx);
    } else {
      Validator.Text(def);
      asset_id = ++this.assetId;
      def.id   = asset_id;
      asset    = new Primitives.Text(def, this.scale, this.ctx);
    }

    this.assetDir[asset_id] = asset;
    this.drawList.push(asset_id);
    return asset_id;
  }


  // animate an existing object. on_complete callbacks can occur immediately if duration
  // and delay are < 0.5 frames or the animation is invalid
  animate(asset_id, attributes, duration, ease, on_complete, params, redraw_list) {
    let delay;
    if (ease == null) { ease = Easing.Linear.easeIn; }
    const num_frames = Math.ceil(duration / this.frameInterval);

    // convert delay in ms to frames
    if (attributes.delay != null) {
      delay = Math.round(attributes.delay / this.frameInterval);
      delete attributes.delay;
    } else {
      delay = 0;
    }

    // if animation is zero length (or < 0.5 frames) set attributes and trigger any callback
    if ((num_frames <= 0) && (delay <= 0)) {
      if (on_complete != null) { on_complete(asset_id, params); }
      return this.setAttributes(asset_id, attributes);
    }

    const asset = this.assetDir[asset_id];
  
    // prepare anim objet
    const anim_obj = {
      id         : asset_id,
      frameIdx   : 0,
      attributes : [],
      onComplete : on_complete,
      paramsi    : params,
      redrawList : redraw_list
    };

    let valid = false;

    // validate the supplied attributes, i.e. they exist, are of the same type as the existing
    // attributes and are a different value to the current attributes. valid = false if none
    // meet these requirements
    for (var i in attributes) {
      if ((asset[i] != null) && (asset[i] !== attributes[i]) && (typeof asset[i] === typeof attributes[i])) {
        anim_obj.attributes.push({
          attribute: i,
          sequence: this.getSequence(asset[i], attributes[i], num_frames, ease, delay)});

        valid = true;
      }
    }

    // if requested animation is valid, delete any existing anim for the asset and add anim object
    // to anim queue. Otherwise trigger any supplied callback
    if (valid) {
      if (this.animsById[asset_id] != null) { this.anims.splice(this.anims.indexOf(this.animsById[asset_id]), 1); }
      this.anims.push(anim_obj);
      this.animsById[asset_id] = anim_obj;
    } else if (on_complete != null) {
      on_complete(asset_id, params);
    }

    return valid;
  }


  // sets attributes of an asset and redraws. Encourages all attributes to be set in one go to avoid multiple redraws
  setAttributes(asset_id, attributes) {
    const asset = this.assetDir[asset_id];
    this.clearList.push(asset.getBoundaries(this.scale));
    for (var i in attributes) { asset[i] = attributes[i]; }
    return this.drawList.push(asset_id);
  }


  // returns an asset attribute
  getAttribute(asset_id, attribute) {
    return this.assetDir[asset_id][attribute];
  }


  getBounds(asset_id) {
    return this.assetDir[asset_id].getBoundaries(this.scale);
  }


  runAnims() {
    if (this.paused) { return; }

    let count = 0;
    let len   = this.anims.length;
    return (() => {
      const result = [];
      while (count < len) {
        var attr_obj;
        var anim_obj = this.anims[count];
        var {
          id
        } = anim_obj;
        var asset    = this.assetDir[id];
        var count2   = 0;
        var len2     = anim_obj.attributes.length;

        // designate clearance region before attributes are updated
        this.clearList.push(asset.getBoundaries(this.scale));

        while (count2 < len2) {
          attr_obj = anim_obj.attributes[count2];
          asset[attr_obj.attribute] = attr_obj.sequence[anim_obj.frameIdx];
          ++count2;
        }

        ++anim_obj.frameIdx;
        if (anim_obj.frameIdx === attr_obj.sequence.length) {
          var on_complete = anim_obj.onComplete;
          this.anims.splice(count, 1);
          delete this.animsById[id];
          if (on_complete != null) { on_complete(id, anim_obj.params); }
          --len;
        } else {
          ++count;
        }

        // push to draw list
        this.drawList.push(id);
        if (anim_obj.redrawList != null) {
          result.push((() => {
            const result1 = [];
            for (id of Array.from(anim_obj.redrawList)) {
              this.clearList.push(this.assetDir[id].getBoundaries(this.scale));
              result1.push(this.drawList.push(id));
            }
            return result1;
          })());
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }


  drawFrame() {
    this.runAnims();
    for (var region of Array.from(this.clearList)) { this.ctx.clearRect(region.x - 1, region.y - 1, region.width + 2, region.height + 2); }
    this.clearList = [];

    const drawn = [];
    for (var asset_id of Array.from(this.drawList)) {
      // prevent duplicate draws
      var asset = this.assetDir[asset_id];
      if ((asset != null) && !drawn[asset_id]) {
        this.assetDir[asset_id].draw(this.scale);
        drawn[asset_id] = true;
      }
    }
    this.drawList = [];

    // drawComplete can be assigned externally. Triggers a callback when frame finishes rendering
    if (this.drawComplete != null) { return this.drawComplete(); }
  }


  // called on initialising an animation, generates an array of steps to animate from 'start' to 'end'
  getSequence(start, end, num_frames, ease, delay) {
    const sequence = [];

    let count = 0;
    while (count < delay) {
      sequence.push(start);
      ++count;
    }

    count = 1;

    if (typeof(start) === 'string') {
      start = parseInt(start.substr(1), 16);
      end   = parseInt(end.substr(1), 16);

      const start_r = (start >> 16) & 0xff;
      const start_g = (start >> 8) & 0xff;
      const start_b = start & 0xff;

      const end_r = (end >> 16) & 0xff;
      const end_g = (end >> 8) & 0xff;
      const end_b = end & 0xff;

      const delta_r = end_r - start_r;
      const delta_g = end_g - start_g;
      const delta_b = end_b - start_b;

      while(count <= num_frames) {
        var progress = ease(count, num_frames);
        var r = start_r + (delta_r * progress);
        var g = start_g + (delta_g * progress);
        var b = start_b + (delta_b * progress);
        var blended = ((r << 16) | (g << 8) | b).toString(16);
        while(blended.length < 6) {
          blended = '0' + blended;
        }
        sequence.push('#' + blended);
        ++count;
      }
    } else {
      const delta = end - start;
      while (count <= num_frames) {
        sequence.push(start + (delta * ease(count, num_frames)));
        ++count;
      }
    }
    return sequence;
  }


  stopAnim(asset_id) {
    // maintaining animsById allows us to check if the asset is animating 
    // without iterating through the whole anims array
    if (this.animsById[asset_id] != null) {
      delete this.animsById[asset_id];
      let count = 0;
      const len = this.anims.length;
      return (() => {
        const result = [];
        while (count < len) {
          if (this.anims[count].id === asset_id) {
            this.anims.splice(count, 1);
            break;
          }
          result.push(++count);
        }
        return result;
      })();
    }
  }
};
SimpleRenderer.initClass();
export default SimpleRenderer;
