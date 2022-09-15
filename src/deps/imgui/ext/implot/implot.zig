/// help wrappers of raw implot api
const assert = @import("std").debug.assert;
const imgui = @import("../../c.zig");
pub const c = @import("c.zig");
pub const ImPlotContext = c.ImPlotContext;
pub const IMPLOT_AUTO = -1;
pub const IMPLOT_AUTO_COL = imgui.ImVec4{ .x = 0, .y = 0, .z = 0, .w = -1 };
pub const Point = struct {
    pub fn init() *c.ImPlotPoint {
        return c.ImPlotPoint_ImPlotPoint_Nil();
    }
    pub fn deinit(self: *c.ImPlotPoint) void {
        return c.ImPlotPoint_destroy(self);
    }
    pub fn fromDouble(_x: f64, _y: f64) *c.ImPlotPoint {
        return c.ImPlotPoint_ImPlotPoint_double(_x, _y);
    }
    pub fn fromVec2(p: imgui.ImVec2) *c.ImPlotPoint {
        return c.ImPlotPoint_ImPlotPoint_Vec2(p);
    }
};

pub const Range = struct {
    pub fn init() *c.ImPlotRange {
        return c.ImPlotRange_ImPlotRange_Nil();
    }
    pub fn deinit(self: *c.ImPlotRange) void {
        return c.ImPlotRange_destroy(self);
    }
    pub fn fromDouble(_min: f64, _max: f64) *c.ImPlotRange {
        return c.ImPlotRange_ImPlotRange_double(_min, _max);
    }
    pub fn contains(self: *c.ImPlotRange, value: f64) bool {
        return c.ImPlotRange_Contains(self, value);
    }
    pub fn size(self: *c.ImPlotRange) f64 {
        return c.ImPlotRange_Size(self);
    }
};

pub const BufWriter = struct {
    pub fn init(buffer: [*c]u8, size: c_int) [*c]c.ImBufferWriter {
        return c.ImBufferWriter_ImBufferWriter(buffer, size);
    }
    pub fn deinit(self: [*c]c.ImBufferWriter) void {
        return c.ImBufferWriter_destroy(self);
    }
    pub const write = c.ImBufferWriter_Write;
};

pub const InputMap = struct {
    pub fn init() *c.ImPlotInputMap {
        return c.ImPlotInputMap_ImPlotInputMap();
    }
    pub fn deinit(self: *c.ImPlotInputMap) void {
        return c.ImPlotInputMap_destroy(self);
    }
};

pub const DateTimeFmt = struct {
    pub fn init(date_fmt: c.ImPlotDateFmt, time_fmt: c.ImPlotTimeFmt, use_24_hr_clk: bool, use_iso_8601: bool) *c.ImPlotDateTimeFmt {
        return c.ImPlotDateTimeFmt_ImPlotDateTimeFmt(date_fmt, time_fmt, use_24_hr_clk, use_iso_8601);
    }
    pub fn deinit(self: *c.ImPlotDateTimeFmt) void {
        return c.ImPlotDateTimeFmt_destroy(self);
    }
};

pub const Time = struct {
    pub fn init() *c.ImPlotTime {
        return c.ImPlotTime_ImPlotTime_Nil();
    }
    pub fn deinit(self: *c.ImPlotTime) void {
        return c.ImPlotTime_destroy(self);
    }
    pub fn fromTimet(s: c.time_t, us: c_int) *c.ImPlotTime {
        return c.ImPlotTime_ImPlotTime_time_t(s, us);
    }
    pub fn rollOver(self: *c.ImPlotTime) void {
        return c.ImPlotTime_RollOver(self);
    }
    pub fn toDouble(self: *c.ImPlotTime) f64 {
        return c.ImPlotTime_ToDouble(self);
    }
    pub fn setDouble(self: *c.ImPlotTime, t: f64) void {
        return c.ImPlotTime_FromDouble(self, t);
    }
};

pub const ColorMap = struct {
    pub fn init() *c.ImPlotColormapData {
        return c.ImPlotColormapData_ImPlotColormapData();
    }
    pub fn deinit(self: *c.ImPlotColormapData) void {
        return c.ImPlotColormapData_destroy(self);
    }
    pub fn append(self: *c.ImPlotColormapData, name: [*c]const u8, keys: [*c]const imgui.ImU32, count: c_int, qual: bool) c_int {
        return c.ImPlotColormapData_Append(self, name, keys, count, qual);
    }
    pub fn appendTable(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap) void {
        return c.ImPlotColormapData__AppendTable(self, cmap);
    }
    pub fn rebuildTables(self: *c.ImPlotColormapData) void {
        return c.ImPlotColormapData_RebuildTables(self);
    }
    pub fn isQual(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap) bool {
        return c.ImPlotColormapData_IsQual(self, cmap);
    }
    pub fn getName(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap) [*c]const u8 {
        return c.ImPlotColormapData_GetName(self, cmap);
    }
    pub fn getIndex(self: *c.ImPlotColormapData, name: [*c]const u8) c.ImPlotColormap {
        return c.ImPlotColormapData_GetIndex(self, name);
    }
    pub fn getKeys(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap) [*c]const imgui.ImU32 {
        return c.ImPlotColormapData_GetKeys(self, cmap);
    }
    pub fn getKeyCount(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap) c_int {
        return c.ImPlotColormapData_GetKeyCount(self, cmap);
    }
    pub fn getKeyColor(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap, idx: c_int) imgui.ImU32 {
        return c.ImPlotColormapData_GetKeyColor(self, cmap, idx);
    }
    pub fn setKeyColor(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap, idx: c_int, value: imgui.ImU32) void {
        return c.ImPlotColormapData_SetKeyColor(self, cmap, idx, value);
    }
    pub fn getTable(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap) [*c]const imgui.ImU32 {
        return c.ImPlotColormapData_GetTable(self, cmap);
    }
    pub fn getTableSize(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap) c_int {
        return c.ImPlotColormapData_GetTableSize(self, cmap);
    }
    pub fn getTableColor(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap, idx: c_int) imgui.ImU32 {
        return c.ImPlotColormapData_GetTableColor(self, cmap, idx);
    }
    pub fn lerpTable(self: *c.ImPlotColormapData, cmap: c.ImPlotColormap, t: f32) imgui.ImU32 {
        return c.ImPlotColormapData_LerpTable(self, cmap, t);
    }
};

pub const PointError = struct {
    pub fn init(x: f64, y: f64, neg: f64, pos: f64) *c.ImPlotPointError {
        return c.ImPlotPointError_ImPlotPointError(x, y, neg, pos);
    }
    pub fn deinit(self: *c.ImPlotPointError) void {
        return c.ImPlotPointError_destroy(self);
    }
};

pub const AnnotationCollection = struct {
    pub fn init() *c.ImPlotAnnotationCollection {
        return c.ImPlotAnnotationCollection_ImPlotAnnotationCollection();
    }
    pub fn deinit(self: *c.ImPlotAnnotationCollection) void {
        return c.ImPlotAnnotationCollection_destroy(self);
    }
    pub fn append(self: *c.ImPlotAnnotationCollection, pos: imgui.ImVec2, off: imgui.ImVec2, bg: imgui.ImU32, fg: imgui.ImU32, clamp: bool, fmt: [*c]const u8) void {
        return c.ImPlotAnnotationCollection_Append(self, pos, off, bg, fg, clamp, fmt);
    }
    pub fn getText(self: *c.ImPlotAnnotationCollection, idx: c_int) [*c]const u8 {
        return c.ImPlotAnnotationCollection_GetText(self, idx);
    }
    pub fn reset(self: *c.ImPlotAnnotationCollection) void {
        return c.ImPlotAnnotationCollection_Reset(self);
    }
};

pub const Tick = struct {
    pub fn init(value: f64, major: bool, show_label: bool) *c.ImPlotTick {
        return c.ImPlotTick_ImPlotTick(value, major, show_label);
    }
    pub fn deinit(self: *c.ImPlotTick) void {
        return c.ImPlotTick_destroy(self);
    }
};

pub const TickCollection = struct {
    pub fn init() *c.ImPlotTickCollection {
        return c.ImPlotTickCollection_ImPlotTickCollection();
    }
    pub fn deinit(self: *c.ImPlotTickCollection) void {
        return c.ImPlotTickCollection_destroy(self);
    }
    pub fn append_PlotTick(self: *c.ImPlotTickCollection, tick: c.ImPlotTick) [*c]const c.ImPlotTick {
        return c.ImPlotTickCollection_Append_PlotTick(self, tick);
    }
    pub fn append_double(self: *c.ImPlotTickCollection, value: f64, major: bool, show_label: bool, fmt: [*c]const u8) [*c]const c.ImPlotTick {
        return c.ImPlotTickCollection_Append_double(self, value, major, show_label, fmt);
    }
    pub fn getText(self: *c.ImPlotTickCollection, idx: c_int) [*c]const u8 {
        return c.ImPlotTickCollection_GetText(self, idx);
    }
    pub fn reset(self: *c.ImPlotTickCollection) void {
        return c.ImPlotTickCollection_Reset(self);
    }
};

pub const Axis = struct {
    pub fn init() *c.ImPlotAxis {
        return c.ImPlotAxis_ImPlotAxis();
    }
    pub fn deinit(self: *c.ImPlotAxis) void {
        return c.ImPlotAxis_destroy(self);
    }
    pub fn setMin(self: *c.ImPlotAxis, _min: f64, force: bool) bool {
        return c.ImPlotAxis_SetMin(self, _min, force);
    }
    pub fn setMax(self: *c.ImPlotAxis, _max: f64, force: bool) bool {
        return c.ImPlotAxis_SetMax(self, _max, force);
    }
    pub fn setRange_double(self: *c.ImPlotAxis, _min: f64, _max: f64) void {
        return c.ImPlotAxis_SetRange_double(self, _min, _max);
    }
    pub fn setRange_PlotRange(self: *c.ImPlotAxis, range: c.ImPlotRange) void {
        return c.ImPlotAxis_SetRange_PlotRange(self, range);
    }
    pub fn setAspect(self: *c.ImPlotAxis, unit_per_pix: f64) void {
        return c.ImPlotAxis_SetAspect(self, unit_per_pix);
    }
    pub fn getAspect(self: *c.ImPlotAxis) f64 {
        return c.ImPlotAxis_GetAspect(self);
    }
    pub fn constrain(self: *c.ImPlotAxis) void {
        return c.ImPlotAxis_Constrain(self);
    }
    pub fn isLabeled(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsLabeled(self);
    }
    pub fn isInverted(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsInverted(self);
    }
    pub fn isAutoFitting(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsAutoFitting(self);
    }
    pub fn isRangeLocked(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsRangeLocked(self);
    }
    pub fn isLockedMin(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsLockedMin(self);
    }
    pub fn isLockedMax(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsLockedMax(self);
    }
    pub fn isLocked(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsLocked(self);
    }
    pub fn isInputLockedMin(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsInputLockedMin(self);
    }
    pub fn isInputLockedMax(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsInputLockedMax(self);
    }
    pub fn isInputLocked(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsInputLocked(self);
    }
    pub fn isTime(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsTime(self);
    }
    pub fn isLog(self: *c.ImPlotAxis) bool {
        return c.ImPlotAxis_IsLog(self);
    }
};

pub const AlignmentData = struct {
    pub fn init() *c.ImPlotAlignmentData {
        return c.ImPlotAlignmentData_ImPlotAlignmentData();
    }
    pub fn deinit(self: *c.ImPlotAlignmentData) void {
        return c.ImPlotAlignmentData_destroy(self);
    }
    pub fn begin(self: *c.ImPlotAlignmentData) void {
        return c.ImPlotAlignmentData_Begin(self);
    }
    pub fn update(self: *c.ImPlotAlignmentData, pad_a: [*c]f32, pad_b: [*c]f32) void {
        return c.ImPlotAlignmentData_Update(self, pad_a, pad_b);
    }
    pub fn end(self: *c.ImPlotAlignmentData) void {
        return c.ImPlotAlignmentData_End(self);
    }
    pub fn reset(self: *c.ImPlotAlignmentData) void {
        return c.ImPlotAlignmentData_Reset(self);
    }
};

pub const Item = struct {
    pub fn init() *c.ImPlotItem {
        return c.ImPlotItem_ImPlotItem();
    }
    pub fn deinit(self: *c.ImPlotItem) void {
        return c.ImPlotItem_destroy(self);
    }
};

pub const LegendData = struct {
    pub fn init() *c.ImPlotLegendData {
        return c.ImPlotLegendData_ImPlotLegendData();
    }
    pub fn deinit(self: *c.ImPlotLegendData) void {
        return c.ImPlotLegendData_destroy(self);
    }
    pub fn reset(self: *c.ImPlotLegendData) void {
        return c.ImPlotLegendData_Reset(self);
    }
};

pub const ItemGroup = struct {
    pub fn init() *c.ImPlotItemGroup {
        return c.ImPlotItemGroup_ImPlotItemGroup();
    }
    pub fn deinit(self: *c.ImPlotItemGroup) void {
        return c.ImPlotItemGroup_destroy(self);
    }
    pub fn getItemCount(self: *c.ImPlotItemGroup) c_int {
        return c.ImPlotItemGroup_GetItemCount(self);
    }
    pub fn getItemID(self: *c.ImPlotItemGroup, label_id: [:0]const u8) imgui.ImGuiID {
        return c.ImPlotItemGroup_GetItemID(self, label_id.ptr);
    }
    pub fn getItem_ID(self: *c.ImPlotItemGroup, id: imgui.ImGuiID) *c.ImPlotItem {
        return c.ImPlotItemGroup_GetItem_ID(self, id);
    }
    pub fn getItem_Str(self: *c.ImPlotItemGroup, label_id: [:0]const u8) *c.ImPlotItem {
        return c.ImPlotItemGroup_GetItem_Str(self, label_id.ptr);
    }
    pub fn getOrAddItem(self: *c.ImPlotItemGroup, id: imgui.ImGuiID) *c.ImPlotItem {
        return c.ImPlotItemGroup_GetOrAddItem(self, id);
    }
    pub fn getItemByIndex(self: *c.ImPlotItemGroup, i: c_int) *c.ImPlotItem {
        return c.ImPlotItemGroup_GetItemByIndex(self, i);
    }
    pub fn getItemIndex(self: *c.ImPlotItemGroup, item: *c.ImPlotItem) c_int {
        return c.ImPlotItemGroup_GetItemIndex(self, item);
    }
    pub fn getLegendCount(self: *c.ImPlotItemGroup) c_int {
        return c.ImPlotItemGroup_GetLegendCount(self);
    }
    pub fn getLegendItem(self: *c.ImPlotItemGroup, i: c_int) *c.ImPlotItem {
        return c.ImPlotItemGroup_GetLegendItem(self, i);
    }
    pub fn getLegendLabel(self: *c.ImPlotItemGroup, i: c_int) [*c]const u8 {
        return c.ImPlotItemGroup_GetLegendLabel(self, i);
    }
    pub fn reset(self: *c.ImPlotItemGroup) void {
        return c.ImPlotItemGroup_Reset(self);
    }
};

pub const Plot = struct {
    pub fn init() *c.ImPlotPlot {
        return c.ImPlotPlot_ImPlotPlot();
    }
    pub fn deinit(self: *c.ImPlotPlot) void {
        return c.ImPlotPlot_destroy(self);
    }
    pub fn anyYInputLocked(self: *c.ImPlotPlot) bool {
        return c.ImPlotPlot_AnyYInputLocked(self);
    }
    pub fn allYInputLocked(self: *c.ImPlotPlot) bool {
        return c.ImPlotPlot_AllYInputLocked(self);
    }
    pub fn isInputLocked(self: *c.ImPlotPlot) bool {
        return c.ImPlotPlot_IsInputLocked(self);
    }
};

