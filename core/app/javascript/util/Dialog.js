/**
 * Based on code taken from
 * https://css-tricks.com/replace-javascript-dialogs-html-dialog-element/
 * Licence available at https://css-tricks.com/license/
 */

/**
* Dialog class for managing a HTMLDialogElement.
*/
class Dialog {
  constructor(settings = {}) {
    this.settings = Object.assign(
      {
        accept: 'OK',
        bodyClass: 'dialog-open',
        dialogClass: 'ct-vis-dialog',
        header: '',
        message: '',
        modal: false,
      },
      settings,
    )
    this.init()
  }

  getFocusable() {
    return [...this.dialogEl.querySelectorAll('button,[href],select,textarea,input:not([type="hidden"]),[tabindex]:not([tabindex="-1"])')];
  }

  init() {
    this.dialogEl = document.createElement('dialog');
    this.dialogEl.role = 'dialog';
    this.dialogEl.innerHTML = `
    <form method="dialog" data-ref="form">
      <h4 data-ref="header" id="${(Math.round(Date.now())).toString(36)}"></h4>
      <div data-ref="message"></div>
      <menu>
        <button type="button" data-ref="cancel" value="cancel"></button>
        <button type="button" data-ref="accept" value="default"></button>
      </menu>
    </form>`
    document.body.appendChild(this.dialogEl);

    this.elements = {};
    this.focusable = [];
    this.dialogEl.querySelectorAll('[data-ref]').forEach(el => this.elements[el.dataset.ref] = el);
    this.dialogEl.setAttribute('aria-labelledby', this.elements.message.id);
    this.elements.cancel.addEventListener('click', () => {
      this.dialogEl.dispatchEvent(new CustomEvent('dialog:cancel'));
    })
    this.dialogEl.addEventListener('keydown', e => {
      if (e.key === 'Escape') {
        this.dialogEl.dispatchEvent(new CustomEvent('dialog:cancel'));
      }
      if (e.key === 'Tab') {
        e.preventDefault();
        const len =  this.focusable.length - 1;
        let index = this.focusable.indexOf(e.target);
        index = e.shiftKey ? index - 1 : index + 1;
        if (index < 0) index = len;
        if (index > len) index = 0;
        this.focusable[index].focus();
      }
    })
  }

  update(settings = {}) {
    const mergedSettings = Object.assign({}, this.settings, settings);
    this.dialogEl.className = mergedSettings.dialogClass || '';
    this.elements.accept.innerText = mergedSettings.accept;
    this.elements.cancel.innerText = mergedSettings.cancel
    this.elements.cancel.hidden = mergedSettings.cancel === '' || mergedSettings == null;
    this.elements.message.innerText = mergedSettings.message;
    this.elements.header.innerHTML = mergedSettings.header || '';
    this.focusable = this.getFocusable();
  }

  open() {
    if (this.settings.modal) {
      this.dialogEl.showModal();
    } else {
      this.dialogEl.show();
    }
    this.elements.accept.focus();
  }

  close() {
    this.dialogEl.close();
  }

  toggle() {
    if (this.dialogEl.open) {
      this.close();
    } else {
      this.open();
    }
  }

  waitForUser() {
    return new Promise((resolve, reject) => {
      this.dialogEl.addEventListener('dialog:cancel', () => { 
        this.close();
        reject();
      }, { once: true })
      this.dialogEl.addEventListener('dialog:accept', () => {
        this.close();
        resolve();
      }, { once: true })
    })
  }

  alert(message, header='') {
    const settings = { message, header };
    this.update(settings);
    this.open();
    return this.waitForUser();
  }

  confirm(message, header='') {
    const settings = { message, header, cancel: 'Cancel' };
    this.update(settings);
    this.open();
    return this.waitForUser();
  }

}

export default Dialog;

// API compatible implementation of MIA's alert_dialog.
window.alert_dialog = function(message, header, modal) {
  const dialog = new Dialog({ modal });
  dialog.alert(message, header);
  return dialog;
}

// (Mostly) API compatible implementation of MIA's confirm_dialog.
window.confirm_dialog = function(question, header, modal) {
  const dialog = new Dialog({ modal });
  return dialog.confirm(question, header);
}
