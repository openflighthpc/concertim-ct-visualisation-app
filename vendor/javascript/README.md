# Vendored JavaScript files

These JavaScript libraries have been vendored as we are using old versions of
them and cannot easily update them right now.

* jquery.js : A dependency of foundation.js the CSS framework we are currently
  using.  Also possibly used by parts of the interactive rack view.
* modernizr.js : An old version of https://modernizr.com/.
* mootools : Used by the interactive rack view.  It has a number of (once)
  useful utility functions especially for creating classes and making XHR
  requests.  Our use of these should be replaced with now standard javascript
  functions.