pub const Subplot = struct {
    pub fn init() *c.ImPlotSubplot {
        return c.ImPlotSubplot_ImPlotSubplot();
    }
    pub fn destroy(self: *c.ImPlotSubplot) void {
        return c.ImPlotSubplot_destroy(self);
    }
};

pub const NextPlotData = struct {
    pub fn init() *c.ImPlotNextPlotData {
        return c.ImPlotNextPlotData_ImPlotNextPlotData();
    }
    pub fn deinit(self: *c.ImPlotNextPlotData) void {
        return c.ImPlotNextPlotData_destroy(self);
    }
    pub fn reset(self: *c.ImPlotNextPlotData) void {
        return c.ImPlotNextPlotData_Reset(self);
    }
};

pub const NextItem = struct {
    pub fn init() *c.ImPlotNextItemData {
        return c.ImPlotNextItemData_ImPlotNextItemData();
    }
    pub fn deinit(self: *c.ImPlotNextItemData) void {
        return c.ImPlotNextItemData_destroy(self);
    }
    pub fn reset(self: *c.ImPlotNextItemData) void {
        return c.ImPlotNextItemData_Reset(self);
    }
};

pub const Limits = struct {
    pub fn init() *c.ImPlotLimits {
        return c.ImPlotLimits_ImPlotLimits_Nil();
    }
    pub fn deinit(self: *c.ImPlotLimits) void {
        return c.ImPlotLimits_destroy(self);
    }
    pub fn fromDoubles(x_min: f64, x_max: f64, y_min: f64, y_max: f64) *c.ImPlotLimits {
        return c.ImPlotLimits_ImPlotLimits_double(x_min, x_max, y_min, y_max);
    }
    pub fn contains_PlotPoInt(self: *c.ImPlotLimits, p: c.ImPlotPoint) bool {
        return c.ImPlotLimits_Contains_PlotPoInt(self, p);
    }
    pub fn contains_double(self: *c.ImPlotLimits, x: f64, y: f64) bool {
        return c.ImPlotLimits_Contains_double(self, x, y);
    }
    pub fn min(self: *c.ImPlotLimits, pOut: *c.ImPlotPoint) void {
        return c.ImPlotLimits_Min(pOut, self);
    }
    pub fn max(self: *c.ImPlotLimits, pOut: *c.ImPlotPoint) void {
        return c.ImPlotLimits_Max(pOut, self);
    }
};

pub const Style = struct {
    pub fn init() *c.ImPlotStyle {
        return c.ImPlotStyle_ImPlotStyle();
    }
    pub fn deinit(self: *c.ImPlotStyle) void {
        return c.ImPlotStyle_destroy(self);
    }
};

// Creates a new ImPlot context. Call this after ImGui::CreateContext.
pub fn createContext() *c.ImPlotContext {
    return c.ImPlot_CreateContext();
}

// Destroys an ImPlot context. Call this before ImGui::DestroyContext. NULL = destroy current context.
pub fn destroyContext(ctx: *c.ImPlotContext) void {
    return c.ImPlot_DestroyContext(ctx);
}

// Returns the current ImPlot context. NULL if no context has ben set.
pub fn getCurrentContext() *c.ImPlotContext {
    return c.ImPlot_GetCurrentContext();
}

// Sets the current ImPlot context.
pub fn setCurrentContext(ctx: *c.ImPlotContext) void {
    return c.ImPlot_SetCurrentContext(ctx);
}

// Sets the current **ImGui** context. This is ONLY necessary if you are compiling
// ImPlot as a DLL (not recommended) separate from your ImGui compilation. It
// sets the global variable GImGui, which is not shared across DLL boundaries.
// See GImGui documentation in imgui.cpp for more details.
pub fn setImGuiContext(ctx: [*c]imgui.ImGuiContext) void {
    return c.ImPlot_SetImGuiContext(ctx);
}

//-----------------------------------------------------------------------------
// Begin/End Plot
//-----------------------------------------------------------------------------

// Starts a 2D plotting context. If this function returns true, EndPlot() MUST
// be called! You are encouraged to use the following convention:
//
// if (BeginPlot(...)) {
//     ImPlot::PlotLine(...);
//     ...
//     EndPlot();
// }
//
// Important notes:
//
// - #title_id must be unique to the current ImGui ID scope. If you need to avoid ID
//   collisions or don't want to display a title in the plot, use double hashes
//   (e.g. "MyPlot##HiddenIdText" or "##NoTitle").
// - If #x_label and/or #y_label are provided, axes labels will be displayed.
// - #size is the **frame** size of the plot widget, not the plot area. The default
//   size of plots (i.e. when ImVec2(0,0)) can be modified in your ImPlotStyle
//   (default is 400x300 px).
// - Auxiliary y-axes must be enabled with ImPlotFlags_YAxis2/3 to be displayed.
// - See ImPlotFlags and ImPlotAxisFlags for more available options.
pub const BeginPlotOption = struct {
    x_label: [*c]const u8 = null,
    y_label: [*c]const u8 = null,
    size: imgui.ImVec2 = .{ .x = -1, .y = 0 },
    flags: c.ImPlotFlags = c.ImPlotFlags_None,
    x_flags: c.ImPlotAxisFlags = c.ImPlotAxisFlags_None,
    y_flags: c.ImPlotAxisFlags = c.ImPlotAxisFlags_None,
    y2_flags: c.ImPlotAxisFlags = c.ImPlotAxisFlags_NoGridLines,
    y3_flags: c.ImPlotAxisFlags = c.ImPlotAxisFlags_NoGridLines,
    y2_label: [*c]const u8 = null,
    y3_label: [*c]const u8 = null,
};
pub fn beginPlot(title_id: [:0]const u8, option: BeginPlotOption) bool {
    return c.ImPlot_BeginPlot(
        title_id.ptr,
        option.x_label,
        option.y_label,
        option.size,
        option.flags,
        option.x_flags,
        option.y_flags,
        option.y2_flags,
        option.y3_flags,
        option.y2_label,
        option.y3_label,
    );
}

// Only call EndPlot() if BeginPlot() returns true! Typically called at the end
// of an if statement conditioned on BeginPlot(). See example above.
pub fn endPlot() void {
    return c.ImPlot_EndPlot();
}

//-----------------------------------------------------------------------------
// Begin/EndSubplots
//-----------------------------------------------------------------------------

// Starts a subdivided plotting context. If the function returns true,
// EndSubplots() MUST be called! Call BeginPlot/EndPlot AT MOST [rows*cols]
// times in  between the begining and end of the subplot context. Plots are
// added in row major order.
//
// Example:
//
// if (BeginSubplots("My Subplot",2,3,ImVec2(800,400)) {
//     for (int i = 0; i < 6; ++i) {
//         if (BeginPlot(...)) {
//             ImPlot::PlotLine(...);
//             ...
//             EndPlot();
//         }
//     }
//     EndSubplots();
// }
//
// Produces:
//
// [0][1][2]
// [3][4][5]
//
// Important notes:
//
// - #title_id must be unique to the current ImGui ID scope. If you need to avoid ID
//   collisions or don't want to display a title in the plot, use double hashes
//   (e.g. "MyPlot##HiddenIdText" or "##NoTitle").
// - #rows and #cols must be greater than 0.
// - #size is the size of the entire grid of subplots, not the individual plots
// - #row_ratios and #col_ratios must have AT LEAST #rows and #cols elements,
//   respectively. These are the sizes of the rows and columns expressed in ratios.
//   If the user adjusts the dimensions, the arrays are updated with new ratios.
//
// Important notes regarding BeginPlot from inside of BeginSubplots:
//
// - The #title_id parameter of _BeginPlot_ (see above) does NOT have to be
//   unique when called inside of a subplot context. Subplot IDs are hashed
//   for your convenience so you don't have call PushID or generate unique title
//   strings. Simply pass an empty string to BeginPlot unless you want to title
//   each subplot.
// - The #size parameter of _BeginPlot_ (see above) is ignored when inside of a
//   subplot context. The actual size of the subplot will be based on the
//   #size value you pass to _BeginSubplots_ and #row/#col_ratios if provided.
pub const BeginSubplotsOption = struct {
    flags: c.ImPlotSubplotFlags = c.ImPlotSubplotFlags_None,
    row_ratios: [*c]f32 = null,
    col_ratios: [*c]f32 = null,
};
pub fn beginSubplots(title_id: [:0]const u8, rows: c_int, cols: c_int, size: imgui.ImVec2, option: BeginSubplotsOption) bool {
    return c.ImPlot_BeginSubplots(title_id.ptr, rows, cols, size, option.flags, option.row_ratios, option.col_ratios);
}

// Only call EndSubplots() if BeginSubplots() returns true! Typically called at the end
// of an if statement conditioned on BeginSublots(). See example above.
pub fn endSubplots() void {
    return c.ImPlot_EndSubplots();
}

//-----------------------------------------------------------------------------
// Plot Items
//-----------------------------------------------------------------------------

// The template functions below are explicitly instantiated in implot_items.cpp.
// They are not intended to be used generically with custom types. You will get
// a linker error if you try! All functions support the following scalar types:
//
// float, double, ImS8, ImU8, ImS16, ImU16, ImS32, ImU32, ImS64, ImU64
//
//
// If you need to plot custom or non-homogenous data you have a few options:
//
// 1. If your data is a simple struct/class (e.g. Vector2f), you can use striding.
//    This is the most performant option if applicable.
//
//    struct Vector2f { float X, Y; };
//    ...
//    Vector2f data[42];
//    ImPlot::PlotLine("line", &data[0].x, &data[0].y, 42, 0, sizeof(Vector2f)); // or sizeof(float)*2
//
// 2. Write a custom getter C function or C++ lambda and pass it and optionally your data to
//    an ImPlot function post-fixed with a G (e.g. PlotScatterG). This has a slight performance
//    cost, but probably not enough to worry about unless your data is very large. Examples:
//
//    ImPlotPoint MyDataGetter(void* data, int idx) {
//        MyData* my_data = (MyData*)data;
//        ImPlotPoint p;
//        p.x = my_data->GetTime(idx);
//        p.y = my_data->GetValue(idx);
//        return p
//    }
//    ...
//    auto my_lambda = [](void*, int idx) {
//        double t = idx / 999.0;
//        return ImPlotPoint(t, 0.5+0.5*std::sin(2*PI*10*t));
//    };
//    ...
//    if (ImPlot::BeginPlot("MyPlot")) {
//        MyData my_data;
//        ImPlot::PlotScatterG("scatter", MyDataGetter, &my_data, my_data.Size());
//        ImPlot::PlotLineG("line", my_lambda, nullptr, 1000);
//        ImPlot::EndPlot();
//    }
//
// NB: All types are converted to double before plotting. You may lose information
// if you try plotting extremely large 64-bit integral types. Proceed with caution!

// Plots a standard 2D line plot.
pub const PlotLineOption = struct {
    xscale: f64 = 1,
    x0: f64 = 0,
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotLine_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotLineOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotLine_FloatPtrInt,
        f64 => c.ImPlot_PlotLine_doublePtrInt,
        i8 => c.ImPlot_PlotLine_S8PtrInt,
        u8 => c.ImPlot_PlotLine_U8PtrInt,
        i16 => c.ImPlot_PlotLine_S16PtrInt,
        u16 => c.ImPlot_PlotLine_U16PtrInt,
        i32 => c.ImPlot_PlotLine_S32PtrInt,
        u32 => c.ImPlot_PlotLine_U32PtrInt,
        i64 => c.ImPlot_PlotLine_S64PtrInt,
        u64 => c.ImPlot_PlotLine_U64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.xscale,
        option.x0,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotLine_PtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotLineOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotLine_FloatPtrFloatPtr,
        f64 => c.ImPlot_PlotLine_doublePtrdoublePtr,
        i8 => c.ImPlot_PlotLine_S8PtrS8Ptr,
        u8 => c.ImPlot_PlotLine_U8PtrU8Ptr,
        i16 => c.ImPlot_PlotLine_S16PtrS16Ptr,
        u16 => c.ImPlot_PlotLine_U16PtrU16Ptr,
        i32 => c.ImPlot_PlotLine_S32PtrS32Ptr,
        u32 => c.ImPlot_PlotLine_U32PtrU32Ptr,
        i64 => c.ImPlot_PlotLine_S64PtrS64Ptr,
        u64 => c.ImPlot_PlotLine_U64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}
pub fn plotLineG(label_id: [:0]const u8, getter: c.ImPlotPoint_getter, data: ?*anyopaque, count: c_int) void {
    return c.ImPlot_PlotLineG(label_id.ptr, getter, data, count);
}

// Plots a standard 2D scatter plot. Default marker is ImPlotMarker_Circle.
pub const PlotScatterOption = struct {
    xscale: f64 = 1,
    x0: f64 = 0,
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotScatter_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotScatterOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotScatter_FloatPtrInt,
        f64 => c.ImPlot_PlotScatter_doublePtrInt,
        i8 => c.ImPlot_PlotScatter_S8PtrInt,
        u8 => c.ImPlot_PlotScatter_U8PtrInt,
        i16 => c.ImPlot_PlotScatter_S16PtrInt,
        u16 => c.ImPlot_PlotScatter_U16PtrInt,
        i32 => c.ImPlot_PlotScatter_S32PtrInt,
        u32 => c.ImPlot_PlotScatter_U32PtrInt,
        i64 => c.ImPlot_PlotScatter_S64PtrInt,
        u64 => c.ImPlot_PlotScatter_U64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.xscale,
        option.x0,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotScatter_PtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotScatterOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotScatter_FloatPtrFloatPtr,
        f64 => c.ImPlot_PlotScatter_doublePtrdoublePtr,
        i8 => c.ImPlot_PlotScatter_S8PtrS8Ptr,
        u8 => c.ImPlot_PlotScatter_U8PtrU8Ptr,
        i16 => c.ImPlot_PlotScatter_S16PtrS16Ptr,
        u16 => c.ImPlot_PlotScatter_U16PtrU16Ptr,
        i32 => c.ImPlot_PlotScatter_S32PtrS32Ptr,
        u32 => c.ImPlot_PlotScatter_U32PtrU32Ptr,
        i64 => c.ImPlot_PlotScatter_S64PtrS64Ptr,
        u64 => c.ImPlot_PlotScatter_U64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}
pub fn plotScatterG(label_id: [:0]const u8, getter: c.ImPlotPoint_getter, data: ?*anyopaque, count: c_int) void {
    return c.ImPlot_PlotScatterG(label_id.ptr, getter, data, count);
}

