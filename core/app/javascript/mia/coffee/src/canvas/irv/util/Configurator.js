/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// sets static properties of all classes with values defined in the config
// this is a static class/singleton

import SimpleChart from 'canvas/common/widgets/SimpleChart';
import UpdateMsg from 'canvas/irv/view/UpdateMsg';
import PresetManager from 'canvas/common/util/PresetManager';
import Parser from 'canvas/irv/util/Parser';
import Util from 'canvas/common/util/Util';
import AssetManager from 'canvas/irv/util/AssetManager';
import CanvasSpace from 'canvas/common/CanvasSpace';
import RackSpace from 'canvas/irv/view/RackSpace';
import RackSpaceObject from 'canvas/irv/view/RackSpaceObject';
import RackObject from 'canvas/irv/view/RackObject';
import Rack from 'canvas/irv/view/Rack';
import Chassis from 'canvas/irv/view/Chassis';
import Machine from 'canvas/irv/view/Machine';
import Highlight from 'canvas/irv/view/Highlight';
import Metric from 'canvas/irv/view/Metric';
import Primitives from 'canvas/common/gfx/Primitives';
import LBC from 'canvas/common/widgets/LBC';
import RackHint from 'canvas/irv/view/RackHint';
import ThumbHint from 'canvas/irv/view/ThumbHint';
import ContextMenu from 'canvas/irv/view/ContextMenu';
import ThumbNav from 'canvas/common/widgets/ThumbNav';
import FilterBar from 'canvas/common/widgets/FilterBar';
import CanvasViewModel from 'canvas/common/CanvasViewModel';
import ViewModel from 'canvas/irv/ViewModel';
import StaticGroupManager from 'canvas/common/util/StaticGroupManager';
import IRVChart from 'canvas/irv/view/IRVChart';
import Profiler from 'Profiler';


class Configurator {

