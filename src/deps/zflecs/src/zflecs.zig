const std = @import("std");
const assert = std.debug.assert;

pub const ftime_t = f32;
pub const size_t = i32;
pub const flags8_t = u8;
pub const flags16_t = u16;
pub const flags32_t = u32;
pub const flags64_t = u64;

pub const vector_t = opaque {};
pub const mixins_t = opaque {};

const filter_t_magic = 0x65637366;

pub const error_t = error{FlecsError};
pub fn make_error() error{FlecsError} {
    //if (getError()) |str| {
    //    std.log.debug("SDL2: {s}", .{str});
    //}
    return error.FlecsError;
}
//--------------------------------------------------------------------------------------------------
//
// Types for core API objects.
//
//--------------------------------------------------------------------------------------------------
pub const id_t = u64;
pub const entity_t = id_t;

pub const type_t = extern struct {
    array: [*]id_t,
    count: i32,
};

pub const world_t = opaque {};
pub const table_t = opaque {};

pub const query_t = opaque {};

pub const table_record_t = opaque {};
pub const id_record_t = opaque {};
pub const query_table_node_t = opaque {};
pub const rule_t = opaque {};

pub const poly_t = anyopaque;

pub const header_t = extern struct {
    magic: i32,
    type: i32 = 0,
    mixins: ?*mixins_t = null,
};
//--------------------------------------------------------------------------------------------------
//
// Function types.
//
//--------------------------------------------------------------------------------------------------
pub const run_action_t = *const fn (it: *iter_t) callconv(.C) void;

pub const iter_action_t = *const fn (it: *iter_t) callconv(.C) void;

pub const iter_init_action_t = *const fn (
    world: *const world_t,
    iterable: *const poly_t,
    it: *iter_t,
    filter: ?*term_t,
) callconv(.C) void;

pub const iter_next_action_t = *const fn (it: *iter_t) callconv(.C) bool;

pub const iter_fini_action_t = *const fn (it: *iter_t) callconv(.C) void;

pub const order_by_action_t = *const fn (
    e1: entity_t,
    ptr1: *const anyopaque,
    e2: entity_t,
    ptr2: *const anyopaque,
) callconv(.C) i32;

pub const sort_table_action_t = *const fn (
    world: *world_t,
    table: *table_t,
    entities: ?[*]entity_t,
    ptr: ?*anyopaque,
    size: i32,
    lo: i32,
    hi: i32,
    order_by: ?order_by_action_t,
) callconv(.C) void;

pub const group_by_action_t = *const fn (
    world: *world_t,
    table: *table_t,
    group_id: id_t,
    ctx: ?*anyopaque,
) callconv(.C) u64;

pub const group_create_action_t = *const fn (
    world: *world_t,
    group_id: u64,
    group_by_ctx: ?*anyopaque,
) callconv(.C) ?*anyopaque;

pub const group_delete_action_t = *const fn (
    world: *world_t,
    group_id: u64,
    group_ctx: ?*anyopaque,
    group_by_ctx: ?*anyopaque,
) callconv(.C) void;

pub const module_action_t = *const fn (world: *world_t) callconv(.C) void;

pub const fini_action_t = *const fn (world: *world_t, ctx: ?*anyopaque) callconv(.C) void;

pub const ctx_free_t = *const fn (ctx: ?*anyopaque) callconv(.C) void;

pub const compare_action_t = *const fn (
    ptr1: *const anyopaque,
    ptr2: *const anyopaque,
) callconv(.C) i32;

pub const hash_value_action_t = *const fn (ptr: ?*const anyopaque) callconv(.C) u64;

pub const xtor_t = *const fn (
    ptr: *anyopaque,
    count: i32,
    type_info: *const type_info_t,
) callconv(.C) void;

pub const copy_t = *const fn (
    dst_ptr: *anyopaque,
    src_ptr: *const anyopaque,
    count: i32,
    type_info: *const type_info_t,
) callconv(.C) void;

pub const move_t = *const fn (
    dst_ptr: *anyopaque,
    src_ptr: *anyopaque,
    count: i32,
    type_info: *const type_info_t,
) callconv(.C) void;

pub const poly_dtor_t = *const fn (poly: *poly_t) callconv(.C) void;
//--------------------------------------------------------------------------------------------------
//
// Mixin types for poly mechanism.
//
//--------------------------------------------------------------------------------------------------
pub const iterable_t = extern struct {
    init: ?iter_init_action_t = null,
};
//--------------------------------------------------------------------------------------------------
//
// Query descriptor types.
//
//--------------------------------------------------------------------------------------------------
pub const inout_kind_t = enum(i32) {
    InOutDefault,
    InOutNone,
    InOut,
    In,
    Out,
};

pub const oper_kind_t = enum(i32) {
    And,
    Or,
    Not,
    Optional,
    AndFrom,
    OrFrom,
    NotFrom,
};

pub const Self = 1 << 1;
pub const Up = 1 << 2;
pub const Down = 1 << 3;
pub const TraverseAll = 1 << 4;
pub const Cascade = 1 << 5;
pub const Parent = 1 << 6;
pub const IsVariable = 1 << 7;
pub const IsEntity = 1 << 8;
pub const Filter = 1 << 9;
pub const TraverseFlags = Up | Down | TraverseAll | Self | Cascade | Parent;

pub const term_id_t = extern struct {
    id: entity_t = 0,
    name: ?[*:0]u8 = null,
    trav: entity_t = 0,
    flags: flags32_t = 0,
};

pub const term_t = extern struct {
    id: id_t = 0,

    src: term_id_t = .{},
    first: term_id_t = .{},
    second: term_id_t = .{},

    inout: inout_kind_t = @intToEnum(inout_kind_t, 0),
    oper: oper_kind_t = @intToEnum(oper_kind_t, 0),

    id_flags: id_t = 0,
    name: ?[*:0]u8 = null,

    field_index: i32 = 0,
    idr: ?*id_record_t = null,

    move: bool = true,
};

pub fn array(comptime T: type, comptime len: comptime_int) [len]T {
    return [_]T{.{}} ** len;
}

pub const filter_t = extern struct {
    hdr: header_t = .{ .magic = filter_t_magic },

    terms: ?[*]term_t = null,
    term_count: i32 = 0,
    field_count: i32 = 0,

    owned: bool = false,
    terms_owned: bool = false,

    flags: flags32_t = 0,

    variable_names: ?[*][*:0]u8 = null, // TODO: Only `variable_names[0]` is valid?

    entity: entity_t = 0,
    world: ?*world_t = null,
    iterable: iterable_t = .{},
    dtor: ?poly_dtor_t = null,
};

pub const observer_t = extern struct {
    hdr: header_t,
    filter: filter_t,
    events: [8]entity_t,
    event_count: i32,
    callback: iter_action_t,
    run: run_action_t,
    ctx: ?*anyopaque,
    binding_ctx: ?*anyopaque,
    ctx_free: ctx_free_t,
    binding_ctx_free: ctx_free_t,
    observable: [*c]observable_t,
    last_event_id: [*c]i32,
    last_event_id_storage: i32,
    register_id: id_t,
    term_index: i32,
    is_monitor: bool,
    is_multi: bool,
    dtor: poly_dtor_t,
};
//--------------------------------------------------------------------------------------------------
pub const type_hooks_t = extern struct {
    ctor: ?xtor_t = null,
    dtor: ?xtor_t = null,
    copy: ?copy_t = null,
    move: ?move_t = null,
    copy_ctor: ?copy_t = null,
    move_ctor: ?move_t = null,
    ctor_move_dtor: ?move_t = null,
    move_dtor: ?move_t = null,
    on_add: ?iter_action_t = null,
    on_set: ?iter_action_t = null,
    on_remove: ?iter_action_t = null,
    ctx: ?*anyopaque = null,
    binding_ctx: ?*anyopaque = null,
    ctx_free: ?ctx_free_t = null,
    binding_ctx_free: ?ctx_free_t = null,
};

pub const type_info_t = extern struct {
    size: size_t,
    alignment: size_t,
    hooks: type_hooks_t = .{},
    component: entity_t = 0,
    name: ?[*:0]const u8 = null,
};

pub const event_id_record_t = opaque {};

pub const event_record_t = extern struct {
    any: ?*event_id_record_t,
    wildcard: ?*event_id_record_t,
    wildcard_pair: ?*event_id_record_t,
    event_ids: map_t,
    event: entity_t,
};

pub const observable_t = extern struct {
    on_add: event_record_t,
    on_remove: event_record_t,
    on_set: event_record_t,
    un_set: event_record_t,
    on_wildcard: event_record_t,
    events: sparse_t,
};

pub const table_range_t = extern struct {
    table: ?*table_t,
    offset: i32,
    count: i32,
};

pub const var_t = extern struct {
    range: table_range_t,
    entity: entity_t,
};