// Plots a a stairstep graph. The y value is continued constantly from every x position, i.e. the interval [x[i], x[i+1]) has the value y[i].
pub const PlotStairsOption = struct {
    xscale: f64 = 1,
    x0: f64 = 0,
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotStairs_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotScatterOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotStairs_FloatPtrInt,
        f64 => c.ImPlot_PlotStairs_doublePtrInt,
        i8 => c.ImPlot_PlotStairs_S8PtrInt,
        u8 => c.ImPlot_PlotStairs_U8PtrInt,
        i16 => c.ImPlot_PlotStairs_S16PtrInt,
        u16 => c.ImPlot_PlotStairs_U16PtrInt,
        i32 => c.ImPlot_PlotStairs_S32PtrInt,
        u32 => c.ImPlot_PlotStairs_U32PtrInt,
        i64 => c.ImPlot_PlotStairs_S64PtrInt,
        u64 => c.ImPlot_PlotStairs_U64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.xscale,
        option.x0,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotStairs_PtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotStairsOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotStairs_FloatPtrFloatPtr,
        f64 => c.ImPlot_PlotStairs_doublePtrdoublePtr,
        i8 => c.ImPlot_PlotStairs_S8PtrS8Ptr,
        u8 => c.ImPlot_PlotStairs_U8PtrU8Ptr,
        i16 => c.ImPlot_PlotStairs_S16PtrS16Ptr,
        u16 => c.ImPlot_PlotStairs_U16PtrU16Ptr,
        i32 => c.ImPlot_PlotStairs_S32PtrS32Ptr,
        u32 => c.ImPlot_PlotStairs_U32PtrU32Ptr,
        i64 => c.ImPlot_PlotStairs_S64PtrS64Ptr,
        u64 => c.ImPlot_PlotStairs_U64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}
pub fn plotStairsG(label_id: [:0]const u8, getter: ?fn (?*anyopaque, c_int) callconv(.C) c.ImPlotPoint, data: ?*anyopaque, count: c_int) void {
    return c.ImPlot_PlotStairsG(label_id.ptr, getter, data, count);
}

// Plots a shaded (filled) region between two lines, or a line and a horizontal reference. Set y_ref to +/-INFINITY for infinite fill extents.
pub const PlotShadedOption = struct {
    y_ref: f64 = 0,
    xscale: f64 = 1,
    x0: f64 = 0,
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotShaded_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotShadedOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotShaded_FloatPtrInt,
        f64 => c.ImPlot_PlotShaded_doublePtrInt,
        i8 => c.ImPlot_PlotShaded_S8PtrInt,
        u8 => c.ImPlot_PlotShaded_U8PtrInt,
        i16 => c.ImPlot_PlotShaded_S16PtrInt,
        u16 => c.ImPlot_PlotShaded_U16PtrInt,
        i32 => c.ImPlot_PlotShaded_S32PtrInt,
        u32 => c.ImPlot_PlotShaded_U32PtrInt,
        i64 => c.ImPlot_PlotShaded_S64PtrInt,
        u64 => c.ImPlot_PlotShaded_U64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.y_ref,
        option.xscale,
        option.x0,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotShaded_PtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotShadedOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotShaded_FloatPtrFloatPtrInt,
        f64 => c.ImPlot_PlotShaded_doublePtrdoublePtrInt,
        i8 => c.ImPlot_PlotShaded_S8PtrS8PtrInt,
        u8 => c.ImPlot_PlotShaded_U8PtrU8PtrInt,
        i16 => c.ImPlot_PlotShaded_S16PtrS16PtrInt,
        u16 => c.ImPlot_PlotShaded_U16PtrU16PtrInt,
        i32 => c.ImPlot_PlotShaded_S32PtrS32PtrInt,
        u32 => c.ImPlot_PlotShaded_U32PtrU32PtrInt,
        i64 => c.ImPlot_PlotShaded_S64PtrS64PtrInt,
        u64 => c.ImPlot_PlotShaded_U64PtrU64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.y_ref,
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}
pub fn plotShaded_PtrPtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys1: [*c]const T, ys2: [*c]const T, count: u32, option: PlotShadedOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotShaded_FloatPtrFloatPtrFloatPtr,
        f64 => c.ImPlot_PlotShaded_doublePtrdoublePtrdoublePtr,
        i8 => c.ImPlot_PlotShaded_S8PtrS8PtrS8Ptr,
        u8 => c.ImPlot_PlotShaded_U8PtrU8PtrU8Ptr,
        i16 => c.ImPlot_PlotShaded_S16PtrS16PtrS16Ptr,
        u16 => c.ImPlot_PlotShaded_U16PtrU16PtrU16Ptr,
        i32 => c.ImPlot_PlotShaded_S32PtrS32PtrS32Ptr,
        u32 => c.ImPlot_PlotShaded_U32PtrU32PtrU32Ptr,
        i64 => c.ImPlot_PlotShaded_S64PtrS64PtrS64Ptr,
        u64 => c.ImPlot_PlotShaded_U64PtrU64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys1,
        ys2,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 3,
    );
}
pub fn plotShadedG(label_id: [:0]const u8, getter1: c.ImPlotPoint_getter, data1: ?*anyopaque, getter2: c.ImPlotPoint_getter, data2: ?*anyopaque, count: c_int) void {
    return c.ImPlot_PlotShadedG(label_id.ptr, getter1, data1, getter2, data2, count);
}

// Plots a vertical bar graph. #width and #shift are in X units.
pub const PlotBarsOption = struct {
    width: f64 = 0.67,
    shift: f64 = 0,
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotBars_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotBarsOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotBars_FloatPtrInt,
        f64 => c.ImPlot_PlotBars_doublePtrInt,
        i8 => c.ImPlot_PlotBars_S8PtrInt,
        u8 => c.ImPlot_PlotBars_U8PtrInt,
        i16 => c.ImPlot_PlotBars_S16PtrInt,
        u16 => c.ImPlot_PlotBars_U16PtrInt,
        i32 => c.ImPlot_PlotBars_S32PtrInt,
        u32 => c.ImPlot_PlotBars_U32PtrInt,
        i64 => c.ImPlot_PlotBars_S64PtrInt,
        u64 => c.ImPlot_PlotBars_U64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.width,
        option.shift,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotBars_PtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotBarsOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotBars_FloatPtrFloatPtr,
        f64 => c.ImPlot_PlotBars_doublePtrdoublePtr,
        i8 => c.ImPlot_PlotBars_S8PtrS8Ptr,
        u8 => c.ImPlot_PlotBars_U8PtrU8Ptr,
        i16 => c.ImPlot_PlotBars_S16PtrS16Ptr,
        u16 => c.ImPlot_PlotBars_U16PtrU16Ptr,
        i32 => c.ImPlot_PlotBars_S32PtrS32Ptr,
        u32 => c.ImPlot_PlotBars_U32PtrU32Ptr,
        i64 => c.ImPlot_PlotBars_S64PtrS64Ptr,
        u64 => c.ImPlot_PlotBars_U64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.width,
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}
pub fn plotBarsG(label_id: [:0]const u8, getter: c.ImPlotPoint_getter, data: ?*anyopaque, count: c_int, width: f64) void {
    return c.ImPlot_PlotBarsG(label_id.ptr, getter, data, count, width);
}

// Plots a horizontal bar graph. #height and #shift are in Y units.
pub const PlotBarsHOption = struct {
    height: f64 = 0.67,
    shift: f64 = 0,
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotBarsH_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotBarsHOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotBarsH_FloatPtrInt,
        f64 => c.ImPlot_PlotBarsH_doublePtrInt,
        i8 => c.ImPlot_PlotBarsH_S8PtrInt,
        u8 => c.ImPlot_PlotBarsH_U8PtrInt,
        i16 => c.ImPlot_PlotBarsH_S16PtrInt,
        u16 => c.ImPlot_PlotBarsH_U16PtrInt,
        i32 => c.ImPlot_PlotBarsH_S32PtrInt,
        u32 => c.ImPlot_PlotBarsH_U32PtrInt,
        i64 => c.ImPlot_PlotBarsH_S64PtrInt,
        u64 => c.ImPlot_PlotBarsH_U64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.height,
        option.shift,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotBarsH_PtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotBarsHOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotBarsH_FloatPtrFloatPtr,
        f64 => c.ImPlot_PlotBarsH_doublePtrdoublePtr,
        i8 => c.ImPlot_PlotBarsH_S8PtrS8Ptr,
        u8 => c.ImPlot_PlotBarsH_U8PtrU8Ptr,
        i16 => c.ImPlot_PlotBarsH_S16PtrS16Ptr,
        u16 => c.ImPlot_PlotBarsH_U16PtrU16Ptr,
        i32 => c.ImPlot_PlotBarsH_S32PtrS32Ptr,
        u32 => c.ImPlot_PlotBarsH_U32PtrU32Ptr,
        i64 => c.ImPlot_PlotBarsH_S64PtrS64Ptr,
        u64 => c.ImPlot_PlotBarsH_U64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.height,
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}
pub fn plotBarsHG(label_id: [:0]const u8, getter: c.ImPlotPoint_getter, data: ?*anyopaque, count: c_int, height: f64) void {
    return c.ImPlot_PlotBarsHG(label_id.ptr, getter, data, count, height);
}

// Plots vertical error bar. The label_id should be the same as the label_id of the associated line or bar plot.
pub const PlotErrorBarsOption = struct {
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotErrorBars_PtrPtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, err: [*c]const T, count: u32, option: PlotErrorBarsOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrInt,
        f64 => c.ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrInt,
        i8 => c.ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrInt,
        u8 => c.ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrInt,
        i16 => c.ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrInt,
        u16 => c.ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrInt,
        i32 => c.ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrInt,
        u32 => c.ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrInt,
        i64 => c.ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrInt,
        u64 => c.ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        err,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 3,
    );
}
pub fn plotErrorBars_PtrPtrPtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, neg: [*c]const T, pos: [*c]const T, count: u32, option: PlotErrorBarsOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrFloatPtr,
        f64 => c.ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrdoublePtr,
        i8 => c.ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrS8Ptr,
        u8 => c.ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrU8Ptr,
        i16 => c.ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrS16Ptr,
        u16 => c.ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrU16Ptr,
        i32 => c.ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrS32Ptr,
        u32 => c.ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrU32Ptr,
        i64 => c.ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrS64Ptr,
        u64 => c.ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        neg,
        pos,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 4,
    );
}

// Plots horizontal error bars. The label_id should be the same as the label_id of the associated line or bar plot.
pub const PlotErrorBarsHOption = struct {
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotErrorBarsH_PtrPtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, err: [*c]const T, count: u32, option: PlotErrorBarsHOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotErrorBarsH_FloatPtrFloatPtrFloatPtrInt,
        f64 => c.ImPlot_PlotErrorBarsH_doublePtrdoublePtrdoublePtrInt,
        i8 => c.ImPlot_PlotErrorBarsH_S8PtrS8PtrS8PtrInt,
        u8 => c.ImPlot_PlotErrorBarsH_U8PtrU8PtrU8PtrInt,
        i16 => c.ImPlot_PlotErrorBarsH_S16PtrS16PtrS16PtrInt,
        u16 => c.ImPlot_PlotErrorBarsH_U16PtrU16PtrU16PtrInt,
        i32 => c.ImPlot_PlotErrorBarsH_S32PtrS32PtrS32PtrInt,
        u32 => c.ImPlot_PlotErrorBarsH_U32PtrU32PtrU32PtrInt,
        i64 => c.ImPlot_PlotErrorBarsH_S64PtrS64PtrS64PtrInt,
        u64 => c.ImPlot_PlotErrorBarsH_U64PtrU64PtrU64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        err,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 3,
    );
}
pub fn plotErrorBarsH_PtrPtrPtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, neg: [*c]const T, pos: [*c]const T, count: u32, option: PlotErrorBarsHOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotErrorBarsH_FloatPtrFloatPtrFloatPtrFloatPtr,
        f64 => c.ImPlot_PlotErrorBarsH_doublePtrdoublePtrdoublePtrdoublePtr,
        i8 => c.ImPlot_PlotErrorBarsH_S8PtrS8PtrS8PtrS8Ptr,
        u8 => c.ImPlot_PlotErrorBarsH_U8PtrU8PtrU8PtrU8Ptr,
        i16 => c.ImPlot_PlotErrorBarsH_S16PtrS16PtrS16PtrS16Ptr,
        u16 => c.ImPlot_PlotErrorBarsH_U16PtrU16PtrU16PtrU16Ptr,
        i32 => c.ImPlot_PlotErrorBarsH_S32PtrS32PtrS32PtrS32Ptr,
        u32 => c.ImPlot_PlotErrorBarsH_U32PtrU32PtrU32PtrU32Ptr,
        i64 => c.ImPlot_PlotErrorBarsH_S64PtrS64PtrS64PtrS64Ptr,
        u64 => c.ImPlot_PlotErrorBarsH_U64PtrU64PtrU64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        neg,
        pos,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 4,
    );
}

// Plots vertical stems.
pub const PlotStemsOption = struct {
    y_ref: f64 = 0,
    xscale: f64 = 1,
    x0: f64 = 0,
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotStems_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotStemsOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotStems_FloatPtrInt,
        f64 => c.ImPlot_PlotStems_doublePtrInt,
        i8 => c.ImPlot_PlotStems_S8PtrInt,
        u8 => c.ImPlot_PlotStems_U8PtrInt,
        i16 => c.ImPlot_PlotStems_S16PtrInt,
        u16 => c.ImPlot_PlotStems_U16PtrInt,
        i32 => c.ImPlot_PlotStems_S32PtrInt,
        u32 => c.ImPlot_PlotStems_U32PtrInt,
        i64 => c.ImPlot_PlotStems_S64PtrInt,
        u64 => c.ImPlot_PlotStems_U64PtrInt,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.y_ref,
        option.xscale,
        option.x0,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotStems_PtrPtr(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotStemsOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotStems_FloatPtrFloatPtr,
        f64 => c.ImPlot_PlotStems_doublePtrdoublePtr,
        i8 => c.ImPlot_PlotStems_S8PtrS8Ptr,
        u8 => c.ImPlot_PlotStems_U8PtrU8Ptr,
        i16 => c.ImPlot_PlotStems_S16PtrS16Ptr,
        u16 => c.ImPlot_PlotStems_U16PtrU16Ptr,
        i32 => c.ImPlot_PlotStems_S32PtrS32Ptr,
        u32 => c.ImPlot_PlotStems_U32PtrU32Ptr,
        i64 => c.ImPlot_PlotStems_S64PtrS64Ptr,
        u64 => c.ImPlot_PlotStems_U64PtrU64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.y_ref,
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}

// Plots infinite vertical or horizontal lines (e.g. for references or asymptotes).
pub const PlotVHLinesOption = struct {
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotVLines_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotVHLinesOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotVLines_FloatPtr,
        f64 => c.ImPlot_PlotVLines_doublePtr,
        i8 => c.ImPlot_PlotVLines_S8Ptr,
        u8 => c.ImPlot_PlotVLines_U8Ptr,
        i16 => c.ImPlot_PlotVLines_S16Ptr,
        u16 => c.ImPlot_PlotVLines_U16Ptr,
        i32 => c.ImPlot_PlotVLines_S32Ptr,
        u32 => c.ImPlot_PlotVLines_U32Ptr,
        i64 => c.ImPlot_PlotVLines_S64Ptr,
        u64 => c.ImPlot_PlotVLines_U64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.y_ref,
        option.xscale,
        option.x0,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}
pub fn plotHLines_Ptr(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotVHLinesOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotHLines_FloatPtr,
        f64 => c.ImPlot_PlotHLines_doublePtr,
        i8 => c.ImPlot_PlotHLines_S8Ptr,
        u8 => c.ImPlot_PlotHLines_U8Ptr,
        i16 => c.ImPlot_PlotHLines_S16Ptr,
        u16 => c.ImPlot_PlotHLines_U16Ptr,
        i32 => c.ImPlot_PlotHLines_S32Ptr,
        u32 => c.ImPlot_PlotHLines_U32Ptr,
        i64 => c.ImPlot_PlotHLines_S64Ptr,
        u64 => c.ImPlot_PlotHLines_U64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.y_ref,
        option.xscale,
        option.x0,
        option.offset,
        option.stride orelse @sizeOf(T),
    );
}

