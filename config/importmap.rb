# Pin npm packages by running ./bin/importmap

pin "application", to: "application.js"

# Page-specific javascripts.
pin "IRV", to: "IRV.js"
pin "key_pairs/new", to: "key_pairs/new.js"

# Utility Javascripts.
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.5/lib/assets/compiled/rails-ujs.js"
pin "Profiler", to: "canvas/irv/NullProfiler.js"
pin "util/NotImplementedError", to: "util/NotImplementedError.js"
pin "util/ComboBox", to: "util/ComboBox.js"
pin "util/Dialog", to: "util/Dialog.js"
# pin "util/copyToClipboard", to: "util/copyToClipboard.js"

# Javascripts for the IRV.
pin "canvas/irv/util/DragPolicy", to: "canvas/irv/util/DragPolicy.js"
pin "canvas/irv/util/Parser", to: "canvas/irv/util/Parser.js"
pin "canvas/irv/util/Configurator", to: "canvas/irv/util/Configurator.js"
pin "canvas/irv/util/AssetManager", to: "canvas/irv/util/AssetManager.js"
pin "canvas/irv/IRVController", to: "canvas/irv/IRVController.js"
pin "canvas/irv/view/UpdateMsg", to: "canvas/irv/view/UpdateMsg.js"
pin "canvas/irv/view/RackSpaceObject", to: "canvas/irv/view/RackSpaceObject.js"
pin "canvas/irv/view/MessageHint", to: "canvas/irv/view/MessageHint.js"
pin "canvas/irv/view/Metric", to: "canvas/irv/view/Metric.js"
pin "canvas/irv/view/IRVChart", to: "canvas/irv/view/IRVChart.js"
pin "canvas/irv/view/Tooltip", to: "canvas/irv/view/Tooltip.js"
pin "canvas/irv/view/ImageLink", to: "canvas/irv/view/ImageLink.js"
pin "canvas/irv/view/Chassis", to: "canvas/irv/view/Chassis.js"
pin "canvas/irv/view/RackSpace", to: "canvas/irv/view/RackSpace.js"
pin "canvas/irv/view/ContextMenu", to: "canvas/irv/view/ContextMenu.js"
pin "canvas/irv/view/RackHint", to: "canvas/irv/view/RackHint.js"
pin "canvas/irv/view/Highlight", to: "canvas/irv/view/Highlight.js"
pin "canvas/irv/view/Text", to: "canvas/irv/view/Text.js"
pin "canvas/irv/view/Machine", to: "canvas/irv/view/Machine.js"
pin "canvas/irv/view/InfoTable", to: "canvas/irv/view/InfoTable.js"
pin "canvas/irv/view/Rack", to: "canvas/irv/view/Rack.js"
pin "canvas/irv/view/Link", to: "canvas/irv/view/Link.js"
pin "canvas/irv/view/HoldingArea", to: "canvas/irv/view/HoldingArea.js"
pin "canvas/irv/view/Hint", to: "canvas/irv/view/Hint.js"
pin "canvas/irv/view/ThumbHint", to: "canvas/irv/view/ThumbHint.js"
pin "canvas/irv/view/RackObject", to: "canvas/irv/view/RackObject.js"
pin "canvas/irv/view/NameLabel", to: "canvas/irv/view/NameLabel.js"
pin "canvas/irv/view/ChassisLabel", to: "canvas/irv/view/ChassisLabel.js"
pin "canvas/irv/view/RackNameLabel", to: "canvas/irv/view/RackNameLabel.js"
pin "canvas/irv/view/RackOwnerLabel", to: "canvas/irv/view/RackOwnerLabel.js"
pin "canvas/irv/ViewModel", to: "canvas/irv/ViewModel.js"
pin "canvas/common/util/Events", to: "canvas/common/util/Events.js"
pin "canvas/common/util/PresetManager", to: "canvas/common/util/PresetManager.js"
pin "canvas/common/util/RBAC", to: "canvas/common/util/RBAC.js"
pin "canvas/common/util/Util", to: "canvas/common/util/Util.js"
pin "canvas/common/util/StaticGroupManager", to: "canvas/common/util/StaticGroupManager.js"
pin "canvas/common/util/CrossAppSettings", to: "canvas/common/util/CrossAppSettings.js"
pin "canvas/common/gfx/SimpleRenderer", to: "canvas/common/gfx/SimpleRenderer.js"
pin "canvas/common/gfx/Easing", to: "canvas/common/gfx/Easing.js"
pin "canvas/common/gfx/Validator", to: "canvas/common/gfx/Validator.js"
pin "canvas/common/gfx/Primitives", to: "canvas/common/gfx/Primitives.js"
pin "canvas/common/widgets/SimpleChart", to: "canvas/common/widgets/SimpleChart.js"
pin "canvas/common/widgets/BarMetric", to: "canvas/common/widgets/BarMetric.js"
pin "canvas/common/widgets/FilterBar", to: "canvas/common/widgets/FilterBar.js"
pin "canvas/common/widgets/Metric", to: "canvas/common/widgets/Metric.js"
pin "canvas/common/widgets/LBC", to: "canvas/common/widgets/LBC.js"
pin "canvas/common/widgets/PieCountdown", to: "canvas/common/widgets/PieCountdown.js"
pin "canvas/common/widgets/EllipticalMetric", to: "canvas/common/widgets/EllipticalMetric.js"
pin "canvas/common/widgets/MultiMetric", to: "canvas/common/widgets/MultiMetric.js"
pin "canvas/common/widgets/ThumbNav", to: "canvas/common/widgets/ThumbNav.js"
