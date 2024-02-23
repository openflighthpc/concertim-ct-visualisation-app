import Chassis from 'canvas/irv/view/Chassis';
import DragPolicy from 'canvas/irv/util/DragPolicy';
import HoldingArea from 'canvas/irv/view/HoldingArea';
import Machine from 'canvas/irv/view/Machine';
import MessageHint from 'canvas/irv/view/MessageHint';
import Rack from 'canvas/irv/view/Rack';
import RackObject from 'canvas/irv/view/RackObject';
import Util from 'canvas/common/util/Util';

const ITEM_ALPHA  = 0.5;
const STROKE_WIDTH = 5;

// RackSpaceDragHandler implements support for dragging devices around in racks.
class RackSpaceDragHandler {
    static SNAP_RANGE  = 10;

    constructor(rackEl, rackSpace, model) {
        this.rackEl = rackEl;
        this.model = model;
        this.rackSpace = rackSpace;
        this.messageHint = new MessageHint();
    }

    // startDrag starts the dragging of a device.
    // @param  x   the x coordinate of the mouse relative to the rack canvas layer
    // @param  y   the y coordinate of the mouse relative to the rack canvas layer
    startDrag(x, y) {
        x /= this.rackSpace.scale;
        y /= this.rackSpace.scale;
        this.draggee = this.getDeviceAt(x, y);

        if (this.draggee == null || !this.canIMoveThisItem()) {
            // If not over a device or we're not permitted to move it abort.
            this.draggee = null;
            return;
        }

        this.debug('starting drag', x, y, this.draggee);
        Util.setStyle(this.rackEl, 'cursor', 'move');
        const xOffset = Util.getStyleNumeric(this.rackSpace.coordReferenceEl,'left') / this.rackSpace.scale;
        const yOffset = Util.getStyleNumeric(this.rackSpace.coordReferenceEl,'top') / this.rackSpace.scale;
        let dragLayerWidth = this.rackSpace.rackGfx.width;
        if (this.model.showHoldingArea()) {
            dragLayerWidth += this.rackSpace.holdingAreaGfx.width;
        }
        // Create a gfx layer for the drag animation.
        this.fx = this.rackSpace.createGfxLayer(this.rackEl, 0, 0, xOffset + dragLayerWidth, this.rackSpace.rackGfx.height, this.rackSpace.scale);

        const {chassisId, selectionHeight, image} = this.getDraggedChassis(this.draggee);
        this.dragImgOffset = { x: xOffset, y: yOffset };
        this.dragImg = this.fx.addImg({ img: image, x: x + xOffset, y: y + yOffset, alpha: ITEM_ALPHA });

        this.highlightDropSites(this.draggee, chassisId, selectionHeight);
        this.draggee.showDrag();
    }

    // getDraggedChassis returns the id, image and uHeight of the chassis being
    // dragged.
    //
    // If draggee is a chassis, we use that, if chassis is a Machine we
    // traverse its parents looking for the chassis.
    getDraggedChassis(draggee) {
        let chassisId, selectionHeight, image;
        if (draggee instanceof Machine) {
            chassisId = draggee.parent().id;
            if (draggee.parent().complex === true) {
                this.movingABlade = true;
                image = draggee.img;
                selectionHeight = 1;
            } else {
                image = draggee.parent().img;
                selectionHeight = draggee.parent().uHeight;
            }
        } else {
            chassisId = draggee.id;
            image = draggee.img;
            selectionHeight = draggee.uHeight;
        }
        return {chassisId, selectionHeight, image};
    }

    // highlightDropSites highlighs the valid drop sites for draggee.
    highlightDropSites(draggee, chassisId, selectionHeight) {
        if (draggee instanceof Chassis || draggee instanceof Machine) {
            const targetRacks = DragPolicy.filter(draggee, this.rackSpace.racks);
            targetRacks.forEach((rack) => {
                if (this.movingABlade) {
                    rack.showFreeSpacesForBlade(draggee.template.images.front, chassisId);
                } else if (rack instanceof Rack) {
                    rack.showFreeSpacesForChassis(selectionHeight, chassisId, draggee.depth());
                }
            });
        }
    }