pub const record_t = extern struct {
    idr: *id_record_t,
    table: *table_t,
    row: u32,
};

pub const ref_t = extern struct {
    entity: entity_t,
    id: entity_t,
    tr: *table_record_t,
    record: *record_t,
};

pub const stack_page_t = opaque {};

pub const stack_cursor_t = extern struct {
    cur: ?*stack_page_t,
    sp: i16,
};

pub const page_iter_t = extern struct {
    offset: i32,
    limit: i32,
    remaining: i32,
};

pub const worker_iter_t = extern struct {
    index: i32,
    count: i32,
};

pub const table_cache_hdr_t = opaque {};

pub const table_cache_iter_t = extern struct {
    cur: ?*table_cache_hdr_t,
    next: ?*table_cache_hdr_t,
    next_list: ?*table_cache_hdr_t,
};

pub const iter_cache_t = extern struct {
    stack_cursor: stack_cursor_t,
    used: flags8_t,
    allocated: flags8_t,
};

pub const term_iter_t = extern struct {
    term: term_t,
    self_index: ?*id_record_t,
    set_index: ?*id_record_t,
    cur: ?*id_record_t,
    it: table_cache_iter_t,
    index: i32,
    observed_table_count: i32,
    table: ?*table_t,
    cur_match: i32,
    match_count: i32,
    last_column: i32,
    empty_tables: bool,
    id: id_t,
    column: i32,
    subject: entity_t,
    size: size_t,
    ptr: ?*anyopaque,
};

pub const iter_kind_t = enum(i32) {
    EvalCondition,
    EvalTables,
    EvalChain,
    EvalNone,
};

pub const filter_iter_t = extern struct {
    filter: [*c]const filter_t,
    kind: iter_kind_t,
    term_iter: term_iter_t,
    matches_left: i32,
    pivot_term: i32,
};

pub const query_iter_t = extern struct {
    query: ?*query_t,
    node: ?*query_table_node_t,
    prev: ?*query_table_node_t,
    last: ?*query_table_node_t,
    sparse_smallest: i32,
    sparse_first: i32,
    bitset_first: i32,
    skip_count: i32,
};

pub const rule_op_ctx_t = opaque {};

pub const rule_iter_t = extern struct {
    rule: ?*const rule_t,
    registers: [*c]var_t,
    op_ctx: ?*rule_op_ctx_t,
    columns: [*c]i32,
    entity: entity_t,
    redo: bool,
    op: i32,
    sp: i32,
};

pub const snapshot_iter_t = extern struct {
    filter: filter_t,
    tables: ?*vector_t,
    index: i32,
};

pub const iter_private_t = extern struct {
    iter: extern union {
        term: term_iter_t,
        filter: filter_iter_t,
        query: query_iter_t,
        rule: rule_iter_t,
        snapshot: snapshot_iter_t,
        page: page_iter_t,
        worker: worker_iter_t,
    },
    entity_iter: ?*anyopaque,
    cache: iter_cache_t,
};

pub const iter_t = extern struct {
    world: *world_t,
    real_world: *world_t,
    entities: ?[*]entity_t,
    ptrs: ?[*]*anyopaque,
    sizes: ?[*]size_t,
    table: ?*table_t,
    other_table: ?*table_t,
    ids: ?[*]id_t,
    variables: ?[*]var_t,
    columns: ?[*]i32,
    sources: ?[*]entity_t,
    match_indices: ?[*]i32,
    references: ?[*]ref_t,
    constrained_vars: flags64_t,
    group_id: u64,
    field_count: i32,
    system: entity_t,
    event: entity_t,
    event_id: id_t,
    terms: ?[*]term_t,
    table_count: i32,
    term_index: i32,
    variable_count: i32,
    variable_names: ?[*][*:0]u8,
    param: ?*anyopaque,
    ctx: ?*anyopaque,
    binding_ctx: ?*anyopaque,
    delta_time: f32,
    delta_system_time: f32,
    frame_offset: i32,
    offset: i32,
    count: i32,
    instance_count: i32,
    flags: flags32_t,
    interrupted_by: entity_t,
    priv: iter_private_t,
    next: iter_next_action_t,
    callback: iter_action_t,
    fini: iter_fini_action_t,
    chain_it: ?*iter_t,

    pub fn get_entities(iter: iter_t) ?[]entity_t {
        if (iter.entities) |ptr| {
            return ptr[0..@intCast(usize, iter.count)];
        }
        return null;
    }
};
//--------------------------------------------------------------------------------------------------
//
// allocator_t, vec_t, map_t
//
//--------------------------------------------------------------------------------------------------
pub const vec_t = extern struct {
    array: ?*anyopaque,
    count: i32,
    size: i32,
    elem_size: size_t,
};

pub const sparse_t = extern struct {
    dense: vec_t,
    pages: vec_t,
    size: size_t,
    count: i32,
    max_id_local: u64,
    max_id: [*c]u64,
    allocator: [*c]allocator_t,
    page_allocator: [*c]block_allocator_t,
};

pub const block_allocator_chunk_header_t = extern struct {
    next: ?*block_allocator_chunk_header_t,
};

pub const block_allocator_block_t = extern struct {
    memory: ?*anyopaque,
    next: ?*block_allocator_block_t,
};

pub const block_allocator_t = extern struct {
    head: ?*block_allocator_chunk_header_t,
    block_head: ?*block_allocator_block_t,
    block_tail: ?*block_allocator_block_t,
    chunk_size: i32,
    data_size: i32,
    chunks_per_block: i32,
    block_size: i32,
    alloc_count: i32,
};

pub const allocator_t = extern struct {
    chunks: block_allocator_t,
    sizes: sparse_t,
};

pub const map_data_t = u64;
pub const map_key_t = map_data_t;
pub const map_val_t = map_data_t;

pub const bucket_entry_t = extern struct {
    key: map_key_t,
    value: map_val_t,
    next: [*c]bucket_entry_t,
};

pub const bucket_t = extern struct {
    first: [*c]bucket_entry_t,
};

pub const map_t = extern struct {
    bucket_shift: u8,
    shared_allocator: bool,
    buckets: [*c]bucket_t,
    bucket_count: i32,
    count: i32,
    entry_allocator: [*c]block_allocator_t,
    allocator: [*c]allocator_t,
};

pub const map_iter_t = extern struct {
    map: [*c]const map_t,
    bucket: [*c]bucket_t,
    entry: [*c]bucket_entry_t,
    res: [*c]map_data_t,
};

pub const map_params_t = extern struct {
    allocator: [*c]allocator_t,
    entry_allocator: block_allocator_t,
};
//--------------------------------------------------------------------------------------------------
pub const query_desc_t = extern struct {
    _canary: i32 = 0,
    filter: filter_desc_t = .{},
    order_by_component: entity_t = 0,
    order_by: ?order_by_action_t = null,
    sort_table: ?sort_table_action_t = null,
    group_by_id: id_t = 0,
    group_by: ?group_by_action_t = null,
    on_group_create: ?group_create_action_t = null,
    on_group_delete: ?group_delete_action_t = null,
    group_by_ctx: ?*anyopaque = null,
    group_by_ctx_free: ?ctx_free_t = null,
    parent: ?*query_t = null,
};

pub const component_desc_t = extern struct {
    _canary: i32 = 0,
    entity: entity_t,
    type: type_info_t,
};

pub const ID_CACHE_SIZE = 32;

pub const entity_desc_t = extern struct {
    _canary: i32 = 0,
    id: entity_t = 0,
    name: ?[*:0]const u8 = null,
    sep: ?[*:0]const u8 = null,
    root_sep: ?[*:0]const u8 = null,
    symbol: ?[*:0]const u8 = null,
    use_low_id: bool = false,
    add: [ID_CACHE_SIZE]id_t = [_]id_t{0} ** ID_CACHE_SIZE,
    add_expr: ?[*:0]const u8 = null,
};

pub const TERM_DESC_CACHE_SIZE = 16;

pub const filter_desc_t = extern struct {
    _canary: i32 = 0,
    terms: [TERM_DESC_CACHE_SIZE]term_t = [_]term_t{.{}} ** TERM_DESC_CACHE_SIZE,
    terms_buffer: ?[*]term_t = null,
    terms_buffer_count: i32 = 0,
    storage: ?*filter_t = null,
    instanced: bool = false,
    flags: flags32_t = 0,
    expr: ?[*:0]const u8 = null,
    entity: entity_t = 0,
};

pub const OBSERVER_DESC_EVENT_COUNT_MAX = 8;

