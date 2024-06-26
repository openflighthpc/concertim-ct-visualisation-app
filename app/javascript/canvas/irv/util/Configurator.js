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
import RackSpace from 'canvas/irv/view/RackSpace';
import RackSpaceDragHandler from 'canvas/irv/view/RackSpaceDragHandler';
import RackSpaceObject from 'canvas/irv/view/RackSpaceObject';
import RackObject from 'canvas/irv/view/RackObject';
import NameLabel from 'canvas/irv/view/NameLabel';
import RackNameLabel from 'canvas/irv/view/RackNameLabel';
import Rack from 'canvas/irv/view/Rack';
import Chassis from 'canvas/irv/view/Chassis';
import Machine from 'canvas/irv/view/Machine';
import Highlight from 'canvas/irv/view/Highlight';
import Metric from 'canvas/irv/view/Metric';
import Primitives from 'canvas/common/gfx/Primitives';
import LBC from 'canvas/common/widgets/LBC';
import RackSpaceHinter from 'canvas/irv/view/RackSpaceHinter';
import ThumbHint from 'canvas/irv/view/ThumbHint';
import ContextMenu from 'canvas/irv/view/ContextMenu';
import ThumbNav from 'canvas/common/widgets/ThumbNav';
import FilterBar from 'canvas/common/widgets/FilterBar';
import ViewModel from 'canvas/irv/ViewModel';
import IRVChart from 'canvas/irv/view/IRVChart';
import Profiler from 'Profiler';


