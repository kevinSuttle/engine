var Command, URL,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Command = require('../Command');

URL = (function(_super) {
  __extends(URL, _super);

  URL.prototype.type = 'URL';

  function URL(obj) {
    switch (typeof obj) {
      case 'object':
        if (URL[obj[0]]) {
          return obj;
        }
    }
  }

  URL.define({
    'url': function() {},
    'src': function() {},
    'canvas': function() {}
  });

  return URL;

})(Command);

module.exports = URL;