// Plots a pie chart. If the sum of values > 1 or normalize is true, each value will be normalized. Center and radius are in plot units. #label_fmt can be set to NULL for no labels.
pub const PlotPieChartOption = struct {
    normalized: bool = false,
    label_fmt: [:0]const u8 = "%.1f",
    angle0: f64 = 90,
};
pub fn plotPieChart(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, x: f64, y: f64, radius: f64, option: PlotPieChartOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotPieChart_FloatPtr,
        f64 => c.ImPlot_PlotPieChart_doublePtr,
        i8 => c.ImPlot_PlotPieChart_S8Ptr,
        u8 => c.ImPlot_PlotPieChart_U8Ptr,
        i16 => c.ImPlot_PlotPieChart_S16Ptr,
        u16 => c.ImPlot_PlotPieChart_U16Ptr,
        i32 => c.ImPlot_PlotPieChart_S32Ptr,
        u32 => c.ImPlot_PlotPieChart_U32Ptr,
        i64 => c.ImPlot_PlotPieChart_S64Ptr,
        u64 => c.ImPlot_PlotPieChart_U64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        x,
        y,
        radius,
        option.normalized,
        option.label_fmt,
        option.angle0,
    );
}

// Plots a 2D heatmap chart. Values are expected to be in row-major order. Leave #scale_min and scale_max both at 0 for automatic color scaling, or set them to a predefined range. #label_fmt can be set to NULL for no labels.
pub const PlotHeatmapOption = struct {
    scale_min: f64 = 0,
    scale_max: f64 = 0,
    label_fmt: [:0]const u8 = "%.1f",
    bounds_min: c.ImPlotPoint = .{ .x = 0, .y = 0 },
    bounds_max: c.ImPlotPoint = .{ .x = 1, .y = 1 },
};
pub fn plotHeatmap(label_id: [:0]const u8, comptime T: type, values: [*]const T, rows: u32, cols: u32, option: PlotHeatmapOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotHeatmap_FloatPtr,
        f64 => c.ImPlot_PlotHeatmap_doublePtr,
        i8 => c.ImPlot_PlotHeatmap_S8Ptr,
        u8 => c.ImPlot_PlotHeatmap_U8Ptr,
        i16 => c.ImPlot_PlotHeatmap_S16Ptr,
        u16 => c.ImPlot_PlotHeatmap_U16Ptr,
        i32 => c.ImPlot_PlotHeatmap_S32Ptr,
        u32 => c.ImPlot_PlotHeatmap_U32Ptr,
        i64 => c.ImPlot_PlotHeatmap_S64Ptr,
        u64 => c.ImPlot_PlotHeatmap_U64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, rows),
        @intCast(c_int, cols),
        option.scale_min,
        option.scale_max,
        option.label_fmt,
        option.bounds_min,
        option.bounds_max,
    );
}

// Plots a horizontal histogram. #bins can be a positive integer or an ImPlotBin_ method. If #cumulative is true, each bin contains its count plus the counts of all previous bins.
// If #density is true, the PDF is visualized. If both are true, the CDF is visualized. If #range is left unspecified, the min/max of #values will be used as the range.
// If #range is specified, outlier values outside of the range are not binned. However, outliers still count toward normalizing and cumulative counts unless #outliers is false. The largest bin count or density is returned.
pub const PlotHistogramOption = struct {
    bins: c_int = c.ImPlotBin_Sturges,
    cumulative: bool = false,
    density: bool = false,
    range: c.ImPlotRange = .{ .x = 0, .y = 0 },
    outlier: bool = true,
    bar_scale: f64 = 1.0,
};
pub fn plotHistogram(label_id: [:0]const u8, comptime T: type, values: [*c]const T, count: u32, option: PlotHistogramOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotHistogram_FloatPtr,
        f64 => c.ImPlot_PlotHistogram_doublePtr,
        i8 => c.ImPlot_PlotHistogram_S8Ptr,
        u8 => c.ImPlot_PlotHistogram_U8Ptr,
        i16 => c.ImPlot_PlotHistogram_S16Ptr,
        u16 => c.ImPlot_PlotHistogram_U16Ptr,
        i32 => c.ImPlot_PlotHistogram_S32Ptr,
        u32 => c.ImPlot_PlotHistogram_U32Ptr,
        i64 => c.ImPlot_PlotHistogram_S64Ptr,
        u64 => c.ImPlot_PlotHistogram_U64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        values,
        @intCast(c_int, count),
        option.bins,
        option.cumulative,
        option.density,
        option.range,
        option.outlier,
        option.bar_scale,
    );
}

// Plots two dimensional, bivariate histogram as a heatmap. #x_bins and #y_bins can be a positive integer or an ImPlotBin. If #density is true, the PDF is visualized.
// If #range is left unspecified, the min/max of #xs an #ys will be used as the ranges. If #range is specified, outlier values outside of range are not binned.
// However, outliers still count toward the normalizing count for density plots unless #outliers is false. The largest bin count or density is returned.
pub const PlotHistogram2DOption = struct {
    x_bins: c_int = c.ImPlotBin_Sturges,
    y_bins: c_int = c.ImPlotBin_Sturges,
    density: bool = false,
    range: c.ImPlotRange = .{ .x = 0, .y = 0 },
    outlier: bool = true,
};
pub fn plotHistogram2D(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotHistogram2DOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotHistogram2D_FloatPtr,
        f64 => c.ImPlot_PlotHistogram2D_doublePtr,
        i8 => c.ImPlot_PlotHistogram2D_S8Ptr,
        u8 => c.ImPlot_PlotHistogram2D_U8Ptr,
        i16 => c.ImPlot_PlotHistogram2D_S16Ptr,
        u16 => c.ImPlot_PlotHistogram2D_U16Ptr,
        i32 => c.ImPlot_PlotHistogram2D_S32Ptr,
        u32 => c.ImPlot_PlotHistogram2D_U32Ptr,
        i64 => c.ImPlot_PlotHistogram2D_S64Ptr,
        u64 => c.ImPlot_PlotHistogram2D_U64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.x_bins,
        option.y_bins,
        option.density,
        option.range,
        option.outlier,
    );
}

// Plots digital data. Digital plots do not respond to y drag or zoom, and are always referenced to the bottom of the plot.
pub const PlotDigitalOption = struct {
    offset: c_int = 0,
    stride: ?c_int = null,
};
pub fn plotDigital(label_id: [:0]const u8, comptime T: type, xs: [*c]const T, ys: [*c]const T, count: u32, option: PlotDigitalOption) void {
    const plotFn = switch (T) {
        f32 => c.ImPlot_PlotDigital_FloatPtr,
        f64 => c.ImPlot_PlotDigital_doublePtr,
        i8 => c.ImPlot_PlotDigital_S8Ptr,
        u8 => c.ImPlot_PlotDigital_U8Ptr,
        i16 => c.ImPlot_PlotDigital_S16Ptr,
        u16 => c.ImPlot_PlotDigital_U16Ptr,
        i32 => c.ImPlot_PlotDigital_S32Ptr,
        u32 => c.ImPlot_PlotDigital_U32Ptr,
        i64 => c.ImPlot_PlotDigital_S64Ptr,
        u64 => c.ImPlot_PlotDigital_U64Ptr,
        else => unreachable,
    };
    plotFn(
        label_id.ptr,
        xs,
        ys,
        @intCast(c_int, count),
        option.offset,
        option.stride orelse @sizeOf(T) * 2,
    );
}
pub fn plotDigitalG(label_id: [:0]const u8, getter: c.ImPlotPoint_getter, data: ?*anyopaque, count: c_int) void {
    return c.ImPlot_PlotDigitalG(label_id.ptr, getter, data, count);
}

// Plots an axis-aligned image. #bounds_min/bounds_max are in plot coordinates (y-up) and #uv0/uv1 are in texture coordinates (y-down).
pub const PlotImageOption = struct {
    uv0: imgui.ImVec2 = .{ .x = 0, .y = 0 },
    uv1: imgui.ImVec2 = .{ .x = 1, .y = 1 },
    tint_col: imgui.ImVec4 = .{ .x = 1, .y = 1, .z = 1, .w = 1 },
};
pub fn plotImage(label_id: [:0]const u8, user_texture_id: imgui.ImTextureID, bounds_min: c.ImPlotPoint, bounds_max: c.ImPlotPoint, option: PlotImageOption) void {
    return c.ImPlot_PlotImage(
        label_id.ptr,
        user_texture_id,
        bounds_min,
        bounds_max,
        option.uv0,
        option.uv1,
        option.tint_col,
    );
}

// Plots a centered text label at point x,y with an optional pixel offset. Text color can be changed with ImPlot::PushStyleColor(ImPlotCol_InlayText, ...).
pub const PlotTextOption = struct {
    vertical: bool = false,
    pix_offset: imgui.ImVec2 = .{ .x = 0, .y = 0 },
};
pub fn plotText(text: [:0]const u8, x: f64, y: f64, option: PlotTextOption) void {
    return c.ImPlot_PlotText(text, x, y, option.vertical, option.pix_offset);
}

// Plots a dummy item (i.e. adds a legend entry colored by ImPlotCol_Line)
pub fn plotDummy(label_id: [:0]const u8) void {
    return c.ImPlot_PlotDummy(label_id.ptr);
}

//-----------------------------------------------------------------------------
// Plot Utils
//-----------------------------------------------------------------------------

////// The following functions MUST be called BEFORE BeginPlot!
// Set the axes range limits of the next plot. Call right before BeginPlot(). If ImGuiCond_Always is used, the axes limits will be locked.
pub fn setNextPlotLimits(xmin: f64, xmax: f64, ymin: f64, ymax: f64, cond: ?imgui.ImGuiCond) void {
    return c.ImPlot_SetNextPlotLimits(xmin, xmax, ymin, ymax, cond orelse imgui.ImGuiCond_Once);
}
// Set the X axis range limits of the next plot. Call right before BeginPlot(). If ImGuiCond_Always is used, the X axis limits will be locked.
pub fn setNextPlotLimitsX(xmin: f64, xmax: f64, cond: ?imgui.ImGuiCond) void {
    return c.ImPlot_SetNextPlotLimitsX(xmin, xmax, cond orelse imgui.ImGuiCond_Once);
}
// Set the Y axis range limits of the next plot. Call right before BeginPlot(). If ImGuiCond_Always is used, the Y axis limits will be locked.
pub const SetNextPlotLimitsYOption = struct {
    cond: imgui.ImGuiCond = imgui.ImGuiCond_Once,
    y_axis: c.ImPlotYAxis = c.ImPlotYAxis_1,
};
pub fn setNextPlotLimitsY(ymin: f64, ymax: f64, option: SetNextPlotLimitsYOption) void {
    return c.ImPlot_SetNextPlotLimitsY(
        ymin,
        ymax,
        option.cond,
        option.y_axis,
    );
}
// Links the next plot limits to external values. Set to NULL for no linkage. The pointer data must remain valid until the matching call to EndPlot.
pub const LinkNextPlotLimitsOption = struct {
    ymin2: [*c]f64 = null,
    ymax2: [*c]f64 = null,
    ymin3: [*c]f64 = null,
    ymax3: [*c]f64 = null,
};
pub fn linkNextPlotLimits(xmin: [*c]f64, xmax: [*c]f64, ymin: [*c]f64, ymax: [*c]f64, option: LinkNextPlotLimitsOption) void {
    return c.ImPlot_LinkNextPlotLimits(
        xmin,
        xmax,
        ymin,
        ymax,
        option.ymin2,
        option.ymax2,
        option.ymin3,
        option.ymax3,
    );
}
// Fits the next plot axes to all plotted data if they are unlocked (equivalent to double-clicks).
pub const FitNextPlotAxes = struct {
    x: bool = true,
    y: bool = true,
    y2: bool = true,
    y3: bool = true,
};
pub fn fitNextPlotAxes(option: FitNextPlotAxes) void {
    return c.ImPlot_FitNextPlotAxes(option.x, option.y, option.y2, option.y3);
}
// Set the X axis ticks and optionally the labels for the next plot. To keep the default ticks, set #keep_default=true.
pub const SetNextPlotTicksXOption = struct {
    labels: [*c]const [*c]const u8 = null,
    keep_default: bool = false,
};
pub fn setNextPlotTicksX_doublePtr(values: [*c]const f64, n_ticks: c_int, option: SetNextPlotTicksXOption) void {
    return c.ImPlot_SetNextPlotTicksX_doublePtr(values, n_ticks, option.labels, option.keep_default);
}
pub fn setNextPlotTicksX_double(x_min: f64, x_max: f64, n_ticks: c_int, option: SetNextPlotTicksXOption) void {
    return c.ImPlot_SetNextPlotTicksX_double(x_min, x_max, n_ticks, option.labels, option.keep_default);
}
// Set the Y axis ticks and optionally the labels for the next plot. To keep the default ticks, set #keep_default=true.
pub const SetNextPlotTicksYOption = struct {
    labels: [*c]const [*c]const u8 = null,
    keep_default: bool = false,
    y_axis: c.ImPlotYAxis = c.ImPlotYAxis_1,
};
pub fn setNextPlotTicksY_doublePtr(values: [*c]const f64, n_ticks: c_int, option: SetNextPlotTicksYOption) void {
    return c.ImPlot_SetNextPlotTicksY_doublePtr(values, n_ticks, option.labels, option.keep_default, option.y_axis);
}
pub fn setNextPlotTicksY_double(y_min: f64, y_max: f64, n_ticks: c_int, option: SetNextPlotTicksYOption) void {
    return c.ImPlot_SetNextPlotTicksY_double(y_min, y_max, n_ticks, option.labels, option.keep_default, option.y_axis);
}
// Set the format for numeric X axis labels (default="%g"). Formated values will be doubles (i.e. don't supply %d, %i, etc.). Not applicable if ImPlotAxisFlags_Time enabled.
pub fn setNextPlotFormatX(fmt: [:0]const u8) void {
    return c.ImPlot_SetNextPlotFormatX(fmt);
}
// Set the format for numeric Y axis labels (default="%g"). Formated values will be doubles (i.e. don't supply %d, %i, etc.).
pub fn setNextPlotFormatY(fmt: [:0]const u8, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_SetNextPlotFormatY(fmt, y_axis orelse c.ImPlotYAxis_1);
}

//////// The following functions MUST be called BETWEEN Begin/EndPlot!
// Select which Y axis will be used for subsequent plot elements. The default is ImPlotYAxis_1, or the first (left) Y axis. Enable 2nd and 3rd axes with ImPlotFlags_YAxisX.
pub fn setPlotYAxis(y_axis: c.ImPlotYAxis) void {
    return c.ImPlot_SetPlotYAxis(y_axis);
}
// Hides or shows the next plot item (i.e. as if it were toggled from the legend). Use ImGuiCond_Always if you need to forcefully set this every frame.
pub const HideNextItemOption = struct {
    hidden: bool = true,
    cond: ?imgui.ImGuiCond = imgui.ImGuiCond_Once,
};
pub fn hideNextItem(option: HideNextItemOption) void {
    return c.ImPlot_HideNextItem(option.hidden, option.cond);
}

