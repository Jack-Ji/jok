/// image loading
const struct__iobuf = extern struct {
    _ptr: [*c]u8,
    _cnt: c_int,
    _base: [*c]u8,
    _flag: c_int,
    _file: c_int,
    _charbuf: c_int,
    _bufsiz: c_int,
    _tmpfname: [*c]u8,
};
const FILE = struct__iobuf;
pub const stbi_uc = u8;
pub const stbi_us = c_ushort;
pub const stbi_io_callbacks = extern struct {
    read: ?fn (?*anyopaque, [*c]u8, c_int) callconv(.C) c_int,
    skip: ?fn (?*anyopaque, c_int) callconv(.C) void,
    eof: ?fn (?*anyopaque) callconv(.C) c_int,
};
pub extern fn stbi_load_from_memory(buffer: [*c]const stbi_uc, len: c_int, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_uc;
pub extern fn stbi_load_from_callbacks(clbk: [*c]const stbi_io_callbacks, user: ?*anyopaque, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_uc;
pub extern fn stbi_load(filename: [*c]const u8, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_uc;
pub extern fn stbi_load_from_file(f: [*c]FILE, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_uc;
pub extern fn stbi_load_gif_from_memory(buffer: [*c]const stbi_uc, len: c_int, delays: [*c][*c]c_int, x: [*c]c_int, y: [*c]c_int, z: [*c]c_int, comp: [*c]c_int, req_comp: c_int) [*c]stbi_uc;
pub extern fn stbi_load_16_from_memory(buffer: [*c]const stbi_uc, len: c_int, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_us;
pub extern fn stbi_load_16_from_callbacks(clbk: [*c]const stbi_io_callbacks, user: ?*anyopaque, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_us;
pub extern fn stbi_load_16(filename: [*c]const u8, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_us;
pub extern fn stbi_load_from_file_16(f: [*c]FILE, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]stbi_us;
pub extern fn stbi_loadf_from_memory(buffer: [*c]const stbi_uc, len: c_int, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]f32;
pub extern fn stbi_loadf_from_callbacks(clbk: [*c]const stbi_io_callbacks, user: ?*anyopaque, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]f32;
pub extern fn stbi_loadf(filename: [*c]const u8, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]f32;
pub extern fn stbi_loadf_from_file(f: [*c]FILE, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]f32;
pub extern fn stbi_hdr_to_ldr_gamma(gamma: f32) void;
pub extern fn stbi_hdr_to_ldr_scale(scale: f32) void;
pub extern fn stbi_ldr_to_hdr_gamma(gamma: f32) void;
pub extern fn stbi_ldr_to_hdr_scale(scale: f32) void;
pub extern fn stbi_is_hdr_from_callbacks(clbk: [*c]const stbi_io_callbacks, user: ?*anyopaque) c_int;
pub extern fn stbi_is_hdr_from_memory(buffer: [*c]const stbi_uc, len: c_int) c_int;
pub extern fn stbi_is_hdr(filename: [*c]const u8) c_int;
pub extern fn stbi_is_hdr_from_file(f: [*c]FILE) c_int;
pub extern fn stbi_failure_reason() [*c]const u8;
pub extern fn stbi_image_free(retval_from_stbi_load: ?*const anyopaque) void;
pub extern fn stbi_info_from_memory(buffer: [*c]const stbi_uc, len: c_int, x: [*c]c_int, y: [*c]c_int, comp: [*c]c_int) c_int;
pub extern fn stbi_info_from_callbacks(clbk: [*c]const stbi_io_callbacks, user: ?*anyopaque, x: [*c]c_int, y: [*c]c_int, comp: [*c]c_int) c_int;
pub extern fn stbi_is_16_bit_from_memory(buffer: [*c]const stbi_uc, len: c_int) c_int;
pub extern fn stbi_is_16_bit_from_callbacks(clbk: [*c]const stbi_io_callbacks, user: ?*anyopaque) c_int;
pub extern fn stbi_info(filename: [*c]const u8, x: [*c]c_int, y: [*c]c_int, comp: [*c]c_int) c_int;
pub extern fn stbi_info_from_file(f: [*c]FILE, x: [*c]c_int, y: [*c]c_int, comp: [*c]c_int) c_int;
pub extern fn stbi_is_16_bit(filename: [*c]const u8) c_int;
pub extern fn stbi_is_16_bit_from_file(f: [*c]FILE) c_int;
pub extern fn stbi_set_unpremultiply_on_load(flag_true_if_should_unpremultiply: c_int) void;
pub extern fn stbi_convert_iphone_png_to_rgb(flag_true_if_should_convert: c_int) void;
pub extern fn stbi_set_flip_vertically_on_load(flag_true_if_should_flip: c_int) void;
pub extern fn stbi_set_flip_vertically_on_load_thread(flag_true_if_should_flip: c_int) void;
pub extern fn stbi_zlib_decode_malloc_guesssize(buffer: [*c]const u8, len: c_int, initial_size: c_int, outlen: [*c]c_int) [*c]u8;
pub extern fn stbi_zlib_decode_malloc_guesssize_headerflag(buffer: [*c]const u8, len: c_int, initial_size: c_int, outlen: [*c]c_int, parse_header: c_int) [*c]u8;
pub extern fn stbi_zlib_decode_malloc(buffer: [*c]const u8, len: c_int, outlen: [*c]c_int) [*c]u8;
pub extern fn stbi_zlib_decode_buffer(obuffer: [*c]u8, olen: c_int, ibuffer: [*c]const u8, ilen: c_int) c_int;
pub extern fn stbi_zlib_decode_noheader_malloc(buffer: [*c]const u8, len: c_int, outlen: [*c]c_int) [*c]u8;
pub extern fn stbi_zlib_decode_noheader_buffer(obuffer: [*c]u8, olen: c_int, ibuffer: [*c]const u8, ilen: c_int) c_int;

/// image writing
pub extern var stbi_write_tga_with_rle: c_int;
pub extern var stbi_write_png_compression_level: c_int;
pub extern var stbi_write_force_png_filter: c_int;
pub extern fn stbi_write_png(filename: [*c]const u8, w: c_int, h: c_int, comp: c_int, data: ?*const anyopaque, stride_in_bytes: c_int) c_int;
pub extern fn stbi_write_bmp(filename: [*c]const u8, w: c_int, h: c_int, comp: c_int, data: ?*const anyopaque) c_int;
pub extern fn stbi_write_tga(filename: [*c]const u8, w: c_int, h: c_int, comp: c_int, data: ?*const anyopaque) c_int;
pub extern fn stbi_write_hdr(filename: [*c]const u8, w: c_int, h: c_int, comp: c_int, data: [*c]const f32) c_int;
pub extern fn stbi_write_jpg(filename: [*c]const u8, x: c_int, y: c_int, comp: c_int, data: ?*const anyopaque, quality: c_int) c_int;
pub const stbi_write_func = fn (?*anyopaque, ?*anyopaque, c_int) callconv(.C) void;
pub extern fn stbi_write_png_to_func(func: ?stbi_write_func, context: ?*anyopaque, w: c_int, h: c_int, comp: c_int, data: ?*const anyopaque, stride_in_bytes: c_int) c_int;
pub extern fn stbi_write_bmp_to_func(func: ?stbi_write_func, context: ?*anyopaque, w: c_int, h: c_int, comp: c_int, data: ?*const anyopaque) c_int;
pub extern fn stbi_write_tga_to_func(func: ?stbi_write_func, context: ?*anyopaque, w: c_int, h: c_int, comp: c_int, data: ?*const anyopaque) c_int;
pub extern fn stbi_write_hdr_to_func(func: ?stbi_write_func, context: ?*anyopaque, w: c_int, h: c_int, comp: c_int, data: [*c]const f32) c_int;
pub extern fn stbi_write_jpg_to_func(func: ?stbi_write_func, context: ?*anyopaque, x: c_int, y: c_int, comp: c_int, data: ?*const anyopaque, quality: c_int) c_int;
pub extern fn stbi_flip_vertically_on_write(flip_boolean: c_int) void;

/// image resizing
pub const stbir_uint8 = u8;
pub const stbir_uint16 = u16;
pub const stbir_uint32 = u32;
pub extern fn stbir_resize_uint8(input_pixels: [*c]const u8, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: [*c]u8, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, num_channels: c_int) c_int;
pub extern fn stbir_resize_float(input_pixels: [*c]const f32, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: [*c]f32, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, num_channels: c_int) c_int;
pub extern fn stbir_resize_uint8_srgb(input_pixels: [*c]const u8, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: [*c]u8, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, num_channels: c_int, alpha_channel: c_int, flags: c_int) c_int;
pub const STBIR_EDGE_CLAMP: c_int = 1;
pub const STBIR_EDGE_REFLECT: c_int = 2;
pub const STBIR_EDGE_WRAP: c_int = 3;
pub const STBIR_EDGE_ZERO: c_int = 4;
pub const stbir_edge = c_uint;
pub extern fn stbir_resize_uint8_srgb_edgemode(input_pixels: [*c]const u8, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: [*c]u8, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, num_channels: c_int, alpha_channel: c_int, flags: c_int, edge_wrap_mode: stbir_edge) c_int;
pub const STBIR_FILTER_DEFAULT: c_int = 0;
pub const STBIR_FILTER_BOX: c_int = 1;
pub const STBIR_FILTER_TRIANGLE: c_int = 2;
pub const STBIR_FILTER_CUBICBSPLINE: c_int = 3;
pub const STBIR_FILTER_CATMULLROM: c_int = 4;
pub const STBIR_FILTER_MITCHELL: c_int = 5;
pub const stbir_filter = c_uint;
pub const STBIR_COLORSPACE_LINEAR: c_int = 0;
pub const STBIR_COLORSPACE_SRGB: c_int = 1;
pub const STBIR_MAX_COLORSPACES: c_int = 2;
pub const stbir_colorspace = c_uint;
pub extern fn stbir_resize_uint8_generic(input_pixels: [*c]const u8, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: [*c]u8, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, num_channels: c_int, alpha_channel: c_int, flags: c_int, edge_wrap_mode: stbir_edge, filter: stbir_filter, space: stbir_colorspace, alloc_context: ?*anyopaque) c_int;
pub extern fn stbir_resize_uint16_generic(input_pixels: [*c]const stbir_uint16, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: [*c]stbir_uint16, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, num_channels: c_int, alpha_channel: c_int, flags: c_int, edge_wrap_mode: stbir_edge, filter: stbir_filter, space: stbir_colorspace, alloc_context: ?*anyopaque) c_int;
pub extern fn stbir_resize_float_generic(input_pixels: [*c]const f32, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: [*c]f32, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, num_channels: c_int, alpha_channel: c_int, flags: c_int, edge_wrap_mode: stbir_edge, filter: stbir_filter, space: stbir_colorspace, alloc_context: ?*anyopaque) c_int;
pub const STBIR_TYPE_UINT8: c_int = 0;
pub const STBIR_TYPE_UINT16: c_int = 1;
pub const STBIR_TYPE_UINT32: c_int = 2;
pub const STBIR_TYPE_FLOAT: c_int = 3;
pub const STBIR_MAX_TYPES: c_int = 4;
pub const stbir_datatype = c_uint;
pub extern fn stbir_resize(input_pixels: ?*const anyopaque, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: ?*anyopaque, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, datatype: stbir_datatype, num_channels: c_int, alpha_channel: c_int, flags: c_int, edge_mode_horizontal: stbir_edge, edge_mode_vertical: stbir_edge, filter_horizontal: stbir_filter, filter_vertical: stbir_filter, space: stbir_colorspace, alloc_context: ?*anyopaque) c_int;
pub extern fn stbir_resize_subpixel(input_pixels: ?*const anyopaque, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: ?*anyopaque, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, datatype: stbir_datatype, num_channels: c_int, alpha_channel: c_int, flags: c_int, edge_mode_horizontal: stbir_edge, edge_mode_vertical: stbir_edge, filter_horizontal: stbir_filter, filter_vertical: stbir_filter, space: stbir_colorspace, alloc_context: ?*anyopaque, x_scale: f32, y_scale: f32, x_offset: f32, y_offset: f32) c_int;
pub extern fn stbir_resize_region(input_pixels: ?*const anyopaque, input_w: c_int, input_h: c_int, input_stride_in_bytes: c_int, output_pixels: ?*anyopaque, output_w: c_int, output_h: c_int, output_stride_in_bytes: c_int, datatype: stbir_datatype, num_channels: c_int, alpha_channel: c_int, flags: c_int, edge_mode_horizontal: stbir_edge, edge_mode_vertical: stbir_edge, filter_horizontal: stbir_filter, filter_vertical: stbir_filter, space: stbir_colorspace, alloc_context: ?*anyopaque, s0: f32, t0: f32, s1: f32, t1: f32) c_int;
