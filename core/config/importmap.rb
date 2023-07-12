# Pin npm packages by running ./bin/importmap

pin "application", to: "application.js"

# Page-specific javascripts.
pin "IRV", to: "IRV.js"
pin "registrations/new", to: "registrations/new.js"

# Utility Javascripts.
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.5/lib/assets/compiled/rails-ujs.js"
pin "Profiler", to: "mia/javascript/irv/NullProfiler.js"
pin "util/ComboBox", to: "mia/javascript/util/ComboBox.js"
pin "util/Dialog", to: "util/Dialog.js"
# pin "util/copyToClipboard", to: "util/copyToClipboard.js"

# Javascripts for the IRV.
pin "canvas/irv/util/DragPolicy", to: "mia/coffee/src/canvas/irv/util/DragPolicy.js"
pin "canvas/irv/util/Parser", to: "mia/coffee/src/canvas/irv/util/Parser.js"
pin "canvas/irv/util/Configurator", to: "mia/coffee/src/canvas/irv/util/Configurator.js"
pin "canvas/irv/util/AssetManager", to: "mia/coffee/src/canvas/irv/util/AssetManager.js"
pin "canvas/irv/IRVController", to: "mia/coffee/src/canvas/irv/IRVController.js"
pin "canvas/irv/view/UpdateMsg", to: "mia/coffee/src/canvas/irv/view/UpdateMsg.js"
pin "canvas/irv/view/RackSpaceObject", to: "mia/coffee/src/canvas/irv/view/RackSpaceObject.js"
pin "canvas/irv/view/MessageHint", to: "mia/coffee/src/canvas/irv/view/MessageHint.js"
pin "canvas/irv/view/Metric", to: "mia/coffee/src/canvas/irv/view/Metric.js"
pin "canvas/irv/view/IRVChart", to: "mia/coffee/src/canvas/irv/view/IRVChart.js"
pin "canvas/irv/view/Tooltip", to: "mia/coffee/src/canvas/irv/view/Tooltip.js"
pin "canvas/irv/view/ImageLink", to: "mia/coffee/src/canvas/irv/view/ImageLink.js"
pin "canvas/irv/view/Chassis", to: "mia/coffee/src/canvas/irv/view/Chassis.js"
pin "canvas/irv/view/RackSpace", to: "mia/coffee/src/canvas/irv/view/RackSpace.js"
pin "canvas/irv/view/ContextMenu", to: "mia/coffee/src/canvas/irv/view/ContextMenu.js"
pin "canvas/irv/view/RackHint", to: "mia/coffee/src/canvas/irv/view/RackHint.js"
pin "canvas/irv/view/Highlight", to: "mia/coffee/src/canvas/irv/view/Highlight.js"
pin "canvas/irv/view/Text", to: "mia/coffee/src/canvas/irv/view/Text.js"
pin "canvas/irv/view/Machine", to: "mia/coffee/src/canvas/irv/view/Machine.js"
pin "canvas/irv/view/InfoTable", to: "mia/coffee/src/canvas/irv/view/InfoTable.js"
pin "canvas/irv/view/Rack", to: "mia/coffee/src/canvas/irv/view/Rack.js"
pin "canvas/irv/view/Link", to: "mia/coffee/src/canvas/irv/view/Link.js"
pin "canvas/irv/view/HoldingArea", to: "mia/coffee/src/canvas/irv/view/HoldingArea.js"
pin "canvas/irv/view/Hint", to: "mia/coffee/src/canvas/irv/view/Hint.js"
pin "canvas/irv/view/ThumbHint", to: "mia/coffee/src/canvas/irv/view/ThumbHint.js"
pin "canvas/irv/view/RackObject", to: "mia/coffee/src/canvas/irv/view/RackObject.js"
pin "canvas/irv/ViewModel", to: "mia/coffee/src/canvas/irv/ViewModel.js"
pin "canvas/common/CanvasController", to: "mia/coffee/src/canvas/common/CanvasController.js"
pin "canvas/common/util/Events", to: "mia/coffee/src/canvas/common/util/Events.js"
pin "canvas/common/util/PresetManager", to: "mia/coffee/src/canvas/common/util/PresetManager.js"
pin "canvas/common/util/RBAC", to: "mia/coffee/src/canvas/common/util/RBAC.js"
pin "canvas/common/util/Util", to: "mia/coffee/src/canvas/common/util/Util.js"
pin "canvas/common/util/StaticGroupManager", to: "mia/coffee/src/canvas/common/util/StaticGroupManager.js"
pin "canvas/common/util/CrossAppSettings", to: "mia/coffee/src/canvas/common/util/CrossAppSettings.js"
pin "canvas/common/gfx/SimpleRenderer", to: "mia/coffee/src/canvas/common/gfx/SimpleRenderer.js"
pin "canvas/common/gfx/Easing", to: "mia/coffee/src/canvas/common/gfx/Easing.js"
pin "canvas/common/gfx/Validator", to: "mia/coffee/src/canvas/common/gfx/Validator.js"
pin "canvas/common/gfx/Primitives", to: "mia/coffee/src/canvas/common/gfx/Primitives.js"
pin "canvas/common/CanvasSpace", to: "mia/coffee/src/canvas/common/CanvasSpace.js"
pin "canvas/common/CanvasParser", to: "mia/coffee/src/canvas/common/CanvasParser.js"
pin "canvas/common/widgets/SimpleChart", to: "mia/coffee/src/canvas/common/widgets/SimpleChart.js"
pin "canvas/common/widgets/BarMetric", to: "mia/coffee/src/canvas/common/widgets/BarMetric.js"
pin "canvas/common/widgets/FilterBar", to: "mia/coffee/src/canvas/common/widgets/FilterBar.js"
pin "canvas/common/widgets/Metric", to: "mia/coffee/src/canvas/common/widgets/Metric.js"
pin "canvas/common/widgets/LBC", to: "mia/coffee/src/canvas/common/widgets/LBC.js"
pin "canvas/common/widgets/PieCountdown", to: "mia/coffee/src/canvas/common/widgets/PieCountdown.js"
pin "canvas/common/widgets/EllipticalMetric", to: "mia/coffee/src/canvas/common/widgets/EllipticalMetric.js"
pin "canvas/common/widgets/MultiMetric", to: "mia/coffee/src/canvas/common/widgets/MultiMetric.js"
pin "canvas/common/widgets/ThumbNav", to: "mia/coffee/src/canvas/common/widgets/ThumbNav.js"
pin "canvas/common/CanvasViewModel", to: "mia/coffee/src/canvas/common/CanvasViewModel.js"