// Convert pixels to a position in the current plot's coordinate system. A negative y_axis uses the current value of SetPlotYAxis (ImPlotYAxis_1 initially).
pub fn pixelsToPlot_Vec2(pOut: *c.ImPlotPoint, pix: imgui.ImVec2, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_PixelsToPlot_Vec2(pOut, pix, y_axis orelse IMPLOT_AUTO);
}
pub fn pixelsToPlot_Float(pOut: *c.ImPlotPoint, x: f32, y: f32, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_PixelsToPlot_Float(pOut, x, y, y_axis orelse IMPLOT_AUTO);
}
// Convert a position in the current plot's coordinate system to pixels. A negative y_axis uses the current value of SetPlotYAxis (ImPlotYAxis_1 initially).
pub fn plotToPixels_PlotPoInt(pOut: [*c]imgui.ImVec2, plt: c.ImPlotPoint, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_PlotToPixels_PlotPoInt(pOut, plt, y_axis orelse IMPLOT_AUTO);
}
pub fn plotToPixels_double(pOut: [*c]imgui.ImVec2, x: f64, y: f64, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_PlotToPixels_double(pOut, x, y, y_axis orelse IMPLOT_AUTO);
}
// Get the current Plot position (top-left) in pixels.
pub fn getPlotPos(pOut: [*c]imgui.ImVec2) void {
    return c.ImPlot_GetPlotPos(pOut);
}
// Get the curent Plot size in pixels.
pub fn getPlotSize(pOut: [*c]imgui.ImVec2) void {
    return c.ImPlot_GetPlotSize(pOut);
}
// Returns true if the plot area in the current plot is hovered.
pub fn isPlotHovered() bool {
    return c.ImPlot_IsPlotHovered();
}
// Returns true if the XAxis plot area in the current plot is hovered.
pub fn isPlotXAxisHovered() bool {
    return c.ImPlot_IsPlotXAxisHovered();
}
// Returns true if the YAxis[n] plot area in the current plot is hovered.
pub fn isPlotYAxisHovered(y_axis: ?c.ImPlotYAxis) bool {
    return c.ImPlot_IsPlotYAxisHovered(y_axis orelse 0);
}
// Returns the mouse position in x,y coordinates of the current plot. A negative y_axis uses the current value of SetPlotYAxis (ImPlotYAxis_1 initially).
pub fn getPlotMousePos(pOut: *c.ImPlotPoint, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_GetPlotMousePos(pOut, y_axis orelse IMPLOT_AUTO);
}
// Returns the current plot axis range. A negative y_axis uses the current value of SetPlotYAxis (ImPlotYAxis_1 initially).
pub fn getPlotLimits(pOut: *c.ImPlotLimits, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_GetPlotLimits(pOut, y_axis orelse IMPLOT_AUTO);
}
// Returns true if the current plot is being box selected.
pub fn isPlotSelected() bool {
    return c.ImPlot_IsPlotSelected();
}
// Returns the current plot box selection bounds.
pub fn getPlotSelection(pOut: *c.ImPlotLimits, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_GetPlotSelection(pOut, y_axis orelse IMPLOT_AUTO);
}
// Returns true if the current plot is being queried or has an active query. Query must be enabled with ImPlotFlags_Query.
pub fn isPlotQueried() bool {
    return c.ImPlot_IsPlotQueried();
}
// Returns the current plot query bounds. Query must be enabled with ImPlotFlags_Query.
pub fn getPlotQuery(pOut: *c.ImPlotLimits, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_GetPlotQuery(pOut, y_axis orelse IMPLOT_AUTO);
}
// Set the current plot query bounds. Query must be enabled with ImPlotFlags_Query.
pub fn setPlotQuery(query: c.ImPlotLimits, y_axis: ?c.ImPlotYAxis) void {
    return c.ImPlot_SetPlotQuery(query, y_axis orelse IMPLOT_AUTO);
}
// Returns true if the bounding frame of a subplot is hovered/
pub fn isSubplotsHovered() bool {
    return c.ImPlot_IsSubplotsHovered();
}

//-----------------------------------------------------------------------------
// Aligned Plots
//-----------------------------------------------------------------------------

// Consider using Begin/EndSubplots first. They are more feature rich and
// accomplish the same behaviour by default. The functions below offer lower
// level control of plot alignment.

// Align axis padding over multiple plots in a single row or column. If this function returns true, EndAlignedPlots() must be called. #group_id must be unique.
pub fn beginAlignedPlots(group_id: [:0]const u8, orientation: ?c.ImPlotOrientation) bool {
    return c.ImPlot_BeginAlignedPlots(group_id, orientation orelse c.ImPlotOrientation_Vertical);
}
pub fn endAlignedPlots() void {
    return c.ImPlot_EndAlignedPlots();
}

//-----------------------------------------------------------------------------
// Plot Tools
//-----------------------------------------------------------------------------

// The following functions MUST be called BETWEEN Begin/EndPlot!

// Shows an annotation callout at a chosen point.
pub fn annotate_Str(x: f64, y: f64, pix_offset: imgui.ImVec2, fmt: [*c]const u8) void {
    return c.ImPlot_Annotate_Str(x, y, pix_offset, fmt);
}
pub fn annotate_Vec4(x: f64, y: f64, pix_offset: imgui.ImVec2, color: imgui.ImVec4, fmt: [*c]const u8) void {
    return c.ImPlot_Annotate_Vec4(x, y, pix_offset, color, fmt);
}
// Same as above, but the annotation will always be clamped to stay inside the plot area.
pub fn annotateClamped_Str(x: f64, y: f64, pix_offset: imgui.ImVec2, fmt: [*c]const u8) void {
    return c.ImPlot_AnnotateClamped_Str(x, y, pix_offset, fmt);
}
pub fn annotateClamped_Vec4(x: f64, y: f64, pix_offset: imgui.ImVec2, color: imgui.ImVec4, fmt: [*c]const u8) void {
    return c.ImPlot_AnnotateClamped_Vec4(x, y, pix_offset, color, fmt);
}
// Shows a draggable vertical guide line at an x-value. #col defaults to ImGuiCol_Text.
pub const DragLineOption = struct {
    show_label: bool = true,
    col: imgui.ImVec4 = IMPLOT_AUTO_COL,
    thickness: f32 = 1,
};
pub fn dragLineX(id: [:0]const u8, x_value: [*c]f64, option: DragLineOption) bool {
    return c.ImPlot_DragLineX(id, x_value, option.show_label, option.col, option.thickness);
}
// Shows a draggable horizontal guide line at a y-value. #col defaults to ImGuiCol_Text.
pub fn dragLineY(id: [:0]const u8, y_value: [*c]f64, option: DragLineOption) bool {
    return c.ImPlot_DragLineY(id, y_value, option.show_label, option.col, option.thickness);
}
// Shows a draggable point at x,y. #col defaults to ImGuiCol_Text.
pub const DragPointOption = struct {
    show_label: bool = true,
    col: imgui.ImVec4 = IMPLOT_AUTO_COL,
    thickness: f32 = 4,
};
pub fn dragPoint(id: [:0]const u8, x: [*c]f64, y: [*c]f64, option: DragPointOption) bool {
    return c.ImPlot_DragPoint(id, x, y, option.show_label, option.col, option.radius);
}

//-----------------------------------------------------------------------------
// Legend Utils and Tools
//-----------------------------------------------------------------------------

// The following functions MUST be called BETWEEN Begin/EndPlot!

// Set the location of the current plot's (or subplot's) legend.
pub const SetLegendLocationOption = struct {
    orientation: c.ImPlotOrientation = c.ImPlotOrientation_Vertical,
    outside: bool = false,
};
pub fn setLegendLocation(location: c.ImPlotLocation, option: SetLegendLocationOption) void {
    return c.ImPlot_SetLegendLocation(location, option.orientation, option.outside);
}
// Set the location of the current plot's mouse position text (default = South|East).
pub fn setMousePosLocation(location: c.ImPlotLocation) void {
    return c.ImPlot_SetMousePosLocation(location);
}
// Returns true if a plot item legend entry is hovered.
pub fn isLegendEntryHovered(label_id: [:0]const u8) bool {
    return c.ImPlot_IsLegendEntryHovered(label_id.ptr);
}

// Begin a popup for a legend entry.
pub fn beginLegendPopup(label_id: [:0]const u8, mouse_button: ?imgui.ImGuiMouseButton) bool {
    return c.ImPlot_BeginLegendPopup(label_id.ptr, mouse_button orelse 1);
}
// End a popup for a legend entry.
pub fn endLegendPopup() void {
    return c.ImPlot_EndLegendPopup();
}

//-----------------------------------------------------------------------------
// Drag and Drop Utils
//-----------------------------------------------------------------------------

// The following functions MUST be called BETWEEN Begin/EndPlot!

// Turns the current plot's plotting area into a drag and drop target. Don't forget to call EndDragDropTarget!
pub fn beginDragDropTarget() bool {
    return c.ImPlot_BeginDragDropTarget();
}
// Turns the current plot's X-axis into a drag and drop target. Don't forget to call EndDragDropTarget!
pub fn beginDragDropTargetX() bool {
    return c.ImPlot_BeginDragDropTargetX();
}
// Turns the current plot's Y-Axis into a drag and drop target. Don't forget to call EndDragDropTarget!
pub fn beginDragDropTargetY(axis: ?c.ImPlotYAxis) bool {
    return c.ImPlot_BeginDragDropTargetY(axis orelse c.ImPlotYAxis_1);
}
// Turns the current plot's legend into a drag and drop target. Don't forget to call EndDragDropTarget!
pub fn beginDragDropTargetLegend() bool {
    return c.ImPlot_BeginDragDropTargetLegend();
}
// Ends a drag and drop target (currently just an alias for ImGui::EndDragDropTarget).
pub fn endDragDropTarget() void {
    return c.ImPlot_EndDragDropTarget();
}

// NB: By default, plot and axes drag and drop *sources* require holding the Ctrl modifier to initiate the drag.
// You can change the modifier if desired. If ImGuiKeyModFlags_None is provided, the axes will be locked from panning.

// Turns the current plot's plotting area into a drag and drop source. Don't forget to call EndDragDropSource!
pub const BeginDragDropSourceOption = struct {
    key_mods: imgui.ImGuiKeyModFlags = imgui.ImGuiKeyModFlags_Ctrl,
    flags: imgui.ImGuiDragDropFlags = 0,
};
pub fn beginDragDropSource(option: BeginDragDropSourceOption) bool {
    return c.ImPlot_BeginDragDropSource(option.key_mods, option.flags);
}
// Turns the current plot's X-axis into a drag and drop source. Don't forget to call EndDragDropSource!
pub fn beginDragDropSourceX(option: BeginDragDropSourceOption) bool {
    return c.ImPlot_BeginDragDropSourceX(option.key_mods, option.flags);
}
// Turns the current plot's Y-axis into a drag and drop source. Don't forget to call EndDragDropSource!
pub const BeginDragDropSourceYOption = struct {
    axis: c.ImPlotYAxis = c.ImPlotYAxis_1,
    key_mods: imgui.ImGuiKeyModFlags = imgui.ImGuiKeyModFlags_Ctrl,
    flags: imgui.ImGuiDragDropFlags = 0,
};
pub fn beginDragDropSourceY(option: BeginDragDropSourceYOption) bool {
    return c.ImPlot_BeginDragDropSourceY(option.axis, option.key_mods, option.flags);
}
// Turns an item in the current plot's legend into drag and drop source. Don't forget to call EndDragDropSource!
pub fn beginDragDropSourceItem(label_id: [:0]const u8, flags: ?imgui.ImGuiDragDropFlags) bool {
    return c.ImPlot_BeginDragDropSourceItem(label_id.ptr, flags orelse 0);
}
// Ends a drag and drop source (currently just an alias for ImGui::EndDragDropSource).
pub fn endDragDropSource() void {
    return c.ImPlot_EndDragDropSource();
}

//-----------------------------------------------------------------------------
// Plot and Item Styling
//-----------------------------------------------------------------------------

// Styling colors in ImPlot works similarly to styling colors in ImGui, but
// with one important difference. Like ImGui, all style colors are stored in an
// indexable array in ImPlotStyle. You can permanently modify these values through
// GetStyle().Colors, or temporarily modify them with Push/Pop functions below.
// However, by default all style colors in ImPlot default to a special color
// IMPLOT_AUTO_COL. The behavior of this color depends upon the style color to
// which it as applied:
//
//     1) For style colors associated with plot items (e.g. ImPlotCol_Line),
//        IMPLOT_AUTO_COL tells ImPlot to color the item with the next unused
//        color in the current colormap. Thus, every item will have a different
//        color up to the number of colors in the colormap, at which point the
//        colormap will roll over. For most use cases, you should not need to
//        set these style colors to anything but IMPLOT_COL_AUTO; you are
//        probably better off changing the current colormap. However, if you
//        need to explicitly color a particular item you may either Push/Pop
//        the style color around the item in question, or use the SetNextXXXStyle
//        API below. If you permanently set one of these style colors to a specific
//        color, or forget to call Pop, then all subsequent items will be styled
//        with the color you set.
//
//     2) For style colors associated with plot styling (e.g. ImPlotCol_PlotBg),
//        IMPLOT_AUTO_COL tells ImPlot to set that color from color data in your
//        **ImGuiStyle**. The ImGuiCol_ that these style colors default to are
//        detailed above, and in general have been mapped to produce plots visually
//        consistent with your current ImGui style. Of course, you are free to
//        manually set these colors to whatever you like, and further can Push/Pop
//        them around individual plots for plot-specific styling (e.g. coloring axes).

// Provides access to plot style structure for permanant modifications to colors, sizes, etc.
pub fn getStyle() *c.ImPlotStyle {
    return c.ImPlot_GetStyle();
}

// Style plot colors for current ImGui style (default).
pub fn styleColorsAuto(dst: ?*c.ImPlotStyle) void {
    return c.ImPlot_StyleColorsAuto(dst);
}
// Style plot colors for ImGui "Classic".
pub fn styleColorsClassic(dst: ?*c.ImPlotStyle) void {
    return c.ImPlot_StyleColorsClassic(dst);
}
// Style plot colors for ImGui "Dark".
pub fn styleColorsDark(dst: ?*c.ImPlotStyle) void {
    return c.ImPlot_StyleColorsDark(dst);
}
// Style plot colors for ImGui "Light".
pub fn styleColorsLight(dst: ?*c.ImPlotStyle) void {
    return c.ImPlot_StyleColorsLight(dst);
}

// Use PushStyleX to temporarily modify your ImPlotStyle. The modification
// will last until the matching call to PopStyleX. You MUST call a pop for
// every push, otherwise you will leak memory! This behaves just like ImGui.

// Temporarily modify a style color. Don't forget to call PopStyleColor!
pub fn pushStyleColor_U32(idx: c.ImPlotCol, col: imgui.ImU32) void {
    return c.ImPlot_PushStyleColor_U32(idx, col);
}
pub fn pushStyleColor_Vec4(idx: c.ImPlotCol, col: imgui.ImVec4) void {
    return c.ImPlot_PushStyleColor_Vec4(idx, col);
}
// Undo temporary style color modification(s). Undo multiple pushes at once by increasing count.
pub fn popStyleColor(count: ?c_int) void {
    return c.ImPlot_PopStyleColor(count orelse 1);
}

// Temporarily modify a style variable of float type. Don't forget to call PopStyleVar!
pub fn pushStyleVar_Float(idx: c.ImPlotStyleVar, val: f32) void {
    return c.ImPlot_PushStyleVar_Float(idx, val);
}
// Temporarily modify a style variable of int type. Don't forget to call PopStyleVar!
pub fn pushStyleVar_Int(idx: c.ImPlotStyleVar, val: c_int) void {
    return c.ImPlot_PushStyleVar_Int(idx, val);
}
// Temporarily modify a style variable of ImVec2 type. Don't forget to call PopStyleVar!
pub fn pushStyleVar_Vec2(idx: c.ImPlotStyleVar, val: imgui.ImVec2) void {
    return c.ImPlot_PushStyleVar_Vec2(idx, val);
}
// Undo temporary style variable modification(s). Undo multiple pushes at once by increasing count.
pub fn popStyleVar(count: ?c_int) void {
    return c.ImPlot_PopStyleVar(count orelse 1);
}