  static setup(CanvasController, IRVController, config) {
    Profiler.trace(Profiler.DEBUG, "Configurator.setup");
    AssetManager.NUM_CONCURRENT_LOADS = config.ASSETMANAGER.numConcurrentLoads;
 
    // parse colours into decimal ints
    for (var obj of Array.from(config.VIEWMODEL.colourScale)) { obj.col = Configurator.parseColourString(obj.col); }
    Util.sortByProperty(config.VIEWMODEL.colourScale, 'pos', true);

    IRVChart.SERIES_FADE_ALPHA = config.RACKSPACE.LBC.IRVCHART.seriesFadeAlpha;
 
    const view_model_config                  = config.VIEWMODEL;
    CanvasViewModel.INIT_FACE                = view_model_config.startUp.face;

    ViewModel.COLOUR_SCALE             = view_model_config.colourScale;
    ViewModel.INIT_VIEW_MODE           = view_model_config.startUp.viewMode;
    ViewModel.INIT_SCALE_BARS          = view_model_config.startUp.scaleBars;
    ViewModel.INIT_SHOW_CHART          = view_model_config.startUp.showChart;
    ViewModel.INIT_METRIC_LEVEL        = view_model_config.startUp.metricLevel;
    ViewModel.INIT_GRAPH_ORDER         = view_model_config.startUp.graphOrder;
    ViewModel.INIT_METRIC_POLL_RATE    = view_model_config.startUp.metricPollRate;

    const util_config     = config.IRVUTIL;
    Util.SIG_FIG = util_config.sigFig;
 
    const controller_config                         = config.CONTROLLER;
    CanvasController.PRIMARY_IMAGE_PATH       = controller_config.resources.primaryImagePath;
    CanvasController.SECONDARY_IMAGE_PATH     = controller_config.resources.secondaryImagePath;
    CanvasController.LIVE                     = controller_config.resources.live;
    CanvasController.LIVE_RESOURCES           = controller_config.resources.liveResources;
    CanvasController.OFFLINE_RESOURCES        = controller_config.resources.offlineResources;
    CanvasController.NUM_RESOURCES            = controller_config.resources.numResources;
    CanvasController.RESOURCE_LOAD_CAPTION    = controller_config.resourceLoadCaption;

    if (IRVController !== null) {
      IRVController.RACK_HINT_HOVER_DELAY       = controller_config.rackHintHoverDelay;
      IRVController.THUMB_HINT_HOVER_DELAY      = controller_config.thumbHintHoverDelay;
      IRVController.DOUBLE_CLICK_TIMEOUT        = controller_config.doubleClickTimeout;
      IRVController.DRAG_ACTIVATION_DIST        = controller_config.dragActivationDist;
      IRVController.RACK_PAGE_HEIGHT_PROPORTION = controller_config.rackPageHeightProportion;
      IRVController.STEP_ZOOM_AMOUNT            = controller_config.stepZoomAmount;
      IRVController.ZOOM_KEY                    = controller_config.zoomKey;
      IRVController.THUMB_WIDTH                 = config.THUMBNAV.width;
      IRVController.THUMB_HEIGHT                = config.THUMBNAV.height;
      IRVController.SCREENSHOT_FILENAME         = controller_config.screenShotFilename;
      IRVController.EXPORT_FILENAME             = controller_config.export.filename;
      IRVController.EXPORT_HEADER               = controller_config.export.header;
      IRVController.EXPORT_RECORD               = controller_config.export.record;
      IRVController.EXPORT_MESSAGE              = controller_config.export.message;
      IRVController.MIN_METRIC_POLL_RATE        = controller_config.minMetricPollRate;
      IRVController.METRIC_POLL_EDIT_DELAY      = controller_config.metricPollEditDelay;
      IRVController.INVALID_POLL_COLOUR         = controller_config.invalidPollColour;
      IRVController.DEFAULT_METRIC_STAT         = controller_config.defaultMetricStat;
      IRVController.MODIFIED_RACK_POLL_RATE     = controller_config.modifiedRackPollRate;
    }
 
    const parser_config                  = config.PARSER;
    Parser.OFFLINE_METRIC_VARIANCE = parser_config.offlineMetricVariance;
    Parser.OFFLINE                 = !controller_config.resources.live;
 
    if (IRVController !== null) {
      const preset_config                       = config.PRESETMANAGER;
      PresetManager.PATH                  = preset_config.path;
      PresetManager.GET                   = preset_config.get;
      PresetManager.NEW                   = preset_config.new;
      PresetManager.UPDATE                = preset_config.update;
      PresetManager.VALUES                = preset_config.values;
      PresetManager.ERR_CAPTION           = preset_config.errors.caption;
      PresetManager.ERR_INVALID_NAME      = preset_config.errors.invalidName;
      PresetManager.ERR_WHITE_NAME        = preset_config.errors.whiteName;
      PresetManager.ERR_DUPLICATE_NAME    = preset_config.errors.duplicateName;
      PresetManager.ERR_NOT_OWNED         = preset_config.errors.notOwned;
      PresetManager.MODEL_DEPENDENCIES    = preset_config.modelDependencies;
      PresetManager.DOM_DEPENDENCIES      = preset_config.domDependencies;
      PresetManager.MSG_CONFIRM_UPDATE    = preset_config.msgConfirmUpdate;

      const group_config = config.STATICGROUPMANAGER;
      console.log(group_config);
      StaticGroupManager.LIST                  = group_config.list;
      StaticGroupManager.GET                   = group_config.get;
      StaticGroupManager.NEW                   = group_config.new;
      StaticGroupManager.UPDATE                = group_config.update;
      StaticGroupManager.ERR_CAPTION           = group_config.errors.caption;
      StaticGroupManager.ERR_INAVLID_NAME      = group_config.errors.invalidName;
      StaticGroupManager.ERR_WHITE_NAME        = group_config.errors.whiteName;
      StaticGroupManager.ERR_DUPLICATE_NAME    = group_config.errors.duplicateName;
      StaticGroupManager.ERR_EMPTY_GROUP       = group_config.errors.emptyGroup;
      StaticGroupManager.ERR_READ_ONLY         = group_config.errors.readOnly;
      StaticGroupManager.ERR_GROUP_DATA_CENTRE = group_config.errors.groupDataCentre;
      StaticGroupManager.MODEL_DEPENDENCIES    = group_config.modelDependencies;
      StaticGroupManager.DOM_DEPENDENCIES      = group_config.domDependencies;
      StaticGroupManager.MSG_READ_ONLY         = group_config.errors.readOnly;
      StaticGroupManager.MSG_CONFIRM_UPDATE    = group_config.msgConfirmUpdate;
      StaticGroupManager.MSG_EMPTY_GROUP       = group_config.emptyGroup;
    }
 
    const thumb_nav_config            = config.THUMBNAV;
    ThumbNav.MASK_FILL          = thumb_nav_config.maskFill;
    ThumbNav.MASK_FILL_ALPHA    = thumb_nav_config.maskFillAlpha;
    ThumbNav.SHADE_FILL         = thumb_nav_config.shadeFill;
    ThumbNav.SHADE_ALPHA        = thumb_nav_config.shadeAlpha;
    ThumbNav.MODEL_DEPENDENCIES = thumb_nav_config.modelDependencies;

    const update_msg_config = config.UPDATEMSG;
    UpdateMsg.MESSAGE = update_msg_config.message;
 
    const rackspace_config                         = config.RACKSPACE;
    CanvasSpace.PADDING                        = rackspace_config.padding;
    CanvasSpace.H_PADDING                      = rackspace_config.h_padding;
    CanvasSpace.BOTH_VIEW_PAIR_PADDING         = rackspace_config.bothViewPairPadding;
    CanvasSpace.RACK_H_SPACING                 = rackspace_config.rackHSpacing;
    CanvasSpace.RACK_V_SPACING                 = rackspace_config.rackVSpacing;
    CanvasSpace.U_LBL_SCALE_CUTOFF             = rackspace_config.uLblScaleCutoff;
    CanvasSpace.NAME_LBL_SCALE_CUTOFF          = rackspace_config.nameLblScaleCutoff;
    CanvasSpace.CANVAS_MAX_DIMENSION           = rackspace_config.canvasMaxDimension;
    CanvasSpace.FPS                            = rackspace_config.fps;
    CanvasSpace.ADDITIONAL_ROW_TOLERANCE       = rackspace_config.additionalRowTolerance;

    if (IRVController !== null) {
      RackSpace.ZOOM_DURATION                  = rackspace_config.zoomDuration;
      RackSpace.DRAG_FADE_FILL                 = rackspace_config.drag.fadeFill;
      RackSpace.DRAG_FADE_ALPHA                = rackspace_config.drag.fadeAlpha;
      RackSpace.DRAG_SNAP_RANGE                = rackspace_config.drag.snapRange;
      RackSpace.INFO_FADE_DURATION             = rackspace_config.infoFadeDuration;
      RackSpace.FLIP_DURATION                  = rackspace_config.flipDuration;
      RackSpace.FLIP_DELAY                     = rackspace_config.flipDelay;
      RackSpace.METRIC_FADE_FILL               = rackspace_config.metricFadeFill;
      RackSpace.METRIC_FADE_ALPHA              = rackspace_config.metricFadeAlpha;
      RackSpace.SELECT_BOX_STROKE              = rackspace_config.selectBox.stroke;
      RackSpace.SELECT_BOX_STROKE_WIDTH        = rackspace_config.selectBox.strokeWidth;
      RackSpace.SELECT_BOX_ALPHA               = rackspace_config.selectBox.alpha;
      RackSpace.LAYOUT_UPDATE_DELAY            = rackspace_config.layoutUpdateDelay;
      RackSpace.CHART_SELECTION_COUNT_FILL     = rackspace_config.selectionCount.fill;
      RackSpace.CHART_SELECTION_COUNT_FONT     = rackspace_config.selectionCount.font;
      RackSpace.CHART_SELECTION_COUNT_BG_FILL  = rackspace_config.selectionCount.bgFill;
      RackSpace.CHART_SELECTION_COUNT_BG_ALPHA = rackspace_config.selectionCount.bgAlpha;
      RackSpace.CHART_SELECTION_COUNT_CAPTION  = rackspace_config.selectionCount.caption;
      RackSpace.CHART_SELECTION_COUNT_OFFSET_X = rackspace_config.selectionCount.offsetX;
      RackSpace.CHART_SELECTION_COUNT_OFFSET_Y = rackspace_config.selectionCount.offsetY;
    }
 
    const rack_object_config           = config.RACKSPACE.RACKOBJECT;
    RackObject.BLANK_FILL        = rack_object_config.blankFill;
    RackObject.METRIC_FADE_FILL  = rack_object_config.metricFadeFill;
    RackObject.METRIC_FADE_ALPHA = rack_object_config.metricFadeAlpha;
    RackObject.IMAGE_PATH        = controller_config.resources.primaryImagePath;
    RackObject.EXCLUDED_ALPHA    = rack_object_config.excludedAlpha;
    RackObject.U_PX_HEIGHT       = rack_object_config.uPxHeight;
 
    const rack_config              = config.RACKSPACE.RACKOBJECT.RACK;
    RackObject.NAME_LBL_OFFSET_X   = rack_config.nameLbl.offsetX;
    RackObject.NAME_LBL_OFFSET_Y   = rack_config.nameLbl.offsetY;
    RackObject.NAME_LBL_FONT       = rack_config.nameLbl.font;
    RackObject.NAME_LBL_COLOUR     = rack_config.nameLbl.colour;
    RackObject.NAME_LBL_ALIGN      = rack_config.nameLbl.align;
    RackObject.NAME_LBL_BG_FILL    = rack_config.nameLbl.bg.fill;
    RackObject.NAME_LBL_BG_PADDING = rack_config.nameLbl.bg.padding;
    RackObject.NAME_LBL_BG_ALPHA   = rack_config.nameLbl.bg.alpha;
    RackObject.NAME_LBL_SIZE       = rack_config.nameLbl.size;
    RackObject.NAME_LBL_MIN_SIZE   = rack_config.nameLbl.minSize;
    RackObject.CAPTION_FRONT       = rack_config.captionFront;
    RackObject.CAPTION_REAR        = rack_config.captionRear;
    Rack.U_LBL_OFFSET_X      = rack_config.uLbl.offsetX;
    Rack.U_LBL_OFFSET_Y      = rack_config.uLbl.offsetY;
    Rack.U_LBL_FONT          = rack_config.uLbl.font;
    Rack.U_LBL_FONT_SIZE     = rack_config.uLbl.fontSize;
    Rack.U_LBL_COLOUR        = rack_config.uLbl.colour;
    Rack.U_LBL_ALIGN         = rack_config.uLbl.align;
    RackSpaceObject.SPACE_ALPHA         = rack_config.space.alpha;
    RackSpaceObject.SPACE_FILL          = rack_config.space.fill;
    RackSpaceObject.SPACE_FADE_DURATION = rack_config.space.fadeDuration;
    Rack.FADE_IN_METRIC_MODE = rack_config.fadeInMetricMode;
 
    const chassis_config                = config.RACKSPACE.RACKOBJECT.CHASSIS;
    Chassis.DEFAULT_WIDTH         = chassis_config.defaultWidth;
    Chassis.U_PX_HEIGHT           = chassis_config.uPxHeight;
    Chassis.UNKNOWN_FILL          = chassis_config.unknownFill;
    Chassis.DEPTH_SHADE_FILL      = chassis_config.depthShadeFill;
    Chassis.DEPTH_SHADE_MAX_ALPHA = chassis_config.depthShadeMaxAlpha;

    if (IRVController !== null) {
      const highlight_config                 = config.RACKSPACE.HIGHLIGHT;
      Highlight.SELECTED_FILL          = highlight_config.selected.fill;
      Highlight.SELECTED_ANIM_DURATION = highlight_config.selected.animDuration;
      Highlight.SELECTED_MAX_ALPHA     = highlight_config.selected.maxAlpha;
      Highlight.SELECTED_MIN_ALPHA     = highlight_config.selected.minAlpha;
      Highlight.DRAGGED_FILL           = highlight_config.dragged.fill;
      Highlight.DRAGGED_ANIM_DURATION  = highlight_config.dragged.animDuration;
      Highlight.DRAGGED_MAX_ALPHA      = highlight_config.dragged.maxAlpha;
      Highlight.DRAGGED_MIN_ALPHA      = highlight_config.dragged.minAlpha;
 
      const metric_config        = config.RACKSPACE.METRIC;
      Metric.ALPHA         = metric_config.alpha;
      Metric.FADE_DURATION = metric_config.fadeDuration;
      Metric.ANIM_DURATION = metric_config.animDuration;
    }
    
    Primitives.Text.TRUNCATION_SUFFIX = config.RACKSPACE.PRIMITIVES.text.truncationSuffix;
 
    const lbc_config                         = config.RACKSPACE.LBC;
    LBC.TITLE_CAPTION                  = lbc_config.titleCaption;
    LBC.POINTER_OFFSET_X               = lbc_config.pointerOffsetX;
    LBC.POINTER_OFFSET_Y               = lbc_config.pointerOffsetY;
    LBC.SELECT_COUNT_OFFSET_X          = lbc_config.selectCount.offsetX;
    LBC.SELECT_COUNT_OFFSET_Y          = lbc_config.selectCount.offsetY;
    LBC.SELECT_COUNT_FILL              = lbc_config.selectCount.fill;
    LBC.SELECT_COUNT_FONT              = lbc_config.selectCount.font;
    LBC.SELECT_COUNT_PADDING           = lbc_config.selectCount.padding;
    LBC.SELECT_COUNT_BG_ALPHA          = lbc_config.selectCount.bgAlpha;
    LBC.SELECT_COUNT_BG_FILL           = lbc_config.selectCount.bgFill;
    LBC.SELECT_COUNT_CAPTION           = lbc_config.selectCount.caption;
    LBC.SELECT_BOX_STROKE              = lbc_config.selectBox.stroke;
    LBC.SELECT_BOX_STROKE_WIDTH        = lbc_config.selectBox.strokeWidth;
    LBC.SELECT_BOX_ALPHA               = lbc_config.selectBox.alpha;
    LBC.MODEL_DEPENDENCIES             = lbc_config.modelDependencies;
    LBC.BAR_CHART_MIN_DATUM_WIDTH      = lbc_config.barChartMinDatumWidth;
    LBC.FILL_SINGLE_SERIES_LINE_CHARTS = lbc_config.fillSingleSeriesLineCharts;
    LBC.LINE_POINTER_COLOUR            = lbc_config.linePointerColour;
    LBC.LINE_POINTER_WIDTH             = lbc_config.linePointerWidth;

    const simple_chart_config                   = config.RACKSPACE.SIMPLECHART;
    SimpleChart.LABEL_DIVISIONS           = simple_chart_config.label.divisions;
    SimpleChart.LABEL_MIN_GAP             = simple_chart_config.label.minGap;
    SimpleChart.LABEL_TICK_SIZE           = simple_chart_config.label.tickSize;
    SimpleChart.LABEL_FONT                = simple_chart_config.label.font;
    SimpleChart.LABEL_FONT_SIZE           = simple_chart_config.label.fontSize;
    SimpleChart.LABEL_FONT_COLOUR         = simple_chart_config.label.fontColour;
    SimpleChart.LABEL_MARGIN              = simple_chart_config.label.margin;
    SimpleChart.TITLE_FONT                = simple_chart_config.title.font;
    SimpleChart.TITLE_FONT_STYLE          = simple_chart_config.title.fontStyle;
    SimpleChart.TITLE_FONT_SIZE           = simple_chart_config.title.fontSize;
    SimpleChart.TITLE_FONT_COLOUR         = simple_chart_config.title.fontColour;
    SimpleChart.TRUNCATION_SUFFIX         = simple_chart_config.truncationSuffix;
    SimpleChart.MARGIN_LEFT               = simple_chart_config.margin.left;
    SimpleChart.MARGIN_RIGHT              = simple_chart_config.margin.right;
    SimpleChart.MARGIN_TOP                = simple_chart_config.margin.top;
    SimpleChart.MARGIN_BOTTOM             = simple_chart_config.margin.bottom;
    SimpleChart.AXIS_STROKE_WIDTH         = simple_chart_config.axis.strokeWidth;
    SimpleChart.AXIS_STROKE               = simple_chart_config.axis.stroke;
    SimpleChart.GRID_STROKE_WIDTH         = simple_chart_config.grid.strokeWidth;
    SimpleChart.GRID_STROKE               = simple_chart_config.grid.stroke;
    SimpleChart.LINE_DATUM_HOVER_RADIUS   = simple_chart_config.lineDatumHoverRadius;
    SimpleChart.TOOLTIP_CAPTION           = simple_chart_config.tooltip.caption;
    SimpleChart.TOOLTIP_COLOUR_FIELD      = simple_chart_config.tooltip.colourField;
    SimpleChart.MOUSE_MOVE_THROTTLE_DELAY = simple_chart_config.mouseMoveThrottleDelay;

    const rack_hint_config         = config.RACKSPACE.HINT.RACKHINT;
    RackHint.RACK_TEXT       = rack_hint_config.rackText;
    RackHint.CHASSIS_TEXT    = rack_hint_config.chassisText;
    RackHint.DEVICE_TEXT     = rack_hint_config.deviceText;
    RackHint.MORE_INFO_DELAY = rack_hint_config.moreInfoDelay;
 
    const thumb_hint_config = config.RACKSPACE.HINT.THUMBHINT;
    ThumbHint.CAPTION = thumb_hint_config.caption;
 
    const context_menu_config             = config.RACKSPACE.CONTEXTMENU;
    ContextMenu.OPTIONS             = context_menu_config.options;
    ContextMenu.LAYOUT              = context_menu_config.layout;
    ContextMenu.VERBOSE             = context_menu_config.verbose;
    ContextMenu.SPACER              = context_menu_config.spacer;
    ContextMenu.URL_INTERNAL_PREFIX = context_menu_config.urlInternalPrefix;
    ContextMenu.ASPECT_MAP          = context_menu_config.aspectMap;
    ContextMenu.DEVICE_TYPE_URL_MAP = context_menu_config.deviceTypeURLMap;
    ContextMenu.COMMAND_MODEL       = context_menu_config.commandModel;
 
    const filter_bar_config                  = config.FILTERBAR;
    FilterBar.THICKNESS                = filter_bar_config.thickness;
    FilterBar.LENGTH                   = filter_bar_config.length;
    FilterBar.PADDING                  = filter_bar_config.padding;
    FilterBar.MODEL_UPDATE_DELAY       = filter_bar_config.slider.updateDelay;
    FilterBar.DRAG_TAB_FILL            = filter_bar_config.slider.fill;
    FilterBar.DRAG_TAB_SHAPE           = filter_bar_config.slider.shape;
    FilterBar.DRAG_TAB_STROKE          = filter_bar_config.slider.stroke;
    FilterBar.DRAG_TAB_STROKE_WIDTH    = filter_bar_config.slider.strokeWidth;
    FilterBar.CUTOFF_LINE_STROKE       = filter_bar_config.cutoffLine.stroke;
    FilterBar.CUTOFF_LINE_STROKE_WIDTH = filter_bar_config.cutoffLine.strokeWidth;
    FilterBar.CUTOFF_LINE_ALPHA        = filter_bar_config.cutoffLine.alpha;
    FilterBar.DRAG_TAB_DISABLED_ALPHA  = filter_bar_config.slider.disabledAlpha;
    FilterBar.INPUT_WIDTH              = filter_bar_config.input.width;
    FilterBar.INPUT_SPACING            = filter_bar_config.input.spacing;
    FilterBar.INPUT_UPDATE_DELAY       = filter_bar_config.input.updateDelay;
    FilterBar.FONT                     = filter_bar_config.font;
    FilterBar.FONT_SIZE                = filter_bar_config.fontSize;
    FilterBar.FONT_FILL                = filter_bar_config.fontFill;
    FilterBar.DRAG_BOX_STROKE          = filter_bar_config.dragBox.stroke;
    FilterBar.DRAG_BOX_STROKE_WIDTH    = filter_bar_config.dragBox.strokeWidth;
    FilterBar.DRAG_BOX_ALPHA           = filter_bar_config.dragBox.alpha;
    FilterBar.MODEL_DEPENDENCIES       = filter_bar_config.modelDependencies;
    FilterBar.LABEL_MIN_SEPARATION     = filter_bar_config.labelMinSeparation;
 
    switch (filter_bar_config.defaultAlign) {
          case 'top':
                FilterBar.DEFAULT_ALIGN = FilterBar.ALIGN_TOP;
            break;
          case 'bottom':
                FilterBar.DEFAULT_ALIGN = FilterBar.ALIGN_BOTTOM;
            break;
          case 'left':
                FilterBar.DEFAULT_ALIGN = FilterBar.ALIGN_LEFT;
            break;
          case 'right':
                FilterBar.DEFAULT_ALIGN = FilterBar.ALIGN_RIGHT;
            break;
          default:
                FilterBar.DEFAULT_ALIGN = FilterBar.ALIGN_BOTTOM;
    }
 
    return config = null;
  }
 
 
 
  static parseColourString(col_str) {
    switch (col_str.charAt(0)) {
      case '#':
        return parseInt('0x' + col_str.substr(1));
      default:
        return parseInt(col_str);
    }
  }
};

export default Configurator;