pub const observer_desc_t = extern struct {
    _canary: i32 = 0,
    entity: entity_t = 0,
    filter: filter_desc_t = .{},
    events: [OBSERVER_DESC_EVENT_COUNT_MAX]entity_t = [_]entity_t{0} ** OBSERVER_DESC_EVENT_COUNT_MAX,
    yield_existing: bool = false,
    callback: iter_action_t,
    run: ?run_action_t = null,
    ctx: ?*anyopaque = null,
    binding_ctx: ?*anyopaque = null,
    ctx_free: ?ctx_free_t = null,
    binding_ctx_free: ?ctx_free_t = null,
    observable: ?*poly_t = null,
    last_event_id: ?*i32 = null,
    term_index: i32 = 0,
};

pub const world_info_t = extern struct {
    last_component_id: entity_t,
    last_id: entity_t,
    min_id: entity_t,
    max_id: entity_t,
    delta_time_raw: f32,
    delta_time: f32,
    time_scale: f32,
    target_fps: f32,
    frame_time_total: f32,
    system_time_total: f32,
    emit_time_total: f32,
    merge_time_total: f32,
    world_time_total: f32,
    world_time_total_raw: f32,
    rematch_time_total: f32,
    frame_count_total: i64,
    merge_count_total: i64,
    rematch_count_total: i64,
    id_create_total: i64,
    id_delete_total: i64,
    table_create_total: i64,
    table_delete_total: i64,
    pipeline_build_count_total: i64,
    systems_ran_frame: i64,
    observers_ran_frame: i64,
    id_count: i32,
    tag_id_count: i32,
    component_id_count: i32,
    pair_id_count: i32,
    wildcard_id_count: i32,
    table_count: i32,
    tag_table_count: i32,
    trivial_table_count: i32,
    empty_table_count: i32,
    table_record_count: i32,
    table_storage_count: i32,
    cmd: extern struct {
        add_count: i64,
        remove_count: i64,
        delete_count: i64,
        clear_count: i64,
        set_count: i64,
        get_mut_count: i64,
        modified_count: i64,
        other_count: i64,
        discard_count: i64,
        batched_entity_count: i64,
        batched_command_count: i64,
    },
    name_prefix: [*:0]const u8,
};
//--------------------------------------------------------------------------------------------------
//
// Creation & Deletion
//
//--------------------------------------------------------------------------------------------------
pub fn init() *world_t {
    assert(num_worlds == 0);
    num_worlds += 1;
    component_ids_hm.ensureTotalCapacity(32) catch @panic("OOM");
    return ecs_init();
}
extern fn ecs_init() *world_t;

pub fn fini(world: *world_t) i32 {
    assert(num_worlds == 1);
    num_worlds -= 1;

    var it = component_ids_hm.iterator();
    while (it.next()) |kv| {
        const ptr = kv.key_ptr.*;
        ptr.* = 0;
    }
    component_ids_hm.clearRetainingCapacity();

    return ecs_fini(world);
}
extern fn ecs_fini(world: *world_t) i32;

/// `pub fn is_fini(world: *const world_t) bool`
pub const is_fini = ecs_is_fini;
extern fn ecs_is_fini(world: *const world_t) bool;

/// `pub fn atfini(world: *world_t, action: fini_action_t, ctx: ?*anyopaque) bool`
pub const atfini = ecs_atfini;
extern fn ecs_atfini(world: *world_t, action: fini_action_t, ctx: ?*anyopaque) bool;
//--------------------------------------------------------------------------------------------------
//
// Frame functions
//
//--------------------------------------------------------------------------------------------------
/// `pub fn frame_begin(world: *world_t, delta_time: ftime_t) ftime_t`
pub const frame_begin = ecs_frame_begin;
extern fn ecs_frame_begin(world: *world_t, delta_time: ftime_t) ftime_t;

/// `pub fn frame_end(world: *world_t) void`
pub const frame_end = ecs_frame_end;
extern fn ecs_frame_end(world: *world_t) void;

/// `pub fn run_post_frame(world: *world_t, action: fini_action_t, ctx: ?*anyopaque) void`
pub const run_post_frame = ecs_run_post_frame;
extern fn ecs_run_post_frame(world: *world_t, action: fini_action_t, ctx: ?*anyopaque) void;

/// `pub fn quit(world: *world_t) void`
pub const quit = ecs_quit;
extern fn ecs_quit(world: *world_t) void;

/// `pub fn should_quit(world: *const world_t) bool`
pub const should_quit = ecs_should_quit;
extern fn ecs_should_quit(world: *const world_t) bool;

/// `pub fn measure_frame_time(world: *world_t, enable: bool) void`
pub const measure_frame_time = ecs_measure_frame_time;
extern fn ecs_measure_frame_time(world: *world_t, enable: bool) void;

/// `pub fn measure_system_time(world: *world_t, enable: bool) void`
pub const measure_system_time = ecs_measure_system_time;
extern fn ecs_measure_system_time(world: *world_t, enable: bool) void;

/// `pub fn set_target_fps(world: *world_t, fps: ftime_t) void`
pub const set_target_fps = ecs_set_target_fps;
extern fn ecs_set_target_fps(world: *world_t, fps: ftime_t) void;
//--------------------------------------------------------------------------------------------------
//
// Commands
//
//--------------------------------------------------------------------------------------------------
/// `pub fn readonly_begin(world: *world_t) bool`
pub const readonly_begin = ecs_readonly_begin;
extern fn ecs_readonly_begin(world: *world_t) bool;

/// `pub fn readonly_end(world: *world_t) void`
pub const readonly_end = ecs_readonly_end;
extern fn ecs_readonly_end(world: *world_t) void;

/// `pub fn merge(world: *world_t) void`
pub const merge = ecs_merge;
extern fn ecs_merge(world: *world_t) void;

/// `pub fn defer_begin(world: *world_t) bool`
pub const defer_begin = ecs_defer_begin;
extern fn ecs_defer_begin(world: *world_t) bool;

/// `pub fn is_deferred(world: *const world_t) bool`
pub const is_deferred = ecs_is_deferred;
extern fn ecs_is_deferred(world: *const world_t) bool;

/// `pub fn defer_end(world: *world_t) bool`
pub const defer_end = ecs_defer_end;
extern fn ecs_defer_end(world: *world_t) bool;

/// `pub fn defer_suspend(world: *world_t) void`
pub const defer_suspend = ecs_defer_suspend;
extern fn ecs_defer_suspend(world: *world_t) void;

/// `pub fn defer_resume(world: *world_t) void`
pub const defer_resume = ecs_defer_resume;
extern fn ecs_defer_resume(world: *world_t) void;

/// `pub fn set_automerge(world: *world_t, automerge: bool) void`
pub const set_automerge = ecs_set_automerge;
extern fn ecs_set_automerge(world: *world_t, automerge: bool) void;

/// `pub fn set_stage_count(world: *world_t, stages: i32) void`
pub const set_stage_count = ecs_set_stage_count;
extern fn ecs_set_stage_count(world: *world_t, stages: i32) void;

/// `pub fn get_stage_count(world: *const world_t) i32`
pub const get_stage_count = ecs_get_stage_count;
extern fn ecs_get_stage_count(world: *const world_t) i32;

/// `pub fn get_stage_id(world: *const world_t) i32`
pub const get_stage_id = ecs_get_stage_id;
extern fn ecs_get_stage_id(world: *const world_t) i32;

/// `pub fn get_stage(world: *const world_t, stage_id: i32) *world_t`
pub const get_stage = ecs_get_stage;
extern fn ecs_get_stage(world: *const world_t, stage_id: i32) *world_t;

/// `pub fn stage_is_readonly(world: *const world_t) bool`
pub const stage_is_readonly = ecs_stage_is_readonly;
extern fn ecs_stage_is_readonly(world: *const world_t) bool;

/// `pub fn async_stage_new(world: *world_t) *world_t`
pub const async_stage_new = ecs_async_stage_new;
extern fn ecs_async_stage_new(world: *world_t) *world_t;

/// `pub fn async_stage_free(world: *world_t) *world_t`
pub const async_stage_free = ecs_async_stage_free;
extern fn ecs_async_stage_free(world: *world_t) *world_t;

/// `pub fn stage_is_async(world: *const world_t) bool`
pub const stage_is_async = ecs_stage_is_async;
extern fn ecs_stage_is_async(world: *const world_t) bool;
//--------------------------------------------------------------------------------------------------
//
// Misc
//
//--------------------------------------------------------------------------------------------------
/// `pub fn set_context(world: *world_t, ctx: ?*anyopaque) void`
pub const set_context = ecs_set_context;
extern fn ecs_set_context(world: *world_t, ctx: ?*anyopaque) void;

/// `pub fn get_context(world: *const world_t) ?*anyopaque`
pub const get_context = ecs_get_context;
extern fn ecs_get_context(world: *const world_t) ?*anyopaque;

/// `pub fn ecs_get_world_info(world: *const world_t) *const world_info_t`
pub const get_world_info = ecs_get_world_info;
extern fn ecs_get_world_info(world: *const world_t) *const world_info_t;

