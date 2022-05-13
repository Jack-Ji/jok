/// help wrappers of raw imnodes api
const imgui = @import("../../c.zig");
pub const c = @import("c.zig");
pub const ImNodesContext = c.ImNodesContext;
pub const ImNodesEditorContext = c.ImNodesEditorContext;
pub fn setImGuiContext(ctx: *imgui.ImGuiContext) void {
    return c.imnodes_SetImGuiContext(ctx);
}
pub fn createContext() ?*c.ImNodesContext {
    return c.imnodes_CreateContext();
}
pub fn destroyContext(ctx: *c.ImNodesContext) void {
    return c.imnodes_DestroyContext(ctx);
}
pub fn getCurrentContext() ?*c.ImNodesContext {
    return c.imnodes_GetCurrentContext();
}
pub fn setCurrentContext(ctx: *c.ImNodesContext) void {
    return c.imnodes_SetCurrentContext(ctx);
}
pub fn editorContextCreate() ?*c.ImNodesEditorContext {
    return c.imnodes_EditorContextCreate();
}
pub fn editorContextFree(noname1: *c.ImNodesEditorContext) void {
    return c.imnodes_EditorContextFree(noname1);
}
pub fn editorContextSet(noname1: *c.ImNodesEditorContext) void {
    return c.imnodes_EditorContextSet(noname1);
}
pub fn editorContextGetPanning(pOut: [*c]imgui.ImVec2) void {
    return c.imnodes_EditorContextGetPanning(pOut);
}
pub fn editorContextResetPanning(pos: imgui.ImVec2) void {
    return c.imnodes_EditorContextResetPanning(pos);
}
pub fn editorContextMoveToNode(node_id: c_int) void {
    return c.imnodes_EditorContextMoveToNode(node_id);
}
pub fn getIO() [*c]c.ImNodesIO {
    return c.imnodes_GetIO();
}
pub fn getStyle() [*c]c.ImNodesStyle {
    return c.imnodes_GetStyle();
}
pub fn styleColorsDark() void {
    return c.imnodes_StyleColorsDark();
}
pub fn styleColorsClassic() void {
    return c.imnodes_StyleColorsClassic();
}
pub fn styleColorsLight() void {
    return c.imnodes_StyleColorsLight();
}
pub fn beginNodeEditor() void {
    return c.imnodes_BeginNodeEditor();
}
pub fn endNodeEditor() void {
    return c.imnodes_EndNodeEditor();
}
pub fn miniMap(minimap_size_fraction: f32, location: c.ImNodesMiniMapLocation, node_hovering_callback: c.ImNodesMiniMapNodeHoveringCallback, node_hovering_callback_data: *anyopaque) void {
    return c.imnodes_MiniMap(minimap_size_fraction, location, node_hovering_callback, node_hovering_callback_data);
}
pub fn pushColorStyle(item: c.ImNodesCol, color: c_uint) void {
    return c.imnodes_PushColorStyle(item, color);
}
pub fn popColorStyle() void {
    return c.imnodes_PopColorStyle();
}
pub fn pushStyleVar(style_item: c.ImNodesStyleVar, value: f32) void {
    return c.imnodes_PushStyleVar(style_item, value);
}
pub fn popStyleVar() void {
    return c.imnodes_PopStyleVar();
}
pub fn beginNode(id: c_int) void {
    return c.imnodes_BeginNode(id);
}
pub fn endNode() void {
    return c.imnodes_EndNode();
}
pub fn getNodeDimensions(pOut: [*c]imgui.ImVec2, id: c_int) void {
    return c.imnodes_GetNodeDimensions(pOut, id);
}
pub fn beginNodeTitleBar() void {
    return c.imnodes_BeginNodeTitleBar();
}
pub fn endNodeTitleBar() void {
    return c.imnodes_EndNodeTitleBar();
}
pub fn beginInputAttribute(id: c_int, shape: c.ImNodesPinShape) void {
    return c.imnodes_BeginInputAttribute(id, shape);
}
pub fn endInputAttribute() void {
    return c.imnodes_EndInputAttribute();
}
pub fn beginOutputAttribute(id: c_int, shape: c.ImNodesPinShape) void {
    return c.imnodes_BeginOutputAttribute(id, shape);
}
pub fn endOutputAttribute() void {
    return c.imnodes_EndOutputAttribute();
}
pub fn beginStaticAttribute(id: c_int) void {
    return c.imnodes_BeginStaticAttribute(id);
}
pub fn endStaticAttribute() void {
    return c.imnodes_EndStaticAttribute();
}
pub fn pushAttributeFlag(flag: c.ImNodesAttributeFlags) void {
    return c.imnodes_PushAttributeFlag(flag);
}
pub fn popAttributeFlag() void {
    return c.imnodes_PopAttributeFlag();
}
pub fn link(id: c_int, start_attribute_id: c_int, end_attribute_id: c_int) void {
    return c.imnodes_Link(id, start_attribute_id, end_attribute_id);
}
pub fn setNodeDraggable(node_id: c_int, draggable: bool) void {
    return c.imnodes_SetNodeDraggable(node_id, draggable);
}
pub fn setNodeScreenSpacePos(node_id: c_int, screen_space_pos: imgui.ImVec2) void {
    return c.imnodes_SetNodeScreenSpacePos(node_id, screen_space_pos);
}
pub fn setNodeEditorSpacePos(node_id: c_int, editor_space_pos: imgui.ImVec2) void {
    return c.imnodes_SetNodeEditorSpacePos(node_id, editor_space_pos);
}
pub fn setNodeGridSpacePos(node_id: c_int, grid_pos: imgui.ImVec2) void {
    return c.imnodes_SetNodeGridSpacePos(node_id, grid_pos);
}
pub fn getNodeScreenSpacePos(pOut: [*c]imgui.ImVec2, node_id: c_int) void {
    return c.imnodes_GetNodeScreenSpacePos(pOut, node_id);
}
pub fn getNodeEditorSpacePos(pOut: [*c]imgui.ImVec2, node_id: c_int) void {
    return c.imnodes_GetNodeEditorSpacePos(pOut, node_id);
}
pub fn getNodeGridSpacePos(pOut: [*c]imgui.ImVec2, node_id: c_int) void {
    return c.imnodes_GetNodeGridSpacePos(pOut, node_id);
}
pub fn isEditorHovered() bool {
    return c.imnodes_IsEditorHovered();
}
pub fn isNodeHovered(node_id: [*c]c_int) bool {
    return c.imnodes_IsNodeHovered(node_id);
}
pub fn isLinkHovered(link_id: [*c]c_int) bool {
    return c.imnodes_IsLinkHovered(link_id);
}
pub fn isPinHovered(attribute_id: [*c]c_int) bool {
    return c.imnodes_IsPinHovered(attribute_id);
}
pub fn numSelectedNodes() c_int {
    return c.imnodes_NumSelectedNodes();
}
pub fn numSelectedLinks() c_int {
    return c.imnodes_NumSelectedLinks();
}
pub fn getSelectedNodes(node_ids: [*c]c_int) void {
    return c.imnodes_GetSelectedNodes(node_ids);
}
pub fn getSelectedLinks(link_ids: [*c]c_int) void {
    return c.imnodes_GetSelectedLinks(link_ids);
}
pub fn clearNodeSelection_Nil() void {
    return c.imnodes_ClearNodeSelection_Nil();
}
pub fn clearLinkSelection_Nil() void {
    return c.imnodes_ClearLinkSelection_Nil();
}
pub fn selectNode(node_id: c_int) void {
    return c.imnodes_SelectNode(node_id);
}
pub fn clearNodeSelection_Int(node_id: c_int) void {
    return c.imnodes_ClearNodeSelection_Int(node_id);
}
pub fn isNodeSelected(node_id: c_int) bool {
    return c.imnodes_IsNodeSelected(node_id);
}
pub fn selectLink(link_id: c_int) void {
    return c.imnodes_SelectLink(link_id);
}
pub fn clearLinkSelection_Int(link_id: c_int) void {
    return c.imnodes_ClearLinkSelection_Int(link_id);
}
pub fn isLinkSelected(link_id: c_int) bool {
    return c.imnodes_IsLinkSelected(link_id);
}
pub fn isAttributeActive() bool {
    return c.imnodes_IsAttributeActive();
}
pub fn isAnyAttributeActive(attribute_id: [*c]c_int) bool {
    return c.imnodes_IsAnyAttributeActive(attribute_id);
}
pub fn isLinkStarted(started_at_attribute_id: [*c]c_int) bool {
    return c.imnodes_IsLinkStarted(started_at_attribute_id);
}
pub fn isLinkDropped(started_at_attribute_id: [*c]c_int, including_detached_links: bool) bool {
    return c.imnodes_IsLinkDropped(started_at_attribute_id, including_detached_links);
}
pub fn isLinkCreated_BoolPtr(started_at_attribute_id: [*c]c_int, ended_at_attribute_id: [*c]c_int, created_from_snap: [*c]bool) bool {
    return c.imnodes_IsLinkCreated_BoolPtr(started_at_attribute_id, ended_at_attribute_id, created_from_snap);
}
pub fn isLinkCreated_IntPtr(started_at_node_id: [*c]c_int, started_at_attribute_id: [*c]c_int, ended_at_node_id: [*c]c_int, ended_at_attribute_id: [*c]c_int, created_from_snap: [*c]bool) bool {
    return c.imnodes_IsLinkCreated_IntPtr(started_at_node_id, started_at_attribute_id, ended_at_node_id, ended_at_attribute_id, created_from_snap);
}
pub fn isLinkDestroyed(link_id: *c_int) bool {
    return c.imnodes_IsLinkDestroyed(link_id);
}
pub fn saveCurrentEditorStateToIniString(data_size: *usize) [*c]const u8 {
    return c.imnodes_SaveCurrentEditorStateToIniString(data_size);
}
pub fn saveEditorStateToIniString(editor: *const c.ImNodesEditorContext, data_size: *usize) [*c]const u8 {
    return c.imnodes_SaveEditorStateToIniString(editor, data_size);
}
pub fn loadCurrentEditorStateFromIniString(data: []u8) void {
    return c.imnodes_LoadCurrentEditorStateFromIniString(data.ptr, data.len);
}
pub fn loadEditorStateFromIniString(editor: *c.ImNodesEditorContext, data: []const u8) void {
    return c.imnodes_LoadEditorStateFromIniString(editor, data.ptr, data.len);
}
pub fn saveCurrentEditorStateToIniFile(file_name: [:0]const u8) void {
    return c.imnodes_SaveCurrentEditorStateToIniFile(file_name);
}
pub fn saveEditorStateToIniFile(editor: *const c.ImNodesEditorContext, file_name: [:0]const u8) void {
    return c.imnodes_SaveEditorStateToIniFile(editor, file_name);
}
pub fn loadCurrentEditorStateFromIniFile(file_name: [:0]const u8) void {
    return c.imnodes_LoadCurrentEditorStateFromIniFile(file_name);
}
pub fn loadEditorStateFromIniFile(editor: *c.ImNodesEditorContext, file_name: [:0]const u8) void {
    return c.imnodes_LoadEditorStateFromIniFile(editor, file_name);
}
