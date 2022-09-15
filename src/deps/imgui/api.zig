/// help wrappers of raw imgui api
const std = @import("std");
const math = std.math;
const c = @import("c.zig");
const vec2_zero = c.ImVec2{ .x = 0, .y = 0 };
const vec2_one = c.ImVec2{ .x = 1, .y = 1 };
const vec4_zero = c.ImVec4{ .x = 0, .y = 0, .z = 0, .w = 0 };
const vec4_one = c.ImVec4{ .x = 1, .y = 1, .z = 1, .w = 1 };
pub const Font = c.ImFont;
pub const getIO = c.igGetIO;
pub const getStyle = c.igGetStyle;
pub const getDrawData = c.igGetDrawData;
pub const showDemoWindow = c.igShowDemoWindow;
pub const showMetricsWindow = c.igShowMetricsWindow;
pub const showStackToolWindow = c.igShowStackToolWindow;
pub const showAboutWindow = c.igShowAboutWindow;
pub const showStyleEditor = c.igShowStyleEditor;
pub fn showStyleSelector(label: [:0]const u8) bool {
    return c.igShowStyleSelector(label.ptr);
}
pub fn showFontSelector(label: [:0]const u8) void {
    return c.igShowFontSelector(label.ptr);
}
pub const showUserGuide = c.igShowUserGuide;
pub const getVersion = c.igGetVersion;
pub const styleColorsDark = c.igStyleColorsDark;
pub const styleColorsLight = c.igStyleColorsLight;
pub const styleColorsClassic = c.igStyleColorsClassic;

// Windows
// - Begin() = push window to the stack and start appending to it. End() = pop window from the stack.
// - Passing 'bool* p_open != NULL' shows a window-closing widget in the upper-right corner of the window,
//   which clicking will set the boolean to false when clicked.
// - You may append multiple times to the same window during the same frame by calling Begin()/End() pairs multiple times.
//   Some information such as 'flags' or 'p_open' will only be considered by the first call to Begin().
// - Begin() return false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
//   anything to the window. Always call a matching End() for each Begin() call, regardless of its return value!
//   [Important: due to legacy reason, this is inconsistent with most other functions such as BeginMenu/EndMenu,
//    BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding BeginXXX function
//    returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
// - Note that the bottom of window stack always contains a window called "Debug".
pub fn begin(name: [:0]const u8, p_open: ?*bool, flags: ?c.ImGuiWindowFlags) bool {
    return c.igBegin(name.ptr, p_open, flags orelse 0);
}
pub const end = c.igEnd;

// Child Windows
// - Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window. Child windows can embed their own child.
// - For each independent axis of 'size': ==0.0f: use remaining host window size / >0.0f: fixed size / <0.0f: use remaining window size minus abs(size) / Each axis can use a different mode, e.g. ImVec2(0,400).
// - BeginChild() returns false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting anything to the window.
//   Always call a matching EndChild() for each BeginChild() call, regardless of its return value.
//   [Important: due to legacy reason, this is inconsistent with most other functions such as BeginMenu/EndMenu,
//    BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding BeginXXX function
//    returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
pub const BeginChildOption = struct {
    size: c.ImVec2 = vec2_zero,
    border: bool = false,
    flags: c.ImGuiWindowFlags = 0,
};
pub fn beginChild_Str(str_id: [:0]const u8, option: BeginChildOption) bool {
    return c.igBeginChild_Str(str_id.ptr, option.size, option.border, option.flags);
}
pub fn beginChild_ID(id: c.ImGuiID, option: BeginChildOption) bool {
    return c.igBeginChild_ID(id, option.size, option.border, option.flags);
}
pub const endChild = c.igEndChild;

// Windows Utilities
// - 'current window' = the window we are appending into while inside a Begin()/End() block. 'next window' = next window we will Begin() into.
pub const isWindowAppearing = c.igIsWindowAppearing;
pub const isWindowCollapsed = c.igIsWindowCollapsed;
pub fn isWindowFocused(flags: ?c.ImGuiFocusedFlags) bool {
    return c.igIsWindowFocused(flags orelse 0);
}
pub fn isWindowHovered(flags: ?c.ImGuiHoveredFlags) bool {
    return c.igIsWindowHovered(flags orelse 0);
}
pub fn getWindowDrawList() DrawList {
    return .{ ._dl = c.igGetWindowDrawList() };
}
pub fn getWindowPos(pOut: *c.ImVec2) void {
    return c.igGetWindowPos(pOut);
}
pub fn getWindowSize(pOut: *c.ImVec2) void {
    return c.igGetWindowSize(pOut);
}
pub const getWindowWidth = c.igGetWindowWidth;
pub const getWindowHeight = c.igGetWindowHeight;

// Window manipulation
// - Prefer using SetNextXXX functions (before Begin) rather that SetXXX functions (after Begin).
pub const SetNextWindowPosOption = struct {
    cond: c.ImGuiCond = 0,
    pivot: c.ImVec2 = vec2_zero,
};
pub fn setNextWindowPos(pos: c.ImVec2, option: SetNextWindowPosOption) void {
    return c.igSetNextWindowPos(pos, option.cond, option.pivot);
}
pub fn setNextWindowSize(size: c.ImVec2, cond: c.ImGuiCond) void {
    return c.igSetNextWindowSize(size, cond);
}
pub const SetNextWindowSizeConstraintsOption = struct {
    custom_callback: c.ImGuiSizeCallback = null,
    custom_callback_data: ?*anyopaque = null,
};
pub fn setNextWindowSizeConstraints(size_min: c.ImVec2, size_max: c.ImVec2, option: SetNextWindowSizeConstraintsOption) void {
    return c.igSetNextWindowSizeConstraints(size_min, size_max, option.custom_callback, option.custom_callback_data);
}
pub fn setNextWindowContentSize(size: c.ImVec2) void {
    return c.igSetNextWindowContentSize(size);
}
pub fn setNextWindowCollapsed(collapsed: bool, cond: c.ImGuiCond) void {
    return c.igSetNextWindowCollapsed(collapsed, cond);
}
pub const setNextWindowFocus = c.igSetNextWindowFocus;
pub fn setNextWindowBgAlpha(alpha: f32) void {
    return c.igSetNextWindowBgAlpha(alpha);
}
pub fn setWindowPos_Vec2(pos: c.ImVec2, cond: c.ImGuiCond) void {
    return c.igSetWindowPos_Vec2(pos, cond);
}
pub fn setWindowSize_Vec2(size: c.ImVec2, cond: c.ImGuiCond) void {
    return c.igSetWindowSize_Vec2(size, cond);
}
pub fn setWindowCollapsed_Bool(collapsed: bool, cond: c.ImGuiCond) void {
    return c.igSetWindowCollapsed_Bool(collapsed, cond);
}
pub const setWindowFocus = c.igSetWindowFocus_Nil;
pub fn setWindowFontScale(scale: f32) void {
    return c.igSetWindowFontScale(scale);
}
pub fn setWindowPos_Str(name: [:0]const u8, pos: c.ImVec2, cond: c.ImGuiCond) void {
    return c.igSetWindowPos_Str(name.ptr, pos, cond);
}
pub fn setWindowSize_Str(name: [:0]const u8, size: c.ImVec2, cond: c.ImGuiCond) void {
    return c.igSetWindowSize_Str(name.ptr, size, cond);
}
pub fn setWindowCollapsed_Str(name: [:0]const u8, collapsed: bool, cond: c.ImGuiCond) void {
    return c.igSetWindowCollapsed_Str(name.ptr, collapsed, cond);
}
pub fn setWindowFocus_Str(name: [:0]const u8) void {
    return c.igSetWindowFocus_Str(name.ptr);
}

// Content region
// - Retrieve available space from a given point. GetContentRegionAvail() is frequently useful.
// - Those functions are bound to be redesigned (they are confusing, incomplete and the Min/Max return values are in local window coordinates which increases confusion)
pub fn getContentRegionAvail(pOut: *c.ImVec2) void {
    return c.igGetContentRegionAvail(pOut);
}
pub fn getContentRegionMax(pOut: *c.ImVec2) void {
    return c.igGetContentRegionMax(pOut);
}
pub fn getWindowContentRegionMin(pOut: *c.ImVec2) void {
    return c.igGetWindowContentRegionMin(pOut);
}
pub fn getWindowContentRegionMax(pOut: *c.ImVec2) void {
    return c.igGetWindowContentRegionMax(pOut);
}

// Windows Scrolling
pub const getScrollX = c.igGetScrollX;
pub const getScrollY = c.igGetScrollY;
pub fn setScrollX_Float(scroll_x: f32) void {
    return c.igSetScrollX_Float(scroll_x);
}
pub fn setScrollY_Float(scroll_y: f32) void {
    return c.igSetScrollY_Float(scroll_y);
}
pub const getScrollMaxX = c.igGetScrollMaxX;
pub const getScrollMaxY = c.igGetScrollMaxY;
pub fn setScrollHereX(center_x_ratio: ?f32) void {
    return c.igSetScrollHereX(center_x_ratio orelse 0.5);
}
pub fn setScrollHereY(center_y_ratio: ?f32) void {
    return c.igSetScrollHereY(center_y_ratio orelse 0.5);
}
pub fn setScrollFromPosX_Float(local_x: f32, center_x_ratio: ?f32) void {
    return c.igSetScrollFromPosX_Float(local_x, center_x_ratio orelse 0.5);
}
pub fn setScrollFromPosY_Float(local_y: f32, center_y_ratio: ?f32) void {
    return c.igSetScrollFromPosY_Float(local_y, center_y_ratio orelse 0.5);
}

// Parameters stacks (shared)
pub fn pushFont(font: *c.ImFont) void {
    return c.igPushFont(font);
}
pub const popFont = c.igPopFont;
pub fn pushStyleColor_U32(idx: c.ImGuiCol, col: c.ImU32) void {
    return c.igPushStyleColor_U32(idx, col);
}
pub fn pushStyleColor_Vec4(idx: c.ImGuiCol, col: c.ImVec4) void {
    return c.igPushStyleColor_Vec4(idx, col);
}
pub fn popStyleColor(count: c_int) void {
    return c.igPopStyleColor(count);
}
pub fn pushStyleVar_Float(idx: c.ImGuiStyleVar, val: f32) void {
    return c.igPushStyleVar_Float(idx, val);
}
pub fn pushStyleVar_Vec2(idx: c.ImGuiStyleVar, val: c.ImVec2) void {
    return c.igPushStyleVar_Vec2(idx, val);
}
pub fn popStyleVar(count: c_int) void {
    return c.igPopStyleVar(count);
}
pub fn pushAllowKeyboardFocus(allow_keyboard_focus: bool) void {
    return c.igPushAllowKeyboardFocus(allow_keyboard_focus);
}
pub const popAllowKeyboardFocus = c.igPopAllowKeyboardFocus;
pub fn pushButtonRepeat(repeat: bool) void {
    return c.igPushButtonRepeat(repeat);
}
pub const popButtonRepeat = c.igPopButtonRepeat;

// Parameters stacks (current window)
pub fn pushItemWidth(item_width: f32) void {
    return c.igPushItemWidth(item_width);
}
pub const popItemWidth = c.igPopItemWidth;
pub fn setNextItemWidth(item_width: f32) void {
    return c.igSetNextItemWidth(item_width);
}
pub const calcItemWidth = c.igCalcItemWidth;
pub fn pushTextWrapPos(wrap_local_pos_x: f32) void {
    return c.igPushTextWrapPos(wrap_local_pos_x);
}
pub const popTextWrapPos = c.igPopTextWrapPos;

// Style read access
// - Use the style editor (ShowStyleEditor() function) to interactively see what the colors are)
pub const getFont = c.igGetFont;
pub const getFontSize = c.igGetFontSize;
pub fn getFontTexUvWhitePixel(pOut: *c.ImVec2) void {
    return c.igGetFontTexUvWhitePixel(pOut);
}
pub fn getColorU32_Col(idx: c.ImGuiCol, alpha_mul: ?f32) c.ImU32 {
    return c.igGetColorU32_Col(idx, alpha_mul orelse 1.0);
}
pub fn getColorU32_Vec4(col: c.ImVec4) c.ImU32 {
    return c.igGetColorU32_Vec4(col);
}
pub fn getColorU32_U32(col: c.ImU32) c.ImU32 {
    return c.igGetColorU32_U32(col);
}
pub fn getStyleColorVec4(idx: c.ImGuiCol) [*c]const c.ImVec4 {
    return c.igGetStyleColorVec4(idx);
}

