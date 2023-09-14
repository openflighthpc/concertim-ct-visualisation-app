String.implement({
  escapeHTML: function() {
    var div = document.createElement('div');
    var text = document.createTextNode(this);
    div.appendChild(text);
    return div.innerHTML;
  }
});

Element.implement({
	hasClassName: function(className){
	    Boot.warn("compatibility method hasClassName called");
	    return this.hasClass(className);
	},
	    
	addClassName: function(className){
	    Boot.warn("compatibility method addClassName called");
	    return this.addClass(className);
	},
	    
	removeClassName: function(className){
	    Boot.warn("compatibility method removeClassName called");
	    return this.removeClass(className);
        },

	getElementsBySelector: function(selector){
	    Boot.warn("compatibility method getElementsBySelector called");
	    return this.getElements(selector);
	}
});

(function() {
  var a = Window.addListener;
  window.addListener = function() {
    var args = Array.prototype.slice.call(arguments);
    if ( args.length == 3 ) {
      Boot.warn("compatibility method addListener called");
      return Boot.addListener(args[0],args[1],args[2]);
    } else {
      return a(args[0],args[1]);
    }
  }
 })();
