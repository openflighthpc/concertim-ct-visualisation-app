/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// sets up default values and throws errors if required properties are missing for each primative graphic type

const Validator = {};

Validator.Asset = function(data) {
  if (data.x == null) { data.x     = 0; }
  if (data.y == null) { data.y     = 0; }
  if (data.alpha == null) { data.alpha = 1; }
  if (data.fx == null) { return data.fx    = 'source-over'; }
};


Validator.Shape = function(data) {
  if (data.width == null) { throw "Missing property 'width'"; }
  if (data.height == null) { throw "Missing property 'height'"; }
};


Validator.FilledRect = function(data) {
  Validator.Asset(data);
  Validator.Shape(data);
  if (data.fill == null) { throw "Missing property 'fill'"; }
};


Validator.LineRect = function(data) {
  Validator.Asset(data);
  Validator.Shape(data);
  if (data.stroke == null) { throw "Missing property 'stroke'"; }
  if (data.strokeWidth == null) { return data.strokeWidth = 1; }
};


Validator.FullRect = function(data) {
  Validator.Asset(data);
  Validator.Shape(data);
  if (data.fill == null) { throw "Missing property 'fill'"; }
  if (data.stroke == null) { throw "Missing property 'stroke'"; }
  if (data.strokeWidth == null) { return data.strokeWidth = 1; }
};


Validator.Poly = function(data) {
  if (data.coords == null) { throw "Missing property 'coords'"; }
  if (data.coords.length === 0) { throw "No coordinates defined in 'coords'"; }
  if (!(data.coords instanceof Array)) { throw "Invalid coordinate supplied. 'coords' must be an array of objects { x: <x>, y: <y> }"; }
  return (() => {
    const result = [];
    for (var coord of Array.from(data.coords)) {
      if ((coord.x == null) || (coord.y == null)) { throw "Invalid coordinate supplied. 'coords' must be an array of objects { x: <x>, y: <y> }"; } else {
        result.push(undefined);
      }
    }
    return result;
  })();
};


Validator.FilledPoly = function(data) {
  Validator.Asset(data);
  Validator.Poly(data);
  if (data.fill == null) { throw "Missing property 'fill'"; }
};


Validator.LinePoly = function(data) {
  Validator.Asset(data);
  Validator.Poly(data);
  if (data.stroke == null) { throw "Missing property 'stroke'"; }
};


Validator.FullPoly = function(data) {
  Validator.Asset(data);
  Validator.Poly(data);
  if (data.fill == null) { throw "Missing property 'fill'"; }
  if (data.stroke == null) { throw "Missing property 'stroke'"; }
};


Validator.FilledEllipse = function(data) {
  Validator.Asset(data);
  Validator.Shape(data);
  if (data.fill == null) { throw "Missing property 'fill'"; }
};


Validator.LineEllipse = function(data) {
  Validator.Asset(data);
  Validator.Shape(data);
  if (data.stroke == null) { throw "Missing property 'stroke'"; }
  if (data.strokeWidth == null) { return data.strokeWidth = 1; }
};


Validator.FullEllipse = function(data) {
  Validator.Asset(data);
  Validator.Shape(data);
  if (data.fill == null) { throw "Missing property 'fill'"; }
  if (data.stroke == null) { throw "Missing property 'stroke'"; }
  if (data.strokeWidth == null) { return data.strokeWidth = 1; }
};


Validator.Image = function(data) {
  Validator.Asset(data);
  if (!data.img) { throw "Missing property 'img'"; }
  if (data.alpha == null) { data.alpha       = 1; }
  if (data.sliceX == null) { data.sliceX      = 0; }
  if (data.sliceY == null) { data.sliceY      = 0; }
  if (data.sliceWidth == null) { data.sliceWidth  = data.img.width; }
  if (data.sliceHeight == null) { data.sliceHeight = data.img.height; }
  if (data.width == null) { data.width       = data.sliceWidth; }
  if (data.height == null) { return data.height      = data.sliceHeight; }
};


Validator.Text = function(data) {
  Validator.Asset(data);
  if (data.align == null) { data.align   = 'left'; }
  if (data.caption == null) { data.caption = ''; }
  if (data.fill == null) { throw "Missing property 'fill'"; }
  if (data.font == null) { throw "Missing property 'font'"; }
};


Validator.ShadowText = function(data) {
  Validator.Asset(data);
  Validator.Text(data);
  if (data.shadowOffsetX == null) { data.shadowOffsetX = 2; }
  if (data.shadowOffsetY == null) { data.shadowOffsetY = 2; }
  if (data.shadowBlur == null) { data.shadowBlur    = 0; }
  if (data.shadowColour == null) { return data.shadowColour  = 'black'; }
};

Validator.BorderText = function(data) {
  Validator.Asset(data);
  Validator.Text(data);
  if (data.borderColour == null) { data.borderColour = 'gray'; }
  if (data.borderWidth == null) { return data.borderWidth  = 2; }
};

Validator.LabelText = function(data) {
  Validator.Asset(data);
  Validator.Text(data);
  if ((data.bgFill == null) && (data.bgStroke == null)) { throw "Missing property 'bgFill' or 'bgStroke'"; }
  if (!data.bgAlpha) { data.bgAlpha       = 1; }
  if (!data.bgPadding) { data.bgPadding     = 2; }
  if (!data.bgStrokeWidth) { return data.bgStrokeWidth = 1; }
};

export default Validator;