// Cursor / Layout
// - By "cursor" we mean the current output position.
// - The typical widget behavior is to output themselves at the current cursor position, then move the cursor one line down.
// - You can call SameLine() between widgets to undo the last carriage return and output at the right of the preceding widget.
// - Attention! We currently have inconsistencies between window-local and absolute positions we will aim to fix with future API:
//    Window-local coordinates:   SameLine(), GetCursorPos(), SetCursorPos(), GetCursorStartPos(), GetContentRegionMax(), GetWindowContentRegion*(), PushTextWrapPos()
//    Absolute coordinate:        GetCursorScreenPos(), SetCursorScreenPos(), all ImDrawList:: functions.
pub const separator = c.igSeparator;
pub const SameLineOption = struct {
    offset_from_start_x: f32 = 0,
    spacing: f32 = -1,
};
pub fn sameLine(option: SameLineOption) void {
    return c.igSameLine(option.offset_from_start_x, option.spacing);
}
pub const newLine = c.igNewLine;
pub const spacing = c.igSpacing;
pub fn dummy(size: c.ImVec2) void {
    return c.igDummy(size);
}
pub fn indent(indent_w: f32) void {
    return c.igIndent(indent_w);
}
pub fn unindent(indent_w: f32) void {
    return c.igUnindent(indent_w);
}
pub const beginGroup = c.igBeginGroup;
pub const endGroup = c.igEndGroup;
pub fn getCursorPos(pOut: *c.ImVec2) void {
    return c.igGetCursorPos(pOut);
}
pub const getCursorPosX = c.igGetCursorPosX;
pub const getCursorPosY = c.igGetCursorPosY;
pub fn setCursorPos(local_pos: c.ImVec2) void {
    return c.igSetCursorPos(local_pos);
}
pub fn setCursorPosX(local_x: f32) void {
    return c.igSetCursorPosX(local_x);
}
pub fn setCursorPosY(local_y: f32) void {
    return c.igSetCursorPosY(local_y);
}
pub fn getCursorStartPos(pOut: *c.ImVec2) void {
    return c.igGetCursorStartPos(pOut);
}
pub fn getCursorScreenPos(pOut: *c.ImVec2) void {
    return c.igGetCursorScreenPos(pOut);
}
pub fn setCursorScreenPos(pos: c.ImVec2) void {
    return c.igSetCursorScreenPos(pos);
}
pub const alignTextToFramePadding = c.igAlignTextToFramePadding;
pub const getTextLineHeight = c.igGetTextLineHeight;
pub const getTextLineHeightWithSpacing = c.igGetTextLineHeightWithSpacing;
pub const getFrameHeight = c.igGetFrameHeight;
pub const getFrameHeightWithSpacing = c.igGetFrameHeightWithSpacing;

// ID stack/scopes
// Read the FAQ (docs/FAQ.md or http://dearimgui.org/faq) for more details about how ID are handled in dear imgui.
// - Those questions are answered and impacted by understanding of the ID stack system:
//   - "Q: Why is my widget not reacting when I click on it?"
//   - "Q: How can I have widgets with an empty label?"
//   - "Q: How can I have multiple widgets with the same label?"
// - Short version: ID are hashes of the entire ID stack. If you are creating widgets in a loop you most likely
//   want to push a unique identifier (e.g. object pointer, loop index) to uniquely differentiate them.
// - You can also use the "Label##foobar" syntax within widget label to distinguish them from each others.
// - In this header file we use the "label"/"name" terminology to denote a string that will be displayed + used as an ID,
//   whereas "str_id" denote a string that is only used as an ID and not normally displayed.
pub fn pushID_Str(str_id: [:0]const u8) void {
    return c.igPushID_Str(str_id.ptr);
}
pub fn pushID_Ptr(ptr_id: *const anyopaque) void {
    return c.igPushID_Ptr(ptr_id);
}
pub fn pushID_Int(int_id: c_int) void {
    return c.igPushID_Int(int_id);
}
pub const popID = c.igPopID;
pub fn getID_Str(str_id: [:0]const u8) c.ImGuiID {
    return c.igGetID_Str(str_id.ptr);
}
pub fn getID_Ptr(ptr_id: *const anyopaque) c.ImGuiID {
    return c.igGetID_Ptr(ptr_id);
}

// Widgets: Text
pub fn textUnformatted(_text: []const u8) void {
    return c.igTextUnformatted(_text.ptr, _text.ptr + _text.len);
}
pub const text = c.igText;
pub fn ztext(comptime fmt: []const u8, args: anytype) void {
    var buf = [_]u8{0} ** 128;
    var info = std.fmt.bufPrintZ(&buf, fmt, args) catch unreachable;
    text(info.ptr);
}
pub const textColored = c.igTextColored;
pub fn ztextColored(col: c.ImVec4, comptime fmt: []const u8, args: anytype) void {
    var buf = [_]u8{0} ** 128;
    var info = std.fmt.bufPrintZ(&buf, fmt, args) catch unreachable;
    textColored(col, info.ptr);
}
pub const textDisabled = c.igTextDisabled;
pub const textWrapped = c.igTextWrapped;
pub const labelText = c.igLabelText;
pub const bulletText = c.igBulletText;

// Widgets: Main
// - Most widgets return true when the value has been changed or when pressed/selected
// - You may also use one of the many IsItemXXX functions (e.g. IsItemActive, IsItemHovered, etc.) to query widget state.
pub fn button(label: [:0]const u8, size: ?c.ImVec2) bool {
    return c.igButton(label.ptr, size orelse vec2_zero);
}
pub fn smallButton(label: [:0]const u8) bool {
    return c.igSmallButton(label.ptr);
}
pub fn invisibleButton(str_id: [:0]const u8, size: c.ImVec2, flags: ?c.ImGuiButtonFlags) bool {
    return c.igInvisibleButton(str_id.ptr, size, flags orelse 0);
}
pub fn arrowButton(str_id: [:0]const u8, dir: c.ImGuiDir) bool {
    return c.igArrowButton(str_id.ptr, dir);
}
pub const ImageOption = struct {
    uv0: c.ImVec2 = vec2_zero,
    uv1: c.ImVec2 = vec2_one,
    tint_col: c.ImVec4 = vec4_one,
    border_col: c.ImVec4 = vec4_zero,
};
pub fn image(user_texture_id: c.ImTextureID, size: c.ImVec2, option: ImageOption) void {
    return c.igImage(user_texture_id, size, option.uv0, option.uv1, option.tint_col, option.border_col);
}
pub const ImageButtonOption = struct {
    uv0: c.ImVec2 = vec2_zero,
    uv1: c.ImVec2 = vec2_one,
    frame_padding: c_int = -1,
    bg_col: c.ImVec4 = vec4_zero,
    tint_col: c.ImVec4 = vec4_one,
};
pub fn imageButton(user_texture_id: c.ImTextureID, size: c.ImVec2, option: ImageButtonOption) bool {
    return c.igImageButton(user_texture_id, size, option.uv0, option.uv1, option.frame_padding, option.bg_col, option.tint_col);
}
pub fn checkbox(label: [:0]const u8, v: *bool) bool {
    return c.igCheckbox(label.ptr, v);
}
pub fn checkboxFlags_IntPtr(label: [:0]const u8, flags: *c_int, flags_value: c_int) bool {
    return c.igCheckboxFlags_IntPtr(label.ptr, flags, flags_value);
}
pub fn checkboxFlags_UintPtr(label: [:0]const u8, flags: [*c]c_uint, flags_value: c_uint) bool {
    return c.igCheckboxFlags_UintPtr(label.ptr, flags, flags_value);
}
pub fn radioButton_Bool(label: [:0]const u8, active: bool) bool {
    return c.igRadioButton_Bool(label.ptr, active);
}
pub fn radioButton_IntPtr(label: [:0]const u8, v: *c_int, v_button: c_int) bool {
    return c.igRadioButton_IntPtr(label.ptr, v, v_button);
}
pub const ProgressBarOption = struct {
    size_arg: c.ImVec2 = .{ .x = math.f32_min, .y = 0 },
    overlay: [*c]const u8 = null,
};
pub fn progressBar(fraction: f32, option: ProgressBarOption) void {
    return c.igProgressBar(fraction, option.size_arg, option.overlay);
}
pub const bullet = c.igBullet;

// Widgets: Combo Box
// - The BeginCombo()/EndCombo() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() items.
// - The old Combo() api are helpers over BeginCombo()/EndCombo() which are kept available for convenience purpose. This is analogous to how ListBox are created.
pub fn beginCombo(label: [:0]const u8, preview_value: [:0]const u8, flags: ?c.ImGuiComboFlags) bool {
    return c.igBeginCombo(label.ptr, preview_value.ptr, flags orelse 0);
}
pub const endCombo = c.igEndCombo;
pub fn combo_Str_arr(label: [:0]const u8, current_item: *c_int, items: []const [*c]const u8, popup_max_height_in_items: ?c_int) bool {
    return c.igCombo_Str_arr(label.ptr, current_item, items.ptr, items.len, popup_max_height_in_items orelse -1);
}
pub fn combo_Str(label: [:0]const u8, current_item: *c_int, items_separated_by_zeros: [:0]const u8, popup_max_height_in_items: ?c_int) bool {
    return c.igCombo_Str(label.ptr, current_item, items_separated_by_zeros.ptr, popup_max_height_in_items orelse -1);
}
pub fn combo_FnBoolPtr(label: [:0]const u8, current_item: *c_int, items_getter: fn (?*anyopaque, c_int, [*c][*c]const u8) callconv(.C) bool, data: ?*anyopaque, items_count: c_int, popup_max_height_in_items: ?c_int) bool {
    return c.igCombo_FnBoolPtr(label.ptr, current_item, items_getter, data, items_count, popup_max_height_in_items orelse -1);
}