/// `pub fn dim(world: *world_t, entity_count: i32) void`
pub const dim = ecs_dim;
extern fn ecs_dim(world: *world_t, entity_count: i32) void;

/// `pub fn set_entity_range(world: *world_t, id_start: entity_t, id_end: entity_t) void`
pub const set_entity_range = ecs_set_entity_range;
extern fn ecs_set_entity_range(world: *world_t, id_start: entity_t, id_end: entity_t) void;

/// `pub fn enable_range_check(world: *world_t, enable: bool) bool`
pub const enable_range_check = ecs_enable_range_check;
extern fn ecs_enable_range_check(world: *world_t, enable: bool) bool;

/// `pub fn run_aperiodic(world: *world_t, flags: flags32_t) void`
pub const run_aperiodic = ecs_run_aperiodic;
extern fn ecs_run_aperiodic(world: *world_t, flags: flags32_t) void;

/// ```
/// pub fn delete_empty_tables(
///     world: *world_t,
///     id: id_t,
///     clear_generation: u16,
///     delete_generation: u16,
///     min_id_count: i32,
///     time_budget_seconds: f64,
/// ) i32;
/// ```
pub const delete_empty_tables = ecs_delete_empty_tables;
extern fn ecs_delete_empty_tables(
    world: *world_t,
    id: id_t,
    clear_generation: u16,
    delete_generation: u16,
    min_id_count: i32,
    time_budget_seconds: f64,
) i32;

/// `pub fn make_pair(first: entity_t, second: entity_t) id_t`
pub const make_pair = ecs_make_pair;
extern fn ecs_make_pair(first: entity_t, second: entity_t) id_t;
//--------------------------------------------------------------------------------------------------
//
// Functions for creating and deleting entities.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn new_id(world: *world_t) entity_t`
pub const new_id = ecs_new_id;
extern fn ecs_new_id(world: *world_t) entity_t;

/// `pub fn new_low_id(world: *world_t) entity_t`
pub const new_low_id = ecs_new_low_id;
extern fn ecs_new_low_id(world: *world_t) entity_t;

/// `pub fn new_w_id(world: *world_t, id: id_t) entity_t`
pub const new_w_id = ecs_new_w_id;
extern fn ecs_new_w_id(world: *world_t, id: id_t) entity_t;

/// `pub fn new_w_table(world: *world_t, table: *table_t) entity_t`
pub const new_w_table = ecs_new_w_table;
extern fn ecs_new_w_table(world: *world_t, table: *table_t) entity_t;

/// `pub fn entity_init(world: *world_t, desc: *const entity_desc_t) entity_t`
pub const entity_init = ecs_entity_init;
extern fn ecs_entity_init(world: *world_t, desc: *const entity_desc_t) entity_t;

/// `pub fn bulk_new_w_id(world: *world_t, id: id_t, count: i32) [*]const entity_t`
pub const bulk_new_w_id = ecs_bulk_new_w_id;
extern fn ecs_bulk_new_w_id(world: *world_t, id: id_t, count: i32) [*]const entity_t;

/// `pub fn clone(world: *world_t, dst: entity_t, src: entity_t, copy_value: bool) entity_t`
pub const clone = ecs_clone;
extern fn ecs_clone(world: *world_t, dst: entity_t, src: entity_t, copy_value: bool) entity_t;

/// `pub fn delete(world: *world_t, entity: entity_t) void`
pub const delete = ecs_delete;
extern fn ecs_delete(world: *world_t, entity: entity_t) void;

/// `pub fn delete_with(world: *world_t, id: id_t) void`
pub const delete_with = ecs_delete_with;
extern fn ecs_delete_with(world: *world_t, id: id_t) void;
//--------------------------------------------------------------------------------------------------
//
// Functions for adding and removing components.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn add_id(world: *world_t, entity: entity_t, id: id_t) void`
pub const add_id = ecs_add_id;
extern fn ecs_add_id(world: *world_t, entity: entity_t, id: id_t) void;

/// `pub fn remove_id(world: *world_t, entity: entity_t, id: id_t) void`
pub const remove_id = ecs_remove_id;
extern fn ecs_remove_id(world: *world_t, entity: entity_t, id: id_t) void;

/// `pub fn override_id(world: *world_t, entity: entity_t, id: id_t) void`
pub const override_id = ecs_remove_id;
extern fn ecs_override_id(world: *world_t, entity: entity_t, id: id_t) void;

/// `pub fn clear(world: *world_t, entity: entity_t) void`
pub const clear = ecs_clear;
extern fn ecs_clear(world: *world_t, entity: entity_t) void;

/// `pub fn remove_all(world: *world_t, id: id_t) void`
pub const remove_all = ecs_remove_all;
extern fn ecs_remove_all(world: *world_t, id: id_t) void;

/// `pub fn set_with(world: *world_t, id: id_t) void`
pub const set_with = ecs_set_with;
extern fn ecs_set_with(world: *world_t, id: id_t) id_t;

/// `pub fn get_with(world: *const world_t) id_t`
pub const get_with = ecs_get_with;
extern fn ecs_get_with(world: *const world_t) id_t;
//--------------------------------------------------------------------------------------------------
//
// Functions for enabling/disabling entities and components.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn enable(world: *const world_t, entity: entity_t, enable: bool) void`
pub const enable = ecs_enable;
extern fn ecs_enable(world: *world_t, entity: entity_t, enable: bool) void;

/// `pub fn enable_id(world: *const world_t, entity: entity_t, id: id_t, enable: bool) void`
pub const enable_id = ecs_enable_id;
extern fn ecs_enable_id(world: *world_t, entity: entity_t, id: id_t, enable: bool) void;

/// `pub fn is_enabled_id(world: *const world_t, entity: entity_t, id: id_t) bool`
pub const is_enabled_id = ecs_is_enabled_id;
extern fn ecs_is_enabled_id(world: *const world_t, entity: entity_t, id: id_t) bool;
//--------------------------------------------------------------------------------------------------
//
// Functions for getting/setting components.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn get_id(world: *const world_t, entity: entity_t, id: id_t) ?*const anyopaque`
pub const get_id = ecs_get_id;
extern fn ecs_get_id(world: *const world_t, entity: entity_t, id: id_t) ?*const anyopaque;

/// `pub fn ref_init_id(world: *const world_t, entity: entity_t, id: id_t) ref_t`
pub const ref_init_id = ecs_ref_init_id;
extern fn ecs_ref_init_id(world: *const world_t, entity: entity_t, id: id_t) ref_t;

/// `pub fn ref_get_id(world: *const world_t, ref: *ref_t, id: id_t) ?*anyopaque`
pub const ref_get_id = ecs_ref_get_id;
extern fn ecs_ref_get_id(world: *const world_t, ref: *ref_t, id: id_t) ?*anyopaque;

/// `pub fn ref_get_id(world: *const world_t, ref: *ref_t) void`
pub const ref_update = ecs_ref_update;
extern fn ecs_ref_update(world: *const world_t, ref: *ref_t) void;

/// `pub fn get_mut_id(world: *world_t, entity: entity_t, id: id_t) ?*anyopaque`
pub const get_mut_id = ecs_get_mut_id;
extern fn ecs_get_mut_id(world: *world_t, entity: entity_t, id: id_t) ?*anyopaque;

/// `pub fn write_begin(world: *world_t, entity: entity_t) ?*record_t`
pub const write_begin = ecs_write_begin;
extern fn ecs_write_begin(world: *world_t, entity: entity_t) ?*record_t;

/// `pub fn write_end(record: *record_t) void`
pub const write_end = ecs_write_end;
extern fn ecs_write_end(record: *record_t) void;

/// `pub fn read_begin(world: *world_t, entity: entity_t) ?*const record_t`
pub const read_begin = ecs_read_begin;
extern fn ecs_read_begin(world: *world_t, entity: entity_t) ?*const record_t;

/// `pub fn read_end(record: *const record_t) void`
pub const read_end = ecs_read_end;
extern fn ecs_read_end(record: *const record_t) void;

/// `pub fn record_get_id(world: *world_t, record: *const record_t, id: id_t) ?*const anyopaque`
pub const record_get_id = ecs_record_get_id;
extern fn ecs_record_get_id(world: *world_t, record: *const record_t, id: id_t) ?*const anyopaque;

/// `pub fn record_get_mut_id(world: *world_t, record: *record_t, id: id_t) ?*anyopaque`
pub const record_get_mut_id = ecs_record_get_mut_id;
extern fn ecs_record_get_mut_id(world: *world_t, record: *record_t, id: id_t) ?*anyopaque;

/// `pub fn emplace_id(world: *world_t, entity: entity_t, id: id_t) ?*anyopaque`
pub const emplace_id = ecs_emplace_id;
extern fn ecs_emplace_id(world: *world_t, entity: entity_t, id: id_t) ?*anyopaque;

