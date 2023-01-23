/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Easing = {};
// super class provides generic ease routines
Easing.Easer = {

  easeIn(current, total, factor) {
    return Math.pow(current / total, factor);
  },

  easeOut(current, total, factor) {
    return 1 - Math.pow(1 - (current / total), factor);
  }
};


Easing.Linear = {

  easeIn(current, total) {
    return current / total;
  },

  easeOut(current, total) {
    return current / total;
  },
    
  easeInOut(current, total) {
    return current / total;
  },

  easeOutIn(current, total) {
    return current / total;
  }
};


Easing.Quad = {

  easeIn(current, total) {
    return Easing.Easer.easeIn(current, total, 2);
  },

  easeOut(current, total) {
    return Easing.Easer.easeOut(current, total, 2);
  },
    
  easeInOut(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeIn(current, mid_point, 2) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeOut(current - mid_point, mid_point, 2) / 2);
    }
  },

  easeOutIn(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeOut(current, mid_point, 2) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeIn(current - mid_point, mid_point, 2) / 2);
    }
  }
};


Easing.Cubic = {

  easeIn(current, total) {
    return Easing.Easer.easeIn(current, total, 3);
  },

  easeOut(current, total) {
    return Easing.Easer.easeOut(current, total, 3);
  },
    
  easeInOut(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeIn(current, mid_point, 3) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeOut(current - mid_point, mid_point, 3) / 2);
    }
  },

  easeOutIn(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeOut(current, mid_point, 3) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeIn(current - mid_point, mid_point, 3) / 2);
    }
  }
};


Easing.Quart = {

  easeIn(current, total) {
    return Easing.Easer.easeIn(current, total, 4);
  },

  easeOut(current, total) {
    return Easing.Easer.easeOut(current, total, 4);
  },
    
  easeInOut(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeIn(current, mid_point, 4) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeOut(current - mid_point, mid_point, 4) / 2);
    }
  },

  easeOutIn(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeOut(current, mid_point, 4) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeIn(current - mid_point, mid_point, 4) / 2);
    }
  }
};


Easing.Quint = {

  easeIn(current, total) {
    return Easing.Easer.easeIn(current, total, 5);
  },

  easeOut(current, total) {
    return Easing.Easer.easeOut(current, total, 5);
  },
    
  easeInOut(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeIn(current, mid_point, 5) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeOut(current - mid_point, mid_point, 5) / 2);
    }
  },

  easeOutIn(current, total) {
    const mid_point = total / 2;
    if (current < mid_point) {
      return Easing.Easer.easeOut(current, mid_point, 5) / 2;
    } else {
      return 0.5 + (Easing.Easer.easeIn(current - mid_point, mid_point, 5) / 2);
    }
  }
};

export default Easing;
