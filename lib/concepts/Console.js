var Console, Native, method, _i, _len, _ref;

Native = require('../methods/Native');

Console = (function() {
  function Console(level) {
    var _ref, _ref1;
    this.level = level;
    if (this.level == null) {
      this.level = parseFloat(((_ref = window.location) != null ? (_ref1 = _ref.href.match(/log=\d/)) != null ? _ref1[0] : void 0 : void 0) || 1);
    }
  }

  Console.prototype.methods = ['log', 'warn', 'info', 'error', 'group', 'groupEnd', 'groupCollapsed', 'time', 'timeEnd', 'profile', 'profileEnd'];

  Console.prototype.groups = 0;

  Console.prototype.row = function(a, b, c) {
    var p1, p2;
    if (!this.level) {
      return;
    }
    a = a.name || a;
    p1 = Array(5 - Math.floor(a.length / 4)).join('\t');
    if (typeof b === 'object') {
      return this.log('%c%s%s%O%c\t\t\t%s', 'color: #666', a, p1, b, 'color: #999', c || "");
    } else {
      p2 = Array(6 - Math.floor(String(b).length / 4)).join('\t');
      return this.log('%c%s%s%s%c%s%s', 'color: #666', a, p1, b, 'color: #999', p2, c || "");
    }
  };

  Console.prototype.start = function(reason, name) {
    var fmt, method, started;
    this.startTime = Native.prototype.time();
    this.started || (this.started = []);
    if (this.started.indexOf(name) > -1) {
      started = true;
    }
    this.started.push(name);
    if (started) {
      return;
    }
    fmt = '%c%s';
    fmt += Array(5 - Math.floor(String(name).length / 4)).join('\t');
    fmt += "%c";
    if (typeof reason !== 'string') {
      if (reason != null ? reason.slice : void 0) {
        reason = Native.prototype.clone(reason);
      }
      fmt += '%O';
    } else {
      fmt += '%s';
      method = 'groupCollapsed';
    }
    this[method || 'group'](fmt, 'font-weight: normal', name, 'color: #666; font-weight: normal', reason);
    return true;
  };

  Console.prototype.end = function(reason) {
    var popped, _ref;
    popped = (_ref = this.started) != null ? _ref.pop() : void 0;
    if (!popped || this.started.indexOf(popped) > -1) {
      return;
    }
    this.groupEnd();
    return this.endTime = Native.prototype.time();
  };

  return Console;

})();

_ref = Console.prototype.methods;
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  method = _ref[_i];
  Console.prototype[method] = (function(method) {
    return function() {
      if (method === 'group' || method === 'groupCollapsed') {
        Console.prototype.groups++;
      } else if (method === 'groupEnd') {
        Console.prototype.groups--;
      }
      if ((typeof document !== "undefined" && document !== null) && this.level) {
        return typeof console !== "undefined" && console !== null ? typeof console[method] === "function" ? console[method].apply(console, arguments) : void 0 : void 0;
      }
    };
  })(method);
}

module.exports = Console;