class Configurator {
  static setup(IRVController, config) {
    Profiler.trace(Profiler.DEBUG, this.setup, "Configurator.setup");
    AssetManager.NUM_CONCURRENT_LOADS = config.ASSETMANAGER.numConcurrentLoads;

    // parse colours into decimal ints
    for (var obj of Array.from(config.VIEWMODEL.colourScale)) { obj.col = Configurator.parseColourString(obj.col); }
    Util.sortByProperty(config.VIEWMODEL.colourScale, 'pos', true);

    IRVChart.SERIES_FADE_ALPHA = config.RACKSPACE.LBC.IRVCHART.seriesFadeAlpha;

    const view_model_config            = config.VIEWMODEL;
    ViewModel.INIT_FACE                = view_model_config.startUp.face;
    ViewModel.COLOUR_SCALE             = view_model_config.colourScale;
    ViewModel.INIT_VIEW_MODE           = view_model_config.startUp.viewMode;
    ViewModel.INIT_SHOW_CHART          = view_model_config.startUp.showChart;
    ViewModel.INIT_METRIC_LEVEL        = view_model_config.startUp.metricLevel;
    ViewModel.INIT_GRAPH_ORDER         = view_model_config.startUp.graphOrder;
    ViewModel.INIT_METRIC_POLL_RATE    = view_model_config.startUp.metricPollRate;

    const util_config     = config.IRVUTIL;
    Util.SIG_FIG = util_config.sigFig;

    const controller_config                         = config.CONTROLLER;
    IRVController.PRIMARY_IMAGE_PATH          = controller_config.resources.primaryImagePath;
    IRVController.SECONDARY_IMAGE_PATH        = controller_config.resources.secondaryImagePath;
    IRVController.LIVE                        = controller_config.resources.live;
    IRVController.LIVE_RESOURCES              = controller_config.resources.liveResources;
    IRVController.OFFLINE_RESOURCES           = controller_config.resources.offlineResources;
    IRVController.NUM_RESOURCES               = controller_config.resources.numResources;
    IRVController.RESOURCE_LOAD_CAPTION       = controller_config.resourceLoadCaption;
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
    IRVController.METRIC_TEMPLATES_POLL_RATE  = controller_config.metricTemplatesPollRate;

    const parser_config                  = config.PARSER;
    Parser.OFFLINE_METRIC_VARIANCE = parser_config.offlineMetricVariance;
    Parser.OFFLINE                 = !controller_config.resources.live;

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

    const thumb_nav_config            = config.THUMBNAV;
    ThumbNav.MASK_FILL          = thumb_nav_config.maskFill;
    ThumbNav.MASK_FILL_ALPHA    = thumb_nav_config.maskFillAlpha;
    ThumbNav.SHADE_FILL         = thumb_nav_config.shadeFill;
    ThumbNav.SHADE_ALPHA        = thumb_nav_config.shadeAlpha;
    ThumbNav.MODEL_DEPENDENCIES = thumb_nav_config.modelDependencies;

    const update_msg_config = config.UPDATEMSG;
    UpdateMsg.MESSAGE = update_msg_config.message;

    const rackspace_config                         = config.RACKSPACE;
    RackSpace.PADDING                        = rackspace_config.padding;
    RackSpace.H_PADDING                      = rackspace_config.h_padding;
    RackSpace.BOTH_VIEW_PAIR_PADDING         = rackspace_config.bothViewPairPadding;
    RackSpace.RACK_H_SPACING                 = rackspace_config.rackHSpacing;
    RackSpace.RACK_V_SPACING                 = rackspace_config.rackVSpacing;
    RackSpace.U_LBL_SCALE_CUTOFF             = rackspace_config.uLblScaleCutoff;
    RackSpace.NAME_LBL_SCALE_CUTOFF          = rackspace_config.nameLblScaleCutoff;
    RackSpace.CANVAS_MAX_DIMENSION           = rackspace_config.canvasMaxDimension;
    RackSpace.FPS                            = rackspace_config.fps;
    RackSpace.ADDITIONAL_ROW_TOLERANCE       = rackspace_config.additionalRowTolerance;
    RackSpace.ZOOM_DURATION                  = rackspace_config.zoomDuration;
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

    RackSpaceDragHandler.SNAP_RANGE = rackspace_config.drag.snapRange;

    const rack_object_config           = config.RACKSPACE.RACKOBJECT;
    RackObject.BLANK_FILL        = rack_object_config.blankFill;
    RackObject.METRIC_FADE_FILL  = rack_object_config.metricFadeFill;
    RackObject.METRIC_FADE_ALPHA = rack_object_config.metricFadeAlpha;
    RackObject.IMAGE_PATH        = controller_config.resources.primaryImagePath;
    RackObject.EXCLUDED_ALPHA    = rack_object_config.excludedAlpha;
    RackObject.U_PX_HEIGHT       = rack_object_config.uPxHeight;

    const rack_config              = config.RACKSPACE.RACKOBJECT.RACK;
    NameLabel.OFFSET_X             = rack_config.nameLbl.offsetX;
    NameLabel.OFFSET_Y             = rack_config.nameLbl.offsetY;
    NameLabel.FONT                 = rack_config.nameLbl.font;
    NameLabel.COLOUR               = rack_config.nameLbl.colour;
    NameLabel.ALIGN                = rack_config.nameLbl.align;
    NameLabel.BG_FILL              = rack_config.nameLbl.bg.fill;
    NameLabel.BG_PADDING           = rack_config.nameLbl.bg.padding;
    NameLabel.BG_ALPHA             = rack_config.nameLbl.bg.alpha;
    NameLabel.SIZE                 = rack_config.nameLbl.size;
    NameLabel.MIN_SIZE             = rack_config.nameLbl.minSize;
    RackNameLabel.CAPTION_FRONT    = rack_config.captionFront;
    RackNameLabel.CAPTION_REAR     = rack_config.captionRear;
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
    LBC.BAR_CHART_MAX_DATUM_WIDTH      = lbc_config.barChartMaxDatumWidth;
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
    RackSpaceHinter.RACK_TEXT       = rack_hint_config.rackText;
    RackSpaceHinter.CHASSIS_TEXT    = rack_hint_config.chassisText;
    RackSpaceHinter.DEVICE_TEXT     = rack_hint_config.deviceText;

    const thumb_hint_config = config.RACKSPACE.HINT.THUMBHINT;
    ThumbHint.CAPTION = thumb_hint_config.caption;

    const context_menu_config             = config.RACKSPACE.CONTEXTMENU;
    ContextMenu.OPTIONS             = context_menu_config.options;
    ContextMenu.LAYOUT              = context_menu_config.layout;
    ContextMenu.VERBOSE             = context_menu_config.verbose;
    ContextMenu.SPACER              = context_menu_config.spacer;
    ContextMenu.URL_INTERNAL_PREFIX = context_menu_config.urlInternalPrefix;
    ContextMenu.ASPECT_MAP          = context_menu_config.aspectMap;
    ContextMenu.ACTION_PATHS        = context_menu_config.actionPaths;

    const filter_bar_config                  = config.FILTERBAR;
    FilterBar.THICKNESS                = filter_bar_config.thickness;
    FilterBar.LENGTH                   = filter_bar_config.length;
    FilterBar.PADDING                  = filter_bar_config.padding;
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
