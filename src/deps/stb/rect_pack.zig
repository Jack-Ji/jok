pub const stbrp_coord = c_ushort;
pub const struct_stbrp_node = extern struct {
    x: stbrp_coord,
    y: stbrp_coord,
    next: [*c]stbrp_node,
};
pub const stbrp_node = struct_stbrp_node;
pub const struct_stbrp_context = extern struct {
    width: c_int,
    height: c_int,
    @"align": c_int,
    init_mode: c_int,
    heuristic: c_int,
    num_nodes: c_int,
    active_head: [*c]stbrp_node,
    free_head: [*c]stbrp_node,
    extra: [2]stbrp_node,
};
pub const stbrp_context = struct_stbrp_context;
pub const struct_stbrp_rect = extern struct {
    id: c_int,
    w: stbrp_coord,
    h: stbrp_coord,
    x: stbrp_coord,
    y: stbrp_coord,
    was_packed: c_int,
};
pub const stbrp_rect = struct_stbrp_rect;
pub extern fn stbrp_pack_rects(context: [*c]stbrp_context, rects: [*c]stbrp_rect, num_rects: c_int) c_int;
pub extern fn stbrp_init_target(context: [*c]stbrp_context, width: c_int, height: c_int, nodes: [*c]stbrp_node, num_nodes: c_int) void;
pub extern fn stbrp_setup_allow_out_of_mem(context: [*c]stbrp_context, allow_out_of_mem: c_int) void;
pub extern fn stbrp_setup_heuristic(context: [*c]stbrp_context, heuristic: c_int) void;
pub const STBRP_HEURISTIC_Skyline_default: c_int = 0;
pub const STBRP_HEURISTIC_Skyline_BL_sortHeight: c_int = 0;
pub const STBRP_HEURISTIC_Skyline_BF_sortHeight: c_int = 1;