/// `pub fn modified_id(world: *world_t, entity: entity_t, id: id_t) void`
pub const modified_id = ecs_modified_id;
extern fn ecs_modified_id(world: *world_t, entity: entity_t, id: id_t) void;

/// `pub fn set_id(world: *world_t, entity: entity_t, id: id_t, size: usize, ptr: ?*const anyopaque) entity_t`
pub const set_id = ecs_set_id;
extern fn ecs_set_id(world: *world_t, entity: entity_t, id: id_t, size: usize, ptr: ?*const anyopaque) entity_t;
//--------------------------------------------------------------------------------------------------
//
// Functions for testing and modifying entity liveliness.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn is_valid(world: *const world_t, entity: entity_t) bool`
pub const is_valid = ecs_is_valid;
extern fn ecs_is_valid(world: *const world_t, entity: entity_t) bool;

/// `pub fn is_alive(world: *const world_t, entity: entity_t) bool`
pub const is_alive = ecs_is_alive;
extern fn ecs_is_alive(world: *const world_t, entity: entity_t) bool;

/// `pub fn strip_generation(entity: entity_t) id_t`
pub const strip_generation = ecs_strip_generation;
extern fn ecs_strip_generation(entity: entity_t) id_t;

/// `pub fn set_entity_generation(world: *world_t, entity: entity_t) void`
pub const set_entity_generation = ecs_set_entity_generation;
extern fn ecs_set_entity_generation(world: *world_t, entity: entity_t) void;

/// `pub fn get_alive(world: *const world_t, entity: entity_t) entity_t`
pub const get_alive = ecs_get_alive;
extern fn ecs_get_alive(world: *const world_t, entity: entity_t) entity_t;

/// `pub fn ensure(world: *world_t, entity: entity_t) void`
pub const ensure = ecs_ensure;
extern fn ecs_ensure(world: *world_t, entity: entity_t) void;

/// `pub fn ensure_id(world: *world_t, id: id_t) void`
pub const ensure_id = ecs_ensure_id;
extern fn ecs_ensure_id(world: *world_t, id: id_t) void;

/// `pub fn exists(world: *const world_t, entity: entity_t) bool`
pub const exists = ecs_exists;
extern fn ecs_exists(world: *const world_t, entity: entity_t) bool;
//--------------------------------------------------------------------------------------------------
//
// Get information from entity.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn get_type(world: *const world_t, entity: entity_t) ?*const type_t`
pub const get_type = ecs_get_type;
extern fn ecs_get_type(world: *const world_t, entity: entity_t) ?*const type_t;

/// `pub fn get_table(world: *const world_t, entity: entity_t) ?*const table_t`
pub const get_table = ecs_get_table;
extern fn ecs_get_table(world: *const world_t, entity: entity_t) ?*const table_t;

/// `pub fn type_str(world: *const world_t, type: ?*const type_t) [*:0]u8`
pub const type_str = ecs_type_str;
extern fn ecs_type_str(world: *const world_t, type: ?*const type_t) [*:0]u8;

/// `pub fn table_str(world: *const world_t, table: ?*const table_t) ?[*:0]u8`
pub const table_str = ecs_table_str;
extern fn ecs_table_str(world: *const world_t, table: ?*const table_t) ?[*:0]u8;

/// `pub fn entity_str(world: *const world_t, entity: entity_t) ?[*:0]u8`
pub const entity_str = ecs_entity_str;
extern fn ecs_entity_str(world: *const world_t, entity: entity_t) ?[*:0]u8;

/// `pub fn has_id(world: *const world_t, entity: entity_t, id: id_t) bool`
pub const has_id = ecs_has_id;
extern fn ecs_has_id(world: *const world_t, entity: entity_t, id: id_t) bool;

/// `pub fn get_target(world: *const world_t, entity: entity_t, rel: entity_t, index: i32) entity_t`
pub const get_target = ecs_get_target;
extern fn ecs_get_target(world: *const world_t, entity: entity_t, rel: entity_t, index: i32) entity_t;

/// `pub fn get_target_for_id(world: *const world_t, entity: entity_t, rel: entity_t, id: id_t) entity_t`
pub const get_target_for_id = ecs_get_target_for_id;
extern fn ecs_get_target_for_id(world: *const world_t, entity: entity_t, rel: entity_t, id: id_t) entity_t;

/// `pub fn get_depth(world: *const world_t, entity: entity_t, rel: entity_t) i32`
pub const get_depth = ecs_get_depth;
extern fn ecs_get_depth(world: *const world_t, entity: entity_t, rel: entity_t) i32;

/// `pub fn count_id(world: *const world_t, entity: entity_t) i32`
pub const count_id = ecs_count_id;
extern fn ecs_count_id(world: *const world_t, entity: entity_t) i32;
//--------------------------------------------------------------------------------------------------
//
// Functions for working with entity names and paths.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn get_name(world: *const world_t, entity: entity_t) ?[*:0]const u8`
pub const get_name = ecs_get_name;
extern fn ecs_get_name(world: *const world_t, entity: entity_t) ?[*:0]const u8;

/// `pub fn get_symbol(world: *const world_t, entity: entity_t) ?[*:0]const u8`
pub const get_symbol = ecs_get_symbol;
extern fn ecs_get_symbol(world: *const world_t, entity: entity_t) ?[*:0]const u8;

/// `pub fn set_name(world: *world_t, entity: entity_t, name: ?[*:0]const u8) entity_t`
pub const set_name = ecs_set_name;
extern fn ecs_set_name(world: *world_t, entity: entity_t, name: ?[*:0]const u8) entity_t;

/// `pub fn set_symbol(world: *world_t, entity: entity_t, name: ?[*:0]const u8) entity_t`
pub const set_symbol = ecs_set_symbol;
extern fn ecs_set_symbol(world: *world_t, entity: entity_t, name: ?[*:0]const u8) entity_t;

/// `pub fn set_alias(world: *world_t, entity: entity_t, name: ?[*:0]const u8) void`
pub const set_alias = ecs_set_alias;
extern fn ecs_set_alias(world: *world_t, entity: entity_t, name: ?[*:0]const u8) void;

/// `pub fn lookup(world: *const world_t, name: ?[*:0]const u8) entity_t`
pub const lookup = ecs_lookup;
extern fn ecs_lookup(world: *const world_t, name: ?[*:0]const u8) entity_t;

/// `pub fn lookup_child(world: *const world_t, parent: entity_t, name: ?[*:0]const u8) entity_t`
pub const lookup_child = ecs_lookup_child;
extern fn ecs_lookup_child(world: *const world_t, parent: entity_t, name: ?[*:0]const u8) entity_t;

/// ```
/// pub fn lookup_path_w_sep(
///     world: *const world_t,
///     parent: entity_t,
///     path: ?[*:0]const u8,
///     sep: ?[*:0]const u8,
///     prefix: ?[*:0]const u8,
///    recursive: bool,
/// ) entity_t;
/// ```
pub const lookup_path_w_sep = ecs_lookup_path_w_sep;
extern fn ecs_lookup_path_w_sep(
    world: *const world_t,
    parent: entity_t,
    path: ?[*:0]const u8,
    sep: ?[*:0]const u8,
    prefix: ?[*:0]const u8,
    recursive: bool,
) entity_t;

/// `pub fn lookup_symbol(world: *const world_t, symbol: ?[*:0]const u8, lookup_as_path: bool) entity_t`
pub const lookup_symbol = ecs_lookup_symbol;
extern fn ecs_lookup_symbol(world: *const world_t, symbol: ?[*:0]const u8, lookup_as_path: bool) entity_t;

/// ```
/// pub fn ecs_get_path_w_sep(
///     world: *const world_t,
///     parent: entity_t,
///     child: entity_t,
///     sep: ?[*:0]const u8,
///     prefix: ?[*:0]const u8,
/// ) ?[*]u8;
/// ```
pub const get_path_w_sep = ecs_get_path_w_sep;
extern fn ecs_get_path_w_sep(
    world: *const world_t,
    parent: entity_t,
    child: entity_t,
    sep: ?[*:0]const u8,
    prefix: ?[*:0]const u8,
) ?[*]u8;

/// ```
/// pub fn ecs_new_from_path_w_sep(
///     world: *world_t,
///     parent: entity_t,
///     path: ?[*:0]const u8,
///     sep: ?[*:0]const u8,
///     prefix: ?[*:0]const u8,
/// ) entity_t;
/// ```
pub const new_from_path_w_sep = ecs_new_from_path_w_sep;
extern fn ecs_new_from_path_w_sep(
    world: *world_t,
    parent: entity_t,
    path: ?[*:0]const u8,
    sep: ?[*:0]const u8,
    prefix: ?[*:0]const u8,
) entity_t;

