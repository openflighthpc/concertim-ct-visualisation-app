/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

const Util = {

  SIG_FIG: 3,


  formatValue(num, sig_fig = null) {
    const str_val = String(num);
    if (str_val.split('.')[0].length >= (sig_fig || this.SIG_FIG)) {
      return Math.round(num);
    }
    return num.toPrecision(sig_fig || this.SIG_FIG);
  },


  // return a css property. This fn rewrites itself on first invocation 
  // to avoid re-evaluating feature detection
  getStyle(element, prop) {
    if (element.currentStyle) {
      this.getStyle = (element, prop) => element.currentStyle[prop];
    }
    if (document.defaultView && document.defaultView.getComputedStyle) {
      this.getStyle = (element, prop) => document.defaultView.getComputedStyle(element, '')[prop];
    } else {
      this.getStyle = (element, prop) => element.style[prop];
    }

    return this.getStyle(element, prop);
  },


  getStyleNumeric(element, prop) {
    const val = this.getStyle(element, prop);
    return Number(val.replace(/[^-\d\.]/g, ''));
  },


  // set a css property
  setStyle(element, prop, value) {
    element.style[prop] = value;
    return element;
  },


  // takes two numeric colour values and blends one into the other by 'amount'
  blendColour(low, high, amount) {
    const low_amount = 1 - amount;
  
    const low_r  = (low >> 16) & 0xff;
    const low_g  = (low >>  8) & 0xff;
    const low_b  = low & 0xff;
    const high_r = (high >> 16) & 0xff;
    const high_g = (high >>  8) & 0xff;
    const high_b = high & 0xff;
  
    const new_r = ((low_r * low_amount) + (high_r * amount)) & 0xff;
    const new_g = ((low_g * low_amount) + (high_g * amount)) & 0xff;
    const new_b = ((low_b * low_amount) + (high_b * amount)) & 0xff;
  
    return 0x0 | (new_r << 16 ) | (new_g << 8) | new_b;
  },


  arrayIndexOf(arr, to_find) {
    for (let idx = 0; idx < arr.length; idx++) {
      var item = arr[idx];
      if (item === to_find) { return idx; }
    }

    return -1;
  },


  // a fast way of finding an element in a sorted array. If the element can't be found
  // the routine returns success 'false' and the nearest match index
  // @param    arr       array to search
  // @param    to_find   value to search for
  // @param    property  optional, when searching an array of objects indicates the property to test
  // @returns  { success: true/false, idx: int }
  binaryIndexOf(arr, to_find, property) {
    let test_idx;
    let low_idx    = 0;
    let high_idx   = arr.length - 1;
    let test_count = 0;
    const test_prop  = (property != null);

    while (low_idx <= high_idx) {
      ++test_count;
      test_idx = ~~((low_idx + high_idx) / 2);
      var testee   = test_prop ? arr[test_idx][property] : arr[test_idx];
      
      if (testee < to_find) {
        low_idx = test_idx + 1;
      } else if (testee > to_find) {
        high_idx = test_idx - 1;
      } else {
        //console.log 'Util.binaryIndexOf tested: ' + test_count
        return { success: true, idx: test_idx };
      }
    }

    //console.log 'Util.binaryIndexOf tested: ' + test_count
    return { success: false, idx: test_idx };
  },


  // sort a list of objects according to an object property value
  sortByProperty: (list, field, ascending) => {
    const sortAsc = function(a, b) {
      if (a[field] > b[field]) { return 1; }
      if (b[field] > a[field]) { return -1; }
      return 0;
    };

    const sortDesc = function(a, b) {
      if (a[field] > b[field]) { return -1; }
      if (b[field] > a[field]) { return 1; }
      return 0;
    };

    if (ascending) { return list.sort(sortAsc); } else { return list.sort(sortDesc); }
  },


  sortCaseInsensitive(list) {
    const caseEval = function(a, b) {
      const diff = a.toLowerCase().localeCompare(b.toLowerCase());
      if (diff === 0) {
        if (a > b) { return 1; } else { return -1; }
      } else {
        return diff;
      }
    };

    return list.sort(caseEval);
  },


  // return an object with a DOM element's dimensions as numeric values
  getElementDimensions(element) {
    const dims = element.getSize();
    return { width: dims.x, height: dims.y };
  },


  // assumes vertical scrollbars have the same thickness as horizontal
  getScrollbarThickness() {
    const inner_el = document.createElement('p');
    this.setStyle(inner_el, 'width', '100%');
    this.setStyle(inner_el, 'height', '200px');

    const outer_el = document.createElement('div');
    this.setStyle(outer_el, 'position', 'absolute');
    this.setStyle(outer_el, 'top', '0');
    this.setStyle(outer_el, 'left', '0');
    this.setStyle(outer_el, 'visibility', 'hidden');
    this.setStyle(outer_el, 'width', '200px');
    this.setStyle(outer_el, 'height', '150px');
    this.setStyle(outer_el, 'overflow', 'hidden');
    outer_el.appendChild(inner_el);

    document.body.appendChild(outer_el);
    const natural_width  = inner_el.offsetWidth;
    const natural_height = inner_el.offsetHeight;
    this.setStyle(outer_el, 'overflow', 'scroll');
    let scroll_width = inner_el.offsetWidth;

    if (natural_width === scroll_width) {
      scroll_width = outer_el.clientWidth;
    }

    document.body.removeChild(outer_el);

    return natural_width - scroll_width;
  },


  substitutePhrase(text, key, value) {
    let phrase_match;
    if ((value === undefined) || (value === null) || (value.length === 0) || ((typeof(value) === 'string') && (value.replace(/^\s+|\s+$/g, '').length === 0))) {
      phrase_match = new RegExp('\\({2}[^\(]*?\\[\\[' + key + '\\]\\].*?\\){2}', 'g');
      text         = text.replace(phrase_match, '');
      phrase_match = new RegExp('\\[\\[' + key + '\\]\\]', 'g');
      return text.replace(phrase_match, '');
    } else {
      phrase_match = new RegExp('\\[\\[' + key + '\\]\\]', 'g');
      return text.replace(phrase_match, value);
    }
  },


  cleanUpSubstitutions(text) {
    return text.replace(/\({2}|\){2}/g, '');
  },


  // returns an array of phrase substitution keys present in a string
  // @param  text  a string to find substitution keys
  // @return an array of keys
  getSubstitutionKeys(text) {
    let match;
    const keys = [];
    const ptn  = /\[\[.+?\]\]/g;
    while ((match = ptn.exec(text))) { keys.push(match[0].substr(2, match[0].length - 4)); }
    
    return keys;
  },


  addLeadingZeros(num, len) {
    if (len == null) { len = 2; }
    num      = String(num);
    const parts    = num.split('.');
    while (parts[0].length < len) { parts[0] = 0 + parts[0]; }
    return parts.join('.');
  },


  // gets the mouse coords relative to the div
  resolveMouseCoords(div, ev) {
    let x, y;
    if (ev.pageX != null) {
      x = ev.pageX + div.scrollLeft;
      y = ev.pageY + div.scrollTop;
    } else {
      x = ev.clientX + document.body.scrollLeft + document.documentElement.scrollLeft + div.scrollLeft;
      y = ev.clientY + document.body.scrollTop + document.documentElement.scrollTop + div.scrollTop;
    }

    const offset = div.getPosition();
    return { x: x - offset.x, y: y - offset.y };
  },


  forceImmediateRedraw(el) {
    const tmp = document.createTextNode(' ');
    const dsp = Util.getStyle(el, 'display');
    
    el.appendChild(tmp);
    Util.setStyle(el, 'display', 'none');

    return setTimeout(function() {
      Util.setStyle(el, 'display', dsp);
      return el.removeChild(tmp);
    }
    , 20);
  },
  

  printHtmlInNewPage(html) {
    let left;
    const new_window = window.open();
    const node = document.doctype;
    const doctype = "<!DOCTYPE " + node.name + (node.publicId != null ? node.publicId : ' PUBLIC "' + node.publicId + {'"' : ''}) + ((left = !node.publicId && node.systemId) != null ? left : {' SYSTEM' : ''})  + (node.systemId != null ? node.systemId : ' "' + node.systemId + {'"' : ''}) + '>';
    const html_with_header = `${doctype} \
<html> \
<head> \
${document.head.innerHTML} \
<script language=\"javascript\" type=\"text/javascript\"> \
window.addEventListener(\"message\", receiveMessage, false); \
function receiveMessage(event) { \
alert(event.origin); \
} \
\
/* IE fails to clone canvas' when the drawing is done by the originating window \
attempt to redraw with local code in these cases */ \
function redrawCVS() \
{ \
var cvs_list = document.getElementsByTagName('canvas'); \
var count    = 0; \
var len      = cvs_list.length; \
while(count < len) \
{ \
var cvs  = cvs_list[count]; \
var data = cvs.getAttribute('data-b64'); \
if(data) \
{ \
window.open(data); \
var img = document.createElement('image'); \
img.src = data; \
cvs.getContext('2d').drawImage(img, 0, 0); \
} \
++count; \
} \
} \
\
function setRedraw() \
{ \
document.redrawCVS = redrawCVS; \
} \
</script> \
</head> \
<body onload='setRedraw()'> \
${html} \
</body> \
</html>`;
    new_window.document.write( html_with_header.replace(/absolute/g, 'fixed') );
    new_window.document.close();
    return window.setTimeout(function() {
      const svgs = new_window.document.getElementsByTagName('svg');
      if (svgs.length > 0) { svgs[0].style.position = 'static'; }
      let success = true;

      const canvas_list = document.getElementsByTagName('canvas');
      for (var canvas of Array.from(canvas_list)) {
        var new_canvas = new_window.document.getElementById(canvas.id);
        if (new_canvas) {
          var context = new_canvas.getContext('2d');
          try {
            context.drawImage(canvas, 0, 0);
          } catch (err) {
            success = false;
            new_canvas.setAttribute('data-b64', canvas.toDataURL());
          }
        }
      }
      if (!success) { new_window.document.redrawCVS(); }
      return new_window.print();
    }
    , 2000);
  }
};


export default Util;