// Widgets: Drag Sliders
// - CTRL+Click on any drag box to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
// - For all the Float2/Float3/Float4/Int2/Int3/Int4 versions of every functions, note that a 'float v[X]' function argument is the same as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible. You can pass address of your first element out of a contiguous set, e.g. &myvector.x
// - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
// - Format string may also be set to NULL or use the default format ("%f" or "%d").
// - Speed are per-pixel of mouse movement (v_speed=0.2f: mouse needs to move by 5 pixels to increase value by 1). For gamepad/keyboard navigation, minimum speed is Max(v_speed, minimum_step_at_given_precision).
// - Use v_min < v_max to clamp edits to given limits. Note that CTRL+Click manual input can override those limits if ImGuiSliderFlags_AlwaysClamp is not used.
// - Use v_max = FLT_MAX / INT_MAX etc to avoid clamping to a maximum, same with v_min = -FLT_MAX / INT_MIN to avoid clamping to a minimum.
// - We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
// - Legacy: Pre-1.78 there are DragXXX() function signatures that takes a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
//   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
pub const DragFloatOption = struct {
    v_speed: f32 = 1,
    v_min: f32 = 0,
    v_max: f32 = 0,
    format: [:0]const u8 = "%.3f",
    flags: c.ImGuiSliderFlags = 0,
};
pub fn dragFloat(label: [:0]const u8, v: *f32, option: DragFloatOption) bool {
    return c.igDragFloat(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub fn dragFloat2(label: [:0]const u8, v: *[2]f32, option: DragFloatOption) bool {
    return c.igDragFloat2(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub fn dragFloat3(label: [:0]const u8, v: *[3]f32, option: DragFloatOption) bool {
    return c.igDragFloat3(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub fn dragFloat4(label: [:0]const u8, v: *[4]f32, option: DragFloatOption) bool {
    return c.igDragFloat4(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub const DragFloatRangeOption = struct {
    v_speed: f32 = 1,
    v_min: f32 = 0,
    v_max: f32 = 0,
    format: [:0]const u8 = "%.3f",
    format_max: [*c]const u8 = null,
    flags: c.ImGuiSliderFlags = 0,
};
pub fn dragFloatRange2(label: [:0]const u8, v_current_min: *f32, v_current_max: *f32, option: DragFloatRangeOption) bool {
    return c.igDragFloatRange2(label.ptr, v_current_min, v_current_max, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.format_max, option.flags);
}
pub const DragIntOption = struct {
    v_speed: f32 = 1,
    v_min: c_int = 0,
    v_max: c_int = 0,
    format: [:0]const u8 = "%d",
    flags: c.ImGuiSliderFlags = 0,
};
pub fn dragInt(label: [:0]const u8, v: *c_int, option: DragIntOption) bool {
    return c.igDragInt(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub fn dragInt2(label: [:0]const u8, v: *c_int, option: DragIntOption) bool {
    return c.igDragInt2(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub fn dragInt3(label: [:0]const u8, v: *c_int, option: DragIntOption) bool {
    return c.igDragInt3(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub fn dragInt4(label: [:0]const u8, v: *c_int, option: DragIntOption) bool {
    return c.igDragInt4(label.ptr, v, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.flags);
}
pub const DragIntRangeOption = struct {
    v_speed: f32 = 1,
    v_min: c_int = 0,
    v_max: c_int = 0,
    format: [:0]const u8 = "%d",
    format_max: [*c]const u8 = null,
    flags: c.ImGuiSliderFlags = 0,
};
pub fn dragIntRange2(label: [:0]const u8, v_current_min: *c_int, v_current_max: *c_int, option: DragIntRangeOption) bool {
    return c.igDragIntRange2(label.ptr, v_current_min, v_current_max, option.v_speed, option.v_min, option.v_max, option.format.ptr, option.format_max, option.flags);
}
pub const DragScalarOption = struct {
    v_speed: f32 = 1,
    p_min: ?*const anyopaque = null,
    p_max: ?*const anyopaque = null,
    format: ?[:0]const u8 = null,
    flags: c.ImGuiSliderFlags = 0,
};
pub fn dragScalar(label: [:0]const u8, data_type: c.ImGuiDataType, p_data: *anyopaque, option: DragScalarOption) bool {
    return c.igDragScalar(label.ptr, data_type, p_data, option.v_speed, option.p_min, option.p_max, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub fn dragScalarN(label: [:0]const u8, data_type: c.ImGuiDataType, p_data: *anyopaque, components: c_int, option: DragScalarOption) bool {
    return c.igDragScalarN(label.ptr, data_type, p_data, components, option.v_speed, option.p_min, option.p_max, if (option.format) |fmt| fmt.ptr else null, option.flags);
}

// Widgets: Regular Sliders
// - CTRL+Click on any slider to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
// - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
// - Format string may also be set to NULL or use the default format ("%f" or "%d").
// - Legacy: Pre-1.78 there are SliderXXX() function signatures that takes a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
//   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
pub const SliderFloatOption = struct {
    format: [:0]const u8 = "%.3f",
    flags: c.ImGuiSliderFlags = 0,
};
pub fn sliderFloat(label: [:0]const u8, v: *f32, v_min: f32, v_max: f32, option: SliderFloatOption) bool {
    return c.igSliderFloat(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub fn sliderFloat2(label: [:0]const u8, v: *[2]f32, v_min: f32, v_max: f32, option: SliderFloatOption) bool {
    return c.igSliderFloat2(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub fn sliderFloat3(label: [:0]const u8, v: *[2]f32, v_min: f32, v_max: f32, option: SliderFloatOption) bool {
    return c.igSliderFloat3(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub fn sliderFloat4(label: [:0]const u8, v: *[3]f32, v_min: f32, v_max: f32, option: SliderFloatOption) bool {
    return c.igSliderFloat4(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub const SliderAngleOption = struct {
    v_degrees_min: f32 = -360.0,
    v_degrees_max: f32 = 360.0,
    format: [:0]const u8 = "%.0 deg",
    flags: c.ImGuiSliderFlags = 0,
};
pub fn sliderAngle(label: [:0]const u8, v_rad: *f32, option: SliderAngleOption) bool {
    return c.igSliderAngle(label.ptr, v_rad, option.v_degrees_min, option.v_degrees_max, option.format.ptr, option.flags);
}
pub const SliderIntOption = struct {
    format: [:0]const u8 = "%d",
    flags: c.ImGuiSliderFlags = 0,
};
pub fn sliderInt(label: [:0]const u8, v: *c_int, v_min: c_int, v_max: c_int, option: SliderIntOption) bool {
    return c.igSliderInt(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub fn sliderInt2(label: [:0]const u8, v: *c_int, v_min: c_int, v_max: c_int, option: SliderIntOption) bool {
    return c.igSliderInt2(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub fn sliderInt3(label: [:0]const u8, v: *c_int, v_min: c_int, v_max: c_int, option: SliderIntOption) bool {
    return c.igSliderInt3(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub fn sliderInt4(label: [:0]const u8, v: *c_int, v_min: c_int, v_max: c_int, option: SliderIntOption) bool {
    return c.igSliderInt4(label.ptr, v, v_min, v_max, option.format.ptr, option.flags);
}
pub const SliderScalarOption = struct {
    format: ?[:0]const u8 = null,
    flags: c.ImGuiSliderFlags = 0,
};
pub fn sliderScalar(label: [:0]const u8, data_type: c.ImGuiDataType, p_data: *anyopaque, p_min: *const anyopaque, p_max: *const anyopaque, option: SliderScalarOption) bool {
    return c.igSliderScalar(label.ptr, data_type, p_data, p_min, p_max, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub fn sliderScalarN(label: [:0]const u8, data_type: c.ImGuiDataType, p_data: *anyopaque, components: c_int, p_min: *const anyopaque, p_max: *const anyopaque, option: SliderScalarOption) bool {
    return c.igSliderScalarN(label.ptr, data_type, p_data, components, p_min, p_max, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub const VSliderFloatOption = struct {
    format: [:0]const u8 = "%.3f",
    flags: c.ImGuiSliderFlags = 0,
};
pub fn vSliderFloat(label: [:0]const u8, size: c.ImVec2, v: *f32, v_min: f32, v_max: f32, option: VSliderFloatOption) bool {
    return c.igVSliderFloat(label.ptr, size, v, v_min, v_max, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub const VSliderIntOption = struct {
    format: [:0]const u8 = "%d",
    flags: c.ImGuiSliderFlags = 0,
};
pub fn vSliderInt(label: [:0]const u8, size: c.ImVec2, v: *c_int, v_min: c_int, v_max: c_int, option: VSliderIntOption) bool {
    return c.igVSliderInt(label.ptr, size, v, v_min, v_max, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub const VSliderScalarOption = struct {
    format: ?[:0]const u8 = null,
    flags: c.ImGuiSliderFlags = 0,
};
pub fn vSliderScalar(label: [:0]const u8, size: c.ImVec2, data_type: c.ImGuiDataType, p_data: *anyopaque, p_min: *const anyopaque, p_max: *const anyopaque, option: VSliderScalarOption) bool {
    return c.igVSliderScalar(label.ptr, size, data_type, p_data, p_min, p_max, if (option.format) |fmt| fmt.ptr else null, option.flags);
}

// Widgets: Input with Keyboard
// - If you want to use InputText() with std::string or any custom dynamic string type, see misc/cpp/imgui_stdlib.h and comments in imgui_demo.cpp.
// - Most of the ImGuiInputTextFlags flags are only useful for InputText() and not for InputFloatX, InputIntX, InputDouble etc.
pub const InputTextOption = struct {
    flags: c.ImGuiInputTextFlags = 0,
    callback: c.ImGuiInputTextCallback = null,
    user_data: ?*anyopaque = null,
};
pub fn inputText(label: [:0]const u8, buf: []u8, option: InputTextOption) bool {
    return c.igInputText(label.ptr, buf.ptr, buf.len, option.flags, option.callback, option.user_data);
}
pub const InputTextMultilineOption = struct {
    size: c.ImVec2 = vec2_zero,
    flags: c.ImGuiInputTextFlags = 0,
    callback: c.ImGuiInputTextCallback = null,
    user_data: ?*anyopaque = null,
};
pub fn inputTextMultiline(label: [:0]const u8, buf: []u8, option: InputTextMultilineOption) bool {
    return c.igInputTextMultiline(label.ptr, buf.ptr, buf.len, option.size, option.flags, option.callback, option.user_data);
}
pub fn inputTextWithHint(label: [:0]const u8, hint: [:0]const u8, buf: []u8, option: InputTextOption) bool {
    return c.igInputTextWithHint(label.ptr, hint.ptr, buf.ptr, buf.len, option.flags, option.callback, option.user_data);
}
pub const InputFloatOption = struct {
    step: f32 = 0,
    step_fast: f32 = 0,
    format: [:0]const u8 = "%.3f",
    flags: c.ImGuiInputTextFlags = 0,
};
pub fn inputFloat(label: [:0]const u8, v: *f32, option: InputFloatOption) bool {
    return c.igInputFloat(label.ptr, v, option.step, option.step_fast, option.format.ptr, option.flags);
}
pub const InputFloatsOption = struct {
    format: [:0]const u8 = "%.3f",
    flags: c.ImGuiInputTextFlags = 0,
};
pub fn inputFloat2(label: [:0]const u8, v: *[2]f32, option: InputFloatsOption) bool {
    return c.igInputFloat2(label.ptr, v, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub fn inputFloat3(label: [:0]const u8, v: *[3]f32, option: InputFloatsOption) bool {
    return c.igInputFloat3(label.ptr, v, option.format.ptr, option.flags);
}
pub fn inputFloat4(label: [:0]const u8, v: *[4]f32, option: InputFloatsOption) bool {
    return c.igInputFloat4(label.ptr, v, option.format.ptr, option.flags);
}
pub const InputIntOption = struct {
    step: c_int = 1,
    step_fast: c_int = 100,
    flags: c.ImGuiInputTextFlags = 0,
};
pub fn inputInt(label: [:0]const u8, v: *c_int, option: InputIntOption) bool {
    return c.igInputInt(label.ptr, v, option.step, option.step_fast, option.flags);
}
pub fn inputInt2(label: [:0]const u8, v: *[2]c_int, flags: ?c.ImGuiInputTextFlags) bool {
    return c.igInputInt2(label.ptr, v, flags orelse 0);
}
pub fn inputInt3(label: [:0]const u8, v: *[3]c_int, flags: ?c.ImGuiInputTextFlags) bool {
    return c.igInputInt3(label.ptr, v, flags orelse 0);
}
pub fn inputInt4(label: [:0]const u8, v: *[4]c_int, flags: ?c.ImGuiInputTextFlags) bool {
    return c.igInputInt4(label.ptr, v, flags orelse 0);
}
pub const InputDoubleOption = struct {
    step: f64 = 0,
    step_fast: f64 = 0,
    format: [:0]const u8 = "%.6f",
    flags: c.ImGuiInputTextFlags = 0,
};
pub fn inputDouble(label: [:0]const u8, v: *f64, option: InputDoubleOption) bool {
    return c.igInputDouble(label.ptr, v, option.step, option.step_fast, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub const InputScalarOption = struct {
    p_step: ?*const anyopaque = null,
    p_step_fast: ?*const anyopaque = null,
    format: ?[:0]const u8 = null,
    flags: c.ImGuiInputTextFlags = 0,
};
pub fn inputScalar(label: [:0]const u8, data_type: c.ImGuiDataType, p_data: *anyopaque, option: InputScalarOption) bool {
    return c.igInputScalar(label.ptr, data_type, p_data, option.p_step, option.p_step_fast, if (option.format) |fmt| fmt.ptr else null, option.flags);
}
pub fn inputScalarN(label: [:0]const u8, data_type: c.ImGuiDataType, p_data: *anyopaque, components: c_int, option: InputScalarOption) bool {
    return c.igInputScalarN(label.ptr, data_type, p_data, components, option.p_step, option.p_step_fast, if (option.format) |fmt| fmt.ptr else null, option.flags);
}

// Widgets: Color Editor/Picker (tip: the ColorEdit* functions have a little color square that can be left-clicked to open a picker, and right-clicked to open an option menu.)
// - Note that in C++ a 'float v[X]' function argument is the _same_ as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible.
// - You can pass the address of a first float element out of a contiguous structure, e.g. &myvector.x
pub fn colorEdit3(label: [:0]const u8, col: *[3]f32, flags: ?c.ImGuiColorEditFlags) bool {
    return c.igColorEdit3(label.ptr, col, flags orelse 0);
}
pub fn colorEdit4(label: [:0]const u8, col: *[4]f32, flags: ?c.ImGuiColorEditFlags) bool {
    return c.igColorEdit4(label.ptr, col, flags orelse 0);
}
pub fn colorPicker3(label: [:0]const u8, col: *[3]f32, flags: ?c.ImGuiColorEditFlags) bool {
    return c.igColorPicker3(label.ptr, col, flags orelse 0);
}
pub fn colorPicker4(label: [:0]const u8, col: *[4]f32, flags: ?c.ImGuiColorEditFlags, ref_col: ?*[4]f32) bool {
    return c.igColorPicker4(label.ptr, col, flags orelse 0, ref_col);
}
pub const ColorButtonOption = struct {
    flags: c.ImGuiColorEditFlags = 0,
    size: c.ImVec2 = vec2_zero,
};
pub fn colorButton(desc_id: [:0]const u8, col: c.ImVec4, option: ColorButtonOption) bool {
    return c.igColorButton(desc_id.ptr, col, option.flags, option.size);
}
pub fn setColorEditOptions(flags: c.ImGuiColorEditFlags) void {
    return c.igSetColorEditOptions(flags);
}

// Widgets: Trees
// - TreeNode functions return true when the node is open, in which case you need to also call TreePop() when you are finished displaying the tree node contents.
pub fn treeNode_Str(label: [:0]const u8) bool {
    return c.igTreeNode_Str(label.ptr);
}
pub const treeNode_StrStr = c.igTreeNode_StrStr;
pub const treeNode_Ptr = c.igTreeNode_Ptr;
pub const treeNodeEx_Str = c.igTreeNodeEx_Str;
pub const treeNodeEx_StrStr = c.igTreeNodeEx_StrStr;
pub const treeNodeEx_Ptr = c.igTreeNodeEx_Ptr;
pub fn treePush_Str(str_id: [:0]const u8) void {
    return c.igTreePush_Str(str_id.ptr);
}
pub fn treePush_Ptr(ptr_id: *const anyopaque) void {
    return c.igTreePush_Ptr(ptr_id);
}
pub const treePop = c.igTreePop;
pub const getTreeNodeToLabelSpacing = c.igGetTreeNodeToLabelSpacing;
pub fn collapsingHeader_TreeNodeFlags(label: [:0]const u8, flags: ?c.ImGuiTreeNodeFlags) bool {
    return c.igCollapsingHeader_TreeNodeFlags(label.ptr, flags orelse 0);
}
pub fn collapsingHeader_BoolPtr(label: [:0]const u8, p_visible: *bool, flags: ?c.ImGuiTreeNodeFlags) bool {
    return c.igCollapsingHeader_BoolPtr(label.ptr, p_visible, flags orelse 0);
}
pub fn setNextItemOpen(is_open: bool, cond: ?c.ImGuiCond) void {
    return c.igSetNextItemOpen(is_open, cond orelse 0);
}

// Widgets: Selectables
// - A selectable highlights when hovered, and can display another color when selected.
// - Neighbors selectable extend their highlight bounds in order to leave no gap between them. This is so a series of selected Selectable appear contiguous.
pub const SelectableOption = struct {
    selected: bool = false,
    flags: c.ImGuiSelectableFlags = 0,
    size: c.ImVec2 = vec2_zero,
};
pub fn selectable_Bool(label: [:0]const u8, option: SelectableOption) bool {
    return c.igSelectable_Bool(label.ptr, option.selected, option.flags, option.size);
}
pub const SelectablePtrOption = struct {
    flags: c.ImGuiSelectableFlags,
    size: c.ImVec2,
};
pub fn selectable_BoolPtr(label: [:0]const u8, p_selected: *bool, option: SelectablePtrOption) bool {
    return c.igSelectable_BoolPtr(label.ptr, p_selected, option.flags, option.size);
}

// Widgets: List Boxes
// - This is essentially a thin wrapper to using BeginChild/EndChild with some stylistic changes.
// - The BeginListBox()/EndListBox() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() or any items.
// - The simplified/old ListBox() api are helpers over BeginListBox()/EndListBox() which are kept available for convenience purpose. This is analoguous to how Combos are created.
// - Choose frame width:   size.x > 0.0f: custom  /  size.x < 0.0f or -FLT_MIN: right-align   /  size.x = 0.0f (default): use current ItemWidth
// - Choose frame height:  size.y > 0.0f: custom  /  size.y < 0.0f or -FLT_MIN: bottom-align  /  size.y = 0.0f (default): arbitrary default height which can fit ~7 items
pub fn beginListBox(label: [:0]const u8, size: ?c.ImVec2) bool {
    return c.igBeginListBox(label.ptr, size orelse vec2_zero);
}
pub const endListBox = c.igEndListBox;
pub fn listBox_Str_arr(label: [:0]const u8, current_item: *c_int, items: []const [*c]const u8, height_in_items: ?c_int) bool {
    return c.igListBox_Str_arr(label.ptr, current_item, items.ptr, @intCast(c_int, items.len), height_in_items orelse -1);
}
pub fn listBox_FnBoolPtr(label: [:0]const u8, current_item: *c_int, items_getter: fn (?*anyopaque, c_int, [*c][*c]const u8) callconv(.C) bool, data: ?*anyopaque, items_count: c_int, height_in_items: ?c_int) bool {
    return c.igListBox_FnBoolPtr(label.ptr, current_item, items_getter, data, items_count, height_in_items orelse -1);
}

// Widgets: Data Plotting
// - Consider using ImPlot (https://github.com/epezent/implot) which is much better!
var PlotOption = struct {
    values_offset: c_int = 0,
    overlay_text: ?[:0]const u8 = null,
    scale_min: f32 = math.f32_min,
    scale_max: f32 = math.f32_max,
    graph_size: c.ImVec2 = vec2_zero,
    stride: c_int = @sizeOf(f32),
};
pub fn plotLines_FloatPtr(label: [:0]const u8, values: []const f32, option: PlotOption) void {
    return c.igPlotLines_FloatPtr(label.ptr, values.ptr, @intCast(c_int, values.len), option.values_offset, if (option.overlay_text) |txt| txt.ptr else null, option.scale_min, option.scale_max, option.graph_size, option.stride);
}
pub fn plotLines_FnFloatPtr(label: [:0]const u8, values_getter: fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, option: PlotOption) void {
    return c.igPlotLines_FnFloatPtr(label.ptr, values_getter, data, values_count, option.values_offset, option.overlay_text, option.scale_min, option.scale_max, option.graph_size);
}
pub fn plotHistogram_FloatPtr(label: [:0]const u8, values: []const f32, option: PlotOption) void {
    return c.igPlotHistogram_FloatPtr(label.ptr, values.ptr, @intCast(c_int, values.len), option.values_offset, option.overlay_text, option.scale_min, option.scale_max, option.graph_size, option.stride);
}
pub fn plotHistogram_FnFloatPtr(label: [:0]const u8, values_getter: fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, option: PlotOption) void {
    return c.igPlotHistogram_FnFloatPtr(label.ptr, values_getter, data, values_count, option.values_offset, option.overlay_text, option.scale_min, option.scale_max, option.graph_size);
}

// Widgets: Value() Helpers.
// - Those are merely shortcut to calling Text() with a format string. Output single value in "name: value" format (tip: freely declare more in your code to handle your types. you can add functions to the ImGui namespace)
pub fn value_Bool(prefix: [*c]const u8, b: bool) void {
    return c.igValue_Bool(prefix, b);
}
pub fn value_Int(prefix: [*c]const u8, v: c_int) void {
    return c.igValue_Int(prefix, v);
}
pub fn value_Uint(prefix: [*c]const u8, v: c_uint) void {
    return c.igValue_Uint(prefix, v);
}
pub fn value_Float(prefix: [*c]const u8, v: f32, float_format: ?[:0]const u8) void {
    return c.igValue_Float(prefix, v, if (float_format) |fmt| fmt.ptr else null);
}

// Widgets: Menus
// - Use BeginMenuBar() on a window ImGuiWindowFlags_MenuBar to append to its menu bar.
// - Use BeginMainMenuBar() to create a menu bar at the top of the screen and append to it.
// - Use BeginMenu() to create a menu. You can call BeginMenu() multiple time with the same identifier to append more items to it.
// - Not that MenuItem() keyboardshortcuts are displayed as a convenience but _not processed_ by Dear ImGui at the moment.
pub const beginMenuBar = c.igBeginMenuBar;
pub const endMenuBar = c.igEndMenuBar;
pub const beginMainMenuBar = c.igBeginMainMenuBar;
pub const endMainMenuBar = c.igEndMainMenuBar;
pub fn beginMenu(label: [:0]const u8, enabled: ?bool) bool {
    return c.igBeginMenu(label.ptr, enabled orelse true);
}
pub const endMenu = c.igEndMenu;
pub const MenuItemOption = struct {
    shortcut: ?[:0]const u8 = null,
    selected: bool = false,
    enabled: bool = true,
};
pub fn menuItem_Bool(label: [:0]const u8, option: MenuItemOption) bool {
    return c.igMenuItem_Bool(label.ptr, option.shortcut, option.selected, option.enabled);
}
pub fn menuItem_BoolPtr(label: [:0]const u8, shortcut: [*c]const u8, p_selected: *bool, enabled: ?bool) bool {
    return c.igMenuItem_BoolPtr(label.ptr, shortcut, p_selected, enabled orelse true);
}

// Tooltips
// - Tooltip are windows following the mouse. They do not take focus away.
pub const beginTooltip = c.igBeginTooltip;
pub const endTooltip = c.igEndTooltip;
pub const setTooltip = c.igSetTooltip;

// Popups, Modals
//  - They block normal mouse hovering detection (and therefore most mouse interactions) behind them.
//  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
//  - Their visibility state (~bool) is held internally instead of being held by the programmer as we are used to with regular Begin*() calls.
//  - The 3 properties above are related: we need to retain popup visibility state in the library because popups may be closed as any time.
//  - You can bypass the hovering restriction by using ImGuiHoveredFlags_AllowWhenBlockedByPopup when calling IsItemHovered() or IsWindowHovered().
//  - IMPORTANT: Popup identifiers are relative to the current ID stack, so OpenPopup and BeginPopup generally needs to be at the same level of the stack.
//    This is sometimes leading to confusing mistakes. May rework this in the future.

// Popups: begin/end functions
//  - BeginPopup(): query popup state, if open start appending into the window. Call EndPopup() afterwards. ImGuiWindowFlags are forwarded to the window.
//  - BeginPopupModal(): block every interactions behind the window, cannot be closed by user, add a dimming background, has a title bar.
pub fn beginPopup(str_id: [:0]const u8, flags: ?c.ImGuiWindowFlags) bool {
    return c.igBeginPopup(str_id.ptr, flags orelse 0);
}
pub fn beginPopupModal(name: [:0]const u8, p_open: ?*bool, flags: ?c.ImGuiWindowFlags) bool {
    return c.igBeginPopupModal(name.ptr, p_open, flags orelse 0);
}
pub const endPopup = c.igEndPopup;

// Popups: open/close functions
//  - OpenPopup(): set popup state to open. ImGuiPopupFlags are available for opening options.
//  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
//  - CloseCurrentPopup(): use inside the BeginPopup()/EndPopup() scope to close manually.
//  - CloseCurrentPopup() is called by default by Selectable()/MenuItem() when activated (FIXME: need some options).
//  - Use ImGuiPopupFlags_NoOpenOverExistingPopup to avoid opening a popup if there's already one at the same level. This is equivalent to e.g. testing for !IsAnyPopupOpen() prior to OpenPopup().
//  - Use IsWindowAppearing() after BeginPopup() to tell if a window just opened.
pub fn openPopup_Str(str_id: [:0]const u8, popup_flags: ?c.ImGuiPopupFlags) void {
    return c.igOpenPopup_Str(str_id.ptr, popup_flags orelse 0);
}
pub fn openPopup_ID(id: c.ImGuiID, popup_flags: ?c.ImGuiPopupFlags) void {
    return c.igOpenPopup_ID(id, popup_flags orelse 0);
}
pub fn openPopupOnItemClick(str_id: ?[:0]const u8, popup_flags: ?c.ImGuiPopupFlags) void {
    return c.igOpenPopupOnItemClick(if (str_id) |id| id.ptr else null, popup_flags orelse 1);
}
pub const closeCurrentPopup = c.igCloseCurrentPopup;

// Popups: open+begin combined functions helpers
//  - Helpers to do OpenPopup+BeginPopup where the Open action is triggered by e.g. hovering an item and right-clicking.
//  - They are convenient to easily create context menus, hence the name.
//  - IMPORTANT: Notice that BeginPopupContextXXX takes ImGuiPopupFlags just like OpenPopup() and unlike BeginPopup(). For full consistency, we may add ImGuiWindowFlags to the BeginPopupContextXXX functions in the future.
//  - IMPORTANT: we exceptionally default their flags to 1 (== ImGuiPopupFlags_MouseButtonRight) for backward compatibility with older API taking 'int mouse_button = 1' parameter, so if you add other flags remember to re-add the ImGuiPopupFlags_MouseButtonRight.
pub fn beginPopupContextItem(str_id: ?[:0]const u8, popup_flags: ?c.ImGuiPopupFlags) bool {
    return c.igBeginPopupContextItem(if (str_id) |id| id.ptr else null, popup_flags orelse 0);
}
pub fn beginPopupContextWindow(str_id: ?[:0]const u8, popup_flags: ?c.ImGuiPopupFlags) bool {
    return c.igBeginPopupContextWindow(if (str_id) |id| id.ptr else null, popup_flags orelse 0);
}
pub fn beginPopupContextVoid(str_id: ?[:0]const u8, popup_flags: ?c.ImGuiPopupFlags) bool {
    return c.igBeginPopupContextVoid(if (str_id) |id| id.ptr else null, popup_flags orelse 0);
}

// Popups: query functions
//  - IsPopupOpen(): return true if the popup is open at the current BeginPopup() level of the popup stack.
//  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId: return true if any popup is open at the current BeginPopup() level of the popup stack.
//  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId + ImGuiPopupFlags_AnyPopupLevel: return true if any popup is open.
pub fn isPopupOpen_Str(str_id: [:0]const u8, flags: ?c.ImGuiPopupFlags) bool {
    return c.igIsPopupOpen_Str(str_id.ptr, flags orelse 0);
}

// Tables
// [BETA API] API may evolve slightly! If you use this, please update to the next version when it comes out!
// - Full-featured replacement for old Columns API.
// - See Demo->Tables for demo code.
// - See top of imgui_tables.cpp for general commentary.
// - See ImGuiTableFlags_ and ImGuiTableColumnFlags_ enums for a description of available flags.
// The typical call flow is:
// - 1. Call BeginTable().
// - 2. Optionally call TableSetupColumn() to submit column name/flags/defaults.
// - 3. Optionally call TableSetupScrollFreeze() to request scroll freezing of columns/rows.
// - 4. Optionally call TableHeadersRow() to submit a header row. Names are pulled from TableSetupColumn() data.
// - 5. Populate contents:
//    - In most situations you can use TableNextRow() + TableSetColumnIndex(N) to start appending into a column.
//    - If you are using tables as a sort of grid, where every columns is holding the same type of contents,
//      you may prefer using TableNextColumn() instead of TableNextRow() + TableSetColumnIndex().
//      TableNextColumn() will automatically wrap-around into the next row if needed.
//    - IMPORTANT: Comparatively to the old Columns() API, we need to call TableNextColumn() for the first column!
//    - Summary of possible call flow:
//        --------------------------------------------------------------------------------------------------------
//        TableNextRow() -> TableSetColumnIndex(0) -> Text("Hello 0") -> TableSetColumnIndex(1) -> Text("Hello 1")  // OK
//        TableNextRow() -> TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK
//                          TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK: TableNextColumn() automatically gets to next row!
//        TableNextRow()                           -> Text("Hello 0")                                               // Not OK! Missing TableSetColumnIndex() or TableNextColumn()! Text will not appear!
//        --------------------------------------------------------------------------------------------------------
// - 5. Call EndTable()
pub const BeginTableOption = struct {
    flags: c.ImGuiTableFlags = 0,
    outer_size: c.ImVec2 = vec2_zero,
    inner_width: f32 = 0,
};
pub fn beginTable(str_id: [:0]const u8, column: c_int, option: BeginTableOption) bool {
    return c.igBeginTable(str_id.ptr, column, option.flags, option.outer_size, option.inner_width);
}
pub const endTable = c.igEndTable;
pub fn tableNextRow(row_flags: ?c.ImGuiTableRowFlags, min_row_height: ?f32) void {
    return c.igTableNextRow(row_flags orelse 0, min_row_height orelse 0);
}
pub const tableNextColumn = c.igTableNextColumn;
pub fn tableSetColumnIndex(column_n: c_int) bool {
    return c.igTableSetColumnIndex(column_n);
}

// Tables: Headers & Columns declaration
// - Use TableSetupColumn() to specify label.ptr, resizing policy, default width/weight, id, various other flags etc.
// - Use TableHeadersRow() to create a header row and automatically submit a TableHeader() for each column.
//   Headers are required to perform: reordering, sorting, and opening the context menu.
//   The context menu can also be made available in columns body using ImGuiTableFlags_ContextMenuInBody.
// - You may manually submit headers using TableNextRow() + TableHeader() calls, but this is only useful in
//   some advanced use cases (e.g. adding custom widgets in header row).
// - Use TableSetupScrollFreeze() to lock columns/rows so they stay visible when scrolled.
pub const TableSetupColumnOption = struct {
    flags: c.ImGuiTableColumnFlags = 0,
    init_width_or_weight: f32 = 0,
    user_id: c.ImGuiID = 0,
};
pub fn tableSetupColumn(label: [:0]const u8, option: TableSetupColumnOption) void {
    return c.igTableSetupColumn(label.ptr, option.flags, option.init_width_or_weight, option.user_id);
}
pub fn tableSetupScrollFreeze(cols: c_int, rows: c_int) void {
    return c.igTableSetupScrollFreeze(cols, rows);
}
pub const tableHeadersRow = c.igTableHeadersRow;
pub fn tableHeader(label: [:0]const u8) void {
    return c.igTableHeader(label.ptr);
}

// Tables: Sorting
// - Call TableGetSortSpecs() to retrieve latest sort specs for the table. NULL when not sorting.
// - When 'SpecsDirty == true' you should sort your data. It will be true when sorting specs have changed
//   since last call, or the first time. Make sure to set 'SpecsDirty = false' after sorting, else you may
//   wastefully sort your data every frame!
// - Lifetime: don't hold on this pointer over multiple frames or past any subsequent call to BeginTable().
pub const tableGetSortSpecs = c.igTableGetSortSpecs;

// Tables: Miscellaneous functions
// - Functions args 'int column_n' treat the default value of -1 as the same as passing the current column index.
pub const tableGetColumnCount = c.igTableGetColumnCount;
pub const tableGetColumnIndex = c.igTableGetColumnIndex;
pub const tableGetRowIndex = c.igTableGetRowIndex;
pub fn tableGetColumnName_Int(column_n: ?c_int) [*c]const u8 {
    return c.igTableGetColumnName_Int(column_n orelse -1);
}
pub fn tableGetColumnFlags(column_n: ?c_int) c.ImGuiTableColumnFlags {
    return c.igTableGetColumnFlags(column_n orelse -1);
}
pub fn tableSetColumnEnabled(column_n: c_int, v: bool) void {
    return c.igTableSetColumnEnabled(column_n, v);
}
pub fn tableSetBgColor(target: c.ImGuiTableBgTarget, color: c.ImU32, column_n: ?c_int) void {
    return c.igTableSetBgColor(target, color, column_n orelse -1);
}

// Legacy Columns API (prefer using Tables!)
// - You can also use SameLine(pos_x) to mimic simplified columns.
pub fn columns(count: c_int, id: ?[:0]const u8, border: ?bool) void {
    return c.igColumns(count, if (id) |_id| _id.ptr else null, border orelse true);
}
pub const nextColumn = c.igNextColumn;
pub const getColumnIndex = c.igGetColumnIndex;
pub fn getColumnWidth(column_index: ?c_int) f32 {
    return c.igGetColumnWidth(column_index orelse -1);
}
pub fn setColumnWidth(column_index: c_int, width: f32) void {
    return c.igSetColumnWidth(column_index, width);
}
pub fn getColumnOffset(column_index: ?c_int) f32 {
    return c.igGetColumnOffset(column_index orelse -1);
}
pub fn setColumnOffset(column_index: c_int, offset_x: f32) void {
    return c.igSetColumnOffset(column_index, offset_x);
}
pub const getColumnsCount = c.igGetColumnsCount;

// Tab Bars, Tabs
pub fn beginTabBar(str_id: [:0]const u8, flags: ?c.ImGuiTabBarFlags) bool {
    return c.igBeginTabBar(str_id.ptr, flags orelse 0);
}
pub const endTabBar = c.igEndTabBar;
pub fn beginTabItem(label: [:0]const u8, p_open: ?*bool, flags: ?c.ImGuiTabItemFlags) bool {
    return c.igBeginTabItem(label.ptr, p_open, flags orelse 0);
}
pub const endTabItem = c.igEndTabItem;
pub fn tabItemButton(label: [:0]const u8, flags: ?c.ImGuiTabItemFlags) bool {
    return c.igTabItemButton(label.ptr, flags orelse 0);
}
pub fn setTabItemClosed(tab_or_docked_window_label: [:0]const u8) void {
    return c.igSetTabItemClosed(tab_or_docked_window_label.ptr);
}

// Logging/Capture
// - All text output from the interface can be captured into tty/file/clipboard. By default, tree nodes are automatically opened during logging.
pub fn logToTTY(auto_open_depth: ?c_int) void {
    return c.igLogToTTY(auto_open_depth orelse -1);
}
pub fn logToFile(auto_open_depth: ?c_int, filename: ?[:0]const u8) void {
    return c.igLogToFile(auto_open_depth orelse -1, if (filename) |f| f.ptr else null);
}
pub fn logToClipboard(auto_open_depth: ?c_int) void {
    return c.igLogToClipboard(auto_open_depth orelse -1);
}
pub const logFinish = c.igLogFinish;
pub const logButtons = c.igLogButtons;
pub const logText = c.igLogText;

// Drag and Drop
// - On source items, call BeginDragDropSource(), if it returns true also call SetDragDropPayload() + EndDragDropSource().
// - On target candidates, call BeginDragDropTarget(), if it returns true also call AcceptDragDropPayload() + EndDragDropTarget().
// - If you stop calling BeginDragDropSource() the payload is preserved however it won't have a preview tooltip (we currently display a fallback "..." tooltip, see #1725)
// - An item can be both drag source and drop target.
pub fn beginDragDropSource(flags: ?c.ImGuiDragDropFlags) bool {
    return c.igBeginDragDropSource(flags orelse 0);
}
pub fn setDragDropPayload(@"type": [:0]const u8, data: *const anyopaque, sz: usize, cond: ?c.ImGuiCond) bool {
    return c.igSetDragDropPayload(@"type".ptr, data, sz, cond orelse 0);
}
pub const endDragDropSource = c.igEndDragDropSource;
pub const beginDragDropTarget = c.igBeginDragDropTarget;
pub fn acceptDragDropPayload(@"type": [:0]const u8, flags: ?c.ImGuiDragDropFlags) [*c]const c.ImGuiPayload {
    return c.igAcceptDragDropPayload(@"type".ptr, flags orelse 0);
}
pub const endDragDropTarget = c.igEndDragDropTarget;
pub const getDragDropPayload = c.igGetDragDropPayload;

// Disabling [BETA API]
// - Disable all user interactions and dim items visuals (applying style.DisabledAlpha over current colors)
// - Those can be nested but it cannot be used to enable an already disabled section (a single BeginDisabled(true) in the stack is enough to keep everything disabled)
// - BeginDisabled(false) essentially does nothing useful but is provided to facilitate use of boolean expressions. If you can avoid calling BeginDisabled(False)/EndDisabled() best to avoid it.
pub fn beginDisabled(disabled: ?bool) void {
    return c.igBeginDisabled(disabled orelse true);
}
pub const endDisabled = c.igEndDisabled;

// Clipping
// - Mouse hovering is affected by ImGui::PushClipRect() calls, unlike direct calls to ImDrawList::PushClipRect() which are render only.
pub fn pushClipRect(clip_rect_min: c.ImVec2, clip_rect_max: c.ImVec2, intersect_with_current_clip_rect: bool) void {
    return c.igPushClipRect(clip_rect_min, clip_rect_max, intersect_with_current_clip_rect);
}
pub const popClipRect = c.igPopClipRect;

// Focus, Activation
// - Prefer using "SetItemDefaultFocus()" over "if (IsWindowAppearing()) SetScrollHereY()" when applicable to signify "this is the default item"
pub const setItemDefaultFocus = c.igSetItemDefaultFocus;
pub fn setKeyboardFocusHere(offset: ?c_int) void {
    return c.igSetKeyboardFocusHere(offset orelse 0);
}

// Item/Widgets Utilities and Query Functions
// - Most of the functions are referring to the previous Item that has been submitted.
// - See Demo Window under "Widgets->Querying Status" for an interactive visualization of most of those functions.
pub fn isItemHovered(flags: ?c.ImGuiHoveredFlags) bool {
    return c.igIsItemHovered(flags orelse 0);
}
pub const isItemActive = c.igIsItemActive;
pub const isItemFocused = c.igIsItemFocused;
pub fn isItemClicked(mouse_button: ?c.ImGuiMouseButton) bool {
    return c.igIsItemClicked(mouse_button orelse 0);
}
pub const isItemVisible = c.igIsItemVisible;
pub const isItemEdited = c.igIsItemEdited;
pub const isItemActivated = c.igIsItemActivated;
pub const isItemDeactivated = c.igIsItemDeactivated;
pub const isItemDeactivatedAfterEdit = c.igIsItemDeactivatedAfterEdit;
pub const isItemToggledOpen = c.igIsItemToggledOpen;
pub const isAnyItemHovered = c.igIsAnyItemHovered;
pub const isAnyItemActive = c.igIsAnyItemActive;
pub const isAnyItemFocused = c.igIsAnyItemFocused;
pub fn getItemRectMin(pOut: *c.ImVec2) void {
    return c.igGetItemRectMin(pOut);
}
pub fn getItemRectMax(pOut: *c.ImVec2) void {
    return c.igGetItemRectMax(pOut);
}
pub fn getItemRectSize(pOut: *c.ImVec2) void {
    return c.igGetItemRectSize(pOut);
}
pub const setItemAllowOverlap = c.igSetItemAllowOverlap;

// Viewports
// - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
// - In 'docking' branch with multi-viewport enabled, we extend this concept to have multiple active viewports.
// - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
pub const getMainViewport = c.igGetMainViewport;

// Miscellaneous Utilities
pub fn isRectVisible(size: c.ImVec2) bool {
    return c.igIsRectVisible_Nil(size);
}
pub fn isRectVisible_Vec2(rect_min: c.ImVec2, rect_max: c.ImVec2) bool {
    return c.igIsRectVisible_Vec2(rect_min, rect_max);
}
pub const getTime = c.igGetTime;
pub const getFrameCount = c.igGetFrameCount;
pub fn getBackgroundDrawList() DrawList {
    return .{ ._dl = c.igGetBackgroundDrawList_Nil() };
}
pub fn getForegroundDrawList() DrawList {
    return .{ ._dl = c.igGetForegroundDrawList_Nil() };
}
pub const getDrawListSharedData = c.igGetDrawListSharedData;
pub fn getStyleColorName(idx: c.ImGuiCol) [*c]const u8 {
    return c.igGetStyleColorName(idx);
}
pub fn setStateStorage(storage: [*c]c.ImGuiStorage) void {
    return c.igSetStateStorage(storage);
}
pub const getStateStorage = c.igGetStateStorage;
pub fn calcListClipping(items_count: c_int, items_height: f32, out_items_display_start: *c_int, out_items_display_end: [*c]c_int) void {
    return c.igCalcListClipping(items_count, items_height, out_items_display_start, out_items_display_end);
}
pub fn beginChildFrame(id: c.ImGuiID, size: c.ImVec2, flags: ?c.ImGuiWindowFlags) bool {
    return c.igBeginChildFrame(id, size, flags orelse 0);
}
pub const endChildFrame = c.igEndChildFrame;

// Text Utilities
pub const CalcTextSizeOption = struct {
    text_end: [*c]const u8 = null,
    hide_text_after_double_hash: bool = false,
    wrap_width: f32 = -1.0,
};
pub fn calcTextSize(pOut: *c.ImVec2, _text: [*c]const u8, option: CalcTextSizeOption) void {
    return c.igCalcTextSize(pOut, _text, option.text_end, option.hide_text_after_double_hash, option.wrap_width);
}

// Color Utilities
pub fn colorConvertU32ToFloat4(pOut: *c.ImVec4, in: c.ImU32) void {
    return c.igColorConvertU32ToFloat4(pOut, in);
}
pub fn colorConvertFloat4ToU32(in: c.ImVec4) c.ImU32 {
    return c.igColorConvertFloat4ToU32(in);
}
pub fn colorConvertRGBtoHSV(r: f32, g: f32, b: f32, out_h: *f32, out_s: *f32, out_v: [*c]f32) void {
    return c.igColorConvertRGBtoHSV(r, g, b, out_h, out_s, out_v);
}
pub fn colorConvertHSVtoRGB(h: f32, s: f32, v: f32, out_r: *f32, out_g: *f32, out_b: [*c]f32) void {
    return c.igColorConvertHSVtoRGB(h, s, v, out_r, out_g, out_b);
}

// Inputs Utilities: Keyboard
// - For 'int user_key_index' you can use your own indices/enums according to how your backend/engine stored them in io.KeysDown[].
// - We don't know the meaning of those value. You can use GetKeyIndex() to map a ImGuiKey_ value into the user index.
pub fn getKeyIndex(imgui_key: c.ImGuiKey) c_int {
    return c.igGetKeyIndex(imgui_key);
}
pub fn isKeyDown(user_key_index: c_int) bool {
    return c.igIsKeyDown(user_key_index);
}
pub fn isKeyPressed(user_key_index: c_int, repeat: ?bool) bool {
    return c.igIsKeyPressed(user_key_index, repeat orelse true);
}
pub fn isKeyReleased(user_key_index: c_int) bool {
    return c.igIsKeyReleased(user_key_index);
}
pub fn getKeyPressedAmount(key_index: c_int, repeat_delay: f32, rate: f32) c_int {
    return c.igGetKeyPressedAmount(key_index, repeat_delay, rate);
}
pub fn captureKeyboardFromApp(want_capture_keyboard_value: ?bool) void {
    return c.igCaptureKeyboardFromApp(want_capture_keyboard_value orelse true);
}

// Inputs Utilities: Mouse
// - To refer to a mouse button, you may use named enums in your code e.g. ImGuiMouseButton_Left, ImGuiMouseButton_Right.
// - You can also use regular integer: it is forever guaranteed that 0=Left, 1=Right, 2=Middle.
// - Dragging operations are only reported after mouse has moved a certain distance away from the initial clicking position (see 'lock_threshold' and 'io.MouseDraggingThreshold')
pub fn isMouseDown(_button: c.ImGuiMouseButton) bool {
    return c.igIsMouseDown(_button);
}
pub fn isMouseClicked(_button: c.ImGuiMouseButton, repeat: ?bool) bool {
    return c.igIsMouseClicked(_button, repeat orelse false);
}
pub fn isMouseReleased(_button: c.ImGuiMouseButton) bool {
    return c.igIsMouseReleased(_button);
}
pub fn isMouseDoubleClicked(_button: c.ImGuiMouseButton) bool {
    return c.igIsMouseDoubleClicked(_button);
}
pub fn isMouseHoveringRect(r_min: c.ImVec2, r_max: c.ImVec2, clip: ?bool) bool {
    return c.igIsMouseHoveringRect(r_min, r_max, clip orelse true);
}
pub fn isMousePosValid(mouse_pos: ?*const c.ImVec2) bool {
    return c.igIsMousePosValid(mouse_pos);
}
pub const isAnyMouseDown = c.igIsAnyMouseDown;
pub fn getMousePos(pOut: *c.ImVec2) void {
    return c.igGetMousePos(pOut);
}
pub fn getMousePosOnOpeningCurrentPopup(pOut: *c.ImVec2) void {
    return c.igGetMousePosOnOpeningCurrentPopup(pOut);
}
pub fn isMouseDragging(_button: c.ImGuiMouseButton, lock_threshold: ?f32) bool {
    return c.igIsMouseDragging(_button, lock_threshold orelse -1);
}
pub fn getMouseDragDelta(pOut: *c.ImVec2, _button: ?c.ImGuiMouseButton, lock_threshold: ?f32) void {
    return c.igGetMouseDragDelta(pOut, _button orelse 0, lock_threshold orelse -1);
}
pub fn resetMouseDragDelta(_button: ?c.ImGuiMouseButton) void {
    return c.igResetMouseDragDelta(_button orelse 0);
}
pub const getMouseCursor = c.igGetMouseCursor;
pub fn setMouseCursor(cursor_type: c.ImGuiMouseCursor) void {
    return c.igSetMouseCursor(cursor_type);
}
pub fn captureMouseFromApp(want_capture_mouse_value: ?bool) void {
    return c.igCaptureMouseFromApp(want_capture_mouse_value orelse true);
}

// Clipboard Utilities
// - Also see the LogToClipboard() function to capture GUI into clipboard, or easily output text data to the clipboard.
pub const getClipboardText = c.igGetClipboardText;
pub fn setClipboardText(_text: [:0]const u8) void {
    return c.igSetClipboardText(_text.ptr);
}

// Settings/.Ini Utilities
// - The disk functions are automatically called if io.IniFilename != NULL (default is "imgui.ini").
// - Set io.IniFilename to NULL to load/save manually. Read io.WantSaveIniSettings description about handling .ini saving manually.
// - Important: default value "imgui.ini" is relative to current working dir! Most apps will want to lock this to an absolute path (e.g. same path as executables).
pub fn loadIniSettingsFromDisk(ini_filename: [:0]const u8) void {
    return c.igLoadIniSettingsFromDisk(ini_filename.ptr);
}
pub fn loadIniSettingsFromMemory(ini_data: []const u8) void {
    return c.igLoadIniSettingsFromMemory(ini_data.ptr, ini_data.len);
}
pub fn saveIniSettingsToDisk(ini_filename: [:0]const u8) void {
    return c.igSaveIniSettingsToDisk(ini_filename.ptr);
}
pub fn saveIniSettingsToMemory(out_ini_size: ?*usize) [*c]const u8 {
    return c.igSaveIniSettingsToMemory(out_ini_size);
}

// Debug Utilities
// - This is used by the IMGUI_CHECKVERSION() macro.
pub fn debugCheckVersionAndDataLayout(version_str: [:0]const u8, sz_io: usize, sz_style: usize, sz_vec2: usize, sz_vec4: usize, sz_drawvert: usize, sz_drawidx: usize) bool {
    return c.igDebugCheckVersionAndDataLayout(version_str.ptr, sz_io, sz_style, sz_vec2, sz_vec4, sz_drawvert, sz_drawidx);
}

// Memory Allocators
// - Those functions are not reliant on the current context.
// - DLL users: heaps and globals are not shared across DLL boundaries! You will need to call SetCurrentContext() + SetAllocatorFunctions()
//   for each static/DLL boundary you are calling from. Read "Context and Memory Allocators" section of imgui.cpp for more details.
pub fn setAllocatorFunctions(alloc_func: c.ImGuiMemAllocFunc, free_func: c.ImGuiMemFreeFunc, user_data: ?*anyopaque) void {
    return c.igSetAllocatorFunctions(alloc_func, free_func, user_data);
}
pub fn getAllocatorFunctions(p_alloc_func: [*c]c.ImGuiMemAllocFunc, p_free_func: [*c]c.ImGuiMemFreeFunc, p_user_data: **anyopaque) void {
    return c.igGetAllocatorFunctions(p_alloc_func, p_free_func, p_user_data);
}
pub fn memAlloc(size: usize) ?*anyopaque {
    return c.igMemAlloc(size);
}
pub fn memFree(ptr: ?*anyopaque) void {
    return c.igMemFree(ptr);
}

// Draw list
pub const DrawList = struct {
    _dl: *c.ImDrawList,

    pub fn pushClipRect(
        self: DrawList,
        clip_rect_min: c.ImVec2,
        clip_rect_max: c.ImVec2,
        intersect_with_current_clip_rect: bool,
    ) void {
        return c.ImDrawList_PushClipRect(
            self._dl,
            clip_rect_min,
            clip_rect_max,
            intersect_with_current_clip_rect,
        );
    }
    pub fn pushClipRectFullScreen(self: DrawList) void {
        return c.ImDrawList_PushClipRectFullScreen(self._dl);
    }
    pub fn popClipRect(self: DrawList) void {
        return c.ImDrawList_PopClipRect(self._dl);
    }
    pub fn pushTextureID(self: DrawList, texture_id: c.ImTextureID) void {
        return c.ImDrawList_PushTextureID(self._dl, texture_id);
    }
    pub fn popTextureID(self: DrawList) void {
        return c.ImDrawList_PopTextureID(self._dl);
    }
    pub fn getClipRectMin(self: DrawList) c.ImVec2 {
        var rect: c.ImVec2 = undefined;
        c.ImDrawList_GetClipRectMin(&rect, self._dl);
        return rect;
    }
    pub fn getClipRectMax(self: DrawList) c.ImVec2 {
        var rect: c.ImVec2 = undefined;
        c.ImDrawList_GetClipRectMax(&rect, self._dl);
        return rect;
    }
    pub fn addLine(self: DrawList, p1: c.ImVec2, p2: c.ImVec2, col: c.ImU32, thickness: f32) void {
        return c.ImDrawList_AddLine(self._dl, p1, p2, col, thickness);
    }
    pub fn addRect(
        self: DrawList,
        p_min: c.ImVec2,
        p_max: c.ImVec2,
        col: c.ImU32,
        rounding: f32,
        flags: c.ImDrawFlags,
        thickness: f32,
    ) void {
        return c.ImDrawList_AddRect(self._dl, p_min, p_max, col, rounding, flags, thickness);
    }
    pub fn addRectFilled(
        self: DrawList,
        p_min: c.ImVec2,
        p_max: c.ImVec2,
        col: c.ImU32,
        rounding: f32,
        flags: c.ImDrawFlags,
    ) void {
        return c.ImDrawList_AddRectFilled(self._dl, p_min, p_max, col, rounding, flags);
    }
    pub fn addRectFilledMultiColor(
        self: DrawList,
        p_min: c.ImVec2,
        p_max: c.ImVec2,
        col_upr_left: c.ImU32,
        col_upr_right: c.ImU32,
        col_bot_right: c.ImU32,
        col_bot_left: c.ImU32,
    ) void {
        return c.ImDrawList_AddRectFilledMultiColor(self._dl, p_min, p_max, col_upr_left, col_upr_right, col_bot_right, col_bot_left);
    }
    pub fn addQuad(
        self: DrawList,
        p1: c.ImVec2,
        p2: c.ImVec2,
        p3: c.ImVec2,
        p4: c.ImVec2,
        col: c.ImU32,
        thickness: f32,
    ) void {
        return c.ImDrawList_AddQuad(self._dl, p1, p2, p3, p4, col, thickness);
    }
    pub fn addQuadFilled(
        self: DrawList,
        p1: c.ImVec2,
        p2: c.ImVec2,
        p3: c.ImVec2,
        p4: c.ImVec2,
        col: c.ImU32,
    ) void {
        return c.ImDrawList_AddQuadFilled(self._dl, p1, p2, p3, p4, col);
    }
    pub fn addTriangle(
        self: DrawList,
        p1: c.ImVec2,
        p2: c.ImVec2,
        p3: c.ImVec2,
        col: c.ImU32,
        thickness: f32,
    ) void {
        return c.ImDrawList_AddTriangle(self._dl, p1, p2, p3, col, thickness);
    }
    pub fn addTriangleFilled(
        self: DrawList,
        p1: c.ImVec2,
        p2: c.ImVec2,
        p3: c.ImVec2,
        col: c.ImU32,
    ) void {
        return c.ImDrawList_AddTriangleFilled(self._dl, p1, p2, p3, col);
    }
    pub fn addCircle(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        col: c.ImU32,
        num_segments: c_int,
        thickness: f32,
    ) void {
        return c.ImDrawList_AddCircle(self._dl, center, radius, col, num_segments, thickness);
    }
    pub fn addCircleFilled(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        col: c.ImU32,
        num_segments: c_int,
    ) void {
        return c.ImDrawList_AddCircleFilled(self._dl, center, radius, col, num_segments);
    }
    pub fn addNgon(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        col: c.ImU32,
        num_segments: c_int,
        thickness: f32,
    ) void {
        return c.ImDrawList_AddNgon(self._dl, center, radius, col, num_segments, thickness);
    }
    pub fn addNgonFilled(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        col: c.ImU32,
        num_segments: c_int,
    ) void {
        return c.ImDrawList_AddNgonFilled(self._dl, center, radius, col, num_segments);
    }
    pub fn addText_Vec2(
        self: DrawList,
        pos: c.ImVec2,
        col: c.ImU32,
        text_begin: [*c]const u8,
        text_end: [*c]const u8,
    ) void {
        return c.ImDrawList_AddText_Vec2(self._dl, pos, col, text_begin, text_end);
    }
    pub fn addText_FontPtr(
        self: DrawList,
        font: [*c]const c.ImFont,
        font_size: f32,
        pos: c.ImVec2,
        col: c.ImU32,
        text_begin: [*c]const u8,
        text_end: [*c]const u8,
        wrap_width: f32,
        cpu_fine_clip_rect: [*c]const c.ImVec4,
    ) void {
        return c.ImDrawList_AddText_FontPtr(
            self._dl,
            font,
            font_size,
            pos,
            col,
            text_begin,
            text_end,
            wrap_width,
            cpu_fine_clip_rect,
        );
    }
    pub fn addPolyline(
        self: DrawList,
        points: [*c]const c.ImVec2,
        num_points: c_int,
        col: c.ImU32,
        flags: c.ImDrawFlags,
        thickness: f32,
    ) void {
        return c.ImDrawList_AddPolyline(self._dl, points, num_points, col, flags, thickness);
    }
    pub fn addConvexPolyFilled(
        self: DrawList,
        points: [*c]const c.ImVec2,
        num_points: c_int,
        col: c.ImU32,
    ) void {
        return c.ImDrawList_AddConvexPolyFilled(self._dl, points, num_points, col);
    }
    pub fn addBezierCubic(
        self: DrawList,
        p1: c.ImVec2,
        p2: c.ImVec2,
        p3: c.ImVec2,
        p4: c.ImVec2,
        col: c.ImU32,
        thickness: f32,
        num_segments: c_int,
    ) void {
        return c.ImDrawList_AddBezierCubic(self._dl, p1, p2, p3, p4, col, thickness, num_segments);
    }
    pub fn addBezierQuadratic(
        self: DrawList,
        p1: c.ImVec2,
        p2: c.ImVec2,
        p3: c.ImVec2,
        col: c.ImU32,
        thickness: f32,
        num_segments: c_int,
    ) void {
        return c.ImDrawList_AddBezierQuadratic(self._dl, p1, p2, p3, col, thickness, num_segments);
    }
    pub fn addImage(
        self: DrawList,
        user_texture_id: c.ImTextureID,
        p_min: c.ImVec2,
        p_max: c.ImVec2,
        uv_min: c.ImVec2,
        uv_max: c.ImVec2,
        col: c.ImU32,
    ) void {
        return c.ImDrawList_AddImage(self._dl, user_texture_id, p_min, p_max, uv_min, uv_max, col);
    }
    pub fn addImageQuad(
        self: DrawList,
        user_texture_id: c.ImTextureID,
        p1: c.ImVec2,
        p2: c.ImVec2,
        p3: c.ImVec2,
        p4: c.ImVec2,
        uv1: c.ImVec2,
        uv2: c.ImVec2,
        uv3: c.ImVec2,
        uv4: c.ImVec2,
        col: c.ImU32,
    ) void {
        return c.ImDrawList_AddImageQuad(
            self._dl,
            user_texture_id,
            p1,
            p2,
            p3,
            p4,
            uv1,
            uv2,
            uv3,
            uv4,
            col,
        );
    }
    pub fn addImageRounded(
        self: DrawList,
        user_texture_id: c.ImTextureID,
        p_min: c.ImVec2,
        p_max: c.ImVec2,
        uv_min: c.ImVec2,
        uv_max: c.ImVec2,
        col: c.ImU32,
        rounding: f32,
        flags: c.ImDrawFlags,
    ) void {
        return c.ImDrawList_AddImageRounded(
            self._dl,
            user_texture_id,
            p_min,
            p_max,
            uv_min,
            uv_max,
            col,
            rounding,
            flags,
        );
    }
    pub fn pathClear(self: DrawList) void {
        return c.ImDrawList_PathClear(self._dl);
    }
    pub fn pathLineTo(self: DrawList, pos: c.ImVec2) void {
        return c.ImDrawList_PathLineTo(self._dl, pos);
    }
    pub fn pathLineToMergeDuplicate(self: DrawList, pos: c.ImVec2) void {
        return c.ImDrawList_PathLineToMergeDuplicate(self._dl, pos);
    }
    pub fn pathFillConvex(self: DrawList, col: c.ImU32) void {
        return c.ImDrawList_PathFillConvex(self._dl, col);
    }
    pub fn pathStroke(self: DrawList, col: c.ImU32, flags: c.ImDrawFlags, thickness: f32) void {
        return c.ImDrawList_PathStroke(self._dl, col, flags, thickness);
    }
    pub fn pathArcTo(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        a_min: f32,
        a_max: f32,
        num_segments: c_int,
    ) void {
        return c.ImDrawList_PathArcTo(self._dl, center, radius, a_min, a_max, num_segments);
    }
    pub fn pathArcToFast(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        a_min_of_12: c_int,
        a_max_of_12: c_int,
    ) void {
        return c.ImDrawList_PathArcToFast(self._dl, center, radius, a_min_of_12, a_max_of_12);
    }
    pub fn pathBezierCubicCurveTo(
        self: DrawList,
        p2: c.ImVec2,
        p3: c.ImVec2,
        p4: c.ImVec2,
        num_segments: c_int,
    ) void {
        return c.ImDrawList_PathBezierCubicCurveTo(self._dl, p2, p3, p4, num_segments);
    }
    pub fn pathBezierQuadraticCurveTo(
        self: DrawList,
        p2: c.ImVec2,
        p3: c.ImVec2,
        num_segments: c_int,
    ) void {
        return c.ImDrawList_PathBezierQuadraticCurveTo(self._dl, p2, p3, num_segments);
    }
    pub fn pathRect(
        self: DrawList,
        rect_min: c.ImVec2,
        rect_max: c.ImVec2,
        rounding: f32,
        flags: c.ImDrawFlags,
    ) void {
        return c.ImDrawList_PathRect(self._dl, rect_min, rect_max, rounding, flags);
    }
    pub fn addCallback(
        self: DrawList,
        callback: c.ImDrawCallback,
        callback_data: ?*anyopaque,
    ) void {
        return c.ImDrawList_AddCallback(self._dl, callback, callback_data);
    }
    pub fn addDrawCmd(self: DrawList) void {
        return c.ImDrawList_AddDrawCmd(self._dl);
    }
    pub fn cloneOutput(self: DrawList) *c.ImDrawList {
        return c.ImDrawList_CloneOutput(self._dl);
    }
    pub fn channelsSplit(self: DrawList, count: c_int) void {
        return c.ImDrawList_ChannelsSplit(self._dl, count);
    }
    pub fn channelsMerge(self: DrawList) void {
        return c.ImDrawList_ChannelsMerge(self._dl);
    }
    pub fn channelsSetCurrent(self: DrawList, n: c_int) void {
        return c.ImDrawList_ChannelsSetCurrent(self._dl, n);
    }
    pub fn primReserve(self: DrawList, idx_count: c_int, vtx_count: c_int) void {
        return c.ImDrawList_PrimReserve(self._dl, idx_count, vtx_count);
    }
    pub fn primUnreserve(self: DrawList, idx_count: c_int, vtx_count: c_int) void {
        return c.ImDrawList_PrimUnreserve(self._dl, idx_count, vtx_count);
    }
    pub fn primRect(self: DrawList, a: c.ImVec2, b: c.ImVec2, col: c.ImU32) void {
        return c.ImDrawList_PrimRect(self._dl, a, b, col);
    }
    pub fn primRectUV(self: DrawList, a: c.ImVec2, b: c.ImVec2, uv_a: c.ImVec2, uv_b: c.ImVec2, col: c.ImU32) void {
        return c.ImDrawList_PrimRectUV(self._dl, a, b, uv_a, uv_b, col);
    }
    pub fn primQuadUV(
        self: DrawList,
        a: c.ImVec2,
        b: c.ImVec2,
        _c: c.ImVec2,
        d: c.ImVec2,
        uv_a: c.ImVec2,
        uv_b: c.ImVec2,
        uv_c: c.ImVec2,
        uv_d: c.ImVec2,
        col: c.ImU32,
    ) void {
        return c.ImDrawList_PrimQuadUV(self._dl, a, b, _c, d, uv_a, uv_b, uv_c, uv_d, col);
    }
    pub fn primWriteVtx(self: DrawList, pos: c.ImVec2, uv: c.ImVec2, col: c.ImU32) void {
        return c.ImDrawList_PrimWriteVtx(self._dl, pos, uv, col);
    }
    pub fn primWriteIdx(self: DrawList, idx: c.ImDrawIdx) void {
        return c.ImDrawList_PrimWriteIdx(self._dl, idx);
    }
    pub fn primVtx(self: DrawList, pos: c.ImVec2, uv: c.ImVec2, col: c.ImU32) void {
        return c.ImDrawList_PrimVtx(self._dl, pos, uv, col);
    }
    pub fn resetForNewFrame(self: DrawList) void {
        return c.ImDrawList__ResetForNewFrame(self._dl);
    }
    pub fn clearFreeMemory(self: DrawList) void {
        return c.ImDrawList__ClearFreeMemory(self._dl);
    }
    pub fn popUnusedDrawCmd(self: DrawList) void {
        return c.ImDrawList__PopUnusedDrawCmd(self._dl);
    }
    pub fn tryMergeDrawCmds(self: DrawList) void {
        return c.ImDrawList__TryMergeDrawCmds(self._dl);
    }
    pub fn onChangedClipRect(self: DrawList) void {
        return c.ImDrawList__OnChangedClipRect(self._dl);
    }
    pub fn onChangedTextureID(self: DrawList) void {
        return c.ImDrawList__OnChangedTextureID(self._dl);
    }
    pub fn onChangedVtxOffset(self: DrawList) void {
        return c.ImDrawList__OnChangedVtxOffset(self._dl);
    }
    pub fn calcCircleAutoSegmentCount(self: DrawList, radius: f32) c_int {
        return c.ImDrawList__CalcCircleAutoSegmentCount(self._dl, radius);
    }
    pub fn pathArcToFastEx(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        a_min_sample: c_int,
        a_max_sample: c_int,
        a_step: c_int,
    ) void {
        return c.ImDrawList__PathArcToFastEx(
            self._dl,
            center,
            radius,
            a_min_sample,
            a_max_sample,
            a_step,
        );
    }
    pub fn pathArcToN(
        self: DrawList,
        center: c.ImVec2,
        radius: f32,
        a_min: f32,
        a_max: f32,
        num_segments: c_int,
    ) void {
        return c.ImDrawList__PathArcToN(
            self._dl,
            center,
            radius,
            a_min,
            a_max,
            num_segments,
        );
    }
};

// ImGui Helpers
pub const helpers = struct {
    // Helpers: Hashing
    pub fn hashData(data: [*]const anyopaque, data_size: usize, seed: c.ImU32) c.ImGuiID {
        return c.igImHashData(data, data_size, seed);
    }
    pub fn hashStr(data: []const u8, seed: c.ImU32) c.ImGuiID {
        return c.igImHashStr(data.ptr, data.len, seed);
    }

    // Helpers: Color Blending
    pub fn alphaBlendColors(col_a: c.ImU32, col_b: c.ImU32) c.ImU32 {
        return c.igImAlphaBlendColors(col_a, col_b);
    }

    // Helpers: Bit manipulation
    pub fn isPowerOfTwo_Int(v: c_int) bool {
        return c.igImIsPowerOfTwo_Int(v);
    }
    pub fn isPowerOfTwo_U64(v: c.ImU64) bool {
        return c.igImIsPowerOfTwo_U64(v);
    }
    pub fn upperPowerOfTwo(v: c_int) c_int {
        return c.igImUpperPowerOfTwo(v);
    }

    // Helpers: String, Formatting
    pub fn stricmp(str1: [*c]const u8, str2: [*c]const u8) c_int {
        return c.igImStricmp(str1, str2);
    }
    pub fn strnicmp(str1: [*c]const u8, str2: [*c]const u8, count: usize) c_int {
        return c.igImStrnicmp(str1, str2, count);
    }
    pub fn strncpy(dst: [*c]u8, src: [*c]const u8, count: usize) void {
        return c.igImStrncpy(dst, src, count);
    }
    pub fn strdup(str: [*c]const u8) [*c]u8 {
        return c.igImStrdup(str);
    }
    pub fn strdupcpy(dst: [*c]u8, p_dst_size: [*c]usize, str: [*c]const u8) [*c]u8 {
        return c.igImStrdupcpy(dst, p_dst_size, str);
    }
    pub fn strchrRange(str_begin: [*c]const u8, str_end: [*c]const u8, _c: u8) [*c]const u8 {
        return c.igImStrchrRange(str_begin, str_end, _c);
    }
    pub fn strlenW(str: [*c]const c.ImWchar) c_int {
        return c.igImStrlenW(str);
    }
    pub fn streolRange(str: [*c]const u8, str_end: [*c]const u8) [*c]const u8 {
        return c.igImStreolRange(str, str_end);
    }
    pub fn strbolW(buf_mid_line: *const c.ImWchar, buf_begin: [*c]const c.ImWchar) [*c]const c.ImWchar {
        return c.igImStrbolW(buf_mid_line, buf_begin);
    }
    pub fn stristr(haystack: [*c]const u8, haystack_end: [*c]const u8, needle: [*c]const u8, needle_end: [*c]const u8) [*c]const u8 {
        return c.igImStristr(haystack, haystack_end, needle, needle_end);
    }
    pub fn strTrimBlanks(str: [*c]u8) void {
        return c.igImStrTrimBlanks(str);
    }
    pub fn strSkipBlank(str: [*c]const u8) [*c]const u8 {
        return c.igImStrSkipBlank(str);
    }
    pub const formatString = c.igImFormatString;
    pub fn parseFormatFindStart(format: [:0]const u8) [*c]const u8 {
        return c.igImParseFormatFindStart(format.ptr);
    }
    pub fn parseFormatFindEnd(format: [:0]const u8) [*c]const u8 {
        return c.igImParseFormatFindEnd(format.ptr);
    }
    pub fn parseFormatTrimDecorations(format: [:0]const u8, buf: [*c]u8, buf_size: usize) [*c]const u8 {
        return c.igImParseFormatTrimDecorations(format.ptr, buf, buf_size);
    }
    pub fn parseFormatPrecision(format: [:0]const u8, default_value: c_int) c_int {
        return c.igImParseFormatPrecision(format.ptr, default_value);
    }
    pub fn charIsBlankA(_c: u8) bool {
        return c.igImCharIsBlankA(_c);
    }
    pub fn charIsBlankW(_c: c_uint) bool {
        return c.igImCharIsBlankW(_c);
    }

    // Helpers: UTF-8 <> wchar conversions
    pub fn textCharToUtf8(out_buf: [*c]u8, _c: c_uint) [*c]const u8 {
        return c.igImTextCharToUtf8(out_buf, _c);
    }
    pub fn textStrToUtf8(out_buf: [*c]u8, out_buf_size: c_int, in_text: *const c.ImWchar, in_text_end: [*c]const c.ImWchar) c_int {
        return c.igImTextStrToUtf8(out_buf, out_buf_size, in_text, in_text_end);
    }
    pub fn textCharFromUtf8(out_char: [*c]c_uint, in_text: [*c]const u8, in_text_end: [*c]const u8) c_int {
        return c.igImTextCharFromUtf8(out_char, in_text, in_text_end);
    }
    pub fn textStrFromUtf8(out_buf: *c.ImWchar, out_buf_size: c_int, in_text: [*c]const u8, in_text_end: [*c]const u8, in_remaining: [*c][*c]const u8) c_int {
        return c.igImTextStrFromUtf8(out_buf, out_buf_size, in_text, in_text_end, in_remaining);
    }
    pub fn textCountCharsFromUtf8(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int {
        return c.igImTextCountCharsFromUtf8(in_text, in_text_end);
    }
    pub fn textCountUtf8BytesFromChar(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int {
        return c.igImTextCountUtf8BytesFromChar(in_text, in_text_end);
    }
    pub fn textCountUtf8BytesFromStr(in_text: *const c.ImWchar, in_text_end: [*c]const c.ImWchar) c_int {
        return c.igImTextCountUtf8BytesFromStr(in_text, in_text_end);
    }

    // Helpers: File System
    pub fn fileOpen(filename: [*c]const u8, mode: [*c]const u8) c.ImFileHandle {
        return c.igImFileOpen(filename, mode);
    }
    pub fn fileClose(file: c.ImFileHandle) bool {
        return c.igImFileClose(file);
    }
    pub fn fileGetSize(file: c.ImFileHandle) c.ImU64 {
        return c.igImFileGetSize(file);
    }
    pub fn fileRead(data: ?*anyopaque, size: c.ImU64, count: c.ImU64, file: c.ImFileHandle) c.ImU64 {
        return c.igImFileRead(data, size, count, file);
    }
    pub fn fileWrite(data: ?*const anyopaque, size: c.ImU64, count: c.ImU64, file: c.ImFileHandle) c.ImU64 {
        return c.igImFileWrite(data, size, count, file);
    }
    pub fn fileLoadToMemory(filename: [*c]const u8, mode: [*c]const u8, out_file_size: [*c]usize, padding_bytes: c_int) ?*anyopaque {
        return c.igImFileLoadToMemory(filename, mode, out_file_size, padding_bytes);
    }

    // Helpers: Maths
    pub fn pow_Float(x: f32, y: f32) f32 {
        return c.igImPow_Float(x, y);
    }
    pub fn pow_double(x: f64, y: f64) f64 {
        return c.igImPow_double(x, y);
    }
    pub fn log_Float(x: f32) f32 {
        return c.igImLog_Float(x);
    }
    pub fn log_double(x: f64) f64 {
        return c.igImLog_double(x);
    }
    pub fn abs_Int(x: c_int) c_int {
        return c.igImAbs_Int(x);
    }
    pub fn abs_Float(x: f32) f32 {
        return c.igImAbs_Float(x);
    }
    pub fn abs_double(x: f64) f64 {
        return c.igImAbs_double(x);
    }
    pub fn sign_Float(x: f32) f32 {
        return c.igImSign_Float(x);
    }
    pub fn sign_double(x: f64) f64 {
        return c.igImSign_double(x);
    }
    pub fn rsqrt_Float(x: f32) f32 {
        return c.igImRsqrt_Float(x);
    }
    pub fn rsqrt_double(x: f64) f64 {
        return c.igImRsqrt_double(x);
    }

    // - ImMin/ImMax/ImClamp/ImLerp/ImSwap are used by widgets which support variety of types: signed/unsigned int/long long float/double
    // (Exceptionally using templates here but we could also redefine them for those types)
    pub fn min(pOut: *c.ImVec2, lhs: c.ImVec2, rhs: c.ImVec2) void {
        return c.igImMin(pOut, lhs, rhs);
    }
    pub fn max(pOut: *c.ImVec2, lhs: c.ImVec2, rhs: c.ImVec2) void {
        return c.igImMax(pOut, lhs, rhs);
    }
    pub fn clamp(pOut: *c.ImVec2, v: c.ImVec2, mn: c.ImVec2, mx: c.ImVec2) void {
        return c.igImClamp(pOut, v, mn, mx);
    }
    pub fn lerp_Vec2Float(pOut: *c.ImVec2, a: c.ImVec2, b: c.ImVec2, t: f32) void {
        return c.igImLerp_Vec2Float(pOut, a, b, t);
    }
    pub fn lerp_Vec2Vec2(pOut: *c.ImVec2, a: c.ImVec2, b: c.ImVec2, t: c.ImVec2) void {
        return c.igImLerp_Vec2Vec2(pOut, a, b, t);
    }
    pub fn lerp_Vec4(pOut: *c.ImVec4, a: c.ImVec4, b: c.ImVec4, t: f32) void {
        return c.igImLerp_Vec4(pOut, a, b, t);
    }
    pub fn saturate(f: f32) f32 {
        return c.igImSaturate(f);
    }
    pub fn lengthSqr_Vec2(lhs: c.ImVec2) f32 {
        return c.igImLengthSqr_Vec2(lhs);
    }
    pub fn lengthSqr_Vec4(lhs: c.ImVec4) f32 {
        return c.igImLengthSqr_Vec4(lhs);
    }
    pub fn invLength(lhs: c.ImVec2, fail_value: f32) f32 {
        return c.igImInvLength(lhs, fail_value);
    }
    pub fn floor_Float(f: f32) f32 {
        return c.igImFloor_Float(f);
    }
    pub fn floorSigned(f: f32) f32 {
        return c.igImFloorSigned(f);
    }
    pub fn floor_Vec2(pOut: *c.ImVec2, v: c.ImVec2) void {
        return c.igImFloor_Vec2(pOut, v);
    }
    pub fn modPositive(a: c_int, b: c_int) c_int {
        return c.igImModPositive(a, b);
    }
    pub fn dot(a: c.ImVec2, b: c.ImVec2) f32 {
        return c.igImDot(a, b);
    }
    pub fn rotate(pOut: *c.ImVec2, v: c.ImVec2, cos_a: f32, sin_a: f32) void {
        return c.igImRotate(pOut, v, cos_a, sin_a);
    }
    pub fn linearSweep(current: f32, target: f32, speed: f32) f32 {
        return c.igImLinearSweep(current, target, speed);
    }
    pub fn mul(pOut: *c.ImVec2, lhs: c.ImVec2, rhs: c.ImVec2) void {
        return c.igImMul(pOut, lhs, rhs);
    }

    // Helpers: Geometry
    pub fn bezierCubicCalc(pOut: *c.ImVec2, p1: c.ImVec2, p2: c.ImVec2, p3: c.ImVec2, p4: c.ImVec2, t: f32) void {
        return c.igImBezierCubicCalc(pOut, p1, p2, p3, p4, t);
    }
    pub fn bezierCubicClosestPoint(pOut: *c.ImVec2, p1: c.ImVec2, p2: c.ImVec2, p3: c.ImVec2, p4: c.ImVec2, p: c.ImVec2, num_segments: c_int) void {
        return c.igImBezierCubicClosestPoint(pOut, p1, p2, p3, p4, p, num_segments);
    }
    pub fn bezierCubicClosestPointCasteljau(pOut: *c.ImVec2, p1: c.ImVec2, p2: c.ImVec2, p3: c.ImVec2, p4: c.ImVec2, p: c.ImVec2, tess_tol: f32) void {
        return c.igImBezierCubicClosestPointCasteljau(pOut, p1, p2, p3, p4, p, tess_tol);
    }
    pub fn bezierQuadraticCalc(pOut: *c.ImVec2, p1: c.ImVec2, p2: c.ImVec2, p3: c.ImVec2, t: f32) void {
        return c.igImBezierQuadraticCalc(pOut, p1, p2, p3, t);
    }
    pub fn lineClosestPoint(pOut: *c.ImVec2, a: c.ImVec2, b: c.ImVec2, p: c.ImVec2) void {
        return c.igImLineClosestPoint(pOut, a, b, p);
    }
    pub fn triangleContainsPoint(a: c.ImVec2, b: c.ImVec2, _c: c.ImVec2, p: c.ImVec2) bool {
        return c.igImTriangleContainsPoint(a, b, _c, p);
    }
    pub fn triangleClosestPoint(pOut: *c.ImVec2, a: c.ImVec2, b: c.ImVec2, _c: c.ImVec2, p: c.ImVec2) void {
        return c.igImTriangleClosestPoint(pOut, a, b, _c, p);
    }
    pub fn triangleBarycentricCoords(a: c.ImVec2, b: c.ImVec2, _c: c.ImVec2, p: c.ImVec2, out_u: *f32, out_v: *f32, out_w: *f32) void {
        return c.igImTriangleBarycentricCoords(a, b, _c, p, out_u, out_v, out_w);
    }
    pub fn triangleArea(a: c.ImVec2, b: c.ImVec2, _c: c.ImVec2) f32 {
        return c.igImTriangleArea(a, b, _c);
    }
    pub fn getDirQuadrantFromDelta(dx: f32, dy: f32) c.ImGuiDir {
        return c.igImGetDirQuadrantFromDelta(dx, dy);
    }

    // Helper: ImBitArray
    pub fn bitArrayTestBit(arr: *const c.ImU32, n: c_int) bool {
        return c.igImBitArrayTestBit(arr, n);
    }
    pub fn bitArrayClearBit(arr: *c.ImU32, n: c_int) void {
        return c.igImBitArrayClearBit(arr, n);
    }
    pub fn bitArraySetBit(arr: *c.ImU32, n: c_int) void {
        return c.igImBitArraySetBit(arr, n);
    }
    pub fn bitArraySetBitRange(arr: *c.ImU32, n: c_int, n2: c_int) void {
        return c.igImBitArraySetBitRange(arr, n, n2);
    }
};