/// ```
/// pub fn ecs_add_path_w_sep(
///     world: *world_t,
///     entity: entity_t,
///     parent: entity_t,
///     path: ?[*:0]const u8,
///     sep: ?[*:0]const u8,
///     prefix: ?[*:0]const u8,
/// ) entity_t;
/// ```
pub const add_path_w_sep = ecs_add_path_w_sep;
extern fn ecs_add_path_w_sep(
    world: *world_t,
    entity: entity_t,
    parent: entity_t,
    path: ?[*:0]const u8,
    sep: ?[*:0]const u8,
    prefix: ?[*:0]const u8,
) entity_t;

/// `pub fn set_scope(world: *world_t, scope: entity_t) entity_t`
pub const set_scope = ecs_set_scope;
extern fn ecs_set_scope(world: *world_t, scope: entity_t) entity_t;

/// `pub fn get_scope(world: *const world_t) entity_t`
pub const get_scope = ecs_get_scope;
extern fn ecs_get_scope(world: *const world_t) entity_t;

/// `pub fn set_name_prefix(world: *world_t, prefix: ?[*:0]const u8) ?[*:0]const u8`
pub const set_name_prefix = ecs_set_name_prefix;
extern fn ecs_set_name_prefix(world: *world_t, prefix: ?[*:0]const u8) ?[*:0]const u8;

/// `pub fn set_lookup_path(world: *world_t, lookup_path: ?[*]const entity_t) ?[*]entity_t`
pub const set_lookup_path = ecs_set_lookup_path;
extern fn ecs_set_lookup_path(world: *world_t, lookup_path: ?[*]const entity_t) ?[*]entity_t;

/// `pub fn get_lookup_path(world: *const world_t) ?[*]entity_t`
pub const get_lookup_path = ecs_get_lookup_path;
extern fn ecs_get_lookup_path(world: *const world_t) ?[*]entity_t;
//--------------------------------------------------------------------------------------------------
//
// Functions for registering and working with components.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn component_init(world: *world_t, desc: *const component_desc_t) entity_t`
pub const component_init = ecs_component_init;
extern fn ecs_component_init(world: *world_t, desc: *const component_desc_t) entity_t;

/// `pub fn set_hooks_id(world: *world_t, id: entity_t, hooks: *const type_hooks_t) void`
pub const set_hooks_id = ecs_set_hooks_id;
extern fn ecs_set_hooks_id(world: *world_t, id: entity_t, hooks: *const type_hooks_t) void;

/// `pub fn get_hooks_id(world: *const world_t, id: entity_t) *const type_hooks_t`
pub const get_hooks_id = ecs_get_hooks_id;
extern fn ecs_get_hooks_id(world: *const world_t, id: entity_t) *const type_hooks_t;

/// `pub fn id_is_tag(world: *const world_t, id: id_t) bool;
pub const id_is_tag = ecs_id_is_tag;
extern fn ecs_id_is_tag(world: *const world_t, id: id_t) bool;

/// `pub fn id_is_union(world: *const world_t, id: id_t) bool;
pub const id_is_union = ecs_id_is_union;
extern fn ecs_id_is_union(world: *const world_t, id: id_t) bool;

/// `pub fn id_in_use(world: *const world_t, id: id_t) bool`
pub const id_in_use = ecs_id_in_use;
// TODO: flecs upstream: missing const
extern fn ecs_id_in_use(world: *const world_t, id: id_t) bool;

/// `pub fn get_type_info(world: *const world_t, id: id_t) *const type_info_t`
pub const get_type_info = ecs_get_type_info;
extern fn ecs_get_type_info(world: *const world_t, id: id_t) *const type_info_t;

/// `pub fn get_typeid(world: *const world_t, id: id_t) entity_t`
pub const get_typeid = ecs_get_typeid;
extern fn ecs_get_typeid(world: *const world_t, id: id_t) entity_t;

/// `pub fn id_match(id: id_t, pattern: id_t) bool`
pub const id_match = ecs_id_match;
extern fn ecs_id_match(id: id_t, pattern: id_t) bool;

/// `pub fn id_is_pair(id: id_t) bool`
pub const id_is_pair = ecs_id_is_pair;
extern fn ecs_id_is_pair(id: id_t) bool;

/// `pub fn id_is_wildcard(id: id_t) bool`
pub const id_is_wildcard = ecs_id_is_wildcard;
extern fn ecs_id_is_wildcard(id: id_t) bool;

/// `pub fn id_is_valid(world: *const world_t, id: id_t) bool`
pub const id_is_valid = ecs_id_is_valid;
extern fn ecs_id_is_valid(world: *const world_t, id: id_t) bool;

/// `pub fn id_get_flags(world: *const world_t, id: id_t) flags32_t`
pub const id_get_flags = ecs_id_get_flags;
extern fn ecs_id_get_flags(world: *const world_t, id: id_t) flags32_t;

/// `pub fn id_flag_str(id_flags: id_t) ?[*]const u8`
pub const id_flag_str = ecs_id_flag_str;
extern fn ecs_id_flag_str(id_flags: id_t) ?[*:0]const u8;

/// `pub fn id_str(world: *const world_t, id: id_t) ?[*]u8`
pub const id_str = ecs_id_str;
extern fn ecs_id_str(world: *const world_t, id: id_t) ?[*:0]u8;
//--------------------------------------------------------------------------------------------------
//
// Functions for working with `term_t` and `filter_t`.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn term_iter(world: *const world_t, term: *term_t) iter_t`
pub const term_iter = ecs_term_iter;
extern fn ecs_term_iter(world: *const world_t, term: *term_t) iter_t;

/// `pub fn term_chain_iter(world: *const world_t, term: *term_t) iter_t`
pub const term_chain_iter = ecs_term_chain_iter;
extern fn ecs_term_chain_iter(world: *const world_t, term: *term_t) iter_t;

/// `pub fn term_next(it: *iter_t) bool`
pub const term_next = ecs_term_next;
extern fn ecs_term_next(it: *iter_t) bool;

/// `pub fn children(world: *const world_t, parent: entity_t) iter_t`
pub const children = ecs_children;
extern fn ecs_children(world: *const world_t, parent: entity_t) iter_t;

/// `pub fn children_next(it: *iter_t) bool`
pub const children_next = ecs_children_next;
extern fn ecs_children_next(it: *iter_t) bool;

/// `pub fn term_id_is_set(id: *term_id_t) bool`
pub const term_id_is_set = ecs_term_id_is_set;
extern fn ecs_term_id_is_set(id: *term_id_t) bool;

/// `pub fn term_is_initialized(term: *const term_t) bool`
pub const term_is_initialized = ecs_term_is_initialized;
extern fn ecs_term_is_initialized(term: *const term_t) bool;

/// `pub fn term_match_this(term: *const term_t) bool`
pub const term_match_this = ecs_term_match_this;
extern fn ecs_term_match_this(term: *const term_t) bool;

/// `pub fn term_match_0(term: *const term_t) bool`
pub const term_match_0 = ecs_term_match_0;
extern fn ecs_term_match_0(term: *const term_t) bool;

/// `pub fn term_finalize(world: *const world_t, term: *term_t) i32`
pub const term_finalize = ecs_term_finalize;
extern fn ecs_term_finalize(world: *const world_t, term: *term_t) i32;

/// `pub fn term_copy(src: *const term_t) term_t`
pub const term_copy = ecs_term_copy;
extern fn ecs_term_copy(src: *const term_t) term_t;

/// `pub fn term_move(src: *term_t) term_t`
pub const term_move = ecs_term_move;
extern fn ecs_term_move(src: *term_t) term_t;

/// `pub fn term_fini(term: *term_t) void`
pub const term_fini = ecs_term_fini;
extern fn ecs_term_fini(term: *term_t) void;

pub fn filter_init(world: *world_t, desc: *const filter_desc_t) error_t!*filter_t {
    return ecs_filter_init(world, desc) orelse return make_error();
}
extern fn ecs_filter_init(world: *world_t, desc: *const filter_desc_t) ?*filter_t;

/// `pub fn filter_fini(filter: *filter_t) void`
pub const filter_fini = ecs_filter_fini;
extern fn ecs_filter_fini(filter: *filter_t) void;

/// `pub fn filter_finalize(world: *const world_t, filter: *filter_t) i32`
pub const filter_finalize = ecs_filter_finalize;
extern fn ecs_filter_finalize(world: *const world_t, filter: *filter_t) i32;

/// `pub fn filter_find_this_var(filter: *const filter_t) i32`
pub const filter_find_this_var = ecs_filter_find_this_var;
extern fn ecs_filter_find_this_var(filter: *const filter_t) i32;

/// `pub fn term_str(world: *const world_t, term: *const term_t) ?[*:0]u8`
pub const term_str = ecs_term_str;
extern fn ecs_term_str(world: *const world_t, term: *const term_t) ?[*:0]u8;

