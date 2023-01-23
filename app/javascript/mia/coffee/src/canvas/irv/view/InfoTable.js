/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from '../../../canvas/common/util/Util';
import Text from '../../../canvas/irv/view/Text';
import Link from '../../../canvas/irv/view/Link';

class InfoTable {
  static initClass() {
    this.LINK_UNDERLINE_RATIO  = 0.85;
    this.LINK_UNDERLINE_SPACING  = 3;
    this.TEXT_COLOUR  = '#000000';
    this.LINK_COLOUR  = '#2B4A6B';
  }

  constructor(conf, parent) {
    this.conf = conf;
    this.parent = parent;
    this.gfx = this.conf.gfx; 
    this.assets = [];
    this.links = [];
    this.x = this.conf.x;
    this.y = this.conf.y;
    this.width = this.conf.row_width;
    this.height = this.conf.row_height*this.conf.n;
    this.parentEl = this.parent.parentEl;
  }

  draw() {
    let i;
    let n = 0;
    this.assets.push(this.gfx.addRect({
      x: this.conf.x, y: this.conf.y-this.conf.row_height,
      fill:this.conf.colors.header,
      width: this.conf.row_width, height: this.conf.row_height,
      stroke: this.conf.colors.line, strokeWidth: 1, alpha: this.conf.alfa
    }));

    while (n < this.conf.n) {
      var bg_row;
      if ((n % 2) !== 1) {
        bg_row = this.conf.colors.bg1;
      } else {
        bg_row = this.conf.colors.bg2;
      }

      this.assets.push(this.gfx.addRect({
        x: this.conf.x, y: (this.conf.y+(this.conf.row_height*n)),
        fill:bg_row,
        width: this.conf.row_width, height: this.conf.row_height,
        stroke: this.conf.colors.line, strokeWidth: 1, alpha: this.conf.alfa
      }));
      n++;
    }

    const cel_height_center = (this.conf.row_height / 2) + (this.conf.font.size/2);
    const cel_width = this.conf.row_width / this.conf.headers.length;
    const text_x = cel_width/2;

    for (i = 0; i < this.conf.headers.length; i++) {
      var oneHeader = this.conf.headers[i];
      this.assets.push(
        new Text({
          gfx     : this.gfx,
          x       : this.x+(cel_width*i)+text_x,
          y       : (this.y-this.conf.row_height)+cel_height_center,
          text    : oneHeader,
          font    : {decoration:'bolder',size:this.conf.font.size,fontFamily:this.conf.font.font},
          align   : this.conf.font.align,
          fill    : InfoTable.TEXT_COLOUR,
          maxWidth: cel_width
        })
      );
    }

    return (() => {
      const result = [];
      for (i = 0; i < this.conf.data.length; i++) {
        var oneData = this.conf.data[i];
        result.push((() => {
          const result1 = [];
          for (let y = 0; y < oneData.length; y++) {
            var oneValue = oneData[y];
            if (oneValue instanceof Array) {
              var link_colour = (oneValue[2] != null) ? oneValue[2] : InfoTable.LINK_COLOUR;
              var oneLink = new Link({
                gfx     : this.gfx,
                x       : this.x+(cel_width*y)+text_x,
                y       : this.y+(this.conf.row_height*i)+cel_height_center,
                text    : oneValue[0],
                font    : {decoration:'bolder',size:this.conf.font.size,fontFamily:this.conf.font.font},
                align   : this.conf.font.align,
                fill    : link_colour,
                url     : oneValue[1],
                maxWidth: cel_width
              }, this);
              this.links.push(oneLink);
              result1.push(this.assets.push(oneLink.asset_text));
            } else {
              var oneText = new Text({
                gfx     : this.gfx,
                x       : this.x+(cel_width*y)+text_x,
                y       : this.y+(this.conf.row_height*i)+cel_height_center,
                text    : oneValue,
                font    : {decoration:'',size:this.conf.font.size,fontFamily:this.conf.font.font},
                align   : this.conf.font.align,
                fill    : InfoTable.TEXT_COLOUR,
                maxWidth: cel_width
              });
              result1.push(this.assets.push(oneText.asset_text));
            }
          }
          return result1;
        })());
      }
      return result;
    })();
  }

  remove() {
    for (var oneAsset of Array.from(this.assets)) {
      this.gfx.remove(oneAsset);
    }
    this.assets = [];
    return this.links = [];
  }

  getLinkAt(x,y) {
    for (var oneLink of Array.from(this.links)) {
      if ((y > (oneLink.y-(oneLink.height/2))) && (y < (oneLink.y+(oneLink.height/2))) && (x > (oneLink.x - (oneLink.width/2))) && (x < (oneLink.x + (oneLink.width/2)))) {
        return oneLink;
      }
    }
    return null;
  }
};
InfoTable.initClass();
export default InfoTable;
