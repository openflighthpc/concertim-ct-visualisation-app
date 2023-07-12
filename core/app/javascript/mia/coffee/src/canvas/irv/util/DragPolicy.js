// Implements a policy for which racks a device/chassis can be dragged to.
//
// Currently the policy is very simple: a device/chassis can be dragged only in
// its own rack.  This will likely become more complicated.
class DragPolicy {

  // Return a list of racks that are suitable targets for dropping draggee to.
  static filter(draggee, racks) {
    return [draggee.rack()].filter(r => r != null);
  }
}

export default DragPolicy;
