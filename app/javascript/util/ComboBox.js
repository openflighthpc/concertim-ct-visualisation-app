/*!
* (C) Concurrent Thinking Ltd 2013
* (C) Alces Flight Ltd 2023
*
* name: 'util/ComboBox',
* description: 'ComboBox to provide dynamic filtering combo boxes'
*
* adapted from Eric Waldheims MochiKit-based ComboBox
*/

import Util from 'canvas/common/util/Util';

if (RegExp.escape == undefined) {
    RegExp.escape = function(text) {
        return text.replace(/[/\-\\^$*+?.()|[\]{}]/g, '\\$&');
    }
}

const ComboBox = new Class({

    Binds: ['handleKey', 'handleKeyUp', 'clickOption', 'toggle', 'mouseDown', 'updateDataIds'],

    initialize: function(id, /* optional */config) {
        this.node = $(id);
        this.exposed_options = [];
        this.config = Object.merge({
            maxListLength: 10,
            options: [],
            highlightNotFound: true,
            isRemoteUrl: false,
            optionStringGetter: function(i) { return i }
        },(config || {}));
        this.textedit = this.node.getElements('input.drop_down_box')[0];
        this.button = this.node.getElements('input.drop_down_button')[0];
        var that = this;	
        this.button.addEvents({
            focus: function() {
                that.button.blur();
            },
            click: function(evt) {that.toggle(evt)}
        });

        this.optionslist = new Element('div', {
            'class': 'cbox-list',
            styles: {
                display: 'none',
                position: 'absolute'
            }
        });

        this.optionslist.addEvents({
            onselectstart: function() { return false; },
            click: this.clickOption
        });

        this.textedit.addEvents({
            keydown: this.handleKey,
            keyup: this.handleKeyUp
        });

        document.addEvents({
            mousedown: this.mouseDown
        });

        this.node.appendChild(this.optionslist);
    },

    add_change_callback: function(callback) {
        this.textedit.addEvents({
            onchange: callback
        });
    },

    isVisible: function(element) {
        return $(element).getStyle('display') != 'none';
    },

    mouseDown: function(evt) {
        var l = evt.target;
        var found;
        while (l && !found) {
            found = (l == this.node);
            l = l.parentNode;
        }

        if (found) {
            this.textedit.focus();
            this.moveCaretToEnd();
        }
        else {
            Util.hideElement(this.optionslist);
        }
    },

    _prevTexteditValue: "",

    handleKey: function(evt) {
        if (!this._loaded) {
            return;
        }
        this._prevTexteditValue = this.textedit.value;
        this._activate_dropdown = false;
        this._input = true;
        var key  = evt.key;
        switch(key) {
            case 'up':
                this.highlightPrevOption();
                evt.stopPropagation();
                break;
            case 'down':
                if (!this.isVisible(this.optionslist)) {
                    this.toggle(evt);
                } else {
                    this.highlightNextOption();
                }
                evt.stopPropagation();
                break;
            case 'esc':
                Util.hideElement(this.optionslist);
                evt.stopPropagation();
                break;
            case 'backspace':
            case 'delete':
                this._activate_dropdown = true;
                break;
            case 'tab':
            case 'enter':
                if (this.isVisible(this.optionslist) && this._highlighted_node) {
                    this.selectOption();
                    Util.hideElement(this.optionslist);
                    evt.stop();
                } else if ( key === 'enter' && this.textedit.style.background !== '' ) {
                    evt.stop();
                }
                break;
        }
    },

    handleKeyUp: function(evt) {
        var f = function() {
            if ( this._input === true ) {
                this._input = false;
                setTimeout(f, 100);
                return;
            }
            if (this._prevTexteditValue != this.textedit.value) {
                this.update();
                this.build(this.exposed_options);
            }
        }.bind(this);
        f();
    },

    selectOption: function() {
        var val = this.textedit.value;
        var tgt = this._highlighted_node;
        this.textedit.value = tgt.getAttribute("Desc");
        this.removeHighlight();

        if ( this._prevVal != val && !this._suppress_range ) {
            this._prevVal = this.textedit.value;
            this.setSelectionRange(val.length, this.textedit.value.length);
        }

        this.value = tgt.getAttribute("Data");

        if ((this.textedit.value != this._prevTexteditValue) || (this.isVisible(this.optionslist) && this._highlighted_node)) {
            this.textedit.fireEvent('onchange');
        }
    },

    moveCaretToEnd: function() {
        var t = this.textedit;
        if (t.createTextRange) {
            var range = t.createTextRange();
            range.collapse(false);
            range.select();
        } else if (t.setSelectionRange) {
            t.focus();
            var length = t.value.length;
            t.setSelectionRange(length, length);
        }
    },

    update: function() {
        var textedit_start_regexp = new RegExp('^' + RegExp.escape(this.textedit.value.toLowerCase()));
        var textedit_any_regexp = new RegExp(RegExp.escape(this.textedit.value.toLowerCase()));
        var options = this.config.options;
        var get = this.config.optionStringGetter;
        this.exposed_options = [];
        this._suppress_range = false;

        for(let i=0;i<options.length;i++) {
            if (options[i].toLowerCase().match(textedit_start_regexp)) {
                this.exposed_options.push(options[i]);
            } else if (options[i].toLowerCase().match(textedit_any_regexp)) {
                this.exposed_options.push(options[i]);
                this._suppress_range = true;
            }
        }
    },

    _connect_ids: [],

    build: function(options) {
        this.showing_all_options = options === this.config.options;
        while (this._connect_ids.length) { this._connect_ids.pop().removeEvents(); }
        const onmouseover = this.itemMouseOver.bind(this);
        const onmouseout = this.itemMouseOut.bind(this);
        var divs = [];
        for (var i = 0; i < options.length; ++i) {
            var data = options[i];
            var string = this.config.optionStringGetter(data);
            const div = document.createElement('div');
            div.classList.add('cbox-item');
            div.appendChild(document.createTextNode(string));
            div.addEvent('mouseover', onmouseover);
            div.addEvent('mouseout', onmouseout);
            this._connect_ids.push(div);
            div.setAttribute('Desc', string);
            div.setAttribute('Data', data);
            div.setAttribute('title', data);
            div.setAttribute('id', data);
            divs.push(div);
        }
        Util.replaceChildNodes(this.optionslist, ...divs);

        var visibleCount = Math.min(options.length, this.config.maxListLength);
        if ( this._loaded ) {
            if (options.length === 0 && this.textedit.value.length === 0 ) {
                this.addEmptyHighlight();
                return;
            } else if (!visibleCount) {
                Util.hideElement(this.optionslist);
                this.blurHighlightedNode();
                if (this.config.highlightNotFound) {
                    this.addErrorHighlight();
                }
                return;
            }
        }
        if (this._activate_dropdown || this._suppress_range || visibleCount > 1) {
            Util.showElement(this.optionslist);
            this.addEmptyHighlight();
        }
        // mjt - IE seems to break within MochiKit, guessing that firstChild is null (or perhaps... "not an object" ;-p).
        if ( !this.optionslist.firstChild ) {
            return;
        }

        var item_dims = Util.getElementDimensions(this.optionslist.firstChild);
        var textedit_dims = Util.getElementDimensions(this.textedit);
        var node_dims = Util.getElementDimensions(this.node);
        var h = visibleCount ? (visibleCount * item_dims.h) : 0;
        Util.setElementDimensions(this.optionslist, {w:node_dims.w});
        Util.setElementPosition(this.optionslist, {x:0, y: textedit_dims.h});

        this.highlightNode(divs[0]);
        if(!this._activate_dropdown && !this._suppress_range && this.exposed_options.length == 1) {
            this.selectOption();
            //Util.hideElement(this.optionslist);
        }
    },

    addErrorHighlight: function() {
        this.textedit.style.background = "#FF6666";
    },

    removeHighlight: function() {
        this.textedit.style.background = "";
    },

    addEmptyHighlight: function() {
        this.textedit.style.background = "#ddd";
    },

    clickOption: function(evt) {
        this.highlightNode(evt.target);
        this._suppress_range = true;
        this.selectOption();
        Util.hideElement(this.optionslist);
    },

    toggle: function(evt) {
        evt.stop();
        this._activate_dropdown = true;
        if (!this.optionslist || !this.isVisible(this.optionslist)) {
            this.update();
            this.build(this.config.options);
            this.textedit.focus();
            if (this.textedit.value !== "" && document.getElementById(this.textedit.value)) {
                this.highlightNode(document.getElementById(this.textedit.value));
            }
        } else {
            Util.hideElement(this.optionslist);
        }
    },

    highlightNode: function(node) {
        this.focusOptionNode(node);
        this.scrollIntoView(node);
    },

    scrollIntoView: function(el) {
        var rel_pos = el.offsetTop;
        var diff = rel_pos - (Util.getElementDimensions(this.optionslist).h/2);
        if (rel_pos > 0) {
            this.optionslist.scrollTop = diff;
        }
    },

    focusOptionNode: function(node) {
        if (this._highlighted_node != node) {
            this.blurHighlightedNode();
            this._highlighted_node = node;
            this._highlighted_node.classList.add("cbox-hilite");
        }
    },

    blurHighlightedNode: function() {
        if (this._highlighted_node) {
            this._highlighted_node.classList.remove("cbox-hilite");
            this._highlighted_node = null;
        }
    },

    highlightNextOption: function() {
        if ((!this._highlighted_node) || !this._highlighted_node.parentNode) {
            this.focusOptionNode(this.optionsListNode.firstChild);
        }
        else if (this._highlighted_node.nextSibling) {
            this.focusOptionNode(this._highlighted_node.nextSibling);
        }
        this.scrollIntoView(this._highlighted_node);
    },

    highlightPrevOption: function() {
        if (this._highlighted_node && this._highlighted_node.previousSibling) {
            this.focusOptionNode(this._highlighted_node.previousSibling);
        }
        this.scrollIntoView(this._highlighted_node);
    },

    itemMouseOver: function(evt) {
        this.focusOptionNode(evt.target);
    },

    itemMouseOut: function(evt) {
        this.blurHighlightedNode();
    },

    setOptions: function(d) {
        this.config.options = d;
    },

    setText: function(d) {
        this.textedit.value = d;
        this.textedit.fireEvent('onchange');
    },

    updateDataIds: function(dataArray) {
        this._completed = false;

        if (! this.failure_notice) {
            this.failure_notice = new Element('div', {
                'class' : 'drop_down_meta'
            });
            Util.insertSiblingNodesAfter(this.node, this.failure_notice);
        }
        if (dataArray === '') {
            this.failure_notice.innerHTML = '(Option retrieval interrupted)';
            this.failure_notice.tween('background-color', '#FC0');
            this.button.className = 'drop_down_button csshide';
        } else {
            this.failure_notice.innerHTML = '';
            this.button.className = 'drop_down_button loaded';
            this._loaded = true;
            this._completed = true;
            this.button.disabled = '';

            this.setOptions(dataArray);
            if (this.optionslist && this.isVisible(this.optionslist)) {
              // If the dropdown is displayed, update its contents making sure
              // to maintain any active filtering.
              if (this.showing_all_options) {
                    this.update();
                    this._activate_dropdown = true;
                    this.build(this.config.options);
                    if (document.getElementById(this.textedit.value)) {
                      this.highlightNode(document.getElementById(this.textedit.value));
                    }
              } else {
                    this.update();
                    this.build(this.exposed_options);
              }
            }
        }
    },

    loadKnockoutArray: function(dataPath) {
        // load in the data!
        var data = eval(dataPath + "()");
        this.updateDataIds(data);
    },

    updateFromUrl: function(url, error_msg) {
        if (error_msg == null) {
            var error_msg = "Unable to retrieve list";
        }

        var that = this;
        if (! this.failure_notice) {
            this.failure_notice = new Element('div', {
                'class' : 'drop_down_meta'
            });
            Util.insertSiblingNodesAfter(this.node, this.failure_notice);
        }

        this._completed = false;
        new Ajax.Request(url, {
            onLoading: function(transport) {
                if (that._completed) {return;}
                that.button.disabled = 'disabled';
                that.button.className = 'drop_down_button loading';
            },
            onSuccess: function(transport) {
                that.setOptions(eval(transport.responseText));
                if (transport.responseText === '') {
                    that.failure_notice.innerHTML = '(Option retrieval interrupted)';
                    that.failure_notice.highlight('#fcc');
                    that.button.className = 'drop_down_button csshide';
                } else {
                    that.failure_notice.innerHTML = '';
                    that.button.className = 'drop_down_button loaded';
                    that._loaded = true;
                }
            },
            onFailure: function(transport) {
                that.failure_notice.innerHTML = '('+error_msg+')';
                that.failure_notice.tween('background-color', '#FCC');
                that.button.className = 'drop_down_button csshide';
            },
            onComplete: function(transport) {
                that._completed = true;
                that.button.disabled = '';
            }
        });
    },

    setSelectionRange: function(selectionStart, selectionEnd) {
        if (this.textedit.setSelectionRange) {
            this.textedit.focus();
            this.textedit.setSelectionRange(selectionStart, selectionEnd);
        }
        else if (this.textedit.createTextRange) {
            var range = this.textedit.createTextRange();
            /* another IE hack! ;-) */
            if ( !this.textedit.collapse ) {
                return;
            }
            this.textedit.collapse(true);
            this.textedit.moveEnd('character', selectionEnd);
            this.textedit.moveStart('character', selectionStart);
            this.textedit.select();
        }
    },

    loadData: function(url) {
        if (this.config.isRemoteUrl=='true') {
            this.updateFromUrl(url);
        } else {
            this.loadKnockoutArray(url);
        }
    }
});

ComboBox.connect_all = function(c, config) {
    var cboxes = document.getElementsByClassName(c);
    for ( var i = 0; i < cboxes.length; i++ ) {
        ComboBox.connect(cboxes[i], config);
    }
};

ComboBox.connect = function(cbox, config) {
    if ( !cbox._loaded ) {
        cbox._loaded = true;
        var cbox_id = cbox.id.match(/(.*)_auto_complete_box/)[1];
        var url = $(cbox_id + '_url').value;
        var is_remote_url = $(cbox_id).get('data-is-remote-url') || false;
        var cb = new ComboBox(cbox, Object.merge((config||{}), {isRemoteUrl: is_remote_url}));
        ComboBox.boxes[cbox_id] = cb;
        cb.loadData(url);

        return cb;
    }
};

ComboBox.z_index=1000;
ComboBox.boxes={};

export default ComboBox;