/// `pub fn filter_str(world: *const world_t, filter: *const filter_t) ?[*:0]u8`
pub const filter_str = ecs_filter_str;
extern fn ecs_filter_str(world: *const world_t, filter: *const filter_t) ?[*:0]u8;

/// `pub fn filter_iter(world: *const world_t, filter: *const filter_t) iter_t;`
pub const filter_iter = ecs_filter_iter;
extern fn ecs_filter_iter(world: *const world_t, filter: *const filter_t) iter_t;

/// `pub fn filter_chain_iter(world: *const world_t, filter: *const filter_t) iter_t`
pub const filter_chain_iter = ecs_filter_chain_iter;
extern fn ecs_filter_chain_iter(world: *const world_t, filter: *const filter_t) iter_t;

/// `pub fn filter_pivot_term(world: *const world_t, filter: *const filter_t) i32;`
pub const filter_pivot_term = ecs_filter_pivot_term;
extern fn ecs_filter_pivot_term(world: *const world_t, filter: *const filter_t) i32;

/// `pub fn filter_next(it: *iter_t) bool`
pub const filter_next = ecs_filter_next;
extern fn ecs_filter_next(it: *iter_t) bool;

/// `pub fn filter_next_instanced(it: *iter_t) bool`
pub const filter_next_instanced = ecs_filter_next_instanced;
extern fn ecs_filter_next_instanced(it: *iter_t) bool;

/// `pub fn filter_move(dst: *filter_t, src: *filter_t) void`
pub const filter_move = ecs_filter_move;
extern fn ecs_filter_move(dst: *filter_t, src: *filter_t) void;

/// `pub fn filter_copy(dst: *filter_t, src: *const filter_t) void`
pub const filter_copy = ecs_filter_copy;
extern fn ecs_filter_copy(dst: *filter_t, src: *const filter_t) void;
//--------------------------------------------------------------------------------------------------
//
// Functions for working with `query_t`.
//
//--------------------------------------------------------------------------------------------------
pub fn query_init(world: *world_t, desc: *const query_desc_t) error_t!*query_t {
    return ecs_query_init(world, desc) orelse return make_error();
}
extern fn ecs_query_init(world: *world_t, desc: *const query_desc_t) ?*query_t;

/// `pub fn query_fini(query: *query_t) void`
pub const query_fini = ecs_query_fini;
extern fn ecs_query_fini(query: *query_t) void;
//--------------------------------------------------------------------------------------------------
//
// Functions for working with events and observers.
//
//--------------------------------------------------------------------------------------------------
// TODO:
//--------------------------------------------------------------------------------------------------
//
// Functions for working with `iter_t`.
//
//--------------------------------------------------------------------------------------------------
/// `pub fn iter_poly(world: *const world_t, poly: *const poly_t, iter: [*]iter_t, filter: ?*term_t) void`
pub const iter_poly = ecs_iter_poly;
extern fn ecs_iter_poly(world: *const world_t, poly: *const poly_t, iter: [*]iter_t, filter: ?*term_t) void;

/// `pub fn iter_next(it: *iter_t) bool`
pub const iter_next = ecs_iter_next;
extern fn ecs_iter_next(it: *iter_t) bool;

/// `pub fn iter_fini(it: *iter_t) void`
pub const iter_fini = ecs_iter_fini;
extern fn ecs_iter_fini(it: *iter_t) void;

/// `pub fn iter_count(it: *iter_t) i32`
pub const iter_count = ecs_iter_count;
extern fn ecs_iter_count(it: *iter_t) i32;

/// `pub fn iter_is_true(it: *iter_t) bool`
pub const iter_is_true = ecs_iter_is_true;
extern fn ecs_iter_is_true(it: *iter_t) bool;

/// `pub fn iter_first(it: *iter_t) entity_t`
pub const iter_first = ecs_iter_first;
extern fn ecs_iter_first(it: *iter_t) entity_t;

/// `pub fn iter_set_var(it: *iter_t, var_id: i32, entity: entity_t) void`
pub const iter_set_var = ecs_iter_set_var;
extern fn ecs_iter_set_var(it: *iter_t, var_id: i32, entity: entity_t) void;

/// `pub fn iter_set_var_as_table(it: *iter_t, var_id: i32, table: *const table_t) void`
pub const iter_set_var_as_table = ecs_iter_set_var_as_table;
extern fn ecs_iter_set_var_as_table(it: *iter_t, var_id: i32, table: *const table_t) void;

/// `pub fn iter_set_var_as_range(it: *iter_t, var_id: i32, range: *const table_range_t) void`
pub const iter_set_var_as_range = ecs_iter_set_var_as_range;
extern fn ecs_iter_set_var_as_range(it: *iter_t, var_id: i32, range: *const table_range_t) void;

/// `pub fn iter_get_var(it: *iter_t, var_id: i32) entity_t`
pub const iter_get_var = ecs_iter_get_var;
extern fn ecs_iter_get_var(it: *iter_t, var_id: i32) entity_t;

/// `pub fn iter_get_var_as_table(it: *iter_t, var_id: i32) ?*table_t`
pub const iter_get_var_as_table = ecs_iter_get_var_as_table;
extern fn ecs_iter_get_var_as_table(it: *iter_t, var_id: i32) ?*table_t;

/// `pub fn iter_get_var_as_range(it: *iter_t, var_id: i32) table_range_t`
pub const iter_get_var_as_range = ecs_iter_get_var_as_range;
extern fn ecs_iter_get_var_as_range(it: *iter_t, var_id: i32) table_range_t;

/// `pub fn iter_var_is_constrained(it: *iter_t, var_id: i32) bool`
pub const iter_var_is_constrained = ecs_iter_var_is_constrained;
extern fn ecs_iter_var_is_constrained(it: *iter_t, var_id: i32) bool;

/// `pub fn page_iter(it: *const iter_t, offset: i32, limit: i32) iter_t`
pub const page_iter = ecs_page_iter;
extern fn ecs_page_iter(it: *const iter_t, offset: i32, limit: i32) iter_t;

/// `pub fn page_next(it: *iter_t) bool`
pub const page_next = ecs_page_next;
extern fn ecs_page_next(it: *iter_t) bool;

/// `pub fn worker_iter(it: *const iter_t, index: i32, count: i32) iter_t`
pub const worker_iter = ecs_worker_iter;
extern fn ecs_worker_iter(it: *const iter_t, index: i32, count: i32) iter_t;

/// `pub fn field_w_size(it: *const iter_t, size: usize, index: i32) ?*anyopaque`
pub const field_w_size = ecs_field_w_size;
extern fn ecs_field_w_size(it: *const iter_t, size: usize, index: i32) ?*anyopaque;

/// `pub fn field_is_readonly(it: *const iter_t, index: i32) bool`
pub const field_is_readonly = ecs_field_is_readonly;
extern fn ecs_field_is_readonly(it: *const iter_t, index: i32) bool;

/// `pub fn field_is_writeonly(it: *const iter_t, index: i32) bool`
pub const field_is_writeonly = ecs_field_is_writeonly;
extern fn ecs_field_is_writeonly(it: *const iter_t, index: i32) bool;

/// `pub fn field_is_set(it: *const iter_t, index: i32) bool`
pub const field_is_set = ecs_field_is_set;
extern fn ecs_field_is_set(it: *const iter_t, index: i32) bool;

/// `pub fn field_id(it: *const iter_t, index: i32) id_t`
pub const field_id = ecs_field_id;
extern fn ecs_field_id(it: *const iter_t, index: i32) id_t;

/// `pub fn field_src(it: *const iter_t, index: i32) entity_t`
pub const field_src = ecs_field_src;
extern fn ecs_field_src(it: *const iter_t, index: i32) entity_t;

/// `pub fn field_size(it: *const iter_t, index: i32) usize`
pub const field_size = ecs_field_size;
extern fn ecs_field_size(it: *const iter_t, index: i32) usize;

/// `pub fn field_is_self(it: *const iter_t, index: i32) bool`
pub const field_is_self = ecs_field_is_self;
extern fn ecs_field_is_self(it: *const iter_t, index: i32) bool;

/// `pub fn iter_str(it: *const iter_t) ?[*:0]u8`
pub const iter_str = ecs_iter_str;
extern fn ecs_iter_str(it: *const iter_t) ?[*:0]u8;
//--------------------------------------------------------------------------------------------------
//
// Functions for working with `table_t`.
//
//--------------------------------------------------------------------------------------------------
// TODO:
//--------------------------------------------------------------------------------------------------
//
// Declarative functions (ECS_* macros in flecs)
//
//--------------------------------------------------------------------------------------------------
// TODO: We support only one `world_t` at the time because type ids are stored in a global static memory.
// We need to reset those ids to zero when the world is destroyed
// (we do this in `pub fn fini(world: *world_t) i32`).
var num_worlds: u32 = 0;
var component_ids_hm = std.AutoHashMap(*id_t, u0).init(std.heap.page_allocator);

