var Ajax = function() {};

Ajax._compat_warnings = true;

Ajax.Updater = function(target,url,opts) {
  if ( typeof opts == "undefined" ) {
    opts = {};
  }
  var s = opts['onSuccess'];
  this.target = target;
  var onSuccess = function(transport) {
    if ( typeof s != "undefined" && s !== null ) {
      s(transport);
    }
  };
  var c = opts['onComplete'];
  var onComplete = function(transport) {
    $(target).innerHTML = transport.responseText;
    if ( typeof c != "undefined" && c !== null ) {
      c(transport);
    }
  };
  opts.onSuccess = onSuccess;
  opts.onComplete = onComplete;
  new Ajax.Request(url,opts);
};

Ajax.Request = function(url,opts) {
    if ( Ajax._compat_warnings ) {
      Boot.warn("compatibility layer called for Ajax.Request with " + url + " and " + JSON.stringify(opts));
    }
    var method = 'post';
    if ( opts['method'] ) {
      method = opts['method'];
    }
    var r = new Request({url:url,method:method});
    var params = "";
    if ( opts['parameters'] ) {
      if ( typeof opts['parameters'] === 'string' ) {
	params = opts['parameters'];
      } else {
	params = Object.map(opts['parameters'], function(item,key) {
	    return key + "=" + item;
	  });
	params = Object.values(params).join("&");
      }
    }
    if ( opts['onSuccess'] ) {
	r.addEvent('success',function(responseText) {
		opts['onSuccess'](r.xhr);
	    });
    }
    if ( opts['onFailure'] ) {
	r.addEvent('failure',function(xhr) {
		opts['onFailure'](xhr);
	    });
    }
    if ( opts['onComplete'] ) {
	r.addEvent('complete',function() {
		opts['onComplete'](r.xhr);
	    });
    }
    if ( opts['onLoading'] ) {
	r.addEvent('request',function(responseText) {
		opts['onLoading'](r.xhr);
	    });
    }
    if ( Ajax._compat_warnings && window.console ) {
      console.log(r);
    }
    this.transport = r.xhr;
    r.send(params);
};

Array._compat_warnings = false;

Array.implement({
	last: function(){
	    if ( Array._compat_warnings ) {
	      Boot.warn("compatibility method Array#last called");
	    }
	    return this.getLast();
	}
});

Form = {};
Form.serialize = function(form){
    return form.toQueryString();
};