    canIMoveThisItem() {
        return this.draggableItem() && this.doIHavePermissionToMoveOrDrag() && (this.draggee.face === 'front');
    }

    draggableItem() {
        if (this.draggee instanceof Chassis || this.draggee instanceof Machine) {
            if (this.draggee instanceof Chassis && (this.draggee.template.rackable === 1)) {
                return true;
            } else if (this.draggee instanceof Machine && (this.draggee.parent().template.rackable === 1)) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    doIHavePermissionToMoveOrDrag() {
        return ((this.draggee instanceof Chassis || this.draggee instanceof Machine) && this.model.RBAC.can_i_move_device(this.draggee));
    }

    // public method, updates dragging of a draggee box or device
    // @param  x   the x coordinate of the mouse relative to the rack canvas layer
    // @param  y   the y coordinate of the mouse relative to the rack canvas layer
    drag(x, y) {
        if (this.draggee == null) { return; }

        const scale = this.rackSpace.scale;
        const dragImg = this.dragImg;
        const dragImgOffset = this.dragImgOffset;
        const fx = this.fx;
        x /= scale;
        y /= scale;

        const slots = [];
        for (let rack of this.rackSpace.racks) {
            slots.push(rack.getNearestSpace(x, y));
        }
        Util.sortByProperty(slots, 'dist', true);
        const nearest = slots[0];

        if (this.rectangleNearest != null) {
            fx.remove(this.rectangleNearest);
        }
        if (this.overDropSite(nearest, x, y)) {
            this.highlightOverDropSite(nearest, x, y);
            this.nearest = nearest;
        } else {
            this.unhighlightOverDropSite(x, y);
        }
    }

    overDropSite(nearest, x, y) {
        const scale = this.rackSpace.scale;
        if (nearest == null) {
            return false;
        } else if ((nearest.dist * scale) <= Math.pow(RackSpaceDragHandler.SNAP_RANGE / scale, 2) || ((x > nearest.left) && (x < nearest.right) && (y > nearest.top) && (y < nearest.bottom))) {
            return true;
        } else {
            return false;
        }
    }

    highlightOverDropSite(nearest, x, y) {
        const dragImg = this.dragImg;
        const dragImgOffset = this.dragImgOffset;
        const fx = this.fx;
        const scale = this.rackSpace.scale;

        fx.setAttributes(dragImg, { alpha: 1 });
        fx.setAttributes(dragImg, { x: (dragImgOffset.x + nearest.left + ((nearest.right - nearest.left) / 2)) - (fx.getAttribute(dragImg, 'width') / 2), y: nearest.top });
        this.rectangleNearest = fx.addRect({ x: fx.getAttribute(dragImg, 'x'), y: fx.getAttribute(dragImg, 'y'), width: fx.getAttribute(dragImg, 'width'), height: fx.getAttribute(dragImg, 'height'), stroke: '#ff00ff', strokeWidth: STROKE_WIDTH});
    }

    unhighlightOverDropSite(x, y) {
        this.fx.setAttributes(this.dragImg, { alpha: ITEM_ALPHA });
        this.fx.setAttributes(this.dragImg, { x: x + this.dragImgOffset.x, y: y + this.dragImgOffset.y });
    }

    // removes draggee box canvas layer and actions drag operation by either updating the model selected devices when dragging a box or
    // moving a device when dragging a device
    // @param  x   the x coordinate of the mouse relative to the rack canvas layer
    // @param  y   the y coordinate of the mouse relative to the rack canvas layer
    stopDrag(x, y) {
        if (this.draggee == null) { return; }

        this.debug('stopping drag', x, y, this.draggee);
        Util.setStyle(this.rackEl, 'cursor', 'auto');
        this.rackSpace.rackGfx.redraw();
        for (let rack of this.rackSpace.racks) {
            rack.hideSpaces();
        }
        this.fx.destroy();
        this.draggee.hideDrag();
        let deviceToConnect = null;

        x /= this.rackSpace.scale;
        y /= this.rackSpace.scale;

        if ((this.model.showingFullIrv() || this.model.showingRacks()) && this.model.showHoldingArea() && this.rackSpace.holdingArea.overInternalArea(x,y)) {
            if (this.draggee instanceof Chassis || (this.draggee instanceof Machine && (this.draggee.parent().complex === false))) {
                this.moveDeviceToHoldingArea();
            }
        } else if (this.nearest != null) {
            const xCoord = this.nearest.left+((this.nearest.right-this.nearest.left)/2);
            const yCoord = (this.nearest.bottom-(RackObject.U_PX_HEIGHT/2));
            if (this.movingABlade) {
                deviceToConnect = this.getDeviceAt(xCoord,yCoord);
            } else {
                deviceToConnect = this.getRackAt(xCoord,yCoord);
            }
        }

        if (deviceToConnect != null && this.nearest != null) {
            if (this.movingABlade && deviceToConnect instanceof Chassis) {
                this.moveBladeBeingDragged();
            } else if (deviceToConnect instanceof Rack) {
                if (this.draggee.placedInHoldingArea()) {
                    this.moveDeviceFromHoldingArea();
                } else if (this.validLocationToMove(x,y)) {
                    this.moveDeviceBeingDragged();
                } else {
                    this.messageHint.show([["Cannot move device "+this.draggee.name+" to position.", 0]]);
                }
            }
        }

        this.nearest = null;
        this.movingABlade = null;
    }

    validLocationToMove(x,y) {
        const deviceAtDropSite = this.getDeviceAt(x,y);
        if ((deviceAtDropSite != null) && (deviceAtDropSite instanceof Rack || this.movingMyself(this.draggee,deviceAtDropSite) || (deviceAtDropSite.facing !== this.nearest.face))) {
            return true;
        } else {
            return false;
        }
    }

    // Function to validate if the device being dragged is dropped in an area
    // that belongs to itself or in a blade that is inside itself.
    movingMyself(draggee, deviceAtDropSite) {
        return (draggee.id === deviceAtDropSite.id) || (draggee.id === __guard__(deviceAtDropSite.parent(), x => x.id));
    }

    moveDeviceFromHoldingArea() {
        if (!(this.draggee instanceof Machine) && !(this.draggee instanceof Chassis)) { return; }

        const chassisToBeUpdated = this.draggee instanceof Chassis ? this.draggee : this.draggee.parent();
        chassisToBeUpdated.hide();
        const movedChassis = this.rackSpace.holdingArea.remove(chassisToBeUpdated.id);
        this.addChildToRack(this.nearest.rack_id, chassisToBeUpdated);
        const nextRack = this.model.deviceLookup()['racks'][this.nearest.rack_id];
        chassisToBeUpdated.parent(nextRack.instances[0]);
        nextRack.chassis.push(movedChassis);
        this.model.deviceLookup()['racks'][nextRack.id] = nextRack;

        this.updateChassisPositionInARack(this.nearest.rack_id, chassisToBeUpdated.id, this.nearest.u, this.nearest.face, chassisToBeUpdated.face);
        chassisToBeUpdated.moveToOrFromHoldingArea("RackChassis",this.nearest.rack_id,(this.nearest.u+1),this.nearest.face);
    }

    moveDeviceToHoldingArea() {
        if (!(this.draggee instanceof Machine) && !(this.draggee instanceof Chassis)) { return; }

        const chassisToBeUpdated = this.draggee instanceof Chassis ? this.draggee : this.draggee.parent();
        if (!(chassisToBeUpdated.parent() instanceof HoldingArea)) {
            chassisToBeUpdated.hide();
            chassisToBeUpdated.parent(this.rackSpace.holdingArea);
            this.rackSpace.holdingArea.add(chassisToBeUpdated);
            chassisToBeUpdated.moveToOrFromHoldingArea("NonRackChassis",null,0,'f');
        }
    }

    moveDeviceBeingDragged() {
        if (!(this.draggee instanceof Machine) && !(this.draggee instanceof Chassis)) { return; }

        const chassisToBeUpdated = this.draggee instanceof Chassis ? this.draggee : this.draggee.parent();
        this.addChildToRack(this.nearest.rack_id, chassisToBeUpdated);
        chassisToBeUpdated.parent(this.model.deviceLookup()['racks'][this.nearest.rack_id].instances[0]);
        this.updateChassisPositionInARack(this.nearest.rack_id, chassisToBeUpdated.id, this.nearest.u, this.nearest.face, chassisToBeUpdated.face);
        chassisToBeUpdated.updatePosition();
    }

    moveBladeBeingDragged() {
        if (!(this.draggee instanceof Machine)) { return; }

        this.draggee.hideMetric();
        const bladeToBeUpdated = this.draggee;
        let previousChassis = null;
        const movingToDifferentChassis = bladeToBeUpdated.parent().id !== this.nearest.chassis_id;
        if (movingToDifferentChassis) {
            previousChassis = this.model.deviceLookup()['chassis'][bladeToBeUpdated.parent().id];
            const previousChassisRackId = previousChassis.instances[0].parent().id;
            for (let index = 0; index < previousChassis.Slots.length; index++) {
                let slot = previousChassis.Slots[index];
                if ((slot.Machine != null) && (slot.Machine.id === bladeToBeUpdated.id)) {
                    this.removeBladeFromChassisFromRack(previousChassisRackId, previousChassis.id, bladeToBeUpdated.id);
                    this.addBladeToChassisInRack(this.nearest.rack_id, this.nearest.chassis_id, bladeToBeUpdated);
                    let nextChassis = this.model.deviceLookup()['chassis'][this.nearest.chassis_id];
                    bladeToBeUpdated.parent(nextChassis.instances[0]);
                    previousChassis.Slots[index].Machine = null;
                    for (let slotIndex = 0; slotIndex < nextChassis.Slots.length; slotIndex++) {
                        let newSlot = nextChassis.Slots[slotIndex];
                        if ((parseInt(newSlot.row) === this.nearest.row) && (parseInt(newSlot.col) === this.nearest.col)) {
                            nextChassis.Slots[slotIndex].Machine = slot.Machine;
                        }
                    }
                    this.model.deviceLookup()['chassis'][previousChassis.id] = previousChassis;
                    this.model.deviceLookup()['chassis'][nextChassis.id] = nextChassis;
                    break;
                }
            }
        }

        bladeToBeUpdated.slot_id = this.nearest.slot_id;
        bladeToBeUpdated.updateSlot();
    }

    updateChassisPositionInARack(rackId, chassisId, newU, newFacing, draggedImageFace) {
        for (let rack of this.rackSpace.racks) {
            if (rack.id === rackId) {
                rack.updateChassisPosition(chassisId, newU, newFacing);
            }
        }
    }

    addChildToRack(rackId, child) {
        for (let index = 0; index < this.rackSpace.racks.length; index++) {
            let rack = this.rackSpace.racks[index];
            if (rack.id === rackId) {
                this.rackSpace.racks[index].children.push(child);
            }
        }
    }

    removeBladeFromChassisFromRack(rackId, chassisId, bladeId) {
        for (let index = 0; index < this.rackSpace.racks.length; index++) {
            let rack = this.rackSpace.racks[index];
            if (rack.id === rackId) {
                this.rackSpace.racks[index].removeBladeFromChassis(chassisId, bladeId);
                break;
            }
        }
    }

    addBladeToChassisInRack(rackId, chassisId, blade) {
        for (let index = 0; index < this.rackSpace.racks.length; index++) {
            let rack = this.rackSpace.racks[index];
            if (rack.id === rackId) {
                this.rackSpace.racks[index].addBladeToChassis(chassisId, blade);
                break;
            }
        }
    }

    getRackAt(x, y) {
        if (! this.model.showingRacks()) { return; }
        for (let rack of this.rackSpace.racks) {
            // only query the rack if the coordinates lie within it's boundaries
            if ((x > rack.x) && (x < (rack.x + rack.width)) && (y > rack.y) && (y < (rack.y + rack.height))) {
                return rack;
            }
        }
    }

    getDeviceAt(x, y) {
        return this.rackSpace.getDeviceAt(x, y);
    }

    debug(...msg) {
        console.debug('RackSpaceDragHandler:', ...msg);
    }
}

export default RackSpaceDragHandler;

function __guard__(value, transform) {
    return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
