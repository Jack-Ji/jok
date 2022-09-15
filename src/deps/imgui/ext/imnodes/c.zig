const imgui = @import("../../c.zig");
pub const struct_ImNodesEditorContext = opaque {};
pub const ImNodesEditorContext = struct_ImNodesEditorContext;
pub const struct_ImNodesContext = opaque {};
pub const ImNodesContext = struct_ImNodesContext;
pub const ImNodesStyleFlags = c_int;
pub const struct_ImNodesStyle = extern struct {
    GridSpacing: f32,
    NodeCornerRounding: f32,
    NodePaddingHorizontal: f32,
    NodePaddingVertical: f32,
    NodeBorderThickness: f32,
    LinkThickness: f32,
    LinkLineSegmentsPerLength: f32,
    LinkHoverDistance: f32,
    PinCircleRadius: f32,
    PinQuadSideLength: f32,
    PinTriangleSideLength: f32,
    PinLineThickness: f32,
    PinHoverRadius: f32,
    PinOffset: f32,
    Flags: ImNodesStyleFlags,
    Colors: [26]c_uint,
};
pub const ImNodesStyle = struct_ImNodesStyle;
pub const struct_LinkDetachWithModifierClick = extern struct {
    Modifier: [*c]const bool,
};
pub const LinkDetachWithModifierClick = struct_LinkDetachWithModifierClick;
pub const struct_EmulateThreeButtonMouse = extern struct {
    Modifier: [*c]const bool,
};
pub const EmulateThreeButtonMouse = struct_EmulateThreeButtonMouse;
pub const struct_ImNodesIO = extern struct {
    EmulateThreeButtonMouse: EmulateThreeButtonMouse,
    LinkDetachWithModifierClick: LinkDetachWithModifierClick,
    AltMouseButton: c_int,
};
pub const ImNodesIO = struct_ImNodesIO;
pub const ImNodesCol = c_int;
pub const ImNodesStyleVar = c_int;
pub const ImNodesPinShape = c_int;
pub const ImNodesAttributeFlags = c_int;
pub const ImNodesMiniMapLocation = c_int;
pub const ImNodesMiniMapNodeHoveringCallback = ?*const fn (c_int, ?*anyopaque) callconv(.C) void;
pub const ImNodesCol_NodeBackground: c_int = 0;
pub const ImNodesCol_NodeBackgroundHovered: c_int = 1;
pub const ImNodesCol_NodeBackgroundSelected: c_int = 2;
pub const ImNodesCol_NodeOutline: c_int = 3;
pub const ImNodesCol_TitleBar: c_int = 4;
pub const ImNodesCol_TitleBarHovered: c_int = 5;
pub const ImNodesCol_TitleBarSelected: c_int = 6;
pub const ImNodesCol_Link: c_int = 7;
pub const ImNodesCol_LinkHovered: c_int = 8;
pub const ImNodesCol_LinkSelected: c_int = 9;
pub const ImNodesCol_Pin: c_int = 10;
pub const ImNodesCol_PinHovered: c_int = 11;
pub const ImNodesCol_BoxSelector: c_int = 12;
pub const ImNodesCol_BoxSelectorOutline: c_int = 13;
pub const ImNodesCol_GridBackground: c_int = 14;
pub const ImNodesCol_GridLine: c_int = 15;
pub const ImNodesCol_MiniMapBackground: c_int = 16;
pub const ImNodesCol_MiniMapBackgroundHovered: c_int = 17;
pub const ImNodesCol_MiniMapOutline: c_int = 18;
pub const ImNodesCol_MiniMapOutlineHovered: c_int = 19;
pub const ImNodesCol_MiniMapNodeBackground: c_int = 20;
pub const ImNodesCol_MiniMapNodeBackgroundHovered: c_int = 21;
pub const ImNodesCol_MiniMapNodeBackgroundSelected: c_int = 22;
pub const ImNodesCol_MiniMapNodeOutline: c_int = 23;
pub const ImNodesCol_MiniMapLink: c_int = 24;
pub const ImNodesCol_MiniMapLinkSelected: c_int = 25;
pub const ImNodesCol_COUNT: c_int = 26;
pub const ImNodesCol_ = c_uint;
pub const ImNodesStyleVar_GridSpacing: c_int = 0;
pub const ImNodesStyleVar_NodeCornerRounding: c_int = 1;
pub const ImNodesStyleVar_NodePaddingHorizontal: c_int = 2;
pub const ImNodesStyleVar_NodePaddingVertical: c_int = 3;
pub const ImNodesStyleVar_NodeBorderThickness: c_int = 4;
pub const ImNodesStyleVar_LinkThickness: c_int = 5;
pub const ImNodesStyleVar_LinkLineSegmentsPerLength: c_int = 6;
pub const ImNodesStyleVar_LinkHoverDistance: c_int = 7;
pub const ImNodesStyleVar_PinCircleRadius: c_int = 8;
pub const ImNodesStyleVar_PinQuadSideLength: c_int = 9;
pub const ImNodesStyleVar_PinTriangleSideLength: c_int = 10;
pub const ImNodesStyleVar_PinLineThickness: c_int = 11;
pub const ImNodesStyleVar_PinHoverRadius: c_int = 12;
pub const ImNodesStyleVar_PinOffset: c_int = 13;
pub const ImNodesStyleVar_ = c_uint;
pub const ImNodesStyleFlags_None: c_int = 0;
pub const ImNodesStyleFlags_NodeOutline: c_int = 1;
pub const ImNodesStyleFlags_GridLines: c_int = 4;
pub const ImNodesStyleFlags_ = c_uint;
pub const ImNodesPinShape_Circle: c_int = 0;
pub const ImNodesPinShape_CircleFilled: c_int = 1;
pub const ImNodesPinShape_Triangle: c_int = 2;
pub const ImNodesPinShape_TriangleFilled: c_int = 3;
pub const ImNodesPinShape_Quad: c_int = 4;
pub const ImNodesPinShape_QuadFilled: c_int = 5;
pub const ImNodesPinShape_ = c_uint;
pub const ImNodesAttributeFlags_None: c_int = 0;
pub const ImNodesAttributeFlags_EnableLinkDetachWithDragClick: c_int = 1;
pub const ImNodesAttributeFlags_EnableLinkCreationOnSnap: c_int = 2;
pub const ImNodesAttributeFlags_ = c_uint;
pub const ImNodesMiniMapLocation_BottomLeft: c_int = 0;
pub const ImNodesMiniMapLocation_BottomRight: c_int = 1;
pub const ImNodesMiniMapLocation_TopLeft: c_int = 2;
pub const ImNodesMiniMapLocation_TopRight: c_int = 3;
pub const ImNodesMiniMapLocation_ = c_uint;
pub extern fn EmulateThreeButtonMouse_EmulateThreeButtonMouse() [*c]EmulateThreeButtonMouse;
pub extern fn EmulateThreeButtonMouse_destroy(self: [*c]EmulateThreeButtonMouse) void;
pub extern fn LinkDetachWithModifierClick_LinkDetachWithModifierClick() [*c]LinkDetachWithModifierClick;
pub extern fn LinkDetachWithModifierClick_destroy(self: [*c]LinkDetachWithModifierClick) void;
pub extern fn ImNodesIO_ImNodesIO() [*c]ImNodesIO;
pub extern fn ImNodesIO_destroy(self: [*c]ImNodesIO) void;
pub extern fn ImNodesStyle_ImNodesStyle() [*c]ImNodesStyle;
pub extern fn ImNodesStyle_destroy(self: [*c]ImNodesStyle) void;
pub extern fn imnodes_SetImGuiContext(ctx: [*c]imgui.ImGuiContext) void;
pub extern fn imnodes_CreateContext() ?*ImNodesContext;
pub extern fn imnodes_DestroyContext(ctx: ?*ImNodesContext) void;
pub extern fn imnodes_GetCurrentContext() ?*ImNodesContext;
pub extern fn imnodes_SetCurrentContext(ctx: ?*ImNodesContext) void;
pub extern fn imnodes_EditorContextCreate() ?*ImNodesEditorContext;
pub extern fn imnodes_EditorContextFree(noname1: ?*ImNodesEditorContext) void;
pub extern fn imnodes_EditorContextSet(noname1: ?*ImNodesEditorContext) void;
pub extern fn imnodes_EditorContextGetPanning(pOut: [*c]imgui.ImVec2) void;
pub extern fn imnodes_EditorContextResetPanning(pos: imgui.ImVec2) void;
pub extern fn imnodes_EditorContextMoveToNode(node_id: c_int) void;
pub extern fn imnodes_GetIO() [*c]ImNodesIO;
pub extern fn imnodes_GetStyle() [*c]ImNodesStyle;
pub extern fn imnodes_StyleColorsDark() void;
pub extern fn imnodes_StyleColorsClassic() void;
pub extern fn imnodes_StyleColorsLight() void;
pub extern fn imnodes_BeginNodeEditor() void;
pub extern fn imnodes_EndNodeEditor() void;
pub extern fn imnodes_MiniMap(minimap_size_fraction: f32, location: ImNodesMiniMapLocation, node_hovering_callback: ImNodesMiniMapNodeHoveringCallback, node_hovering_callback_data: ?*anyopaque) void;
pub extern fn imnodes_PushColorStyle(item: ImNodesCol, color: c_uint) void;
pub extern fn imnodes_PopColorStyle() void;
pub extern fn imnodes_PushStyleVar(style_item: ImNodesStyleVar, value: f32) void;
pub extern fn imnodes_PopStyleVar() void;
pub extern fn imnodes_BeginNode(id: c_int) void;
pub extern fn imnodes_EndNode() void;
pub extern fn imnodes_GetNodeDimensions(pOut: [*c]imgui.ImVec2, id: c_int) void;
pub extern fn imnodes_BeginNodeTitleBar() void;
pub extern fn imnodes_EndNodeTitleBar() void;
pub extern fn imnodes_BeginInputAttribute(id: c_int, shape: ImNodesPinShape) void;
pub extern fn imnodes_EndInputAttribute() void;
pub extern fn imnodes_BeginOutputAttribute(id: c_int, shape: ImNodesPinShape) void;
pub extern fn imnodes_EndOutputAttribute() void;
pub extern fn imnodes_BeginStaticAttribute(id: c_int) void;
pub extern fn imnodes_EndStaticAttribute() void;
pub extern fn imnodes_PushAttributeFlag(flag: ImNodesAttributeFlags) void;
pub extern fn imnodes_PopAttributeFlag() void;
pub extern fn imnodes_Link(id: c_int, start_attribute_id: c_int, end_attribute_id: c_int) void;
pub extern fn imnodes_SetNodeDraggable(node_id: c_int, draggable: bool) void;
pub extern fn imnodes_SetNodeScreenSpacePos(node_id: c_int, screen_space_pos: imgui.ImVec2) void;
pub extern fn imnodes_SetNodeEditorSpacePos(node_id: c_int, editor_space_pos: imgui.ImVec2) void;
pub extern fn imnodes_SetNodeGridSpacePos(node_id: c_int, grid_pos: imgui.ImVec2) void;
pub extern fn imnodes_GetNodeScreenSpacePos(pOut: [*c]imgui.ImVec2, node_id: c_int) void;
pub extern fn imnodes_GetNodeEditorSpacePos(pOut: [*c]imgui.ImVec2, node_id: c_int) void;
pub extern fn imnodes_GetNodeGridSpacePos(pOut: [*c]imgui.ImVec2, node_id: c_int) void;
pub extern fn imnodes_IsEditorHovered() bool;
pub extern fn imnodes_IsNodeHovered(node_id: [*c]c_int) bool;
pub extern fn imnodes_IsLinkHovered(link_id: [*c]c_int) bool;
pub extern fn imnodes_IsPinHovered(attribute_id: [*c]c_int) bool;
pub extern fn imnodes_NumSelectedNodes() c_int;
pub extern fn imnodes_NumSelectedLinks() c_int;
pub extern fn imnodes_GetSelectedNodes(node_ids: [*c]c_int) void;
pub extern fn imnodes_GetSelectedLinks(link_ids: [*c]c_int) void;
pub extern fn imnodes_ClearNodeSelection_Nil() void;
pub extern fn imnodes_ClearLinkSelection_Nil() void;
pub extern fn imnodes_SelectNode(node_id: c_int) void;
pub extern fn imnodes_ClearNodeSelection_Int(node_id: c_int) void;
pub extern fn imnodes_IsNodeSelected(node_id: c_int) bool;
pub extern fn imnodes_SelectLink(link_id: c_int) void;
pub extern fn imnodes_ClearLinkSelection_Int(link_id: c_int) void;
pub extern fn imnodes_IsLinkSelected(link_id: c_int) bool;
pub extern fn imnodes_IsAttributeActive() bool;
pub extern fn imnodes_IsAnyAttributeActive(attribute_id: [*c]c_int) bool;
pub extern fn imnodes_IsLinkStarted(started_at_attribute_id: [*c]c_int) bool;
pub extern fn imnodes_IsLinkDropped(started_at_attribute_id: [*c]c_int, including_detached_links: bool) bool;
pub extern fn imnodes_IsLinkCreated_BoolPtr(started_at_attribute_id: [*c]c_int, ended_at_attribute_id: [*c]c_int, created_from_snap: [*c]bool) bool;
pub extern fn imnodes_IsLinkCreated_IntPtr(started_at_node_id: [*c]c_int, started_at_attribute_id: [*c]c_int, ended_at_node_id: [*c]c_int, ended_at_attribute_id: [*c]c_int, created_from_snap: [*c]bool) bool;
pub extern fn imnodes_IsLinkDestroyed(link_id: [*c]c_int) bool;
pub extern fn imnodes_SaveCurrentEditorStateToIniString(data_size: [*c]usize) [*c]const u8;
pub extern fn imnodes_SaveEditorStateToIniString(editor: ?*const ImNodesEditorContext, data_size: [*c]usize) [*c]const u8;
pub extern fn imnodes_LoadCurrentEditorStateFromIniString(data: [*c]const u8, data_size: usize) void;
pub extern fn imnodes_LoadEditorStateFromIniString(editor: ?*ImNodesEditorContext, data: [*c]const u8, data_size: usize) void;
pub extern fn imnodes_SaveCurrentEditorStateToIniFile(file_name: [*c]const u8) void;
pub extern fn imnodes_SaveEditorStateToIniFile(editor: ?*const ImNodesEditorContext, file_name: [*c]const u8) void;
pub extern fn imnodes_LoadCurrentEditorStateFromIniFile(file_name: [*c]const u8) void;
pub extern fn imnodes_LoadEditorStateFromIniFile(editor: ?*ImNodesEditorContext, file_name: [*c]const u8) void;
pub extern fn getIOKeyCtrlPtr(...) [*c]bool;