pub fn COMPONENT(world: *world_t, comptime T: type) void {
    if (@sizeOf(T) == 0)
        @compileError("Size of the type must be greater than zero");

    const type_id_ptr = perTypeGlobalVarPtr(T);
    if (type_id_ptr.* != 0)
        return;

    component_ids_hm.put(type_id_ptr, 0) catch @panic("OOM");

    type_id_ptr.* = ecs_component_init(world, &.{
        .entity = ecs_entity_init(world, &.{
            .use_low_id = true,
            .name = typeName(T),
            .symbol = typeName(T),
        }),
        .type = .{
            .alignment = @alignOf(T),
            .size = @sizeOf(T),
        },
    });
}

pub fn TAG(world: *world_t, comptime T: type) void {
    if (@sizeOf(T) != 0)
        @compileError("Size of the type must be zero");

    const type_id_ptr = perTypeGlobalVarPtr(T);
    if (type_id_ptr.* != 0)
        return;

    component_ids_hm.put(type_id_ptr, 0) catch @panic("OOM");

    type_id_ptr.* = ecs_entity_init(world, &.{ .name = typeName(T) });
}

// flecs internally reserves names like u16, u32, f32, etc. so we re-map them to uppercase to avoid collisions
pub fn typeName(comptime T: type) @TypeOf(@typeName(T)) {
    return switch (T) {
        u8 => return "U8",
        u16 => return "U16",
        u32 => return "U32",
        u64 => return "U64",
        i8 => return "I8",
        i16 => return "I16",
        i32 => return "I32",
        i64 => return "I64",
        f32 => return "F32",
        f64 => return "F64",
        else => return @typeName(T),
    };
}
//--------------------------------------------------------------------------------------------------
//
// Function wrappers (ecs_* macros in flecs)
//
//--------------------------------------------------------------------------------------------------
pub fn set(world: *world_t, entity: entity_t, comptime T: type, val: T) entity_t {
    return ecs_set_id(world, entity, id(T), @sizeOf(T), @ptrCast(*const anyopaque, &val));
}

pub fn get(world: *const world_t, entity: entity_t, comptime T: type) ?*const T {
    if (get_id(world, entity, id(T))) |ptr| {
        return cast(T, ptr);
    }
    return null;
}

pub fn add(world: *world_t, entity: entity_t, comptime T: type) void {
    ecs_add_id(world, entity, id(T));
}

pub fn remove(world: *world_t, entity: entity_t, comptime T: type) void {
    ecs_remove_id(world, entity, id(T));
}

pub fn field(it: *iter_t, comptime T: type, index: i32) ?[]T {
    if (ecs_field_w_size(it, @sizeOf(T), index)) |anyptr| {
        const ptr = @ptrCast([*]T, @alignCast(@alignOf(T), anyptr));
        return ptr[0..@intCast(usize, it.count)];
    }
    return null;
}

pub inline fn id(comptime T: type) id_t {
    return perTypeGlobalVarPtr(T).*;
}

fn cast(comptime T: type, val: ?*const anyopaque) *const T {
    return @ptrCast(*const T, @alignCast(@alignOf(T), val));
}

fn cast_mut(comptime T: type, val: ?*anyopaque) *T {
    return @ptrCast(*T, @alignCast(@alignOf(T), val));
}
//--------------------------------------------------------------------------------------------------
fn PerTypeGlobalVar(comptime _: type) type {
    return struct {
        var id: id_t = 0;
    };
}
inline fn perTypeGlobalVarPtr(comptime T: type) *id_t {
    return comptime &PerTypeGlobalVar(T).id;
}
//--------------------------------------------------------------------------------------------------
//
// OS API
//
//--------------------------------------------------------------------------------------------------
pub const time_t = extern struct {
    sec: u32,
    nanosec: u32,
};

pub const os = struct {
    pub const thread_t = usize;
    pub const cond_t = usize;
    pub const mutex_t = usize;
    pub const dl_t = usize;
    pub const sock_t = usize;
    pub const thread_id_t = u64;
    pub const proc_t = *const fn () callconv(.C) void;
    pub const api_init_t = *const fn () callconv(.C) void;
    pub const api_fini_t = *const fn () callconv(.C) void;
    pub const api_malloc_t = *const fn (size_t) callconv(.C) ?*anyopaque;
    pub const api_free_t = *const fn (?*anyopaque) callconv(.C) void;
    pub const api_realloc_t = *const fn (?*anyopaque, size_t) callconv(.C) ?*anyopaque;
    pub const api_calloc_t = *const fn (size_t) callconv(.C) ?*anyopaque;
    pub const api_strdup_t = *const fn ([*:0]const u8) callconv(.C) [*c]u8;
    pub const thread_callback_t = *const fn (?*anyopaque) callconv(.C) ?*anyopaque;
    pub const api_thread_new_t = *const fn (thread_callback_t, ?*anyopaque) callconv(.C) thread_t;
    pub const api_thread_join_t = *const fn (thread_t) callconv(.C) ?*anyopaque;
    pub const api_thread_self_t = *const fn () callconv(.C) thread_id_t;
    pub const api_ainc_t = *const fn (*i32) callconv(.C) i32;
    pub const api_lainc_t = *const fn (*i64) callconv(.C) i64;
    pub const api_mutex_new_t = *const fn () callconv(.C) mutex_t;
    pub const api_mutex_lock_t = *const fn (mutex_t) callconv(.C) void;
    pub const api_mutex_unlock_t = *const fn (mutex_t) callconv(.C) void;
    pub const api_mutex_free_t = *const fn (mutex_t) callconv(.C) void;
    pub const api_cond_new_t = *const fn () callconv(.C) cond_t;
    pub const api_cond_free_t = *const fn (cond_t) callconv(.C) void;
    pub const api_cond_signal_t = *const fn (cond_t) callconv(.C) void;
    pub const api_cond_broadcast_t = *const fn (cond_t) callconv(.C) void;
    pub const api_cond_wait_t = *const fn (cond_t, mutex_t) callconv(.C) void;
    pub const api_sleep_t = *const fn (i32, i32) callconv(.C) void;
    pub const api_enable_high_timer_resolution_t = *const fn (bool) callconv(.C) void;
    pub const api_get_time_t = *const fn (*time_t) callconv(.C) void;
    pub const api_now_t = *const fn () callconv(.C) u64;
    pub const api_log_t = *const fn (i32, [*:0]const u8, i32, [*:0]const u8) callconv(.C) void;
    pub const api_abort_t = *const fn () callconv(.C) void;
    pub const api_dlopen_t = *const fn ([*:0]const u8) callconv(.C) dl_t;
    pub const api_dlproc_t = *const fn (dl_t, [*:0]const u8) callconv(.C) proc_t;
    pub const api_dlclose_t = *const fn (dl_t) callconv(.C) void;
    pub const api_module_to_path_t = *const fn ([*:0]const u8) callconv(.C) [*:0]u8;

    const api_t = extern struct {
        init_: api_init_t,
        fini_: api_fini_t,
        malloc_: api_malloc_t,
        realloc_: api_realloc_t,
        calloc_: api_calloc_t,
        free_: api_free_t,
        strdup_: api_strdup_t,
        thread_new_: api_thread_new_t,
        thread_join_: api_thread_join_t,
        thread_self_: api_thread_self_t,
        ainc_: api_ainc_t,
        adec_: api_ainc_t,
        lainc_: api_lainc_t,
        ladec_: api_lainc_t,
        mutex_new_: api_mutex_new_t,
        mutex_free_: api_mutex_free_t,
        mutex_lock_: api_mutex_lock_t,
        mutex_unlock_: api_mutex_lock_t,
        cond_new_: api_cond_new_t,
        cond_free_: api_cond_free_t,
        cond_signal_: api_cond_signal_t,
        cond_broadcast_: api_cond_broadcast_t,
        cond_wait_: api_cond_wait_t,
        sleep_: api_sleep_t,
        now_: api_now_t,
        get_time_: api_get_time_t,
        log_: api_log_t,
        abort_: api_abort_t,
        dlopen_: api_dlopen_t,
        dlproc_: api_dlproc_t,
        dlclose_: api_dlclose_t,
        module_to_dl_: api_module_to_path_t,
        module_to_etc_: api_module_to_path_t,
        log_level_: i32,
        log_indent_: i32,
        log_last_error_: i32,
        log_last_timestamp_: i64,
        flags_: flags32_t,
    };

    extern var ecs_os_api: api_t;

    pub fn free(ptr: ?*anyopaque) void {
        ecs_os_api.free_(ptr);
    }
};
//--------------------------------------------------------------------------------------------------
comptime {
    _ = @import("tests.zig");
}
//--------------------------------------------------------------------------------------------------