// The following can be used to modify the style of the next plot item ONLY. They do
// NOT require calls to PopStyleX. Leave style attributes you don't want modified to
// IMPLOT_AUTO or IMPLOT_AUTO_COL. Automatic styles will be deduced from the current
// values in your ImPlotStyle or from Colormap data.

// Set the line color and weight for the next item only.
pub const SetNextLineStyleOption = struct {
    col: imgui.ImVec4 = IMPLOT_AUTO_COL,
    weight: f32 = IMPLOT_AUTO,
};
pub fn setNextLineStyle(option: SetNextLineStyleOption) void {
    return c.ImPlot_SetNextLineStyle(option.col, option.weight);
}
// Set the fill color for the next item only.
pub const SetNextFillStyleOption = struct {
    col: imgui.ImVec4 = IMPLOT_AUTO_COL,
    alpha_mod: f32 = IMPLOT_AUTO,
};
pub fn setNextFillStyle(option: SetNextFillStyleOption) void {
    return c.ImPlot_SetNextFillStyle(option.col, option.alpha_mod);
}
// Set the marker style for the next item only.
pub const SetNextMarkerStyleOption = struct {
    marker: c.ImPlotMarker = IMPLOT_AUTO,
    size: f32 = IMPLOT_AUTO,
    fill: imgui.ImVec4 = IMPLOT_AUTO_COL,
    weight: f32 = IMPLOT_AUTO,
    outline: imgui.ImVec4 = IMPLOT_AUTO_COL,
};
pub fn setNextMarkerStyle(option: SetNextMarkerStyleOption) void {
    return c.ImPlot_SetNextMarkerStyle(option.marker, option.size, option.fill, option.weight, option.outline);
}
// Set the error bar style for the next item only.
pub const SetNextErrorBarStyle = struct {
    col: imgui.ImVec4 = IMPLOT_AUTO_COL,
    size: f32 = IMPLOT_AUTO,
    weight: f32 = IMPLOT_AUTO,
};
pub fn setNextErrorBarStyle(option: SetNextErrorBarStyle) void {
    return c.ImPlot_SetNextErrorBarStyle(option.col, option.size, option.weight);
}

// Gets the last item primary color (i.e. its legend icon color)
pub fn getLastItemColor(pOut: [*c]imgui.ImVec4) void {
    return c.ImPlot_GetLastItemColor(pOut);
}

// Returns the null terminated string name for an ImPlotCol.
pub fn getStyleColorName(idx: c.ImPlotCol) [*c]const u8 {
    return c.ImPlot_GetStyleColorName(idx);
}
// Returns the null terminated string name for an ImPlotMarker.
pub fn getMarkerName(idx: c.ImPlotMarker) [*c]const u8 {
    return c.ImPlot_GetMarkerName(idx);
}

//-----------------------------------------------------------------------------
// Colormaps
//-----------------------------------------------------------------------------

// Item styling is based on colormaps when the relevant ImPlotCol_XXX is set to
// IMPLOT_AUTO_COL (default). Several built-in colormaps are available. You can
// add and then push/pop your own colormaps as well. To permanently set a colormap,
// modify the Colormap index member of your ImPlotStyle.

// Colormap data will be ignored and a custom color will be used if you have done one of the following:
//     1) Modified an item style color in your ImPlotStyle to anything other than IMPLOT_AUTO_COL.
//     2) Pushed an item style color using PushStyleColor().
//     3) Set the next item style with a SetNextXXXStyle function.

// Add a new colormap. The color data will be copied. The colormap can be used by pushing either the returned index or the
// string name with PushColormap. The colormap name must be unique and the size must be greater than 1. You will receive
// an assert otherwise! By default colormaps are considered to be qualitative (i.e. discrete). If you want to create a
// continuous colormap, set #qual=false. This will treat the colors you provide as keys, and ImPlot will build a linearly
// interpolated lookup table. The memory footprint of this table will be exactly ((size-1)*255+1)*4 bytes.
pub fn addColormap_Vec4Ptr(name: [:0]const u8, cols: [*c]const imgui.ImVec4, size: c_int, qual: ?bool) c.ImPlotColormap {
    return c.ImPlot_AddColormap_Vec4Ptr(name, cols, size, qual orelse true);
}
pub fn addColormap_U32Ptr(name: [:0]const u8, cols: [*c]const imgui.ImU32, size: c_int, qual: ?bool) c.ImPlotColormap {
    return c.ImPlot_AddColormap_U32Ptr(name, cols, size, qual orelse true);
}

// Returns the number of available colormaps (i.e. the built-in + user-added count).
pub fn getColormapCount() c_int {
    return c.ImPlot_GetColormapCount();
}
// Returns a null terminated string name for a colormap given an index. Returns NULL if index is invalid.
pub fn getColormapName(cmap: c.ImPlotColormap) [*c]const u8 {
    return c.ImPlot_GetColormapName(cmap);
}
// Returns an index number for a colormap given a valid string name. Returns -1 if name is invalid.
pub fn getColormapIndex(name: [*c]const u8) c.ImPlotColormap {
    return c.ImPlot_GetColormapIndex(name);
}

// Temporarily switch to one of the built-in (i.e. ImPlotColormap_XXX) or user-added colormaps (i.e. a return value of AddColormap). Don't forget to call PopColormap!
pub fn pushColormap_PlotColormap(cmap: c.ImPlotColormap) void {
    return c.ImPlot_PushColormap_PlotColormap(cmap);
}
// Push a colormap by string name. Use built-in names such as "Default", "Deep", "Jet", etc. or a string you provided to AddColormap. Don't forget to call PopColormap!
pub fn pushColormap_Str(name: [*c]const u8) void {
    return c.ImPlot_PushColormap_Str(name);
}
// Undo temporary colormap modification(s). Undo multiple pushes at once by increasing count.
pub fn popColormap(count: ?c_int) void {
    return c.ImPlot_PopColormap(count orelse 1);
}

// Returns the next color from the current colormap and advances the colormap for the current plot.
// Can also be used with no return value to skip colors if desired. You need to call this between Begin/EndPlot!
pub fn nextColormapColor(pOut: [*c]imgui.ImVec4) void {
    return c.ImPlot_NextColormapColor(pOut);
}

// Colormap utils. If cmap = IMPLOT_AUTO (default), the current colormap is assumed.
// Pass an explicit colormap index (built-in or user-added) to specify otherwise.

// Returns the size of a colormap.
pub fn getColormapSize(cmap: ?c.ImPlotColormap) c_int {
    return c.ImPlot_GetColormapSize(cmap orelse IMPLOT_AUTO);
}
// Returns a color from a colormap given an index >= 0 (modulo will be performed).
pub fn getColormapColor(pOut: [*c]imgui.ImVec4, idx: c_int, cmap: ?c.ImPlotColormap) void {
    return c.ImPlot_GetColormapColor(pOut, idx, cmap orelse IMPLOT_AUTO);
}
// Sample a color from the current colormap given t between 0 and 1.
pub fn sampleColormap(pOut: [*c]imgui.ImVec4, t: f32, cmap: ?c.ImPlotColormap) void {
    return c.ImPlot_SampleColormap(pOut, t, cmap orelse IMPLOT_AUTO);
}

// Shows a vertical color scale with linear spaced ticks using the specified color map. Use double hashes to hide label (e.g. "##NoLabel").
pub const ColormapScaleOption = struct {
    size: imgui.ImVec2 = .{ .x = 0, .y = 0 },
    cmap: c.ImPlotColormap = IMPLOT_AUTO,
    fmt: [:0]const u8 = "%g",
};
pub fn colormapScale(label: [:0]const u8, scale_min: f64, scale_max: f64, option: ColormapScaleOption) void {
    return c.ImPlot_ColormapScale(label, scale_min, scale_max, option.size, option.cmap, option.fmt);
}
// Shows a horizontal slider with a colormap gradient background. Optionally returns the color sampled at t in [0 1].
pub const ColormapSliderOption = struct {
    out: [*c]imgui.ImVec4 = null,
    format: [:0]const u8 = "",
    cmap: c.ImPlotColormap = IMPLOT_AUTO,
};
pub fn colormapSlider(label: [:0]const u8, t: *f32, option: ColormapSliderOption) bool {
    return c.ImPlot_ColormapSlider(label, t, option.out, option.format, option.cmap);
}
// Shows a button with a colormap gradient brackground.
pub const ColormapButtonOption = struct {
    size: imgui.ImVec2 = .{ .x = 0, .y = 0 },
    cmap: c.ImPlotColormap = IMPLOT_AUTO,
};
pub fn colormapButton(label: [:0]const u8, option: ColormapButtonOption) bool {
    return c.ImPlot_ColormapButton(label, option.size, option.cmap);
}

// When items in a plot sample their color from a colormap, the color is cached and does not change
// unless explicitly overriden. Therefore, if you change the colormap after the item has already been plotted,
// item colors will NOT update. If you need item colors to resample the new colormap, then use this
// function to bust the cached colors. If #plot_title_id is NULL, then every item in EVERY existing plot
// will be cache busted. Otherwise only the plot specified by #plot_title_id will be busted. For the
// latter, this function must be called in the same ImGui ID scope that the plot is in. You should rarely if ever
// need this function, but it is available for applications that require runtime colormap swaps (e.g. Heatmaps demo).
pub fn bustColorCache(plot_title_id: ?[:0]const u8) void {
    return c.ImPlot_BustColorCache(plot_title_id);
}

//-----------------------------------------------------------------------------
// Miscellaneous
//-----------------------------------------------------------------------------

// Render icons similar to those that appear in legends (nifty for data lists).
pub fn itemIcon_Vec4(col: imgui.ImVec4) void {
    return c.ImPlot_ItemIcon_Vec4(col);
}
pub fn itemIcon_U32(col: imgui.ImU32) void {
    return c.ImPlot_ItemIcon_U32(col);
}
pub fn colormapIcon(cmap: c.ImPlotColormap) void {
    return c.ImPlot_ColormapIcon(cmap);
}

// Get the plot draw list for custom rendering to the current plot area. Call between Begin/EndPlot.
pub fn getPlotDrawList() [*c]imgui.ImDrawList {
    return c.ImPlot_GetPlotDrawList();
}
// Push clip rect for rendering to current plot area. The rect can be expanded or contracted by #expand pixels. Call between Begin/EndPlot.
pub fn pushPlotClipRect(expand: ?f32) void {
    return c.ImPlot_PushPlotClipRect(expand orelse 0);
}
// Pop plot clip rect. Call between Begin/EndPlot.
pub fn popPlotClipRect() void {
    return c.ImPlot_PopPlotClipRect();
}

// Shows ImPlot style selector dropdown menu.
pub fn showStyleSelector(label: [:0]const u8) bool {
    return c.ImPlot_ShowStyleSelector(label);
}
// Shows ImPlot colormap selector dropdown menu.
pub fn showColormapSelector(label: [:0]const u8) bool {
    return c.ImPlot_ShowColormapSelector(label);
}
// Shows ImPlot style editor block (not a window).
pub fn showStyleEditor(ref: ?*c.ImPlotStyle) void {
    return c.ImPlot_ShowStyleEditor(ref);
}
// Add basic help/info block for end users (not a window).
pub fn showUserGuide() void {
    return c.ImPlot_ShowUserGuide();
}
// Shows ImPlot metrics/debug information window.
pub fn showMetricsWindow(p_popen: ?*bool) void {
    return c.ImPlot_ShowMetricsWindow(p_popen);
}

//-----------------------------------------------------------------------------
// Demo (add implot_demo.cpp to your sources!)
//-----------------------------------------------------------------------------

// Shows the ImPlot demo window.
pub fn showDemoWindow(p_open: [*c]bool) void {
    return c.ImPlot_ShowDemoWindow(p_open);
}

