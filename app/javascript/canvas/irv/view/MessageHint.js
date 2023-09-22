/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';
import Hint from 'canvas/irv/view/Hint';

class MessageHint {

  constructor() {
    this.styles=['#000000', '#009900','#CC0000'];
  }


  show(captions) {
    const title = 'Device!';
    const content = 'The device';
    let fmtd_msg =  '<div class="messageContainer">';
    fmtd_msg +=   '<div class="title">'+title+'</div>';
    fmtd_msg +=   '<div class="message">';
    fmtd_msg +=     '<table>';
    for (var oneCaption of Array.from(captions)) {
      fmtd_msg +=     '<tr><td><span style="color:'+this.styles[oneCaption[1]]+'">'+oneCaption[0]+'</span></td></tr>';
    }
    fmtd_msg +=     '</table>';
    fmtd_msg +=   '</div>';
    fmtd_msg += '</div>';
    // return MessageSlider.instance.display(fmtd_msg, title, 5, new Date());
  }

  showPopUp(conf) {
    const container = conf.container_id;
    const header = '<h2>'+conf.header+'</h2>';
    const fade_in_param = 25;
    const fade_out_param = 25;
    const opacity_param = 90;
    const jump_anchor = '';
    const posx = conf.x;
    const posy = conf.y;
    const content = '<div class="ajaxPopup" id="' + container + '"></div>';
    overlib(jump_anchor + content, CAPTION, header, DRAGGABLE, DRAGCAP, CLOSECLICK, CLOSETEXT, '&nbsp;X&nbsp;', STICKY, BGCOLOR, 'transparent', FGCOLOR, 'transparent', FIXX, posx, FIXY, posy, NOJUSTX, NOJUSTY, CGCLASS, 'popup_caption', BGCLASS, 'popup_bg', FGCLASS, 'popup_fg', CLOSEFONTCLASS, 'popup_close', FILTER, FADEIN, fade_in_param, FADEOUT, fade_out_param, FILTEROPACITY, opacity_param );
    this.popUp = $(container);
    return this.popUp.appendChild(conf.content);
  }

  closePopUp() {
    // XXX What is this supposed to do?
    // return cClick();
  }
};

export default MessageHint;