/// ImPlot internal API
pub const internal = struct {
    pub fn log10_Float(x: f32) f32 {
        return c.ImPlot_ImLog10_Float(x);
    }
    pub fn log10_double(x: f64) f64 {
        return c.ImPlot_ImLog10_double(x);
    }
    pub fn remap_Float(x: f32, x0: f32, x1: f32, y0: f32, y1: f32) f32 {
        return c.ImPlot_ImRemap_Float(x, x0, x1, y0, y1);
    }
    pub fn remap_double(x: f64, x0: f64, x1: f64, y0: f64, y1: f64) f64 {
        return c.ImPlot_ImRemap_double(x, x0, x1, y0, y1);
    }
    pub fn remap_S8(x: imgui.ImS8, x0: imgui.ImS8, x1: imgui.ImS8, y0: imgui.ImS8, y1: imgui.ImS8) imgui.ImS8 {
        return c.ImPlot_ImRemap_S8(x, x0, x1, y0, y1);
    }
    pub fn remap_U8(x: imgui.ImU8, x0: imgui.ImU8, x1: imgui.ImU8, y0: imgui.ImU8, y1: imgui.ImU8) imgui.ImU8 {
        return c.ImPlot_ImRemap_U8(x, x0, x1, y0, y1);
    }
    pub fn remap_S16(x: imgui.ImS16, x0: imgui.ImS16, x1: imgui.ImS16, y0: imgui.ImS16, y1: imgui.ImS16) imgui.ImS16 {
        return c.ImPlot_ImRemap_S16(x, x0, x1, y0, y1);
    }
    pub fn remap_U16(x: imgui.ImU16, x0: imgui.ImU16, x1: imgui.ImU16, y0: imgui.ImU16, y1: imgui.ImU16) imgui.ImU16 {
        return c.ImPlot_ImRemap_U16(x, x0, x1, y0, y1);
    }
    pub fn remap_S32(x: imgui.ImS32, x0: imgui.ImS32, x1: imgui.ImS32, y0: imgui.ImS32, y1: imgui.ImS32) imgui.ImS32 {
        return c.ImPlot_ImRemap_S32(x, x0, x1, y0, y1);
    }
    pub fn remap_U32(x: imgui.ImU32, x0: imgui.ImU32, x1: imgui.ImU32, y0: imgui.ImU32, y1: imgui.ImU32) imgui.ImU32 {
        return c.ImPlot_ImRemap_U32(x, x0, x1, y0, y1);
    }
    pub fn remap_S64(x: imgui.ImS64, x0: imgui.ImS64, x1: imgui.ImS64, y0: imgui.ImS64, y1: imgui.ImS64) imgui.ImS64 {
        return c.ImPlot_ImRemap_S64(x, x0, x1, y0, y1);
    }
    pub fn remap_U64(x: imgui.ImU64, x0: imgui.ImU64, x1: imgui.ImU64, y0: imgui.ImU64, y1: imgui.ImU64) imgui.ImU64 {
        return c.ImPlot_ImRemap_U64(x, x0, x1, y0, y1);
    }
    pub fn remap01_Float(x: f32, x0: f32, x1: f32) f32 {
        return c.ImPlot_ImRemap01_Float(x, x0, x1);
    }
    pub fn remap01_double(x: f64, x0: f64, x1: f64) f64 {
        return c.ImPlot_ImRemap01_double(x, x0, x1);
    }
    pub fn remap01_S8(x: imgui.ImS8, x0: imgui.ImS8, x1: imgui.ImS8) imgui.ImS8 {
        return c.ImPlot_ImRemap01_S8(x, x0, x1);
    }
    pub fn remap01_U8(x: imgui.ImU8, x0: imgui.ImU8, x1: imgui.ImU8) imgui.ImU8 {
        return c.ImPlot_ImRemap01_U8(x, x0, x1);
    }
    pub fn remap01_S16(x: imgui.ImS16, x0: imgui.ImS16, x1: imgui.ImS16) imgui.ImS16 {
        return c.ImPlot_ImRemap01_S16(x, x0, x1);
    }
    pub fn remap01_U16(x: imgui.ImU16, x0: imgui.ImU16, x1: imgui.ImU16) imgui.ImU16 {
        return c.ImPlot_ImRemap01_U16(x, x0, x1);
    }
    pub fn remap01_S32(x: imgui.ImS32, x0: imgui.ImS32, x1: imgui.ImS32) imgui.ImS32 {
        return c.ImPlot_ImRemap01_S32(x, x0, x1);
    }
    pub fn remap01_U32(x: imgui.ImU32, x0: imgui.ImU32, x1: imgui.ImU32) imgui.ImU32 {
        return c.ImPlot_ImRemap01_U32(x, x0, x1);
    }
    pub fn remap01_S64(x: imgui.ImS64, x0: imgui.ImS64, x1: imgui.ImS64) imgui.ImS64 {
        return c.ImPlot_ImRemap01_S64(x, x0, x1);
    }
    pub fn remap01_U64(x: imgui.ImU64, x0: imgui.ImU64, x1: imgui.ImU64) imgui.ImU64 {
        return c.ImPlot_ImRemap01_U64(x, x0, x1);
    }
    pub fn posMod(l: c_int, r: c_int) c_int {
        return c.ImPlot_ImPosMod(l, r);
    }
    pub fn nanOrInf(val: f64) bool {
        return c.ImPlot_ImNanOrInf(val);
    }
    pub fn constrainNan(val: f64) f64 {
        return c.ImPlot_ImConstrainNan(val);
    }
    pub fn constrainInf(val: f64) f64 {
        return c.ImPlot_ImConstrainInf(val);
    }
    pub fn constrainLog(val: f64) f64 {
        return c.ImPlot_ImConstrainLog(val);
    }
    pub fn constrainTime(val: f64) f64 {
        return c.ImPlot_ImConstrainTime(val);
    }
    pub fn almostEqual(v1: f64, v2: f64, ulp: c_int) bool {
        return c.ImPlot_ImAlmostEqual(v1, v2, ulp);
    }
    pub fn minArray_FloatPtr(values: [*c]const f32, count: c_int) f32 {
        return c.ImPlot_ImMinArray_FloatPtr(values, count);
    }
    pub fn minArray_doublePtr(values: [*c]const f64, count: c_int) f64 {
        return c.ImPlot_ImMinArray_doublePtr(values, count);
    }
    pub fn minArray_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) imgui.ImS8 {
        return c.ImPlot_ImMinArray_S8Ptr(values, count);
    }
    pub fn minArray_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) imgui.ImU8 {
        return c.ImPlot_ImMinArray_U8Ptr(values, count);
    }
    pub fn minArray_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) imgui.ImS16 {
        return c.ImPlot_ImMinArray_S16Ptr(values, count);
    }
    pub fn minArray_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) imgui.ImU16 {
        return c.ImPlot_ImMinArray_U16Ptr(values, count);
    }
    pub fn minArray_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) imgui.ImS32 {
        return c.ImPlot_ImMinArray_S32Ptr(values, count);
    }
    pub fn minArray_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) imgui.ImU32 {
        return c.ImPlot_ImMinArray_U32Ptr(values, count);
    }
    pub fn minArray_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) imgui.ImS64 {
        return c.ImPlot_ImMinArray_S64Ptr(values, count);
    }
    pub fn minArray_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) imgui.ImU64 {
        return c.ImPlot_ImMinArray_U64Ptr(values, count);
    }
    pub fn maxArray_FloatPtr(values: [*c]const f32, count: c_int) f32 {
        return c.ImPlot_ImMaxArray_FloatPtr(values, count);
    }
    pub fn maxArray_doublePtr(values: [*c]const f64, count: c_int) f64 {
        return c.ImPlot_ImMaxArray_doublePtr(values, count);
    }
    pub fn maxArray_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) imgui.ImS8 {
        return c.ImPlot_ImMaxArray_S8Ptr(values, count);
    }
    pub fn maxArray_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) imgui.ImU8 {
        return c.ImPlot_ImMaxArray_U8Ptr(values, count);
    }
    pub fn maxArray_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) imgui.ImS16 {
        return c.ImPlot_ImMaxArray_S16Ptr(values, count);
    }
    pub fn maxArray_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) imgui.ImU16 {
        return c.ImPlot_ImMaxArray_U16Ptr(values, count);
    }
    pub fn maxArray_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) imgui.ImS32 {
        return c.ImPlot_ImMaxArray_S32Ptr(values, count);
    }
    pub fn maxArray_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) imgui.ImU32 {
        return c.ImPlot_ImMaxArray_U32Ptr(values, count);
    }
    pub fn maxArray_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) imgui.ImS64 {
        return c.ImPlot_ImMaxArray_S64Ptr(values, count);
    }
    pub fn maxArray_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) imgui.ImU64 {
        return c.ImPlot_ImMaxArray_U64Ptr(values, count);
    }
    pub fn minMaxArray_FloatPtr(values: [*c]const f32, count: c_int, min_out: [*c]f32, max_out: [*c]f32) void {
        return c.ImPlot_ImMinMaxArray_FloatPtr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_doublePtr(values: [*c]const f64, count: c_int, min_out: [*c]f64, max_out: [*c]f64) void {
        return c.ImPlot_ImMinMaxArray_doublePtr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_S8Ptr(values: [*c]const imgui.ImS8, count: c_int, min_out: [*c]imgui.ImS8, max_out: [*c]imgui.ImS8) void {
        return c.ImPlot_ImMinMaxArray_S8Ptr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_U8Ptr(values: [*c]const imgui.ImU8, count: c_int, min_out: [*c]imgui.ImU8, max_out: [*c]imgui.ImU8) void {
        return c.ImPlot_ImMinMaxArray_U8Ptr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_S16Ptr(values: [*c]const imgui.ImS16, count: c_int, min_out: [*c]imgui.ImS16, max_out: [*c]imgui.ImS16) void {
        return c.ImPlot_ImMinMaxArray_S16Ptr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_U16Ptr(values: [*c]const imgui.ImU16, count: c_int, min_out: [*c]imgui.ImU16, max_out: [*c]imgui.ImU16) void {
        return c.ImPlot_ImMinMaxArray_U16Ptr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_S32Ptr(values: [*c]const imgui.ImS32, count: c_int, min_out: [*c]imgui.ImS32, max_out: [*c]imgui.ImS32) void {
        return c.ImPlot_ImMinMaxArray_S32Ptr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_U32Ptr(values: [*c]const imgui.ImU32, count: c_int, min_out: [*c]imgui.ImU32, max_out: [*c]imgui.ImU32) void {
        return c.ImPlot_ImMinMaxArray_U32Ptr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_S64Ptr(values: [*c]const imgui.ImS64, count: c_int, min_out: [*c]imgui.ImS64, max_out: [*c]imgui.ImS64) void {
        return c.ImPlot_ImMinMaxArray_S64Ptr(values, count, min_out, max_out);
    }
    pub fn minMaxArray_U64Ptr(values: [*c]const imgui.ImU64, count: c_int, min_out: [*c]imgui.ImU64, max_out: [*c]imgui.ImU64) void {
        return c.ImPlot_ImMinMaxArray_U64Ptr(values, count, min_out, max_out);
    }
    pub fn sum_FloatPtr(values: [*c]const f32, count: c_int) f32 {
        return c.ImPlot_ImSum_FloatPtr(values, count);
    }
    pub fn sum_doublePtr(values: [*c]const f64, count: c_int) f64 {
        return c.ImPlot_ImSum_doublePtr(values, count);
    }
    pub fn sum_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) imgui.ImS8 {
        return c.ImPlot_ImSum_S8Ptr(values, count);
    }
    pub fn sum_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) imgui.ImU8 {
        return c.ImPlot_ImSum_U8Ptr(values, count);
    }
    pub fn sum_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) imgui.ImS16 {
        return c.ImPlot_ImSum_S16Ptr(values, count);
    }
    pub fn sum_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) imgui.ImU16 {
        return c.ImPlot_ImSum_U16Ptr(values, count);
    }
    pub fn sum_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) imgui.ImS32 {
        return c.ImPlot_ImSum_S32Ptr(values, count);
    }
    pub fn sum_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) imgui.ImU32 {
        return c.ImPlot_ImSum_U32Ptr(values, count);
    }
    pub fn sum_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) imgui.ImS64 {
        return c.ImPlot_ImSum_S64Ptr(values, count);
    }
    pub fn sum_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) imgui.ImU64 {
        return c.ImPlot_ImSum_U64Ptr(values, count);
    }
    pub fn mean_FloatPtr(values: [*c]const f32, count: c_int) f64 {
        return c.ImPlot_ImMean_FloatPtr(values, count);
    }
    pub fn mean_doublePtr(values: [*c]const f64, count: c_int) f64 {
        return c.ImPlot_ImMean_doublePtr(values, count);
    }
    pub fn mean_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) f64 {
        return c.ImPlot_ImMean_S8Ptr(values, count);
    }
    pub fn mean_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) f64 {
        return c.ImPlot_ImMean_U8Ptr(values, count);
    }
    pub fn mean_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) f64 {
        return c.ImPlot_ImMean_S16Ptr(values, count);
    }
    pub fn mean_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) f64 {
        return c.ImPlot_ImMean_U16Ptr(values, count);
    }
    pub fn mean_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) f64 {
        return c.ImPlot_ImMean_S32Ptr(values, count);
    }
    pub fn mean_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) f64 {
        return c.ImPlot_ImMean_U32Ptr(values, count);
    }
    pub fn mean_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) f64 {
        return c.ImPlot_ImMean_S64Ptr(values, count);
    }
    pub fn mean_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) f64 {
        return c.ImPlot_ImMean_U64Ptr(values, count);
    }
    pub fn stdDev_FloatPtr(values: [*c]const f32, count: c_int) f64 {
        return c.ImPlot_ImStdDev_FloatPtr(values, count);
    }
    pub fn stdDev_doublePtr(values: [*c]const f64, count: c_int) f64 {
        return c.ImPlot_ImStdDev_doublePtr(values, count);
    }
    pub fn stdDev_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) f64 {
        return c.ImPlot_ImStdDev_S8Ptr(values, count);
    }
    pub fn stdDev_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) f64 {
        return c.ImPlot_ImStdDev_U8Ptr(values, count);
    }
    pub fn stdDev_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) f64 {
        return c.ImPlot_ImStdDev_S16Ptr(values, count);
    }
    pub fn stdDev_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) f64 {
        return c.ImPlot_ImStdDev_U16Ptr(values, count);
    }
    pub fn stdDev_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) f64 {
        return c.ImPlot_ImStdDev_S32Ptr(values, count);
    }
    pub fn stdDev_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) f64 {
        return c.ImPlot_ImStdDev_U32Ptr(values, count);
    }
    pub fn stdDev_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) f64 {
        return c.ImPlot_ImStdDev_S64Ptr(values, count);
    }
    pub fn stdDev_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) f64 {
        return c.ImPlot_ImStdDev_U64Ptr(values, count);
    }
    pub fn mixU32(a: imgui.ImU32, b: imgui.ImU32, s: imgui.ImU32) imgui.ImU32 {
        return c.ImPlot_ImMixU32(a, b, s);
    }
    pub fn lerpU32(colors: [*c]const imgui.ImU32, size: c_int, t: f32) imgui.ImU32 {
        return c.ImPlot_ImLerpU32(colors, size, t);
    }
    pub fn alphaU32(col: imgui.ImU32, alpha: f32) imgui.ImU32 {
        return c.ImPlot_ImAlphaU32(col, alpha);
    }
    pub fn initialize(ctx: *c.ImPlotContext) void {
        return c.ImPlot_Initialize(ctx);
    }
    pub fn resetCtxForNextPlot(ctx: *c.ImPlotContext) void {
        return c.ImPlot_ResetCtxForNextPlot(ctx);
    }
    pub fn resetCtxForNextAlignedPlots(ctx: *c.ImPlotContext) void {
        return c.ImPlot_ResetCtxForNextAlignedPlots(ctx);
    }
    pub fn resetCtxForNextSubplot(ctx: *c.ImPlotContext) void {
        return c.ImPlot_ResetCtxForNextSubplot(ctx);
    }
    pub fn getInputMap() *c.ImPlotInputMap {
        return c.ImPlot_GetInputMap();
    }
    pub fn getPlot(title: [*c]const u8) *c.ImPlotPlot {
        return c.ImPlot_GetPlot(title);
    }
    pub fn getCurrentPlot() *c.ImPlotPlot {
        return c.ImPlot_GetCurrentPlot();
    }
    pub fn bustPlotCache() void {
        return c.ImPlot_BustPlotCache();
    }
    pub fn showPlotContextMenu(plot: *c.ImPlotPlot) void {
        return c.ImPlot_ShowPlotContextMenu(plot);
    }
    pub fn subplotNextCell() void {
        return c.ImPlot_SubplotNextCell();
    }
    pub fn showSubplotsContextMenu(subplot: *c.ImPlotSubplot) void {
        return c.ImPlot_ShowSubplotsContextMenu(subplot);
    }
    pub fn beginItem(label_id: [:0]const u8, recolor_from: c.ImPlotCol) bool {
        return c.ImPlot_BeginItem(label_id.ptr, recolor_from);
    }
    pub fn endItem() void {
        return c.ImPlot_EndItem();
    }
    pub fn registerOrGetItem(label_id: [:0]const u8, just_created: [*c]bool) *c.ImPlotItem {
        return c.ImPlot_RegisterOrGetItem(label_id.ptr, just_created);
    }
    pub fn getItem(label_id: [:0]const u8) *c.ImPlotItem {
        return c.ImPlot_GetItem(label_id.ptr);
    }
    pub fn getCurrentItem() *c.ImPlotItem {
        return c.ImPlot_GetCurrentItem();
    }
    pub fn bustItemCache() void {
        return c.ImPlot_BustItemCache();
    }
    pub fn getCurrentYAxis() c_int {
        return c.ImPlot_GetCurrentYAxis();
    }
    pub fn updateAxisColors(axis_flag: c_int, axis: *c.ImPlotAxis) void {
        return c.ImPlot_UpdateAxisColors(axis_flag, axis);
    }
    pub fn updateTransformCache() void {
        return c.ImPlot_UpdateTransformCache();
    }
    pub fn getCurrentScale() c.ImPlotScale {
        return c.ImPlot_GetCurrentScale();
    }
    pub fn fitThisFrame() bool {
        return c.ImPlot_FitThisFrame();
    }
    pub fn fitPointAxis(axis: *c.ImPlotAxis, ext: *c.ImPlotRange, v: f64) void {
        return c.ImPlot_FitPointAxis(axis, ext, v);
    }
    pub fn fitPointMultiAxis(axis: *c.ImPlotAxis, alt: *c.ImPlotAxis, ext: *c.ImPlotRange, v: f64, v_alt: f64) void {
        return c.ImPlot_FitPointMultiAxis(axis, alt, ext, v, v_alt);
    }
    pub fn fitPointX(x: f64) void {
        return c.ImPlot_FitPointX(x);
    }
    pub fn fitPointY(y: f64) void {
        return c.ImPlot_FitPointY(y);
    }
    pub fn fitPoint(p: c.ImPlotPoint) void {
        return c.ImPlot_FitPoint(p);
    }
    pub fn rangesOverlap(r1: c.ImPlotRange, r2: c.ImPlotRange) bool {
        return c.ImPlot_RangesOverlap(r1, r2);
    }
    pub fn pushLinkedAxis(axis: *c.ImPlotAxis) void {
        return c.ImPlot_PushLinkedAxis(axis);
    }
    pub fn pullLinkedAxis(axis: *c.ImPlotAxis) void {
        return c.ImPlot_PullLinkedAxis(axis);
    }
    pub fn showAxisContextMenu(axis: *c.ImPlotAxis, equal_axis: *c.ImPlotAxis, time_allowed: bool) void {
        return c.ImPlot_ShowAxisContextMenu(axis, equal_axis, time_allowed);
    }
    pub fn getFormatX() [*c]const u8 {
        return c.ImPlot_GetFormatX();
    }
    pub fn getFormatY(y: c.ImPlotYAxis) [*c]const u8 {
        return c.ImPlot_GetFormatY(y);
    }
    pub fn getLocationPos(pOut: [*c]imgui.ImVec2, outer_rect: imgui.ImRect, inner_size: imgui.ImVec2, location: c.ImPlotLocation, pad: imgui.ImVec2) void {
        return c.ImPlot_GetLocationPos(pOut, outer_rect, inner_size, location, pad);
    }
    pub fn calcLegendSize(pOut: [*c]imgui.ImVec2, items: *c.ImPlotItemGroup, pad: imgui.ImVec2, spacing: imgui.ImVec2, orientation: c.ImPlotOrientation) void {
        return c.ImPlot_CalcLegendSize(pOut, items, pad, spacing, orientation);
    }
    pub fn showLegendEntries(items: *c.ImPlotItemGroup, legend_bb: imgui.ImRect, interactable: bool, pad: imgui.ImVec2, spacing: imgui.ImVec2, orientation: c.ImPlotOrientation, DrawList: [*c]imgui.ImDrawList) bool {
        return c.ImPlot_ShowLegendEntries(items, legend_bb, interactable, pad, spacing, orientation, DrawList);
    }
    pub fn showAltLegend(title_id: [*c]const u8, orientation: c.ImPlotOrientation, size: imgui.ImVec2, interactable: bool) void {
        return c.ImPlot_ShowAltLegend(title_id, orientation, size, interactable);
    }
    pub fn showLegendContextMenu(legend: *c.ImPlotLegendData, visible: bool) bool {
        return c.ImPlot_ShowLegendContextMenu(legend, visible);
    }
    pub fn labelTickTime(tick: *c.ImPlotTick, buffer: [*c]imgui.ImGuiTextBuffer, t: c.ImPlotTime, fmt: c.ImPlotDateTimeFmt) void {
        return c.ImPlot_LabelTickTime(tick, buffer, t, fmt);
    }
    pub fn addTicksDefault(range: c.ImPlotRange, pix: f32, orn: c.ImPlotOrientation, ticks: *c.ImPlotTickCollection, fmt: [*c]const u8) void {
        return c.ImPlot_AddTicksDefault(range, pix, orn, ticks, fmt);
    }
    pub fn addTicksLogarithmic(range: c.ImPlotRange, pix: f32, orn: c.ImPlotOrientation, ticks: *c.ImPlotTickCollection, fmt: [*c]const u8) void {
        return c.ImPlot_AddTicksLogarithmic(range, pix, orn, ticks, fmt);
    }
    pub fn addTicksTime(range: c.ImPlotRange, plot_width: f32, ticks: *c.ImPlotTickCollection) void {
        return c.ImPlot_AddTicksTime(range, plot_width, ticks);
    }
    pub fn addTicksCustom(values: [*c]const f64, labels: [*c]const [*c]const u8, n: c_int, ticks: *c.ImPlotTickCollection, fmt: [*c]const u8) void {
        return c.ImPlot_AddTicksCustom(values, labels, n, ticks, fmt);
    }
    pub fn labelAxisValue(axis: c.ImPlotAxis, ticks: c.ImPlotTickCollection, value: f64, buff: [*c]u8, size: c_int) c_int {
        return c.ImPlot_LabelAxisValue(axis, ticks, value, buff, size);
    }
    pub fn getItemData() [*c]const c.ImPlotNextItemData {
        return c.ImPlot_GetItemData();
    }
    pub fn isColorAuto_Vec4(col: imgui.ImVec4) bool {
        return c.ImPlot_IsColorAuto_Vec4(col);
    }
    pub fn isColorAuto_PlotCol(idx: c.ImPlotCol) bool {
        return c.ImPlot_IsColorAuto_PlotCol(idx);
    }
    pub fn getAutoColor(pOut: [*c]imgui.ImVec4, idx: c.ImPlotCol) void {
        return c.ImPlot_GetAutoColor(pOut, idx);
    }
    pub fn getStyleColorVec4(pOut: [*c]imgui.ImVec4, idx: c.ImPlotCol) void {
        return c.ImPlot_GetStyleColorVec4(pOut, idx);
    }
    pub fn getStyleColorU32(idx: c.ImPlotCol) imgui.ImU32 {
        return c.ImPlot_GetStyleColorU32(idx);
    }
    pub fn addTextVertical(DrawList: [*c]imgui.ImDrawList, pos: imgui.ImVec2, col: imgui.ImU32, text_begin: [*c]const u8, text_end: [*c]const u8) void {
        return c.ImPlot_AddTextVertical(DrawList, pos, col, text_begin, text_end);
    }
    pub fn addTextCentered(DrawList: [*c]imgui.ImDrawList, top_center: imgui.ImVec2, col: imgui.ImU32, text_begin: [*c]const u8, text_end: [*c]const u8) void {
        return c.ImPlot_AddTextCentered(DrawList, top_center, col, text_begin, text_end);
    }
    pub fn calcTextSizeVertical(pOut: [*c]imgui.ImVec2, text: [*c]const u8) void {
        return c.ImPlot_CalcTextSizeVertical(pOut, text);
    }
    pub fn calcTextColor_Vec4(bg: imgui.ImVec4) imgui.ImU32 {
        return c.ImPlot_CalcTextColor_Vec4(bg);
    }
    pub fn calcTextColor_U32(bg: imgui.ImU32) imgui.ImU32 {
        return c.ImPlot_CalcTextColor_U32(bg);
    }
    pub fn calcHoverColor(col: imgui.ImU32) imgui.ImU32 {
        return c.ImPlot_CalcHoverColor(col);
    }
    pub fn clampLabelPos(pOut: [*c]imgui.ImVec2, pos: imgui.ImVec2, size: imgui.ImVec2, Min: imgui.ImVec2, Max: imgui.ImVec2) void {
        return c.ImPlot_ClampLabelPos(pOut, pos, size, Min, Max);
    }
    pub fn getColormapColorU32(idx: c_int, cmap: c.ImPlotColormap) imgui.ImU32 {
        return c.ImPlot_GetColormapColorU32(idx, cmap);
    }
    pub fn nextColormapColorU32() imgui.ImU32 {
        return c.ImPlot_NextColormapColorU32();
    }
    pub fn sampleColormapU32(t: f32, cmap: c.ImPlotColormap) imgui.ImU32 {
        return c.ImPlot_SampleColormapU32(t, cmap);
    }
    pub fn renderColorBar(colors: [*c]const imgui.ImU32, size: c_int, DrawList: [*c]imgui.ImDrawList, bounds: imgui.ImRect, vert: bool, reversed: bool, continuous: bool) void {
        return c.ImPlot_RenderColorBar(colors, size, DrawList, bounds, vert, reversed, continuous);
    }
    pub fn niceNum(x: f64, round: bool) f64 {
        return c.ImPlot_NiceNum(x, round);
    }
    pub fn orderOfMagnitude(val: f64) c_int {
        return c.ImPlot_OrderOfMagnitude(val);
    }
    pub fn orderToPrecision(order: c_int) c_int {
        return c.ImPlot_OrderToPrecision(order);
    }
    pub fn precision(val: f64) c_int {
        return c.ImPlot_Precision(val);
    }
    pub fn roundTo(val: f64, prec: c_int) f64 {
        return c.ImPlot_RoundTo(val, prec);
    }
    pub fn intersection(pOut: [*c]imgui.ImVec2, a1: imgui.ImVec2, a2: imgui.ImVec2, b1: imgui.ImVec2, b2: imgui.ImVec2) void {
        return c.ImPlot_Intersection(pOut, a1, a2, b1, b2);
    }
    pub fn fillRange_Vector_FloatPtr(buffer: [*c]imgui.ImVector_float, n: c_int, vmin: f32, vmax: f32) void {
        return c.ImPlot_FillRange_Vector_FloatPtr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_doublePtr(buffer: [*c]c.ImVector_double, n: c_int, vmin: f64, vmax: f64) void {
        return c.ImPlot_FillRange_Vector_doublePtr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_S8Ptr(buffer: [*c]c.ImVector_ImS8, n: c_int, vmin: imgui.ImS8, vmax: imgui.ImS8) void {
        return c.ImPlot_FillRange_Vector_S8Ptr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_U8Ptr(buffer: [*c]c.ImVector_ImU8, n: c_int, vmin: imgui.ImU8, vmax: imgui.ImU8) void {
        return c.ImPlot_FillRange_Vector_U8Ptr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_S16Ptr(buffer: [*c]c.ImVector_ImS16, n: c_int, vmin: imgui.ImS16, vmax: imgui.ImS16) void {
        return c.ImPlot_FillRange_Vector_S16Ptr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_U16Ptr(buffer: [*c]c.ImVector_ImU16, n: c_int, vmin: imgui.ImU16, vmax: imgui.ImU16) void {
        return c.ImPlot_FillRange_Vector_U16Ptr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_S32Ptr(buffer: [*c]c.ImVector_ImS32, n: c_int, vmin: imgui.ImS32, vmax: imgui.ImS32) void {
        return c.ImPlot_FillRange_Vector_S32Ptr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_U32Ptr(buffer: [*c]imgui.ImVector_ImU32, n: c_int, vmin: imgui.ImU32, vmax: imgui.ImU32) void {
        return c.ImPlot_FillRange_Vector_U32Ptr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_S64Ptr(buffer: [*c]c.ImVector_ImS64, n: c_int, vmin: imgui.ImS64, vmax: imgui.ImS64) void {
        return c.ImPlot_FillRange_Vector_S64Ptr(buffer, n, vmin, vmax);
    }
    pub fn fillRange_Vector_U64Ptr(buffer: [*c]c.ImVector_ImU64, n: c_int, vmin: imgui.ImU64, vmax: imgui.ImU64) void {
        return c.ImPlot_FillRange_Vector_U64Ptr(buffer, n, vmin, vmax);
    }
    pub fn calculateBins_FloatPtr(values: [*c]const f32, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_FloatPtr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_doublePtr(values: [*c]const f64, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_doublePtr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_S8Ptr(values: [*c]const imgui.ImS8, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_S8Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_U8Ptr(values: [*c]const imgui.ImU8, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_U8Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_S16Ptr(values: [*c]const imgui.ImS16, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_S16Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_U16Ptr(values: [*c]const imgui.ImU16, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_U16Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_S32Ptr(values: [*c]const imgui.ImS32, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_S32Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_U32Ptr(values: [*c]const imgui.ImU32, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_U32Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_S64Ptr(values: [*c]const imgui.ImS64, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_S64Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn calculateBins_U64Ptr(values: [*c]const imgui.ImU64, count: c_int, meth: c.ImPlotBin, range: c.ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void {
        return c.ImPlot_CalculateBins_U64Ptr(values, count, meth, range, bins_out, width_out);
    }
    pub fn isLeapYear(year: c_int) bool {
        return c.ImPlot_IsLeapYear(year);
    }
    pub fn getDaysInMonth(year: c_int, month: c_int) c_int {
        return c.ImPlot_GetDaysInMonth(year, month);
    }
    pub fn mkGmtTime(pOut: *c.ImPlotTime, ptm: [*c]c.struct_tm) void {
        return c.ImPlot_MkGmtTime(pOut, ptm);
    }
    pub fn getGmtTime(t: c.ImPlotTime, ptm: [*c]c.tm) [*c]c.tm {
        return c.ImPlot_GetGmtTime(t, ptm);
    }
    pub fn mkLocTime(pOut: *c.ImPlotTime, ptm: [*c]c.struct_tm) void {
        return c.ImPlot_MkLocTime(pOut, ptm);
    }
    pub fn getLocTime(t: c.ImPlotTime, ptm: [*c]c.tm) [*c]c.tm {
        return c.ImPlot_GetLocTime(t, ptm);
    }
    pub fn makeTime(pOut: *c.ImPlotTime, year: c_int, month: c_int, day: c_int, hour: c_int, min: c_int, sec: c_int, us: c_int) void {
        return c.ImPlot_MakeTime(pOut, year, month, day, hour, min, sec, us);
    }
    pub fn getYear(t: c.ImPlotTime) c_int {
        return c.ImPlot_GetYear(t);
    }
    pub fn addTime(pOut: *c.ImPlotTime, t: c.ImPlotTime, unit: c.ImPlotTimeUnit, count: c_int) void {
        return c.ImPlot_AddTime(pOut, t, unit, count);
    }
    pub fn floorTime(pOut: *c.ImPlotTime, t: c.ImPlotTime, unit: c.ImPlotTimeUnit) void {
        return c.ImPlot_FloorTime(pOut, t, unit);
    }
    pub fn ceilTime(pOut: *c.ImPlotTime, t: c.ImPlotTime, unit: c.ImPlotTimeUnit) void {
        return c.ImPlot_CeilTime(pOut, t, unit);
    }
    pub fn roundTime(pOut: *c.ImPlotTime, t: c.ImPlotTime, unit: c.ImPlotTimeUnit) void {
        return c.ImPlot_RoundTime(pOut, t, unit);
    }
    pub fn combineDateTime(pOut: *c.ImPlotTime, date_part: c.ImPlotTime, time_part: c.ImPlotTime) void {
        return c.ImPlot_CombineDateTime(pOut, date_part, time_part);
    }
    pub fn formatTime(t: c.ImPlotTime, buffer: [*c]u8, size: c_int, fmt: c.ImPlotTimeFmt, use_24_hr_clk: bool) c_int {
        return c.ImPlot_FormatTime(t, buffer, size, fmt, use_24_hr_clk);
    }
    pub fn formatDate(t: c.ImPlotTime, buffer: [*c]u8, size: c_int, fmt: c.ImPlotDateFmt, use_iso_8601: bool) c_int {
        return c.ImPlot_FormatDate(t, buffer, size, fmt, use_iso_8601);
    }
    pub fn formatDateTime(t: c.ImPlotTime, buffer: [*c]u8, size: c_int, fmt: c.ImPlotDateTimeFmt) c_int {
        return c.ImPlot_FormatDateTime(t, buffer, size, fmt);
    }
    pub fn showDatePicker(id: [*c]const u8, level: [*c]c_int, t: *c.ImPlotTime, t1: [*c]const c.ImPlotTime, t2: [*c]const c.ImPlotTime) bool {
        return c.ImPlot_ShowDatePicker(id, level, t, t1, t2);
    }
    pub fn showTimePicker(id: [*c]const u8, t: *c.ImPlotTime) bool {
        return c.ImPlot_ShowTimePicker(id, t);
    }
};
