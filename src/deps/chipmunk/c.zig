pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_labs = @import("std").zig.c_builtins.__builtin_labs;
pub const __builtin_llabs = @import("std").zig.c_builtins.__builtin_llabs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub const wchar_t = c_int;
pub const _Float32 = f32;
pub const _Float64 = f64;
pub const _Float32x = f64;
pub const _Float64x = c_longdouble;
pub const div_t = extern struct {
    quot: c_int = @import("std").mem.zeroes(c_int),
    rem: c_int = @import("std").mem.zeroes(c_int),
};
pub const ldiv_t = extern struct {
    quot: c_long = @import("std").mem.zeroes(c_long),
    rem: c_long = @import("std").mem.zeroes(c_long),
};
pub const lldiv_t = extern struct {
    quot: c_longlong = @import("std").mem.zeroes(c_longlong),
    rem: c_longlong = @import("std").mem.zeroes(c_longlong),
};
pub extern fn __ctype_get_mb_cur_max() usize;
pub extern fn atof(__nptr: [*c]const u8) f64;
pub extern fn atoi(__nptr: [*c]const u8) c_int;
pub extern fn atol(__nptr: [*c]const u8) c_long;
pub extern fn atoll(__nptr: [*c]const u8) c_longlong;
pub extern fn strtod(__nptr: [*c]const u8, __endptr: [*c][*c]u8) f64;
pub extern fn strtof(__nptr: [*c]const u8, __endptr: [*c][*c]u8) f32;
pub extern fn strtold(__nptr: [*c]const u8, __endptr: [*c][*c]u8) c_longdouble;
pub extern fn strtol(__nptr: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_long;
pub extern fn strtoul(__nptr: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_ulong;
pub extern fn strtoq(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_longlong;
pub extern fn strtouq(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_ulonglong;
pub extern fn strtoll(__nptr: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_longlong;
pub extern fn strtoull(__nptr: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_ulonglong;
pub extern fn l64a(__n: c_long) [*c]u8;
pub extern fn a64l(__s: [*c]const u8) c_long;
pub const __u_char = u8;
pub const __u_short = c_ushort;
pub const __u_int = c_uint;
pub const __u_long = c_ulong;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_long;
pub const __uint64_t = c_ulong;
pub const __int_least8_t = __int8_t;
pub const __uint_least8_t = __uint8_t;
pub const __int_least16_t = __int16_t;
pub const __uint_least16_t = __uint16_t;
pub const __int_least32_t = __int32_t;
pub const __uint_least32_t = __uint32_t;
pub const __int_least64_t = __int64_t;
pub const __uint_least64_t = __uint64_t;
pub const __quad_t = c_long;
pub const __u_quad_t = c_ulong;
pub const __intmax_t = c_long;
pub const __uintmax_t = c_ulong;
pub const __dev_t = c_ulong;
pub const __uid_t = c_uint;
pub const __gid_t = c_uint;
pub const __ino_t = c_ulong;
pub const __ino64_t = c_ulong;
pub const __mode_t = c_uint;
pub const __nlink_t = c_ulong;
pub const __off_t = c_long;
pub const __off64_t = c_long;
pub const __pid_t = c_int;
pub const __fsid_t = extern struct {
    __val: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub const __clock_t = c_long;
pub const __rlim_t = c_ulong;
pub const __rlim64_t = c_ulong;
pub const __id_t = c_uint;
pub const __time_t = c_long;
pub const __useconds_t = c_uint;
pub const __suseconds_t = c_long;
pub const __suseconds64_t = c_long;
pub const __daddr_t = c_int;
pub const __key_t = c_int;
pub const __clockid_t = c_int;
pub const __timer_t = ?*anyopaque;
pub const __blksize_t = c_long;
pub const __blkcnt_t = c_long;
pub const __blkcnt64_t = c_long;
pub const __fsblkcnt_t = c_ulong;
pub const __fsblkcnt64_t = c_ulong;
pub const __fsfilcnt_t = c_ulong;
pub const __fsfilcnt64_t = c_ulong;
pub const __fsword_t = c_long;
pub const __ssize_t = c_long;
pub const __syscall_slong_t = c_long;
pub const __syscall_ulong_t = c_ulong;
pub const __loff_t = __off64_t;
pub const __caddr_t = [*c]u8;
pub const __intptr_t = c_long;
pub const __socklen_t = c_uint;
pub const __sig_atomic_t = c_int;
pub const u_char = __u_char;
pub const u_short = __u_short;
pub const u_int = __u_int;
pub const u_long = __u_long;
pub const quad_t = __quad_t;
pub const u_quad_t = __u_quad_t;
pub const fsid_t = __fsid_t;
pub const loff_t = __loff_t;
pub const ino_t = __ino_t;
pub const dev_t = __dev_t;
pub const gid_t = __gid_t;
pub const mode_t = __mode_t;
pub const nlink_t = __nlink_t;
pub const uid_t = __uid_t;
pub const off_t = __off_t;
pub const pid_t = __pid_t;
pub const id_t = __id_t;
pub const daddr_t = __daddr_t;
pub const caddr_t = __caddr_t;
pub const key_t = __key_t;
pub const clock_t = __clock_t;
pub const clockid_t = __clockid_t;
pub const time_t = __time_t;
pub const timer_t = __timer_t;
pub const ulong = c_ulong;
pub const ushort = c_ushort;
pub const uint = c_uint;
pub const u_int8_t = __uint8_t;
pub const u_int16_t = __uint16_t;
pub const u_int32_t = __uint32_t;
pub const u_int64_t = __uint64_t;
pub const register_t = c_long;
pub fn __bswap_16(arg___bsx: __uint16_t) callconv(.C) __uint16_t {
    var __bsx = arg___bsx;
    _ = &__bsx;
    return @as(__uint16_t, @bitCast(@as(c_short, @truncate(((@as(c_int, @bitCast(@as(c_uint, __bsx))) >> @intCast(8)) & @as(c_int, 255)) | ((@as(c_int, @bitCast(@as(c_uint, __bsx))) & @as(c_int, 255)) << @intCast(8))))));
}
pub fn __bswap_32(arg___bsx: __uint32_t) callconv(.C) __uint32_t {
    var __bsx = arg___bsx;
    _ = &__bsx;
    return ((((__bsx & @as(c_uint, 4278190080)) >> @intCast(24)) | ((__bsx & @as(c_uint, 16711680)) >> @intCast(8))) | ((__bsx & @as(c_uint, 65280)) << @intCast(8))) | ((__bsx & @as(c_uint, 255)) << @intCast(24));
}
pub fn __bswap_64(arg___bsx: __uint64_t) callconv(.C) __uint64_t {
    var __bsx = arg___bsx;
    _ = &__bsx;
    return @as(__uint64_t, @bitCast(@as(c_ulong, @truncate(((((((((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 18374686479671623680)) >> @intCast(56)) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 71776119061217280)) >> @intCast(40))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 280375465082880)) >> @intCast(24))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 1095216660480)) >> @intCast(8))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 4278190080)) << @intCast(8))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 16711680)) << @intCast(24))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 65280)) << @intCast(40))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 255)) << @intCast(56))))));
}
pub fn __uint16_identity(arg___x: __uint16_t) callconv(.C) __uint16_t {
    var __x = arg___x;
    _ = &__x;
    return __x;
}
pub fn __uint32_identity(arg___x: __uint32_t) callconv(.C) __uint32_t {
    var __x = arg___x;
    _ = &__x;
    return __x;
}
pub fn __uint64_identity(arg___x: __uint64_t) callconv(.C) __uint64_t {
    var __x = arg___x;
    _ = &__x;
    return __x;
}
pub const __sigset_t = extern struct {
    __val: [16]c_ulong = @import("std").mem.zeroes([16]c_ulong),
};
pub const sigset_t = __sigset_t;
pub const struct_timeval = extern struct {
    tv_sec: __time_t = @import("std").mem.zeroes(__time_t),
    tv_usec: __suseconds_t = @import("std").mem.zeroes(__suseconds_t),
};
pub const struct_timespec = extern struct {
    tv_sec: __time_t = @import("std").mem.zeroes(__time_t),
    tv_nsec: __syscall_slong_t = @import("std").mem.zeroes(__syscall_slong_t),
};
pub const suseconds_t = __suseconds_t;
pub const __fd_mask = c_long;
pub const fd_set = extern struct {
    __fds_bits: [16]__fd_mask = @import("std").mem.zeroes([16]__fd_mask),
};
pub const fd_mask = __fd_mask;
pub extern fn select(__nfds: c_int, noalias __readfds: [*c]fd_set, noalias __writefds: [*c]fd_set, noalias __exceptfds: [*c]fd_set, noalias __timeout: [*c]struct_timeval) c_int;
pub extern fn pselect(__nfds: c_int, noalias __readfds: [*c]fd_set, noalias __writefds: [*c]fd_set, noalias __exceptfds: [*c]fd_set, noalias __timeout: [*c]const struct_timespec, noalias __sigmask: [*c]const __sigset_t) c_int;
pub const blksize_t = __blksize_t;
pub const blkcnt_t = __blkcnt_t;
pub const fsblkcnt_t = __fsblkcnt_t;
pub const fsfilcnt_t = __fsfilcnt_t;
const struct_unnamed_1 = extern struct {
    __low: c_uint = @import("std").mem.zeroes(c_uint),
    __high: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const __atomic_wide_counter = extern union {
    __value64: c_ulonglong,
    __value32: struct_unnamed_1,
};
pub const struct___pthread_internal_list = extern struct {
    __prev: [*c]struct___pthread_internal_list = @import("std").mem.zeroes([*c]struct___pthread_internal_list),
    __next: [*c]struct___pthread_internal_list = @import("std").mem.zeroes([*c]struct___pthread_internal_list),
};
pub const __pthread_list_t = struct___pthread_internal_list;
pub const struct___pthread_internal_slist = extern struct {
    __next: [*c]struct___pthread_internal_slist = @import("std").mem.zeroes([*c]struct___pthread_internal_slist),
};
pub const __pthread_slist_t = struct___pthread_internal_slist;
pub const struct___pthread_mutex_s = extern struct {
    __lock: c_int = @import("std").mem.zeroes(c_int),
    __count: c_uint = @import("std").mem.zeroes(c_uint),
    __owner: c_int = @import("std").mem.zeroes(c_int),
    __nusers: c_uint = @import("std").mem.zeroes(c_uint),
    __kind: c_int = @import("std").mem.zeroes(c_int),
    __spins: c_short = @import("std").mem.zeroes(c_short),
    __elision: c_short = @import("std").mem.zeroes(c_short),
    __list: __pthread_list_t = @import("std").mem.zeroes(__pthread_list_t),
};
pub const struct___pthread_rwlock_arch_t = extern struct {
    __readers: c_uint = @import("std").mem.zeroes(c_uint),
    __writers: c_uint = @import("std").mem.zeroes(c_uint),
    __wrphase_futex: c_uint = @import("std").mem.zeroes(c_uint),
    __writers_futex: c_uint = @import("std").mem.zeroes(c_uint),
    __pad3: c_uint = @import("std").mem.zeroes(c_uint),
    __pad4: c_uint = @import("std").mem.zeroes(c_uint),
    __cur_writer: c_int = @import("std").mem.zeroes(c_int),
    __shared: c_int = @import("std").mem.zeroes(c_int),
    __rwelision: i8 = @import("std").mem.zeroes(i8),
    __pad1: [7]u8 = @import("std").mem.zeroes([7]u8),
    __pad2: c_ulong = @import("std").mem.zeroes(c_ulong),
    __flags: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const struct___pthread_cond_s = extern struct {
    __wseq: __atomic_wide_counter = @import("std").mem.zeroes(__atomic_wide_counter),
    __g1_start: __atomic_wide_counter = @import("std").mem.zeroes(__atomic_wide_counter),
    __g_refs: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
    __g_size: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
    __g1_orig_size: c_uint = @import("std").mem.zeroes(c_uint),
    __wrefs: c_uint = @import("std").mem.zeroes(c_uint),
    __g_signals: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
};
pub const __tss_t = c_uint;
pub const __thrd_t = c_ulong;
pub const __once_flag = extern struct {
    __data: c_int = @import("std").mem.zeroes(c_int),
};
pub const pthread_t = c_ulong;
pub const pthread_mutexattr_t = extern union {
    __size: [4]u8,
    __align: c_int,
};
pub const pthread_condattr_t = extern union {
    __size: [4]u8,
    __align: c_int,
};
pub const pthread_key_t = c_uint;
pub const pthread_once_t = c_int;
pub const union_pthread_attr_t = extern union {
    __size: [56]u8,
    __align: c_long,
};
pub const pthread_attr_t = union_pthread_attr_t;
pub const pthread_mutex_t = extern union {
    __data: struct___pthread_mutex_s,
    __size: [40]u8,
    __align: c_long,
};
pub const pthread_cond_t = extern union {
    __data: struct___pthread_cond_s,
    __size: [48]u8,
    __align: c_longlong,
};
pub const pthread_rwlock_t = extern union {
    __data: struct___pthread_rwlock_arch_t,
    __size: [56]u8,
    __align: c_long,
};
pub const pthread_rwlockattr_t = extern union {
    __size: [8]u8,
    __align: c_long,
};
pub const pthread_spinlock_t = c_int;
pub const pthread_barrier_t = extern union {
    __size: [32]u8,
    __align: c_long,
};
pub const pthread_barrierattr_t = extern union {
    __size: [4]u8,
    __align: c_int,
};
pub extern fn random() c_long;
pub extern fn srandom(__seed: c_uint) void;
pub extern fn initstate(__seed: c_uint, __statebuf: [*c]u8, __statelen: usize) [*c]u8;
pub extern fn setstate(__statebuf: [*c]u8) [*c]u8;
pub const struct_random_data = extern struct {
    fptr: [*c]i32 = @import("std").mem.zeroes([*c]i32),
    rptr: [*c]i32 = @import("std").mem.zeroes([*c]i32),
    state: [*c]i32 = @import("std").mem.zeroes([*c]i32),
    rand_type: c_int = @import("std").mem.zeroes(c_int),
    rand_deg: c_int = @import("std").mem.zeroes(c_int),
    rand_sep: c_int = @import("std").mem.zeroes(c_int),
    end_ptr: [*c]i32 = @import("std").mem.zeroes([*c]i32),
};
pub extern fn random_r(noalias __buf: [*c]struct_random_data, noalias __result: [*c]i32) c_int;
pub extern fn srandom_r(__seed: c_uint, __buf: [*c]struct_random_data) c_int;
pub extern fn initstate_r(__seed: c_uint, noalias __statebuf: [*c]u8, __statelen: usize, noalias __buf: [*c]struct_random_data) c_int;
pub extern fn setstate_r(noalias __statebuf: [*c]u8, noalias __buf: [*c]struct_random_data) c_int;
pub extern fn rand() c_int;
pub extern fn srand(__seed: c_uint) void;
pub extern fn rand_r(__seed: [*c]c_uint) c_int;
pub extern fn drand48() f64;
pub extern fn erand48(__xsubi: [*c]c_ushort) f64;
pub extern fn lrand48() c_long;
pub extern fn nrand48(__xsubi: [*c]c_ushort) c_long;
pub extern fn mrand48() c_long;
pub extern fn jrand48(__xsubi: [*c]c_ushort) c_long;
pub extern fn srand48(__seedval: c_long) void;
pub extern fn seed48(__seed16v: [*c]c_ushort) [*c]c_ushort;
pub extern fn lcong48(__param: [*c]c_ushort) void;
pub const struct_drand48_data = extern struct {
    __x: [3]c_ushort = @import("std").mem.zeroes([3]c_ushort),
    __old_x: [3]c_ushort = @import("std").mem.zeroes([3]c_ushort),
    __c: c_ushort = @import("std").mem.zeroes(c_ushort),
    __init: c_ushort = @import("std").mem.zeroes(c_ushort),
    __a: c_ulonglong = @import("std").mem.zeroes(c_ulonglong),
};
pub extern fn drand48_r(noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]f64) c_int;
pub extern fn erand48_r(__xsubi: [*c]c_ushort, noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]f64) c_int;
pub extern fn lrand48_r(noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn nrand48_r(__xsubi: [*c]c_ushort, noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn mrand48_r(noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn jrand48_r(__xsubi: [*c]c_ushort, noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn srand48_r(__seedval: c_long, __buffer: [*c]struct_drand48_data) c_int;
pub extern fn seed48_r(__seed16v: [*c]c_ushort, __buffer: [*c]struct_drand48_data) c_int;
pub extern fn lcong48_r(__param: [*c]c_ushort, __buffer: [*c]struct_drand48_data) c_int;
pub extern fn arc4random() __uint32_t;
pub extern fn arc4random_buf(__buf: ?*anyopaque, __size: usize) void;
pub extern fn arc4random_uniform(__upper_bound: __uint32_t) __uint32_t;
pub extern fn malloc(__size: c_ulong) ?*anyopaque;
pub extern fn calloc(__nmemb: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
pub extern fn free(__ptr: ?*anyopaque) void;
pub extern fn reallocarray(__ptr: ?*anyopaque, __nmemb: usize, __size: usize) ?*anyopaque;
pub extern fn alloca(__size: c_ulong) ?*anyopaque;
pub extern fn valloc(__size: usize) ?*anyopaque;
pub extern fn posix_memalign(__memptr: [*c]?*anyopaque, __alignment: usize, __size: usize) c_int;
pub extern fn aligned_alloc(__alignment: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn abort() noreturn;
pub extern fn atexit(__func: ?*const fn () callconv(.C) void) c_int;
pub extern fn at_quick_exit(__func: ?*const fn () callconv(.C) void) c_int;
pub extern fn on_exit(__func: ?*const fn (c_int, ?*anyopaque) callconv(.C) void, __arg: ?*anyopaque) c_int;
pub extern fn exit(__status: c_int) noreturn;
pub extern fn quick_exit(__status: c_int) noreturn;
pub extern fn _Exit(__status: c_int) noreturn;
pub extern fn getenv(__name: [*c]const u8) [*c]u8;
pub extern fn putenv(__string: [*c]u8) c_int;
pub extern fn setenv(__name: [*c]const u8, __value: [*c]const u8, __replace: c_int) c_int;
pub extern fn unsetenv(__name: [*c]const u8) c_int;
pub extern fn clearenv() c_int;
pub extern fn mktemp(__template: [*c]u8) [*c]u8;
pub extern fn mkstemp(__template: [*c]u8) c_int;
pub extern fn mkstemps(__template: [*c]u8, __suffixlen: c_int) c_int;
pub extern fn mkdtemp(__template: [*c]u8) [*c]u8;
pub extern fn system(__command: [*c]const u8) c_int;
pub extern fn realpath(noalias __name: [*c]const u8, noalias __resolved: [*c]u8) [*c]u8;
pub const __compar_fn_t = ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int;
pub extern fn bsearch(__key: ?*const anyopaque, __base: ?*const anyopaque, __nmemb: usize, __size: usize, __compar: __compar_fn_t) ?*anyopaque;
pub extern fn qsort(__base: ?*anyopaque, __nmemb: usize, __size: usize, __compar: __compar_fn_t) void;
pub extern fn abs(__x: c_int) c_int;
pub extern fn labs(__x: c_long) c_long;
pub extern fn llabs(__x: c_longlong) c_longlong;
pub extern fn div(__numer: c_int, __denom: c_int) div_t;
pub extern fn ldiv(__numer: c_long, __denom: c_long) ldiv_t;
pub extern fn lldiv(__numer: c_longlong, __denom: c_longlong) lldiv_t;
pub extern fn ecvt(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn fcvt(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn gcvt(__value: f64, __ndigit: c_int, __buf: [*c]u8) [*c]u8;
pub extern fn qecvt(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn qfcvt(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn qgcvt(__value: c_longdouble, __ndigit: c_int, __buf: [*c]u8) [*c]u8;
pub extern fn ecvt_r(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn fcvt_r(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn qecvt_r(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn qfcvt_r(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn mblen(__s: [*c]const u8, __n: usize) c_int;
pub extern fn mbtowc(noalias __pwc: [*c]wchar_t, noalias __s: [*c]const u8, __n: usize) c_int;
pub extern fn wctomb(__s: [*c]u8, __wchar: wchar_t) c_int;
pub extern fn mbstowcs(noalias __pwcs: [*c]wchar_t, noalias __s: [*c]const u8, __n: usize) usize;
pub extern fn wcstombs(noalias __s: [*c]u8, noalias __pwcs: [*c]const wchar_t, __n: usize) usize;
pub extern fn rpmatch(__response: [*c]const u8) c_int;
pub extern fn getsubopt(noalias __optionp: [*c][*c]u8, noalias __tokens: [*c]const [*c]u8, noalias __valuep: [*c][*c]u8) c_int;
pub extern fn getloadavg(__loadavg: [*c]f64, __nelem: c_int) c_int;
pub const float_t = f32;
pub const double_t = f64;
pub extern fn __fpclassify(__value: f64) c_int;
pub extern fn __signbit(__value: f64) c_int;
pub extern fn __isinf(__value: f64) c_int;
pub extern fn __finite(__value: f64) c_int;
pub extern fn __isnan(__value: f64) c_int;
pub extern fn __iseqsig(__x: f64, __y: f64) c_int;
pub extern fn __issignaling(__value: f64) c_int;
pub extern fn acos(__x: f64) f64;
pub extern fn __acos(__x: f64) f64;
pub extern fn asin(__x: f64) f64;
pub extern fn __asin(__x: f64) f64;
pub extern fn atan(__x: f64) f64;
pub extern fn __atan(__x: f64) f64;
pub extern fn atan2(__y: f64, __x: f64) f64;
pub extern fn __atan2(__y: f64, __x: f64) f64;
pub extern fn cos(__x: f64) f64;
pub extern fn __cos(__x: f64) f64;
pub extern fn sin(__x: f64) f64;
pub extern fn __sin(__x: f64) f64;
pub extern fn tan(__x: f64) f64;
pub extern fn __tan(__x: f64) f64;
pub extern fn cosh(__x: f64) f64;
pub extern fn __cosh(__x: f64) f64;
pub extern fn sinh(__x: f64) f64;
pub extern fn __sinh(__x: f64) f64;
pub extern fn tanh(__x: f64) f64;
pub extern fn __tanh(__x: f64) f64;
pub extern fn acosh(__x: f64) f64;
pub extern fn __acosh(__x: f64) f64;
pub extern fn asinh(__x: f64) f64;
pub extern fn __asinh(__x: f64) f64;
pub extern fn atanh(__x: f64) f64;
pub extern fn __atanh(__x: f64) f64;
pub extern fn exp(__x: f64) f64;
pub extern fn __exp(__x: f64) f64;
pub extern fn frexp(__x: f64, __exponent: [*c]c_int) f64;
pub extern fn __frexp(__x: f64, __exponent: [*c]c_int) f64;
pub extern fn ldexp(__x: f64, __exponent: c_int) f64;
pub extern fn __ldexp(__x: f64, __exponent: c_int) f64;
pub extern fn log(__x: f64) f64;
pub extern fn __log(__x: f64) f64;
pub extern fn log10(__x: f64) f64;
pub extern fn __log10(__x: f64) f64;
pub extern fn modf(__x: f64, __iptr: [*c]f64) f64;
pub extern fn __modf(__x: f64, __iptr: [*c]f64) f64;
pub extern fn expm1(__x: f64) f64;
pub extern fn __expm1(__x: f64) f64;
pub extern fn log1p(__x: f64) f64;
pub extern fn __log1p(__x: f64) f64;
pub extern fn logb(__x: f64) f64;
pub extern fn __logb(__x: f64) f64;
pub extern fn exp2(__x: f64) f64;
pub extern fn __exp2(__x: f64) f64;
pub extern fn log2(__x: f64) f64;
pub extern fn __log2(__x: f64) f64;
pub extern fn pow(__x: f64, __y: f64) f64;
pub extern fn __pow(__x: f64, __y: f64) f64;
pub extern fn sqrt(__x: f64) f64;
pub extern fn __sqrt(__x: f64) f64;
pub extern fn hypot(__x: f64, __y: f64) f64;
pub extern fn __hypot(__x: f64, __y: f64) f64;
pub extern fn cbrt(__x: f64) f64;
pub extern fn __cbrt(__x: f64) f64;
pub extern fn ceil(__x: f64) f64;
pub extern fn __ceil(__x: f64) f64;
pub extern fn fabs(__x: f64) f64;
pub extern fn __fabs(__x: f64) f64;
pub extern fn floor(__x: f64) f64;
pub extern fn __floor(__x: f64) f64;
pub extern fn fmod(__x: f64, __y: f64) f64;
pub extern fn __fmod(__x: f64, __y: f64) f64;
pub extern fn isinf(__value: f64) c_int;
pub extern fn finite(__value: f64) c_int;
pub extern fn drem(__x: f64, __y: f64) f64;
pub extern fn __drem(__x: f64, __y: f64) f64;
pub extern fn significand(__x: f64) f64;
pub extern fn __significand(__x: f64) f64;
pub extern fn copysign(__x: f64, __y: f64) f64;
pub extern fn __copysign(__x: f64, __y: f64) f64;
pub extern fn nan(__tagb: [*c]const u8) f64;
pub extern fn __nan(__tagb: [*c]const u8) f64;
pub extern fn isnan(__value: f64) c_int;
pub extern fn j0(f64) f64;
pub extern fn __j0(f64) f64;
pub extern fn j1(f64) f64;
pub extern fn __j1(f64) f64;
pub extern fn jn(c_int, f64) f64;
pub extern fn __jn(c_int, f64) f64;
pub extern fn y0(f64) f64;
pub extern fn __y0(f64) f64;
pub extern fn y1(f64) f64;
pub extern fn __y1(f64) f64;
pub extern fn yn(c_int, f64) f64;
pub extern fn __yn(c_int, f64) f64;
pub extern fn erf(f64) f64;
pub extern fn __erf(f64) f64;
pub extern fn erfc(f64) f64;
pub extern fn __erfc(f64) f64;
pub extern fn lgamma(f64) f64;
pub extern fn __lgamma(f64) f64;
pub extern fn tgamma(f64) f64;
pub extern fn __tgamma(f64) f64;
pub extern fn gamma(f64) f64;
pub extern fn __gamma(f64) f64;
pub extern fn lgamma_r(f64, __signgamp: [*c]c_int) f64;
pub extern fn __lgamma_r(f64, __signgamp: [*c]c_int) f64;
pub extern fn rint(__x: f64) f64;
pub extern fn __rint(__x: f64) f64;
pub extern fn nextafter(__x: f64, __y: f64) f64;
pub extern fn __nextafter(__x: f64, __y: f64) f64;
pub extern fn nexttoward(__x: f64, __y: c_longdouble) f64;
pub extern fn __nexttoward(__x: f64, __y: c_longdouble) f64;
pub extern fn remainder(__x: f64, __y: f64) f64;
pub extern fn __remainder(__x: f64, __y: f64) f64;
pub extern fn scalbn(__x: f64, __n: c_int) f64;
pub extern fn __scalbn(__x: f64, __n: c_int) f64;
pub extern fn ilogb(__x: f64) c_int;
pub extern fn __ilogb(__x: f64) c_int;
pub extern fn scalbln(__x: f64, __n: c_long) f64;
pub extern fn __scalbln(__x: f64, __n: c_long) f64;
pub extern fn nearbyint(__x: f64) f64;
pub extern fn __nearbyint(__x: f64) f64;
pub extern fn round(__x: f64) f64;
pub extern fn __round(__x: f64) f64;
pub extern fn trunc(__x: f64) f64;
pub extern fn __trunc(__x: f64) f64;
pub extern fn remquo(__x: f64, __y: f64, __quo: [*c]c_int) f64;
pub extern fn __remquo(__x: f64, __y: f64, __quo: [*c]c_int) f64;
pub extern fn lrint(__x: f64) c_long;
pub extern fn __lrint(__x: f64) c_long;
pub extern fn llrint(__x: f64) c_longlong;
pub extern fn __llrint(__x: f64) c_longlong;
pub extern fn lround(__x: f64) c_long;
pub extern fn __lround(__x: f64) c_long;
pub extern fn llround(__x: f64) c_longlong;
pub extern fn __llround(__x: f64) c_longlong;
pub extern fn fdim(__x: f64, __y: f64) f64;
pub extern fn __fdim(__x: f64, __y: f64) f64;
pub extern fn fmax(__x: f64, __y: f64) f64;
pub extern fn __fmax(__x: f64, __y: f64) f64;
pub extern fn fmin(__x: f64, __y: f64) f64;
pub extern fn __fmin(__x: f64, __y: f64) f64;
pub extern fn fma(__x: f64, __y: f64, __z: f64) f64;
pub extern fn __fma(__x: f64, __y: f64, __z: f64) f64;
pub extern fn scalb(__x: f64, __n: f64) f64;
pub extern fn __scalb(__x: f64, __n: f64) f64;
pub extern fn __fpclassifyf(__value: f32) c_int;
pub extern fn __signbitf(__value: f32) c_int;
pub extern fn __isinff(__value: f32) c_int;
pub extern fn __finitef(__value: f32) c_int;
pub extern fn __isnanf(__value: f32) c_int;
pub extern fn __iseqsigf(__x: f32, __y: f32) c_int;
pub extern fn __issignalingf(__value: f32) c_int;
pub extern fn acosf(__x: f32) f32;
pub extern fn __acosf(__x: f32) f32;
pub extern fn asinf(__x: f32) f32;
pub extern fn __asinf(__x: f32) f32;
pub extern fn atanf(__x: f32) f32;
pub extern fn __atanf(__x: f32) f32;
pub extern fn atan2f(__y: f32, __x: f32) f32;
pub extern fn __atan2f(__y: f32, __x: f32) f32;
pub extern fn cosf(__x: f32) f32;
pub extern fn __cosf(__x: f32) f32;
pub extern fn sinf(__x: f32) f32;
pub extern fn __sinf(__x: f32) f32;
pub extern fn tanf(__x: f32) f32;
pub extern fn __tanf(__x: f32) f32;
pub extern fn coshf(__x: f32) f32;
pub extern fn __coshf(__x: f32) f32;
pub extern fn sinhf(__x: f32) f32;
pub extern fn __sinhf(__x: f32) f32;
pub extern fn tanhf(__x: f32) f32;
pub extern fn __tanhf(__x: f32) f32;
pub extern fn acoshf(__x: f32) f32;
pub extern fn __acoshf(__x: f32) f32;
pub extern fn asinhf(__x: f32) f32;
pub extern fn __asinhf(__x: f32) f32;
pub extern fn atanhf(__x: f32) f32;
pub extern fn __atanhf(__x: f32) f32;
pub extern fn expf(__x: f32) f32;
pub extern fn __expf(__x: f32) f32;
pub extern fn frexpf(__x: f32, __exponent: [*c]c_int) f32;
pub extern fn __frexpf(__x: f32, __exponent: [*c]c_int) f32;
pub extern fn ldexpf(__x: f32, __exponent: c_int) f32;
pub extern fn __ldexpf(__x: f32, __exponent: c_int) f32;
pub extern fn logf(__x: f32) f32;
pub extern fn __logf(__x: f32) f32;
pub extern fn log10f(__x: f32) f32;
pub extern fn __log10f(__x: f32) f32;
pub extern fn modff(__x: f32, __iptr: [*c]f32) f32;
pub extern fn __modff(__x: f32, __iptr: [*c]f32) f32;
pub extern fn expm1f(__x: f32) f32;
pub extern fn __expm1f(__x: f32) f32;
pub extern fn log1pf(__x: f32) f32;
pub extern fn __log1pf(__x: f32) f32;
pub extern fn logbf(__x: f32) f32;
pub extern fn __logbf(__x: f32) f32;
pub extern fn exp2f(__x: f32) f32;
pub extern fn __exp2f(__x: f32) f32;
pub extern fn log2f(__x: f32) f32;
pub extern fn __log2f(__x: f32) f32;
pub extern fn powf(__x: f32, __y: f32) f32;
pub extern fn __powf(__x: f32, __y: f32) f32;
pub extern fn sqrtf(__x: f32) f32;
pub extern fn __sqrtf(__x: f32) f32;
pub extern fn hypotf(__x: f32, __y: f32) f32;
pub extern fn __hypotf(__x: f32, __y: f32) f32;
pub extern fn cbrtf(__x: f32) f32;
pub extern fn __cbrtf(__x: f32) f32;
pub extern fn ceilf(__x: f32) f32;
pub extern fn __ceilf(__x: f32) f32;
pub extern fn fabsf(__x: f32) f32;
pub extern fn __fabsf(__x: f32) f32;
pub extern fn floorf(__x: f32) f32;
pub extern fn __floorf(__x: f32) f32;
pub extern fn fmodf(__x: f32, __y: f32) f32;
pub extern fn __fmodf(__x: f32, __y: f32) f32;
pub extern fn isinff(__value: f32) c_int;
pub extern fn finitef(__value: f32) c_int;
pub extern fn dremf(__x: f32, __y: f32) f32;
pub extern fn __dremf(__x: f32, __y: f32) f32;
pub extern fn significandf(__x: f32) f32;
pub extern fn __significandf(__x: f32) f32;
pub extern fn copysignf(__x: f32, __y: f32) f32;
pub extern fn __copysignf(__x: f32, __y: f32) f32;
pub extern fn nanf(__tagb: [*c]const u8) f32;
pub extern fn __nanf(__tagb: [*c]const u8) f32;
pub extern fn isnanf(__value: f32) c_int;
pub extern fn j0f(f32) f32;
pub extern fn __j0f(f32) f32;
pub extern fn j1f(f32) f32;
pub extern fn __j1f(f32) f32;
pub extern fn jnf(c_int, f32) f32;
pub extern fn __jnf(c_int, f32) f32;
pub extern fn y0f(f32) f32;
pub extern fn __y0f(f32) f32;
pub extern fn y1f(f32) f32;
pub extern fn __y1f(f32) f32;
pub extern fn ynf(c_int, f32) f32;
pub extern fn __ynf(c_int, f32) f32;
pub extern fn erff(f32) f32;
pub extern fn __erff(f32) f32;
pub extern fn erfcf(f32) f32;
pub extern fn __erfcf(f32) f32;
pub extern fn lgammaf(f32) f32;
pub extern fn __lgammaf(f32) f32;
pub extern fn tgammaf(f32) f32;
pub extern fn __tgammaf(f32) f32;
pub extern fn gammaf(f32) f32;
pub extern fn __gammaf(f32) f32;
pub extern fn lgammaf_r(f32, __signgamp: [*c]c_int) f32;
pub extern fn __lgammaf_r(f32, __signgamp: [*c]c_int) f32;
pub extern fn rintf(__x: f32) f32;
pub extern fn __rintf(__x: f32) f32;
pub extern fn nextafterf(__x: f32, __y: f32) f32;
pub extern fn __nextafterf(__x: f32, __y: f32) f32;
pub extern fn nexttowardf(__x: f32, __y: c_longdouble) f32;
pub extern fn __nexttowardf(__x: f32, __y: c_longdouble) f32;
pub extern fn remainderf(__x: f32, __y: f32) f32;
pub extern fn __remainderf(__x: f32, __y: f32) f32;
pub extern fn scalbnf(__x: f32, __n: c_int) f32;
pub extern fn __scalbnf(__x: f32, __n: c_int) f32;
pub extern fn ilogbf(__x: f32) c_int;
pub extern fn __ilogbf(__x: f32) c_int;
pub extern fn scalblnf(__x: f32, __n: c_long) f32;
pub extern fn __scalblnf(__x: f32, __n: c_long) f32;
pub extern fn nearbyintf(__x: f32) f32;
pub extern fn __nearbyintf(__x: f32) f32;
pub extern fn roundf(__x: f32) f32;
pub extern fn __roundf(__x: f32) f32;
pub extern fn truncf(__x: f32) f32;
pub extern fn __truncf(__x: f32) f32;
pub extern fn remquof(__x: f32, __y: f32, __quo: [*c]c_int) f32;
pub extern fn __remquof(__x: f32, __y: f32, __quo: [*c]c_int) f32;
pub extern fn lrintf(__x: f32) c_long;
pub extern fn __lrintf(__x: f32) c_long;
pub extern fn llrintf(__x: f32) c_longlong;
pub extern fn __llrintf(__x: f32) c_longlong;
pub extern fn lroundf(__x: f32) c_long;
pub extern fn __lroundf(__x: f32) c_long;
pub extern fn llroundf(__x: f32) c_longlong;
pub extern fn __llroundf(__x: f32) c_longlong;
pub extern fn fdimf(__x: f32, __y: f32) f32;
pub extern fn __fdimf(__x: f32, __y: f32) f32;
pub extern fn fmaxf(__x: f32, __y: f32) f32;
pub extern fn __fmaxf(__x: f32, __y: f32) f32;
pub extern fn fminf(__x: f32, __y: f32) f32;
pub extern fn __fminf(__x: f32, __y: f32) f32;
pub extern fn fmaf(__x: f32, __y: f32, __z: f32) f32;
pub extern fn __fmaf(__x: f32, __y: f32, __z: f32) f32;
pub extern fn scalbf(__x: f32, __n: f32) f32;
pub extern fn __scalbf(__x: f32, __n: f32) f32;
pub extern fn __fpclassifyl(__value: c_longdouble) c_int;
pub extern fn __signbitl(__value: c_longdouble) c_int;
pub extern fn __isinfl(__value: c_longdouble) c_int;
pub extern fn __finitel(__value: c_longdouble) c_int;
pub extern fn __isnanl(__value: c_longdouble) c_int;
pub extern fn __iseqsigl(__x: c_longdouble, __y: c_longdouble) c_int;
pub extern fn __issignalingl(__value: c_longdouble) c_int;
pub extern fn acosl(__x: c_longdouble) c_longdouble;
pub extern fn __acosl(__x: c_longdouble) c_longdouble;
pub extern fn asinl(__x: c_longdouble) c_longdouble;
pub extern fn __asinl(__x: c_longdouble) c_longdouble;
pub extern fn atanl(__x: c_longdouble) c_longdouble;
pub extern fn __atanl(__x: c_longdouble) c_longdouble;
pub extern fn atan2l(__y: c_longdouble, __x: c_longdouble) c_longdouble;
pub extern fn __atan2l(__y: c_longdouble, __x: c_longdouble) c_longdouble;
pub extern fn cosl(__x: c_longdouble) c_longdouble;
pub extern fn __cosl(__x: c_longdouble) c_longdouble;
pub extern fn sinl(__x: c_longdouble) c_longdouble;
pub extern fn __sinl(__x: c_longdouble) c_longdouble;
pub extern fn tanl(__x: c_longdouble) c_longdouble;
pub extern fn __tanl(__x: c_longdouble) c_longdouble;
pub extern fn coshl(__x: c_longdouble) c_longdouble;
pub extern fn __coshl(__x: c_longdouble) c_longdouble;
pub extern fn sinhl(__x: c_longdouble) c_longdouble;
pub extern fn __sinhl(__x: c_longdouble) c_longdouble;
pub extern fn tanhl(__x: c_longdouble) c_longdouble;
pub extern fn __tanhl(__x: c_longdouble) c_longdouble;
pub extern fn acoshl(__x: c_longdouble) c_longdouble;
pub extern fn __acoshl(__x: c_longdouble) c_longdouble;
pub extern fn asinhl(__x: c_longdouble) c_longdouble;
pub extern fn __asinhl(__x: c_longdouble) c_longdouble;
pub extern fn atanhl(__x: c_longdouble) c_longdouble;
pub extern fn __atanhl(__x: c_longdouble) c_longdouble;
pub extern fn expl(__x: c_longdouble) c_longdouble;
pub extern fn __expl(__x: c_longdouble) c_longdouble;
pub extern fn frexpl(__x: c_longdouble, __exponent: [*c]c_int) c_longdouble;
pub extern fn __frexpl(__x: c_longdouble, __exponent: [*c]c_int) c_longdouble;
pub extern fn ldexpl(__x: c_longdouble, __exponent: c_int) c_longdouble;
pub extern fn __ldexpl(__x: c_longdouble, __exponent: c_int) c_longdouble;
pub extern fn logl(__x: c_longdouble) c_longdouble;
pub extern fn __logl(__x: c_longdouble) c_longdouble;
pub extern fn log10l(__x: c_longdouble) c_longdouble;
pub extern fn __log10l(__x: c_longdouble) c_longdouble;
pub extern fn modfl(__x: c_longdouble, __iptr: [*c]c_longdouble) c_longdouble;
pub extern fn __modfl(__x: c_longdouble, __iptr: [*c]c_longdouble) c_longdouble;
pub extern fn expm1l(__x: c_longdouble) c_longdouble;
pub extern fn __expm1l(__x: c_longdouble) c_longdouble;
pub extern fn log1pl(__x: c_longdouble) c_longdouble;
pub extern fn __log1pl(__x: c_longdouble) c_longdouble;
pub extern fn logbl(__x: c_longdouble) c_longdouble;
pub extern fn __logbl(__x: c_longdouble) c_longdouble;
pub extern fn exp2l(__x: c_longdouble) c_longdouble;
pub extern fn __exp2l(__x: c_longdouble) c_longdouble;
pub extern fn log2l(__x: c_longdouble) c_longdouble;
pub extern fn __log2l(__x: c_longdouble) c_longdouble;
pub extern fn powl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __powl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn sqrtl(__x: c_longdouble) c_longdouble;
pub extern fn __sqrtl(__x: c_longdouble) c_longdouble;
pub extern fn hypotl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __hypotl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn cbrtl(__x: c_longdouble) c_longdouble;
pub extern fn __cbrtl(__x: c_longdouble) c_longdouble;
pub extern fn ceill(__x: c_longdouble) c_longdouble;
pub extern fn __ceill(__x: c_longdouble) c_longdouble;
pub extern fn fabsl(__x: c_longdouble) c_longdouble;
pub extern fn __fabsl(__x: c_longdouble) c_longdouble;
pub extern fn floorl(__x: c_longdouble) c_longdouble;
pub extern fn __floorl(__x: c_longdouble) c_longdouble;
pub extern fn fmodl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __fmodl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn isinfl(__value: c_longdouble) c_int;
pub extern fn finitel(__value: c_longdouble) c_int;
pub extern fn dreml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __dreml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn significandl(__x: c_longdouble) c_longdouble;
pub extern fn __significandl(__x: c_longdouble) c_longdouble;
pub extern fn copysignl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __copysignl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn nanl(__tagb: [*c]const u8) c_longdouble;
pub extern fn __nanl(__tagb: [*c]const u8) c_longdouble;
pub extern fn isnanl(__value: c_longdouble) c_int;
pub extern fn j0l(c_longdouble) c_longdouble;
pub extern fn __j0l(c_longdouble) c_longdouble;
pub extern fn j1l(c_longdouble) c_longdouble;
pub extern fn __j1l(c_longdouble) c_longdouble;
pub extern fn jnl(c_int, c_longdouble) c_longdouble;
pub extern fn __jnl(c_int, c_longdouble) c_longdouble;
pub extern fn y0l(c_longdouble) c_longdouble;
pub extern fn __y0l(c_longdouble) c_longdouble;
pub extern fn y1l(c_longdouble) c_longdouble;
pub extern fn __y1l(c_longdouble) c_longdouble;
pub extern fn ynl(c_int, c_longdouble) c_longdouble;
pub extern fn __ynl(c_int, c_longdouble) c_longdouble;
pub extern fn erfl(c_longdouble) c_longdouble;
pub extern fn __erfl(c_longdouble) c_longdouble;
pub extern fn erfcl(c_longdouble) c_longdouble;
pub extern fn __erfcl(c_longdouble) c_longdouble;
pub extern fn lgammal(c_longdouble) c_longdouble;
pub extern fn __lgammal(c_longdouble) c_longdouble;
pub extern fn tgammal(c_longdouble) c_longdouble;
pub extern fn __tgammal(c_longdouble) c_longdouble;
pub extern fn gammal(c_longdouble) c_longdouble;
pub extern fn __gammal(c_longdouble) c_longdouble;
pub extern fn lgammal_r(c_longdouble, __signgamp: [*c]c_int) c_longdouble;
pub extern fn __lgammal_r(c_longdouble, __signgamp: [*c]c_int) c_longdouble;
pub extern fn rintl(__x: c_longdouble) c_longdouble;
pub extern fn __rintl(__x: c_longdouble) c_longdouble;
pub extern fn nextafterl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __nextafterl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn nexttowardl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __nexttowardl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn remainderl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __remainderl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn scalbnl(__x: c_longdouble, __n: c_int) c_longdouble;
pub extern fn __scalbnl(__x: c_longdouble, __n: c_int) c_longdouble;
pub extern fn ilogbl(__x: c_longdouble) c_int;
pub extern fn __ilogbl(__x: c_longdouble) c_int;
pub extern fn scalblnl(__x: c_longdouble, __n: c_long) c_longdouble;
pub extern fn __scalblnl(__x: c_longdouble, __n: c_long) c_longdouble;
pub extern fn nearbyintl(__x: c_longdouble) c_longdouble;
pub extern fn __nearbyintl(__x: c_longdouble) c_longdouble;
pub extern fn roundl(__x: c_longdouble) c_longdouble;
pub extern fn __roundl(__x: c_longdouble) c_longdouble;
pub extern fn truncl(__x: c_longdouble) c_longdouble;
pub extern fn __truncl(__x: c_longdouble) c_longdouble;
pub extern fn remquol(__x: c_longdouble, __y: c_longdouble, __quo: [*c]c_int) c_longdouble;
pub extern fn __remquol(__x: c_longdouble, __y: c_longdouble, __quo: [*c]c_int) c_longdouble;
pub extern fn lrintl(__x: c_longdouble) c_long;
pub extern fn __lrintl(__x: c_longdouble) c_long;
pub extern fn llrintl(__x: c_longdouble) c_longlong;
pub extern fn __llrintl(__x: c_longdouble) c_longlong;
pub extern fn lroundl(__x: c_longdouble) c_long;
pub extern fn __lroundl(__x: c_longdouble) c_long;
pub extern fn llroundl(__x: c_longdouble) c_longlong;
pub extern fn __llroundl(__x: c_longdouble) c_longlong;
pub extern fn fdiml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __fdiml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn fmaxl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __fmaxl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn fminl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __fminl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn fmal(__x: c_longdouble, __y: c_longdouble, __z: c_longdouble) c_longdouble;
pub extern fn __fmal(__x: c_longdouble, __y: c_longdouble, __z: c_longdouble) c_longdouble;
pub extern fn scalbl(__x: c_longdouble, __n: c_longdouble) c_longdouble;
pub extern fn __scalbl(__x: c_longdouble, __n: c_longdouble) c_longdouble;
pub extern var signgam: c_int;
pub const FP_NAN: c_int = 0;
pub const FP_INFINITE: c_int = 1;
pub const FP_ZERO: c_int = 2;
pub const FP_SUBNORMAL: c_int = 3;
pub const FP_NORMAL: c_int = 4;
const enum_unnamed_2 = c_uint;
pub extern fn cpMessage(condition: [*c]const u8, file: [*c]const u8, line: c_int, isError: c_int, isHardError: c_int, message: [*c]const u8, ...) void;
pub const int_least8_t = __int_least8_t;
pub const int_least16_t = __int_least16_t;
pub const int_least32_t = __int_least32_t;
pub const int_least64_t = __int_least64_t;
pub const uint_least8_t = __uint_least8_t;
pub const uint_least16_t = __uint_least16_t;
pub const uint_least32_t = __uint_least32_t;
pub const uint_least64_t = __uint_least64_t;
pub const int_fast8_t = i8;
pub const int_fast16_t = c_long;
pub const int_fast32_t = c_long;
pub const int_fast64_t = c_long;
pub const uint_fast8_t = u8;
pub const uint_fast16_t = c_ulong;
pub const uint_fast32_t = c_ulong;
pub const uint_fast64_t = c_ulong;
pub const intmax_t = __intmax_t;
pub const uintmax_t = __uintmax_t;
pub const cpFloat = f32;
pub fn cpfmax(arg_a: cpFloat, arg_b: cpFloat) callconv(.C) cpFloat {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return if (a > b) a else b;
}
pub fn cpfmin(arg_a: cpFloat, arg_b: cpFloat) callconv(.C) cpFloat {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return if (a < b) a else b;
}
pub fn cpfabs(arg_f: cpFloat) callconv(.C) cpFloat {
    var f = arg_f;
    _ = &f;
    return if (f < @as(cpFloat, @floatFromInt(@as(c_int, 0)))) -f else f;
}
pub fn cpfclamp(arg_f: cpFloat, arg_min: cpFloat, arg_max: cpFloat) callconv(.C) cpFloat {
    var f = arg_f;
    _ = &f;
    var min = arg_min;
    _ = &min;
    var max = arg_max;
    _ = &max;
    return cpfmin(cpfmax(f, min), max);
}
pub fn cpfclamp01(arg_f: cpFloat) callconv(.C) cpFloat {
    var f = arg_f;
    _ = &f;
    return cpfmax(0.0, cpfmin(f, 1.0));
}
pub fn cpflerp(arg_f1: cpFloat, arg_f2: cpFloat, arg_t: cpFloat) callconv(.C) cpFloat {
    var f1 = arg_f1;
    _ = &f1;
    var f2 = arg_f2;
    _ = &f2;
    var t = arg_t;
    _ = &t;
    return (f1 * (1.0 - t)) + (f2 * t);
}
pub fn cpflerpconst(arg_f1: cpFloat, arg_f2: cpFloat, arg_d: cpFloat) callconv(.C) cpFloat {
    var f1 = arg_f1;
    _ = &f1;
    var f2 = arg_f2;
    _ = &f2;
    var d = arg_d;
    _ = &d;
    return f1 + cpfclamp(f2 - f1, -d, d);
}
pub const cpHashValue = usize;
pub const cpCollisionID = u32;
pub const cpBool = u8;
pub const cpDataPointer = ?*anyopaque;
pub const cpCollisionType = usize;
pub const cpGroup = usize;
pub const cpBitmask = c_uint;
pub const cpTimestamp = c_uint;
pub const struct_cpVect = extern struct {
    x: cpFloat = @import("std").mem.zeroes(cpFloat),
    y: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpVect = struct_cpVect;
pub const struct_cpTransform = extern struct {
    a: cpFloat = @import("std").mem.zeroes(cpFloat),
    b: cpFloat = @import("std").mem.zeroes(cpFloat),
    c: cpFloat = @import("std").mem.zeroes(cpFloat),
    d: cpFloat = @import("std").mem.zeroes(cpFloat),
    tx: cpFloat = @import("std").mem.zeroes(cpFloat),
    ty: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpTransform = struct_cpTransform;
pub const struct_cpMat2x2 = extern struct {
    a: cpFloat = @import("std").mem.zeroes(cpFloat),
    b: cpFloat = @import("std").mem.zeroes(cpFloat),
    c: cpFloat = @import("std").mem.zeroes(cpFloat),
    d: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpMat2x2 = struct_cpMat2x2;
pub const struct_cpArray = opaque {};
pub const cpArray = struct_cpArray;
pub const struct_cpHashSet = opaque {};
pub const cpHashSet = struct_cpHashSet;
pub const struct_cpBody = opaque {};
pub const cpBody = struct_cpBody;
pub const struct_cpShape = opaque {};
pub const cpShape = struct_cpShape;
pub const struct_cpCircleShape = opaque {};
pub const cpCircleShape = struct_cpCircleShape;
pub const struct_cpSegmentShape = opaque {};
pub const cpSegmentShape = struct_cpSegmentShape;
pub const struct_cpPolyShape = opaque {};
pub const cpPolyShape = struct_cpPolyShape;
pub const struct_cpConstraint = opaque {};
pub const cpConstraint = struct_cpConstraint;
pub const struct_cpPinJoint = opaque {};
pub const cpPinJoint = struct_cpPinJoint;
pub const struct_cpSlideJoint = opaque {};
pub const cpSlideJoint = struct_cpSlideJoint;
pub const struct_cpPivotJoint = opaque {};
pub const cpPivotJoint = struct_cpPivotJoint;
pub const struct_cpGrooveJoint = opaque {};
pub const cpGrooveJoint = struct_cpGrooveJoint;
pub const struct_cpDampedSpring = opaque {};
pub const cpDampedSpring = struct_cpDampedSpring;
pub const struct_cpDampedRotarySpring = opaque {};
pub const cpDampedRotarySpring = struct_cpDampedRotarySpring;
pub const struct_cpRotaryLimitJoint = opaque {};
pub const cpRotaryLimitJoint = struct_cpRotaryLimitJoint;
pub const struct_cpRatchetJoint = opaque {};
pub const cpRatchetJoint = struct_cpRatchetJoint;
pub const struct_cpGearJoint = opaque {};
pub const cpGearJoint = struct_cpGearJoint;
pub const struct_cpSimpleMotorJoint = opaque {};
pub const cpSimpleMotorJoint = struct_cpSimpleMotorJoint;
pub const struct_cpArbiter = opaque {};
pub const cpArbiter = struct_cpArbiter;
pub const struct_cpSpace = opaque {};
pub const cpSpace = struct_cpSpace;
pub const cpCollisionBeginFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) cpBool;
pub const cpCollisionPreSolveFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) cpBool;
pub const cpCollisionPostSolveFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) void;
pub const cpCollisionSeparateFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) void;
pub const struct_cpCollisionHandler = extern struct {
    typeA: cpCollisionType = @import("std").mem.zeroes(cpCollisionType),
    typeB: cpCollisionType = @import("std").mem.zeroes(cpCollisionType),
    beginFunc: cpCollisionBeginFunc = @import("std").mem.zeroes(cpCollisionBeginFunc),
    preSolveFunc: cpCollisionPreSolveFunc = @import("std").mem.zeroes(cpCollisionPreSolveFunc),
    postSolveFunc: cpCollisionPostSolveFunc = @import("std").mem.zeroes(cpCollisionPostSolveFunc),
    separateFunc: cpCollisionSeparateFunc = @import("std").mem.zeroes(cpCollisionSeparateFunc),
    userData: cpDataPointer = @import("std").mem.zeroes(cpDataPointer),
};
pub const cpCollisionHandler = struct_cpCollisionHandler;
const struct_unnamed_3 = extern struct {
    pointA: cpVect = @import("std").mem.zeroes(cpVect),
    pointB: cpVect = @import("std").mem.zeroes(cpVect),
    distance: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const struct_cpContactPointSet = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    normal: cpVect = @import("std").mem.zeroes(cpVect),
    points: [2]struct_unnamed_3 = @import("std").mem.zeroes([2]struct_unnamed_3),
};
pub const cpContactPointSet = struct_cpContactPointSet;
pub const cpvzero: cpVect = cpVect{
    .x = 0.0,
    .y = 0.0,
};
pub fn cpv(x: cpFloat, y: cpFloat) callconv(.C) cpVect {
    _ = &x;
    _ = &y;
    var v: cpVect = cpVect{
        .x = x,
        .y = y,
    };
    _ = &v;
    return v;
}
pub fn cpveql(v1: cpVect, v2: cpVect) callconv(.C) cpBool {
    _ = &v1;
    _ = &v2;
    return @as(cpBool, @intFromBool((v1.x == v2.x) and (v1.y == v2.y)));
}
pub fn cpvadd(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    return cpv(v1.x + v2.x, v1.y + v2.y);
}
pub fn cpvsub(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    return cpv(v1.x - v2.x, v1.y - v2.y);
}
pub fn cpvneg(v: cpVect) callconv(.C) cpVect {
    _ = &v;
    return cpv(-v.x, -v.y);
}
pub fn cpvmult(v: cpVect, s: cpFloat) callconv(.C) cpVect {
    _ = &v;
    _ = &s;
    return cpv(v.x * s, v.y * s);
}
pub fn cpvdot(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    _ = &v1;
    _ = &v2;
    return (v1.x * v2.x) + (v1.y * v2.y);
}
pub fn cpvcross(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    _ = &v1;
    _ = &v2;
    return (v1.x * v2.y) - (v1.y * v2.x);
}
pub fn cpvperp(v: cpVect) callconv(.C) cpVect {
    _ = &v;
    return cpv(-v.y, v.x);
}
pub fn cpvrperp(v: cpVect) callconv(.C) cpVect {
    _ = &v;
    return cpv(v.y, -v.x);
}
pub fn cpvproject(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    return cpvmult(v2, cpvdot(v1, v2) / cpvdot(v2, v2));
}
pub fn cpvforangle(a: cpFloat) callconv(.C) cpVect {
    _ = &a;
    return cpv(cosf(a), sinf(a));
}
pub fn cpvtoangle(v: cpVect) callconv(.C) cpFloat {
    _ = &v;
    return atan2f(v.y, v.x);
}
pub fn cpvrotate(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    return cpv((v1.x * v2.x) - (v1.y * v2.y), (v1.x * v2.y) + (v1.y * v2.x));
}
pub fn cpvunrotate(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    return cpv((v1.x * v2.x) + (v1.y * v2.y), (v1.y * v2.x) - (v1.x * v2.y));
}
pub fn cpvlengthsq(v: cpVect) callconv(.C) cpFloat {
    _ = &v;
    return cpvdot(v, v);
}
pub fn cpvlength(v: cpVect) callconv(.C) cpFloat {
    _ = &v;
    return sqrtf(cpvdot(v, v));
}
pub fn cpvlerp(v1: cpVect, v2: cpVect, t: cpFloat) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    _ = &t;
    return cpvadd(cpvmult(v1, 1.0 - t), cpvmult(v2, t));
}
pub fn cpvnormalize(v: cpVect) callconv(.C) cpVect {
    _ = &v;
    return cpvmult(v, 1.0 / (cpvlength(v) + 0.000000000000000000000000000000000000011754943508222875));
}
pub fn cpvslerp(v1: cpVect, v2: cpVect, t: cpFloat) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    _ = &t;
    var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2));
    _ = &dot;
    var omega: cpFloat = acosf(cpfclamp(dot, -1.0, 1.0));
    _ = &omega;
    if (@as(f64, @floatCast(omega)) < 0.001) {
        return cpvlerp(v1, v2, t);
    } else {
        var denom: cpFloat = 1.0 / sinf(omega);
        _ = &denom;
        return cpvadd(cpvmult(v1, sinf((1.0 - t) * omega) * denom), cpvmult(v2, sinf(t * omega) * denom));
    }
    return @import("std").mem.zeroes(cpVect);
}
pub fn cpvslerpconst(v1: cpVect, v2: cpVect, a: cpFloat) callconv(.C) cpVect {
    _ = &v1;
    _ = &v2;
    _ = &a;
    var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2));
    _ = &dot;
    var omega: cpFloat = acosf(cpfclamp(dot, -1.0, 1.0));
    _ = &omega;
    return cpvslerp(v1, v2, cpfmin(a, omega) / omega);
}
pub fn cpvclamp(v: cpVect, len: cpFloat) callconv(.C) cpVect {
    _ = &v;
    _ = &len;
    return if (cpvdot(v, v) > (len * len)) cpvmult(cpvnormalize(v), len) else v;
}
pub fn cpvlerpconst(arg_v1: cpVect, arg_v2: cpVect, arg_d: cpFloat) callconv(.C) cpVect {
    var v1 = arg_v1;
    _ = &v1;
    var v2 = arg_v2;
    _ = &v2;
    var d = arg_d;
    _ = &d;
    return cpvadd(v1, cpvclamp(cpvsub(v2, v1), d));
}
pub fn cpvdist(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    _ = &v1;
    _ = &v2;
    return cpvlength(cpvsub(v1, v2));
}
pub fn cpvdistsq(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    _ = &v1;
    _ = &v2;
    return cpvlengthsq(cpvsub(v1, v2));
}
pub fn cpvnear(v1: cpVect, v2: cpVect, dist: cpFloat) callconv(.C) cpBool {
    _ = &v1;
    _ = &v2;
    _ = &dist;
    return @as(cpBool, @intFromBool(cpvdistsq(v1, v2) < (dist * dist)));
}
pub fn cpMat2x2New(arg_a: cpFloat, arg_b: cpFloat, arg_c: cpFloat, arg_d: cpFloat) callconv(.C) cpMat2x2 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var c = arg_c;
    _ = &c;
    var d = arg_d;
    _ = &d;
    var m: cpMat2x2 = cpMat2x2{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
    };
    _ = &m;
    return m;
}
pub fn cpMat2x2Transform(arg_m: cpMat2x2, arg_v: cpVect) callconv(.C) cpVect {
    var m = arg_m;
    _ = &m;
    var v = arg_v;
    _ = &v;
    return cpv((v.x * m.a) + (v.y * m.b), (v.x * m.c) + (v.y * m.d));
}
pub const struct_cpBB = extern struct {
    l: cpFloat = @import("std").mem.zeroes(cpFloat),
    b: cpFloat = @import("std").mem.zeroes(cpFloat),
    r: cpFloat = @import("std").mem.zeroes(cpFloat),
    t: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpBB = struct_cpBB;
pub fn cpBBNew(l: cpFloat, b: cpFloat, r: cpFloat, t: cpFloat) callconv(.C) cpBB {
    _ = &l;
    _ = &b;
    _ = &r;
    _ = &t;
    var bb: cpBB = cpBB{
        .l = l,
        .b = b,
        .r = r,
        .t = t,
    };
    _ = &bb;
    return bb;
}
pub fn cpBBNewForExtents(c: cpVect, hw: cpFloat, hh: cpFloat) callconv(.C) cpBB {
    _ = &c;
    _ = &hw;
    _ = &hh;
    return cpBBNew(c.x - hw, c.y - hh, c.x + hw, c.y + hh);
}
pub fn cpBBNewForCircle(p: cpVect, r: cpFloat) callconv(.C) cpBB {
    _ = &p;
    _ = &r;
    return cpBBNewForExtents(p, r, r);
}
pub fn cpBBIntersects(a: cpBB, b: cpBB) callconv(.C) cpBool {
    _ = &a;
    _ = &b;
    return @as(cpBool, @intFromBool((((a.l <= b.r) and (b.l <= a.r)) and (a.b <= b.t)) and (b.b <= a.t)));
}
pub fn cpBBContainsBB(bb: cpBB, other: cpBB) callconv(.C) cpBool {
    _ = &bb;
    _ = &other;
    return @as(cpBool, @intFromBool((((bb.l <= other.l) and (bb.r >= other.r)) and (bb.b <= other.b)) and (bb.t >= other.t)));
}
pub fn cpBBContainsVect(bb: cpBB, v: cpVect) callconv(.C) cpBool {
    _ = &bb;
    _ = &v;
    return @as(cpBool, @intFromBool((((bb.l <= v.x) and (bb.r >= v.x)) and (bb.b <= v.y)) and (bb.t >= v.y)));
}
pub fn cpBBMerge(a: cpBB, b: cpBB) callconv(.C) cpBB {
    _ = &a;
    _ = &b;
    return cpBBNew(cpfmin(a.l, b.l), cpfmin(a.b, b.b), cpfmax(a.r, b.r), cpfmax(a.t, b.t));
}
pub fn cpBBExpand(bb: cpBB, v: cpVect) callconv(.C) cpBB {
    _ = &bb;
    _ = &v;
    return cpBBNew(cpfmin(bb.l, v.x), cpfmin(bb.b, v.y), cpfmax(bb.r, v.x), cpfmax(bb.t, v.y));
}
pub fn cpBBCenter(arg_bb: cpBB) callconv(.C) cpVect {
    var bb = arg_bb;
    _ = &bb;
    return cpvlerp(cpv(bb.l, bb.b), cpv(bb.r, bb.t), 0.5);
}
pub fn cpBBArea(arg_bb: cpBB) callconv(.C) cpFloat {
    var bb = arg_bb;
    _ = &bb;
    return (bb.r - bb.l) * (bb.t - bb.b);
}
pub fn cpBBMergedArea(arg_a: cpBB, arg_b: cpBB) callconv(.C) cpFloat {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return (cpfmax(a.r, b.r) - cpfmin(a.l, b.l)) * (cpfmax(a.t, b.t) - cpfmin(a.b, b.b));
}
pub fn cpBBSegmentQuery(arg_bb: cpBB, arg_a: cpVect, arg_b: cpVect) callconv(.C) cpFloat {
    var bb = arg_bb;
    _ = &bb;
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var delta: cpVect = cpvsub(b, a);
    _ = &delta;
    var tmin: cpFloat = -__builtin_inff();
    _ = &tmin;
    var tmax: cpFloat = __builtin_inff();
    _ = &tmax;
    if (delta.x == 0.0) {
        if ((a.x < bb.l) or (bb.r < a.x)) return __builtin_inff();
    } else {
        var t1: cpFloat = (bb.l - a.x) / delta.x;
        _ = &t1;
        var t2: cpFloat = (bb.r - a.x) / delta.x;
        _ = &t2;
        tmin = cpfmax(tmin, cpfmin(t1, t2));
        tmax = cpfmin(tmax, cpfmax(t1, t2));
    }
    if (delta.y == 0.0) {
        if ((a.y < bb.b) or (bb.t < a.y)) return __builtin_inff();
    } else {
        var t1: cpFloat = (bb.b - a.y) / delta.y;
        _ = &t1;
        var t2: cpFloat = (bb.t - a.y) / delta.y;
        _ = &t2;
        tmin = cpfmax(tmin, cpfmin(t1, t2));
        tmax = cpfmin(tmax, cpfmax(t1, t2));
    }
    if (((tmin <= tmax) and (0.0 <= tmax)) and (tmin <= 1.0)) {
        return cpfmax(tmin, 0.0);
    } else {
        return __builtin_inff();
    }
    return @import("std").mem.zeroes(cpFloat);
}
pub fn cpBBIntersectsSegment(arg_bb: cpBB, arg_a: cpVect, arg_b: cpVect) callconv(.C) cpBool {
    var bb = arg_bb;
    _ = &bb;
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return @as(cpBool, @intFromBool(cpBBSegmentQuery(bb, a, b) != __builtin_inff()));
}
pub fn cpBBClampVect(bb: cpBB, v: cpVect) callconv(.C) cpVect {
    _ = &bb;
    _ = &v;
    return cpv(cpfclamp(v.x, bb.l, bb.r), cpfclamp(v.y, bb.b, bb.t));
}
pub fn cpBBWrapVect(bb: cpBB, v: cpVect) callconv(.C) cpVect {
    _ = &bb;
    _ = &v;
    var dx: cpFloat = cpfabs(bb.r - bb.l);
    _ = &dx;
    var modx: cpFloat = fmodf(v.x - bb.l, dx);
    _ = &modx;
    var x: cpFloat = if (modx > 0.0) modx else modx + dx;
    _ = &x;
    var dy: cpFloat = cpfabs(bb.t - bb.b);
    _ = &dy;
    var mody: cpFloat = fmodf(v.y - bb.b, dy);
    _ = &mody;
    var y: cpFloat = if (mody > 0.0) mody else mody + dy;
    _ = &y;
    return cpv(x + bb.l, y + bb.b);
}
pub fn cpBBOffset(bb: cpBB, v: cpVect) callconv(.C) cpBB {
    _ = &bb;
    _ = &v;
    return cpBBNew(bb.l + v.x, bb.b + v.y, bb.r + v.x, bb.t + v.y);
}
pub const cpTransformIdentity: cpTransform = cpTransform{
    .a = 1.0,
    .b = 0.0,
    .c = 0.0,
    .d = 1.0,
    .tx = 0.0,
    .ty = 0.0,
};
pub fn cpTransformNew(arg_a: cpFloat, arg_b: cpFloat, arg_c: cpFloat, arg_d: cpFloat, arg_tx: cpFloat, arg_ty: cpFloat) callconv(.C) cpTransform {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var c = arg_c;
    _ = &c;
    var d = arg_d;
    _ = &d;
    var tx = arg_tx;
    _ = &tx;
    var ty = arg_ty;
    _ = &ty;
    var t: cpTransform = cpTransform{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
        .tx = tx,
        .ty = ty,
    };
    _ = &t;
    return t;
}
pub fn cpTransformNewTranspose(arg_a: cpFloat, arg_c: cpFloat, arg_tx: cpFloat, arg_b: cpFloat, arg_d: cpFloat, arg_ty: cpFloat) callconv(.C) cpTransform {
    var a = arg_a;
    _ = &a;
    var c = arg_c;
    _ = &c;
    var tx = arg_tx;
    _ = &tx;
    var b = arg_b;
    _ = &b;
    var d = arg_d;
    _ = &d;
    var ty = arg_ty;
    _ = &ty;
    var t: cpTransform = cpTransform{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
        .tx = tx,
        .ty = ty,
    };
    _ = &t;
    return t;
}
pub fn cpTransformInverse(arg_t: cpTransform) callconv(.C) cpTransform {
    var t = arg_t;
    _ = &t;
    var inv_det: cpFloat = @as(cpFloat, @floatCast(1.0 / @as(f64, @floatCast((t.a * t.d) - (t.c * t.b)))));
    _ = &inv_det;
    return cpTransformNewTranspose(t.d * inv_det, -t.c * inv_det, ((t.c * t.ty) - (t.tx * t.d)) * inv_det, -t.b * inv_det, t.a * inv_det, ((t.tx * t.b) - (t.a * t.ty)) * inv_det);
}
pub fn cpTransformMult(arg_t1: cpTransform, arg_t2: cpTransform) callconv(.C) cpTransform {
    var t1 = arg_t1;
    _ = &t1;
    var t2 = arg_t2;
    _ = &t2;
    return cpTransformNewTranspose((t1.a * t2.a) + (t1.c * t2.b), (t1.a * t2.c) + (t1.c * t2.d), ((t1.a * t2.tx) + (t1.c * t2.ty)) + t1.tx, (t1.b * t2.a) + (t1.d * t2.b), (t1.b * t2.c) + (t1.d * t2.d), ((t1.b * t2.tx) + (t1.d * t2.ty)) + t1.ty);
}
pub fn cpTransformPoint(arg_t: cpTransform, arg_p: cpVect) callconv(.C) cpVect {
    var t = arg_t;
    _ = &t;
    var p = arg_p;
    _ = &p;
    return cpv(((t.a * p.x) + (t.c * p.y)) + t.tx, ((t.b * p.x) + (t.d * p.y)) + t.ty);
}
pub fn cpTransformVect(arg_t: cpTransform, arg_v: cpVect) callconv(.C) cpVect {
    var t = arg_t;
    _ = &t;
    var v = arg_v;
    _ = &v;
    return cpv((t.a * v.x) + (t.c * v.y), (t.b * v.x) + (t.d * v.y));
}
pub fn cpTransformbBB(arg_t: cpTransform, arg_bb: cpBB) callconv(.C) cpBB {
    var t = arg_t;
    _ = &t;
    var bb = arg_bb;
    _ = &bb;
    var center: cpVect = cpBBCenter(bb);
    _ = &center;
    var hw: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(bb.r - bb.l)) * 0.5));
    _ = &hw;
    var hh: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(bb.t - bb.b)) * 0.5));
    _ = &hh;
    var a: cpFloat = t.a * hw;
    _ = &a;
    var b: cpFloat = t.c * hh;
    _ = &b;
    var d: cpFloat = t.b * hw;
    _ = &d;
    var e: cpFloat = t.d * hh;
    _ = &e;
    var hw_max: cpFloat = cpfmax(cpfabs(a + b), cpfabs(a - b));
    _ = &hw_max;
    var hh_max: cpFloat = cpfmax(cpfabs(d + e), cpfabs(d - e));
    _ = &hh_max;
    return cpBBNewForExtents(cpTransformPoint(t, center), hw_max, hh_max);
}
pub fn cpTransformTranslate(arg_translate: cpVect) callconv(.C) cpTransform {
    var translate = arg_translate;
    _ = &translate;
    return cpTransformNewTranspose(@as(cpFloat, @floatCast(1.0)), @as(cpFloat, @floatCast(0.0)), translate.x, @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(1.0)), translate.y);
}
pub fn cpTransformScale(arg_scaleX: cpFloat, arg_scaleY: cpFloat) callconv(.C) cpTransform {
    var scaleX = arg_scaleX;
    _ = &scaleX;
    var scaleY = arg_scaleY;
    _ = &scaleY;
    return cpTransformNewTranspose(scaleX, @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(0.0)), scaleY, @as(cpFloat, @floatCast(0.0)));
}
pub fn cpTransformRotate(arg_radians: cpFloat) callconv(.C) cpTransform {
    var radians = arg_radians;
    _ = &radians;
    var rot: cpVect = cpvforangle(radians);
    _ = &rot;
    return cpTransformNewTranspose(rot.x, -rot.y, @as(cpFloat, @floatCast(0.0)), rot.y, rot.x, @as(cpFloat, @floatCast(0.0)));
}
pub fn cpTransformRigid(arg_translate: cpVect, arg_radians: cpFloat) callconv(.C) cpTransform {
    var translate = arg_translate;
    _ = &translate;
    var radians = arg_radians;
    _ = &radians;
    var rot: cpVect = cpvforangle(radians);
    _ = &rot;
    return cpTransformNewTranspose(rot.x, -rot.y, translate.x, rot.y, rot.x, translate.y);
}
pub fn cpTransformRigidInverse(arg_t: cpTransform) callconv(.C) cpTransform {
    var t = arg_t;
    _ = &t;
    return cpTransformNewTranspose(t.d, -t.c, (t.c * t.ty) - (t.tx * t.d), -t.b, t.a, (t.tx * t.b) - (t.a * t.ty));
}
pub fn cpTransformWrap(arg_outer: cpTransform, arg_inner: cpTransform) callconv(.C) cpTransform {
    var outer = arg_outer;
    _ = &outer;
    var inner = arg_inner;
    _ = &inner;
    return cpTransformMult(cpTransformInverse(outer), cpTransformMult(inner, outer));
}
pub fn cpTransformWrapInverse(arg_outer: cpTransform, arg_inner: cpTransform) callconv(.C) cpTransform {
    var outer = arg_outer;
    _ = &outer;
    var inner = arg_inner;
    _ = &inner;
    return cpTransformMult(outer, cpTransformMult(inner, cpTransformInverse(outer)));
}
pub fn cpTransformOrtho(arg_bb: cpBB) callconv(.C) cpTransform {
    var bb = arg_bb;
    _ = &bb;
    return cpTransformNewTranspose(@as(cpFloat, @floatCast(2.0 / @as(f64, @floatCast(bb.r - bb.l)))), @as(cpFloat, @floatCast(0.0)), -(bb.r + bb.l) / (bb.r - bb.l), @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(2.0 / @as(f64, @floatCast(bb.t - bb.b)))), -(bb.t + bb.b) / (bb.t - bb.b));
}
pub fn cpTransformBoneScale(arg_v0: cpVect, arg_v1: cpVect) callconv(.C) cpTransform {
    var v0 = arg_v0;
    _ = &v0;
    var v1 = arg_v1;
    _ = &v1;
    var d: cpVect = cpvsub(v1, v0);
    _ = &d;
    return cpTransformNewTranspose(d.x, -d.y, v0.x, d.y, d.x, v0.y);
}
pub fn cpTransformAxialScale(arg_axis: cpVect, arg_pivot: cpVect, arg_scale: cpFloat) callconv(.C) cpTransform {
    var axis = arg_axis;
    _ = &axis;
    var pivot = arg_pivot;
    _ = &pivot;
    var scale = arg_scale;
    _ = &scale;
    var A: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(axis.x * axis.y)) * (@as(f64, @floatCast(scale)) - 1.0)));
    _ = &A;
    var B: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(cpvdot(axis, pivot))) * (1.0 - @as(f64, @floatCast(scale)))));
    _ = &B;
    return cpTransformNewTranspose(((scale * axis.x) * axis.x) + (axis.y * axis.y), A, axis.x * B, A, (axis.x * axis.x) + ((scale * axis.y) * axis.y), axis.y * B);
}
pub const cpSpatialIndexBBFunc = ?*const fn (?*anyopaque) callconv(.C) cpBB;
pub const cpSpatialIndexIteratorFunc = ?*const fn (?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexQueryFunc = ?*const fn (?*anyopaque, ?*anyopaque, cpCollisionID, ?*anyopaque) callconv(.C) cpCollisionID;
pub const cpSpatialIndexSegmentQueryFunc = ?*const fn (?*anyopaque, ?*anyopaque, ?*anyopaque) callconv(.C) cpFloat;
pub const cpSpatialIndexClass = struct_cpSpatialIndexClass;
pub const struct_cpSpatialIndex = extern struct {
    klass: [*c]cpSpatialIndexClass = @import("std").mem.zeroes([*c]cpSpatialIndexClass),
    bbfunc: cpSpatialIndexBBFunc = @import("std").mem.zeroes(cpSpatialIndexBBFunc),
    staticIndex: [*c]cpSpatialIndex = @import("std").mem.zeroes([*c]cpSpatialIndex),
    dynamicIndex: [*c]cpSpatialIndex = @import("std").mem.zeroes([*c]cpSpatialIndex),
};
pub const cpSpatialIndex = struct_cpSpatialIndex;
pub const cpSpatialIndexDestroyImpl = ?*const fn ([*c]cpSpatialIndex) callconv(.C) void;
pub const cpSpatialIndexCountImpl = ?*const fn ([*c]cpSpatialIndex) callconv(.C) c_int;
pub const cpSpatialIndexEachImpl = ?*const fn ([*c]cpSpatialIndex, cpSpatialIndexIteratorFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexContainsImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) cpBool;
pub const cpSpatialIndexInsertImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexRemoveImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexReindexImpl = ?*const fn ([*c]cpSpatialIndex) callconv(.C) void;
pub const cpSpatialIndexReindexObjectImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexReindexQueryImpl = ?*const fn ([*c]cpSpatialIndex, cpSpatialIndexQueryFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexQueryImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpBB, cpSpatialIndexQueryFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexSegmentQueryImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpVect, cpVect, cpFloat, cpSpatialIndexSegmentQueryFunc, ?*anyopaque) callconv(.C) void;
pub const struct_cpSpatialIndexClass = extern struct {
    destroy: cpSpatialIndexDestroyImpl = @import("std").mem.zeroes(cpSpatialIndexDestroyImpl),
    count: cpSpatialIndexCountImpl = @import("std").mem.zeroes(cpSpatialIndexCountImpl),
    each: cpSpatialIndexEachImpl = @import("std").mem.zeroes(cpSpatialIndexEachImpl),
    contains: cpSpatialIndexContainsImpl = @import("std").mem.zeroes(cpSpatialIndexContainsImpl),
    insert: cpSpatialIndexInsertImpl = @import("std").mem.zeroes(cpSpatialIndexInsertImpl),
    remove: cpSpatialIndexRemoveImpl = @import("std").mem.zeroes(cpSpatialIndexRemoveImpl),
    reindex: cpSpatialIndexReindexImpl = @import("std").mem.zeroes(cpSpatialIndexReindexImpl),
    reindexObject: cpSpatialIndexReindexObjectImpl = @import("std").mem.zeroes(cpSpatialIndexReindexObjectImpl),
    reindexQuery: cpSpatialIndexReindexQueryImpl = @import("std").mem.zeroes(cpSpatialIndexReindexQueryImpl),
    query: cpSpatialIndexQueryImpl = @import("std").mem.zeroes(cpSpatialIndexQueryImpl),
    segmentQuery: cpSpatialIndexSegmentQueryImpl = @import("std").mem.zeroes(cpSpatialIndexSegmentQueryImpl),
};
pub const struct_cpSpaceHash = opaque {};
pub const cpSpaceHash = struct_cpSpaceHash;
pub extern fn cpSpaceHashAlloc() ?*cpSpaceHash;
pub extern fn cpSpaceHashInit(hash: ?*cpSpaceHash, celldim: cpFloat, numcells: c_int, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSpaceHashNew(celldim: cpFloat, cells: c_int, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSpaceHashResize(hash: ?*cpSpaceHash, celldim: cpFloat, numcells: c_int) void;
pub const struct_cpBBTree = opaque {};
pub const cpBBTree = struct_cpBBTree;
pub extern fn cpBBTreeAlloc() ?*cpBBTree;
pub extern fn cpBBTreeInit(tree: ?*cpBBTree, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpBBTreeNew(bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpBBTreeOptimize(index: [*c]cpSpatialIndex) void;
pub const cpBBTreeVelocityFunc = ?*const fn (?*anyopaque) callconv(.C) cpVect;
pub extern fn cpBBTreeSetVelocityFunc(index: [*c]cpSpatialIndex, func: cpBBTreeVelocityFunc) void;
pub const struct_cpSweep1D = opaque {};
pub const cpSweep1D = struct_cpSweep1D;
pub extern fn cpSweep1DAlloc() ?*cpSweep1D;
pub extern fn cpSweep1DInit(sweep: ?*cpSweep1D, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSweep1DNew(bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSpatialIndexFree(index: [*c]cpSpatialIndex) void;
pub extern fn cpSpatialIndexCollideStatic(dynamicIndex: [*c]cpSpatialIndex, staticIndex: [*c]cpSpatialIndex, func: cpSpatialIndexQueryFunc, data: ?*anyopaque) void;
pub fn cpSpatialIndexDestroy(arg_index: [*c]cpSpatialIndex) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    if (index.*.klass != null) {
        index.*.klass.*.destroy.?(index);
    }
}
pub fn cpSpatialIndexCount(arg_index: [*c]cpSpatialIndex) callconv(.C) c_int {
    var index = arg_index;
    _ = &index;
    return index.*.klass.*.count.?(index);
}
pub fn cpSpatialIndexEach(arg_index: [*c]cpSpatialIndex, arg_func: cpSpatialIndexIteratorFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    var func = arg_func;
    _ = &func;
    var data = arg_data;
    _ = &data;
    index.*.klass.*.each.?(index, func, data);
}
pub fn cpSpatialIndexContains(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) cpBool {
    var index = arg_index;
    _ = &index;
    var obj = arg_obj;
    _ = &obj;
    var hashid = arg_hashid;
    _ = &hashid;
    return index.*.klass.*.contains.?(index, obj, hashid);
}
pub fn cpSpatialIndexInsert(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    var obj = arg_obj;
    _ = &obj;
    var hashid = arg_hashid;
    _ = &hashid;
    index.*.klass.*.insert.?(index, obj, hashid);
}
pub fn cpSpatialIndexRemove(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    var obj = arg_obj;
    _ = &obj;
    var hashid = arg_hashid;
    _ = &hashid;
    index.*.klass.*.remove.?(index, obj, hashid);
}
pub fn cpSpatialIndexReindex(arg_index: [*c]cpSpatialIndex) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    index.*.klass.*.reindex.?(index);
}
pub fn cpSpatialIndexReindexObject(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    var obj = arg_obj;
    _ = &obj;
    var hashid = arg_hashid;
    _ = &hashid;
    index.*.klass.*.reindexObject.?(index, obj, hashid);
}
pub fn cpSpatialIndexQuery(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_bb: cpBB, arg_func: cpSpatialIndexQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    var obj = arg_obj;
    _ = &obj;
    var bb = arg_bb;
    _ = &bb;
    var func = arg_func;
    _ = &func;
    var data = arg_data;
    _ = &data;
    index.*.klass.*.query.?(index, obj, bb, func, data);
}
pub fn cpSpatialIndexSegmentQuery(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_a: cpVect, arg_b: cpVect, arg_t_exit: cpFloat, arg_func: cpSpatialIndexSegmentQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    var obj = arg_obj;
    _ = &obj;
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var t_exit = arg_t_exit;
    _ = &t_exit;
    var func = arg_func;
    _ = &func;
    var data = arg_data;
    _ = &data;
    index.*.klass.*.segmentQuery.?(index, obj, a, b, t_exit, func, data);
}
pub fn cpSpatialIndexReindexQuery(arg_index: [*c]cpSpatialIndex, arg_func: cpSpatialIndexQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    _ = &index;
    var func = arg_func;
    _ = &func;
    var data = arg_data;
    _ = &data;
    index.*.klass.*.reindexQuery.?(index, func, data);
}
pub extern fn cpArbiterGetRestitution(arb: ?*const cpArbiter) cpFloat;
pub extern fn cpArbiterSetRestitution(arb: ?*cpArbiter, restitution: cpFloat) void;
pub extern fn cpArbiterGetFriction(arb: ?*const cpArbiter) cpFloat;
pub extern fn cpArbiterSetFriction(arb: ?*cpArbiter, friction: cpFloat) void;
pub extern fn cpArbiterGetSurfaceVelocity(arb: ?*cpArbiter) cpVect;
pub extern fn cpArbiterSetSurfaceVelocity(arb: ?*cpArbiter, vr: cpVect) void;
pub extern fn cpArbiterGetUserData(arb: ?*const cpArbiter) cpDataPointer;
pub extern fn cpArbiterSetUserData(arb: ?*cpArbiter, userData: cpDataPointer) void;
pub extern fn cpArbiterTotalImpulse(arb: ?*const cpArbiter) cpVect;
pub extern fn cpArbiterTotalKE(arb: ?*const cpArbiter) cpFloat;
pub extern fn cpArbiterIgnore(arb: ?*cpArbiter) cpBool;
pub extern fn cpArbiterGetShapes(arb: ?*const cpArbiter, a: [*c]?*cpShape, b: [*c]?*cpShape) void;
pub extern fn cpArbiterGetBodies(arb: ?*const cpArbiter, a: [*c]?*cpBody, b: [*c]?*cpBody) void;
pub extern fn cpArbiterGetContactPointSet(arb: ?*const cpArbiter) cpContactPointSet;
pub extern fn cpArbiterSetContactPointSet(arb: ?*cpArbiter, set: [*c]cpContactPointSet) void;
pub extern fn cpArbiterIsFirstContact(arb: ?*const cpArbiter) cpBool;
pub extern fn cpArbiterIsRemoval(arb: ?*const cpArbiter) cpBool;
pub extern fn cpArbiterGetCount(arb: ?*const cpArbiter) c_int;
pub extern fn cpArbiterGetNormal(arb: ?*const cpArbiter) cpVect;
pub extern fn cpArbiterGetPointA(arb: ?*const cpArbiter, i: c_int) cpVect;
pub extern fn cpArbiterGetPointB(arb: ?*const cpArbiter, i: c_int) cpVect;
pub extern fn cpArbiterGetDepth(arb: ?*const cpArbiter, i: c_int) cpFloat;
pub extern fn cpArbiterCallWildcardBeginA(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardBeginB(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardPreSolveA(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardPreSolveB(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardPostSolveA(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub extern fn cpArbiterCallWildcardPostSolveB(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub extern fn cpArbiterCallWildcardSeparateA(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub extern fn cpArbiterCallWildcardSeparateB(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub const CP_BODY_TYPE_DYNAMIC: c_int = 0;
pub const CP_BODY_TYPE_KINEMATIC: c_int = 1;
pub const CP_BODY_TYPE_STATIC: c_int = 2;
pub const enum_cpBodyType = c_uint;
pub const cpBodyType = enum_cpBodyType;
pub const cpBodyVelocityFunc = ?*const fn (?*cpBody, cpVect, cpFloat, cpFloat) callconv(.C) void;
pub const cpBodyPositionFunc = ?*const fn (?*cpBody, cpFloat) callconv(.C) void;
pub extern fn cpBodyAlloc() ?*cpBody;
pub extern fn cpBodyInit(body: ?*cpBody, mass: cpFloat, moment: cpFloat) ?*cpBody;
pub extern fn cpBodyNew(mass: cpFloat, moment: cpFloat) ?*cpBody;
pub extern fn cpBodyNewKinematic() ?*cpBody;
pub extern fn cpBodyNewStatic() ?*cpBody;
pub extern fn cpBodyDestroy(body: ?*cpBody) void;
pub extern fn cpBodyFree(body: ?*cpBody) void;
pub extern fn cpBodyActivate(body: ?*cpBody) void;
pub extern fn cpBodyActivateStatic(body: ?*cpBody, filter: ?*cpShape) void;
pub extern fn cpBodySleep(body: ?*cpBody) void;
pub extern fn cpBodySleepWithGroup(body: ?*cpBody, group: ?*cpBody) void;
pub extern fn cpBodyIsSleeping(body: ?*const cpBody) cpBool;
pub extern fn cpBodyGetType(body: ?*cpBody) cpBodyType;
pub extern fn cpBodySetType(body: ?*cpBody, @"type": cpBodyType) void;
pub extern fn cpBodyGetSpace(body: ?*const cpBody) ?*cpSpace;
pub extern fn cpBodyGetMass(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetMass(body: ?*cpBody, m: cpFloat) void;
pub extern fn cpBodyGetMoment(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetMoment(body: ?*cpBody, i: cpFloat) void;
pub extern fn cpBodyGetPosition(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetPosition(body: ?*cpBody, pos: cpVect) void;
pub extern fn cpBodyGetCenterOfGravity(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetCenterOfGravity(body: ?*cpBody, cog: cpVect) void;
pub extern fn cpBodyGetVelocity(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetVelocity(body: ?*cpBody, velocity: cpVect) void;
pub extern fn cpBodyGetForce(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetForce(body: ?*cpBody, force: cpVect) void;
pub extern fn cpBodyGetAngle(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetAngle(body: ?*cpBody, a: cpFloat) void;
pub extern fn cpBodyGetAngularVelocity(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetAngularVelocity(body: ?*cpBody, angularVelocity: cpFloat) void;
pub extern fn cpBodyGetTorque(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetTorque(body: ?*cpBody, torque: cpFloat) void;
pub extern fn cpBodyGetRotation(body: ?*const cpBody) cpVect;
pub extern fn cpBodyGetUserData(body: ?*const cpBody) cpDataPointer;
pub extern fn cpBodySetUserData(body: ?*cpBody, userData: cpDataPointer) void;
pub extern fn cpBodySetVelocityUpdateFunc(body: ?*cpBody, velocityFunc: cpBodyVelocityFunc) void;
pub extern fn cpBodySetPositionUpdateFunc(body: ?*cpBody, positionFunc: cpBodyPositionFunc) void;
pub extern fn cpBodyUpdateVelocity(body: ?*cpBody, gravity: cpVect, damping: cpFloat, dt: cpFloat) void;
pub extern fn cpBodyUpdatePosition(body: ?*cpBody, dt: cpFloat) void;
pub extern fn cpBodyLocalToWorld(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyWorldToLocal(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyApplyForceAtWorldPoint(body: ?*cpBody, force: cpVect, point: cpVect) void;
pub extern fn cpBodyApplyForceAtLocalPoint(body: ?*cpBody, force: cpVect, point: cpVect) void;
pub extern fn cpBodyApplyImpulseAtWorldPoint(body: ?*cpBody, impulse: cpVect, point: cpVect) void;
pub extern fn cpBodyApplyImpulseAtLocalPoint(body: ?*cpBody, impulse: cpVect, point: cpVect) void;
pub extern fn cpBodyGetVelocityAtWorldPoint(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyGetVelocityAtLocalPoint(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyKineticEnergy(body: ?*const cpBody) cpFloat;
pub const cpBodyShapeIteratorFunc = ?*const fn (?*cpBody, ?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachShape(body: ?*cpBody, func: cpBodyShapeIteratorFunc, data: ?*anyopaque) void;
pub const cpBodyConstraintIteratorFunc = ?*const fn (?*cpBody, ?*cpConstraint, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachConstraint(body: ?*cpBody, func: cpBodyConstraintIteratorFunc, data: ?*anyopaque) void;
pub const cpBodyArbiterIteratorFunc = ?*const fn (?*cpBody, ?*cpArbiter, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachArbiter(body: ?*cpBody, func: cpBodyArbiterIteratorFunc, data: ?*anyopaque) void;
pub const struct_cpPointQueryInfo = extern struct {
    shape: ?*const cpShape = @import("std").mem.zeroes(?*const cpShape),
    point: cpVect = @import("std").mem.zeroes(cpVect),
    distance: cpFloat = @import("std").mem.zeroes(cpFloat),
    gradient: cpVect = @import("std").mem.zeroes(cpVect),
};
pub const cpPointQueryInfo = struct_cpPointQueryInfo;
pub const struct_cpSegmentQueryInfo = extern struct {
    shape: ?*const cpShape = @import("std").mem.zeroes(?*const cpShape),
    point: cpVect = @import("std").mem.zeroes(cpVect),
    normal: cpVect = @import("std").mem.zeroes(cpVect),
    alpha: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpSegmentQueryInfo = struct_cpSegmentQueryInfo;
pub const struct_cpShapeFilter = extern struct {
    group: cpGroup = @import("std").mem.zeroes(cpGroup),
    categories: cpBitmask = @import("std").mem.zeroes(cpBitmask),
    mask: cpBitmask = @import("std").mem.zeroes(cpBitmask),
};
pub const cpShapeFilter = struct_cpShapeFilter;
pub const CP_SHAPE_FILTER_ALL: cpShapeFilter = cpShapeFilter{
    .group = @as(cpGroup, @bitCast(@as(c_long, @as(c_int, 0)))),
    .categories = ~@as(cpBitmask, @bitCast(@as(c_int, 0))),
    .mask = ~@as(cpBitmask, @bitCast(@as(c_int, 0))),
};
pub const CP_SHAPE_FILTER_NONE: cpShapeFilter = cpShapeFilter{
    .group = @as(cpGroup, @bitCast(@as(c_long, @as(c_int, 0)))),
    .categories = ~~@as(cpBitmask, @bitCast(@as(c_int, 0))),
    .mask = ~~@as(cpBitmask, @bitCast(@as(c_int, 0))),
};
pub fn cpShapeFilterNew(arg_group: cpGroup, arg_categories: cpBitmask, arg_mask: cpBitmask) callconv(.C) cpShapeFilter {
    var group = arg_group;
    _ = &group;
    var categories = arg_categories;
    _ = &categories;
    var mask = arg_mask;
    _ = &mask;
    var filter: cpShapeFilter = cpShapeFilter{
        .group = group,
        .categories = categories,
        .mask = mask,
    };
    _ = &filter;
    return filter;
}
pub extern fn cpShapeDestroy(shape: ?*cpShape) void;
pub extern fn cpShapeFree(shape: ?*cpShape) void;
pub extern fn cpShapeCacheBB(shape: ?*cpShape) cpBB;
pub extern fn cpShapeUpdate(shape: ?*cpShape, transform: cpTransform) cpBB;
pub extern fn cpShapePointQuery(shape: ?*const cpShape, p: cpVect, out: [*c]cpPointQueryInfo) cpFloat;
pub extern fn cpShapeSegmentQuery(shape: ?*const cpShape, a: cpVect, b: cpVect, radius: cpFloat, info: [*c]cpSegmentQueryInfo) cpBool;
pub extern fn cpShapesCollide(a: ?*const cpShape, b: ?*const cpShape) cpContactPointSet;
pub extern fn cpShapeGetSpace(shape: ?*const cpShape) ?*cpSpace;
pub extern fn cpShapeGetBody(shape: ?*const cpShape) ?*cpBody;
pub extern fn cpShapeSetBody(shape: ?*cpShape, body: ?*cpBody) void;
pub extern fn cpShapeGetMass(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeSetMass(shape: ?*cpShape, mass: cpFloat) void;
pub extern fn cpShapeGetDensity(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeSetDensity(shape: ?*cpShape, density: cpFloat) void;
pub extern fn cpShapeGetMoment(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeGetArea(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeGetCenterOfGravity(shape: ?*cpShape) cpVect;
pub extern fn cpShapeGetBB(shape: ?*const cpShape) cpBB;
pub extern fn cpShapeGetSensor(shape: ?*const cpShape) cpBool;
pub extern fn cpShapeSetSensor(shape: ?*cpShape, sensor: cpBool) void;
pub extern fn cpShapeGetElasticity(shape: ?*const cpShape) cpFloat;
pub extern fn cpShapeSetElasticity(shape: ?*cpShape, elasticity: cpFloat) void;
pub extern fn cpShapeGetFriction(shape: ?*const cpShape) cpFloat;
pub extern fn cpShapeSetFriction(shape: ?*cpShape, friction: cpFloat) void;
pub extern fn cpShapeGetSurfaceVelocity(shape: ?*const cpShape) cpVect;
pub extern fn cpShapeSetSurfaceVelocity(shape: ?*cpShape, surfaceVelocity: cpVect) void;
pub extern fn cpShapeGetUserData(shape: ?*const cpShape) cpDataPointer;
pub extern fn cpShapeSetUserData(shape: ?*cpShape, userData: cpDataPointer) void;
pub extern fn cpShapeGetCollisionType(shape: ?*const cpShape) cpCollisionType;
pub extern fn cpShapeSetCollisionType(shape: ?*cpShape, collisionType: cpCollisionType) void;
pub extern fn cpShapeGetFilter(shape: ?*const cpShape) cpShapeFilter;
pub extern fn cpShapeSetFilter(shape: ?*cpShape, filter: cpShapeFilter) void;
pub extern fn cpCircleShapeAlloc() ?*cpCircleShape;
pub extern fn cpCircleShapeInit(circle: ?*cpCircleShape, body: ?*cpBody, radius: cpFloat, offset: cpVect) ?*cpCircleShape;
pub extern fn cpCircleShapeNew(body: ?*cpBody, radius: cpFloat, offset: cpVect) ?*cpShape;
pub extern fn cpCircleShapeGetOffset(shape: ?*const cpShape) cpVect;
pub extern fn cpCircleShapeGetRadius(shape: ?*const cpShape) cpFloat;
pub extern fn cpSegmentShapeAlloc() ?*cpSegmentShape;
pub extern fn cpSegmentShapeInit(seg: ?*cpSegmentShape, body: ?*cpBody, a: cpVect, b: cpVect, radius: cpFloat) ?*cpSegmentShape;
pub extern fn cpSegmentShapeNew(body: ?*cpBody, a: cpVect, b: cpVect, radius: cpFloat) ?*cpShape;
pub extern fn cpSegmentShapeSetNeighbors(shape: ?*cpShape, prev: cpVect, next: cpVect) void;
pub extern fn cpSegmentShapeGetA(shape: ?*const cpShape) cpVect;
pub extern fn cpSegmentShapeGetB(shape: ?*const cpShape) cpVect;
pub extern fn cpSegmentShapeGetNormal(shape: ?*const cpShape) cpVect;
pub extern fn cpSegmentShapeGetRadius(shape: ?*const cpShape) cpFloat;
pub extern fn cpPolyShapeAlloc() ?*cpPolyShape;
pub extern fn cpPolyShapeInit(poly: ?*cpPolyShape, body: ?*cpBody, count: c_int, verts: [*c]const cpVect, transform: cpTransform, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpPolyShapeInitRaw(poly: ?*cpPolyShape, body: ?*cpBody, count: c_int, verts: [*c]const cpVect, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpPolyShapeNew(body: ?*cpBody, count: c_int, verts: [*c]const cpVect, transform: cpTransform, radius: cpFloat) ?*cpShape;
pub extern fn cpPolyShapeNewRaw(body: ?*cpBody, count: c_int, verts: [*c]const cpVect, radius: cpFloat) ?*cpShape;
pub extern fn cpBoxShapeInit(poly: ?*cpPolyShape, body: ?*cpBody, width: cpFloat, height: cpFloat, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpBoxShapeInit2(poly: ?*cpPolyShape, body: ?*cpBody, box: cpBB, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpBoxShapeNew(body: ?*cpBody, width: cpFloat, height: cpFloat, radius: cpFloat) ?*cpShape;
pub extern fn cpBoxShapeNew2(body: ?*cpBody, box: cpBB, radius: cpFloat) ?*cpShape;
pub extern fn cpPolyShapeGetCount(shape: ?*const cpShape) c_int;
pub extern fn cpPolyShapeGetVert(shape: ?*const cpShape, index: c_int) cpVect;
pub extern fn cpPolyShapeGetRadius(shape: ?*const cpShape) cpFloat;
pub const cpConstraintPreSolveFunc = ?*const fn (?*cpConstraint, ?*cpSpace) callconv(.C) void;
pub const cpConstraintPostSolveFunc = ?*const fn (?*cpConstraint, ?*cpSpace) callconv(.C) void;
pub extern fn cpConstraintDestroy(constraint: ?*cpConstraint) void;
pub extern fn cpConstraintFree(constraint: ?*cpConstraint) void;
pub extern fn cpConstraintGetSpace(constraint: ?*const cpConstraint) ?*cpSpace;
pub extern fn cpConstraintGetBodyA(constraint: ?*const cpConstraint) ?*cpBody;
pub extern fn cpConstraintGetBodyB(constraint: ?*const cpConstraint) ?*cpBody;
pub extern fn cpConstraintGetMaxForce(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpConstraintSetMaxForce(constraint: ?*cpConstraint, maxForce: cpFloat) void;
pub extern fn cpConstraintGetErrorBias(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpConstraintSetErrorBias(constraint: ?*cpConstraint, errorBias: cpFloat) void;
pub extern fn cpConstraintGetMaxBias(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpConstraintSetMaxBias(constraint: ?*cpConstraint, maxBias: cpFloat) void;
pub extern fn cpConstraintGetCollideBodies(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpConstraintSetCollideBodies(constraint: ?*cpConstraint, collideBodies: cpBool) void;
pub extern fn cpConstraintGetPreSolveFunc(constraint: ?*const cpConstraint) cpConstraintPreSolveFunc;
pub extern fn cpConstraintSetPreSolveFunc(constraint: ?*cpConstraint, preSolveFunc: cpConstraintPreSolveFunc) void;
pub extern fn cpConstraintGetPostSolveFunc(constraint: ?*const cpConstraint) cpConstraintPostSolveFunc;
pub extern fn cpConstraintSetPostSolveFunc(constraint: ?*cpConstraint, postSolveFunc: cpConstraintPostSolveFunc) void;
pub extern fn cpConstraintGetUserData(constraint: ?*const cpConstraint) cpDataPointer;
pub extern fn cpConstraintSetUserData(constraint: ?*cpConstraint, userData: cpDataPointer) void;
pub extern fn cpConstraintGetImpulse(constraint: ?*cpConstraint) cpFloat;
pub extern fn cpConstraintIsPinJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpPinJointAlloc() ?*cpPinJoint;
pub extern fn cpPinJointInit(joint: ?*cpPinJoint, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpPinJoint;
pub extern fn cpPinJointNew(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpConstraint;
pub extern fn cpPinJointGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPinJointSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpPinJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPinJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpPinJointGetDist(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpPinJointSetDist(constraint: ?*cpConstraint, dist: cpFloat) void;
pub extern fn cpConstraintIsSlideJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpSlideJointAlloc() ?*cpSlideJoint;
pub extern fn cpSlideJointInit(joint: ?*cpSlideJoint, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, min: cpFloat, max: cpFloat) ?*cpSlideJoint;
pub extern fn cpSlideJointNew(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, min: cpFloat, max: cpFloat) ?*cpConstraint;
pub extern fn cpSlideJointGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpSlideJointSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpSlideJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpSlideJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpSlideJointGetMin(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpSlideJointSetMin(constraint: ?*cpConstraint, min: cpFloat) void;
pub extern fn cpSlideJointGetMax(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpSlideJointSetMax(constraint: ?*cpConstraint, max: cpFloat) void;
pub extern fn cpConstraintIsPivotJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpPivotJointAlloc() ?*cpPivotJoint;
pub extern fn cpPivotJointInit(joint: ?*cpPivotJoint, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpPivotJoint;
pub extern fn cpPivotJointNew(a: ?*cpBody, b: ?*cpBody, pivot: cpVect) ?*cpConstraint;
pub extern fn cpPivotJointNew2(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpConstraint;
pub extern fn cpPivotJointGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPivotJointSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpPivotJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPivotJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpConstraintIsGrooveJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpGrooveJointAlloc() ?*cpGrooveJoint;
pub extern fn cpGrooveJointInit(joint: ?*cpGrooveJoint, a: ?*cpBody, b: ?*cpBody, groove_a: cpVect, groove_b: cpVect, anchorB: cpVect) ?*cpGrooveJoint;
pub extern fn cpGrooveJointNew(a: ?*cpBody, b: ?*cpBody, groove_a: cpVect, groove_b: cpVect, anchorB: cpVect) ?*cpConstraint;
pub extern fn cpGrooveJointGetGrooveA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpGrooveJointSetGrooveA(constraint: ?*cpConstraint, grooveA: cpVect) void;
pub extern fn cpGrooveJointGetGrooveB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpGrooveJointSetGrooveB(constraint: ?*cpConstraint, grooveB: cpVect) void;
pub extern fn cpGrooveJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpGrooveJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpConstraintIsDampedSpring(constraint: ?*const cpConstraint) cpBool;
pub const cpDampedSpringForceFunc = ?*const fn (?*cpConstraint, cpFloat) callconv(.C) cpFloat;
pub extern fn cpDampedSpringAlloc() ?*cpDampedSpring;
pub extern fn cpDampedSpringInit(joint: ?*cpDampedSpring, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, restLength: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpDampedSpring;
pub extern fn cpDampedSpringNew(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, restLength: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpConstraint;
pub extern fn cpDampedSpringGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpDampedSpringSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpDampedSpringGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpDampedSpringSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpDampedSpringGetRestLength(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedSpringSetRestLength(constraint: ?*cpConstraint, restLength: cpFloat) void;
pub extern fn cpDampedSpringGetStiffness(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedSpringSetStiffness(constraint: ?*cpConstraint, stiffness: cpFloat) void;
pub extern fn cpDampedSpringGetDamping(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedSpringSetDamping(constraint: ?*cpConstraint, damping: cpFloat) void;
pub extern fn cpDampedSpringGetSpringForceFunc(constraint: ?*const cpConstraint) cpDampedSpringForceFunc;
pub extern fn cpDampedSpringSetSpringForceFunc(constraint: ?*cpConstraint, springForceFunc: cpDampedSpringForceFunc) void;
pub extern fn cpConstraintIsDampedRotarySpring(constraint: ?*const cpConstraint) cpBool;
pub const cpDampedRotarySpringTorqueFunc = ?*const fn (?*struct_cpConstraint, cpFloat) callconv(.C) cpFloat;
pub extern fn cpDampedRotarySpringAlloc() ?*cpDampedRotarySpring;
pub extern fn cpDampedRotarySpringInit(joint: ?*cpDampedRotarySpring, a: ?*cpBody, b: ?*cpBody, restAngle: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpDampedRotarySpring;
pub extern fn cpDampedRotarySpringNew(a: ?*cpBody, b: ?*cpBody, restAngle: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpConstraint;
pub extern fn cpDampedRotarySpringGetRestAngle(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedRotarySpringSetRestAngle(constraint: ?*cpConstraint, restAngle: cpFloat) void;
pub extern fn cpDampedRotarySpringGetStiffness(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedRotarySpringSetStiffness(constraint: ?*cpConstraint, stiffness: cpFloat) void;
pub extern fn cpDampedRotarySpringGetDamping(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedRotarySpringSetDamping(constraint: ?*cpConstraint, damping: cpFloat) void;
pub extern fn cpDampedRotarySpringGetSpringTorqueFunc(constraint: ?*const cpConstraint) cpDampedRotarySpringTorqueFunc;
pub extern fn cpDampedRotarySpringSetSpringTorqueFunc(constraint: ?*cpConstraint, springTorqueFunc: cpDampedRotarySpringTorqueFunc) void;
pub extern fn cpConstraintIsRotaryLimitJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpRotaryLimitJointAlloc() ?*cpRotaryLimitJoint;
pub extern fn cpRotaryLimitJointInit(joint: ?*cpRotaryLimitJoint, a: ?*cpBody, b: ?*cpBody, min: cpFloat, max: cpFloat) ?*cpRotaryLimitJoint;
pub extern fn cpRotaryLimitJointNew(a: ?*cpBody, b: ?*cpBody, min: cpFloat, max: cpFloat) ?*cpConstraint;
pub extern fn cpRotaryLimitJointGetMin(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRotaryLimitJointSetMin(constraint: ?*cpConstraint, min: cpFloat) void;
pub extern fn cpRotaryLimitJointGetMax(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRotaryLimitJointSetMax(constraint: ?*cpConstraint, max: cpFloat) void;
pub extern fn cpConstraintIsRatchetJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpRatchetJointAlloc() ?*cpRatchetJoint;
pub extern fn cpRatchetJointInit(joint: ?*cpRatchetJoint, a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratchet: cpFloat) ?*cpRatchetJoint;
pub extern fn cpRatchetJointNew(a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratchet: cpFloat) ?*cpConstraint;
pub extern fn cpRatchetJointGetAngle(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRatchetJointSetAngle(constraint: ?*cpConstraint, angle: cpFloat) void;
pub extern fn cpRatchetJointGetPhase(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRatchetJointSetPhase(constraint: ?*cpConstraint, phase: cpFloat) void;
pub extern fn cpRatchetJointGetRatchet(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRatchetJointSetRatchet(constraint: ?*cpConstraint, ratchet: cpFloat) void;
pub extern fn cpConstraintIsGearJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpGearJointAlloc() ?*cpGearJoint;
pub extern fn cpGearJointInit(joint: ?*cpGearJoint, a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratio: cpFloat) ?*cpGearJoint;
pub extern fn cpGearJointNew(a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratio: cpFloat) ?*cpConstraint;
pub extern fn cpGearJointGetPhase(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpGearJointSetPhase(constraint: ?*cpConstraint, phase: cpFloat) void;
pub extern fn cpGearJointGetRatio(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpGearJointSetRatio(constraint: ?*cpConstraint, ratio: cpFloat) void;
pub const struct_cpSimpleMotor = opaque {};
pub const cpSimpleMotor = struct_cpSimpleMotor;
pub extern fn cpConstraintIsSimpleMotor(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpSimpleMotorAlloc() ?*cpSimpleMotor;
pub extern fn cpSimpleMotorInit(joint: ?*cpSimpleMotor, a: ?*cpBody, b: ?*cpBody, rate: cpFloat) ?*cpSimpleMotor;
pub extern fn cpSimpleMotorNew(a: ?*cpBody, b: ?*cpBody, rate: cpFloat) ?*cpConstraint;
pub extern fn cpSimpleMotorGetRate(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpSimpleMotorSetRate(constraint: ?*cpConstraint, rate: cpFloat) void;
pub extern fn cpSpaceAlloc() ?*cpSpace;
pub extern fn cpSpaceInit(space: ?*cpSpace) ?*cpSpace;
pub extern fn cpSpaceNew() ?*cpSpace;
pub extern fn cpSpaceDestroy(space: ?*cpSpace) void;
pub extern fn cpSpaceFree(space: ?*cpSpace) void;
pub extern fn cpSpaceGetIterations(space: ?*const cpSpace) c_int;
pub extern fn cpSpaceSetIterations(space: ?*cpSpace, iterations: c_int) void;
pub extern fn cpSpaceGetGravity(space: ?*const cpSpace) cpVect;
pub extern fn cpSpaceSetGravity(space: ?*cpSpace, gravity: cpVect) void;
pub extern fn cpSpaceGetDamping(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetDamping(space: ?*cpSpace, damping: cpFloat) void;
pub extern fn cpSpaceGetIdleSpeedThreshold(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetIdleSpeedThreshold(space: ?*cpSpace, idleSpeedThreshold: cpFloat) void;
pub extern fn cpSpaceGetSleepTimeThreshold(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetSleepTimeThreshold(space: ?*cpSpace, sleepTimeThreshold: cpFloat) void;
pub extern fn cpSpaceGetCollisionSlop(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetCollisionSlop(space: ?*cpSpace, collisionSlop: cpFloat) void;
pub extern fn cpSpaceGetCollisionBias(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetCollisionBias(space: ?*cpSpace, collisionBias: cpFloat) void;
pub extern fn cpSpaceGetCollisionPersistence(space: ?*const cpSpace) cpTimestamp;
pub extern fn cpSpaceSetCollisionPersistence(space: ?*cpSpace, collisionPersistence: cpTimestamp) void;
pub extern fn cpSpaceGetUserData(space: ?*const cpSpace) cpDataPointer;
pub extern fn cpSpaceSetUserData(space: ?*cpSpace, userData: cpDataPointer) void;
pub extern fn cpSpaceGetStaticBody(space: ?*const cpSpace) ?*cpBody;
pub extern fn cpSpaceGetCurrentTimeStep(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceIsLocked(space: ?*cpSpace) cpBool;
pub extern fn cpSpaceAddDefaultCollisionHandler(space: ?*cpSpace) [*c]cpCollisionHandler;
pub extern fn cpSpaceAddCollisionHandler(space: ?*cpSpace, a: cpCollisionType, b: cpCollisionType) [*c]cpCollisionHandler;
pub extern fn cpSpaceAddWildcardHandler(space: ?*cpSpace, @"type": cpCollisionType) [*c]cpCollisionHandler;
pub extern fn cpSpaceAddShape(space: ?*cpSpace, shape: ?*cpShape) ?*cpShape;
pub extern fn cpSpaceAddBody(space: ?*cpSpace, body: ?*cpBody) ?*cpBody;
pub extern fn cpSpaceAddConstraint(space: ?*cpSpace, constraint: ?*cpConstraint) ?*cpConstraint;
pub extern fn cpSpaceRemoveShape(space: ?*cpSpace, shape: ?*cpShape) void;
pub extern fn cpSpaceRemoveBody(space: ?*cpSpace, body: ?*cpBody) void;
pub extern fn cpSpaceRemoveConstraint(space: ?*cpSpace, constraint: ?*cpConstraint) void;
pub extern fn cpSpaceContainsShape(space: ?*cpSpace, shape: ?*cpShape) cpBool;
pub extern fn cpSpaceContainsBody(space: ?*cpSpace, body: ?*cpBody) cpBool;
pub extern fn cpSpaceContainsConstraint(space: ?*cpSpace, constraint: ?*cpConstraint) cpBool;
pub const cpPostStepFunc = ?*const fn (?*cpSpace, ?*anyopaque, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceAddPostStepCallback(space: ?*cpSpace, func: cpPostStepFunc, key: ?*anyopaque, data: ?*anyopaque) cpBool;
pub const cpSpacePointQueryFunc = ?*const fn (?*cpShape, cpVect, cpFloat, cpVect, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpacePointQuery(space: ?*cpSpace, point: cpVect, maxDistance: cpFloat, filter: cpShapeFilter, func: cpSpacePointQueryFunc, data: ?*anyopaque) void;
pub extern fn cpSpacePointQueryNearest(space: ?*cpSpace, point: cpVect, maxDistance: cpFloat, filter: cpShapeFilter, out: [*c]cpPointQueryInfo) ?*cpShape;
pub const cpSpaceSegmentQueryFunc = ?*const fn (?*cpShape, cpVect, cpVect, cpFloat, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceSegmentQuery(space: ?*cpSpace, start: cpVect, end: cpVect, radius: cpFloat, filter: cpShapeFilter, func: cpSpaceSegmentQueryFunc, data: ?*anyopaque) void;
pub extern fn cpSpaceSegmentQueryFirst(space: ?*cpSpace, start: cpVect, end: cpVect, radius: cpFloat, filter: cpShapeFilter, out: [*c]cpSegmentQueryInfo) ?*cpShape;
pub const cpSpaceBBQueryFunc = ?*const fn (?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceBBQuery(space: ?*cpSpace, bb: cpBB, filter: cpShapeFilter, func: cpSpaceBBQueryFunc, data: ?*anyopaque) void;
pub const cpSpaceShapeQueryFunc = ?*const fn (?*cpShape, [*c]cpContactPointSet, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceShapeQuery(space: ?*cpSpace, shape: ?*cpShape, func: cpSpaceShapeQueryFunc, data: ?*anyopaque) cpBool;
pub const cpSpaceBodyIteratorFunc = ?*const fn (?*cpBody, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachBody(space: ?*cpSpace, func: cpSpaceBodyIteratorFunc, data: ?*anyopaque) void;
pub const cpSpaceShapeIteratorFunc = ?*const fn (?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachShape(space: ?*cpSpace, func: cpSpaceShapeIteratorFunc, data: ?*anyopaque) void;
pub const cpSpaceConstraintIteratorFunc = ?*const fn (?*cpConstraint, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachConstraint(space: ?*cpSpace, func: cpSpaceConstraintIteratorFunc, data: ?*anyopaque) void;
pub extern fn cpSpaceReindexStatic(space: ?*cpSpace) void;
pub extern fn cpSpaceReindexShape(space: ?*cpSpace, shape: ?*cpShape) void;
pub extern fn cpSpaceReindexShapesForBody(space: ?*cpSpace, body: ?*cpBody) void;
pub extern fn cpSpaceUseSpatialHash(space: ?*cpSpace, dim: cpFloat, count: c_int) void;
pub extern fn cpSpaceStep(space: ?*cpSpace, dt: cpFloat) void;
pub const struct_cpSpaceDebugColor = extern struct {
    r: f32 = @import("std").mem.zeroes(f32),
    g: f32 = @import("std").mem.zeroes(f32),
    b: f32 = @import("std").mem.zeroes(f32),
    a: f32 = @import("std").mem.zeroes(f32),
};
pub const cpSpaceDebugColor = struct_cpSpaceDebugColor;
pub const cpSpaceDebugDrawCircleImpl = ?*const fn (cpVect, cpFloat, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawSegmentImpl = ?*const fn (cpVect, cpVect, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawFatSegmentImpl = ?*const fn (cpVect, cpVect, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawPolygonImpl = ?*const fn (c_int, [*c]const cpVect, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawDotImpl = ?*const fn (cpFloat, cpVect, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawColorForShapeImpl = ?*const fn (?*cpShape, cpDataPointer) callconv(.C) cpSpaceDebugColor;
pub const CP_SPACE_DEBUG_DRAW_SHAPES: c_int = 1;
pub const CP_SPACE_DEBUG_DRAW_CONSTRAINTS: c_int = 2;
pub const CP_SPACE_DEBUG_DRAW_COLLISION_POINTS: c_int = 4;
pub const enum_cpSpaceDebugDrawFlags = c_uint;
pub const cpSpaceDebugDrawFlags = enum_cpSpaceDebugDrawFlags;
pub const struct_cpSpaceDebugDrawOptions = extern struct {
    drawCircle: cpSpaceDebugDrawCircleImpl = @import("std").mem.zeroes(cpSpaceDebugDrawCircleImpl),
    drawSegment: cpSpaceDebugDrawSegmentImpl = @import("std").mem.zeroes(cpSpaceDebugDrawSegmentImpl),
    drawFatSegment: cpSpaceDebugDrawFatSegmentImpl = @import("std").mem.zeroes(cpSpaceDebugDrawFatSegmentImpl),
    drawPolygon: cpSpaceDebugDrawPolygonImpl = @import("std").mem.zeroes(cpSpaceDebugDrawPolygonImpl),
    drawDot: cpSpaceDebugDrawDotImpl = @import("std").mem.zeroes(cpSpaceDebugDrawDotImpl),
    flags: cpSpaceDebugDrawFlags = @import("std").mem.zeroes(cpSpaceDebugDrawFlags),
    shapeOutlineColor: cpSpaceDebugColor = @import("std").mem.zeroes(cpSpaceDebugColor),
    colorForShape: cpSpaceDebugDrawColorForShapeImpl = @import("std").mem.zeroes(cpSpaceDebugDrawColorForShapeImpl),
    constraintColor: cpSpaceDebugColor = @import("std").mem.zeroes(cpSpaceDebugColor),
    collisionPointColor: cpSpaceDebugColor = @import("std").mem.zeroes(cpSpaceDebugColor),
    data: cpDataPointer = @import("std").mem.zeroes(cpDataPointer),
};
pub const cpSpaceDebugDrawOptions = struct_cpSpaceDebugDrawOptions;
pub extern fn cpSpaceDebugDraw(space: ?*cpSpace, options: [*c]cpSpaceDebugDrawOptions) void;
pub extern var cpVersionString: [*c]const u8;
pub extern fn cpMomentForCircle(m: cpFloat, r1: cpFloat, r2: cpFloat, offset: cpVect) cpFloat;
pub extern fn cpAreaForCircle(r1: cpFloat, r2: cpFloat) cpFloat;
pub extern fn cpMomentForSegment(m: cpFloat, a: cpVect, b: cpVect, radius: cpFloat) cpFloat;
pub extern fn cpAreaForSegment(a: cpVect, b: cpVect, radius: cpFloat) cpFloat;
pub extern fn cpMomentForPoly(m: cpFloat, count: c_int, verts: [*c]const cpVect, offset: cpVect, radius: cpFloat) cpFloat;
pub extern fn cpAreaForPoly(count: c_int, verts: [*c]const cpVect, radius: cpFloat) cpFloat;
pub extern fn cpCentroidForPoly(count: c_int, verts: [*c]const cpVect) cpVect;
pub extern fn cpMomentForBox(m: cpFloat, width: cpFloat, height: cpFloat) cpFloat;
pub extern fn cpMomentForBox2(m: cpFloat, box: cpBB) cpFloat;
pub extern fn cpConvexHull(count: c_int, verts: [*c]const cpVect, result: [*c]cpVect, first: [*c]c_int, tol: cpFloat) c_int;
pub fn cpClosetPointOnSegment(p: cpVect, a: cpVect, b: cpVect) callconv(.C) cpVect {
    _ = &p;
    _ = &a;
    _ = &b;
    var delta: cpVect = cpvsub(a, b);
    _ = &delta;
    var t: cpFloat = cpfclamp01(cpvdot(delta, cpvsub(p, b)) / cpvlengthsq(delta));
    _ = &t;
    return cpvadd(b, cpvmult(delta, t));
}
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // (no file):90:9
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // (no file):96:9
pub const __FLT16_DENORM_MIN__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):119:9
pub const __FLT16_EPSILON__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):123:9
pub const __FLT16_MAX__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):129:9
pub const __FLT16_MIN__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):132:9
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // (no file):193:9
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // (no file):215:9
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // (no file):223:9
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):352:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):353:9
pub const __GLIBC_USE = @compileError("unable to translate macro: undefined identifier `__GLIBC_USE_`"); // /usr/include/features.h:186:9
pub const __glibc_has_attribute = @compileError("unable to translate macro: undefined identifier `__has_attribute`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:45:10
pub const __glibc_has_extension = @compileError("unable to translate macro: undefined identifier `__has_extension`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:55:10
pub const __THROW = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:79:11
pub const __THROWNL = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:80:11
pub const __NTH = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:81:11
pub const __NTHNL = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:82:11
pub const __CONCAT = @compileError("unable to translate C expr: unexpected token '##'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:124:9
pub const __STRING = @compileError("unable to translate C expr: unexpected token '#'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:125:9
pub const __warnattr = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:209:10
pub const __errordecl = @compileError("unable to translate C expr: unexpected token 'extern'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:210:10
pub const __flexarr = @compileError("unable to translate C expr: unexpected token '['"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:218:10
pub const __REDIRECT = @compileError("unable to translate macro: undefined identifier `__asm__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:249:10
pub const __REDIRECT_NTH = @compileError("unable to translate macro: undefined identifier `__asm__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:256:11
pub const __REDIRECT_NTHNL = @compileError("unable to translate macro: undefined identifier `__asm__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:258:11
pub const __ASMNAME2 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:262:10
pub const __attribute_malloc__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:283:10
pub const __attribute_alloc_size__ = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:294:10
pub const __attribute_alloc_align__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:300:10
pub const __attribute_pure__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:310:10
pub const __attribute_const__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:317:10
pub const __attribute_maybe_unused__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:323:10
pub const __attribute_used__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:332:10
pub const __attribute_noinline__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:333:10
pub const __attribute_deprecated__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:341:10
pub const __attribute_deprecated_msg__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:351:10
pub const __attribute_format_arg__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:364:10
pub const __attribute_format_strfmon__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:374:10
pub const __attribute_nonnull__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:386:11
pub const __returns_nonnull = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:399:10
pub const __attribute_warn_unused_result__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:408:10
pub const __always_inline = @compileError("unable to translate macro: undefined identifier `__inline`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:426:10
pub const __attribute_artificial__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:435:10
pub const __extern_inline = @compileError("unable to translate macro: undefined identifier `__inline`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:453:11
pub const __extern_always_inline = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:454:11
pub const __restrict_arr = @compileError("unable to translate macro: undefined identifier `__restrict`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:497:10
pub const __attribute_copy__ = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:546:10
pub const __LDBL_REDIR2_DECL = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:622:10
pub const __LDBL_REDIR_DECL = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:623:10
pub const __glibc_macro_warning1 = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:637:10
pub const __glibc_macro_warning = @compileError("unable to translate macro: undefined identifier `GCC`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:638:10
pub const __fortified_attr_access = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:683:11
pub const __attr_access = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:684:11
pub const __attr_access_none = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:685:11
pub const __attr_dealloc = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:695:10
pub const __attribute_returns_twice__ = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/x86_64-linux-gnu/sys/cdefs.h:702:10
pub const __CFLOAT32 = @compileError("unable to translate: TODO _Complex"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:149:12
pub const __CFLOAT64 = @compileError("unable to translate: TODO _Complex"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:160:13
pub const __CFLOAT32X = @compileError("unable to translate: TODO _Complex"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:169:12
pub const __CFLOAT64X = @compileError("unable to translate: TODO _Complex"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:178:13
pub const __builtin_nansf32 = @compileError("unable to translate macro: undefined identifier `__builtin_nansf`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:221:12
pub const __builtin_huge_valf64 = @compileError("unable to translate macro: undefined identifier `__builtin_huge_val`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:255:13
pub const __builtin_inff64 = @compileError("unable to translate macro: undefined identifier `__builtin_inf`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:256:13
pub const __builtin_nanf64 = @compileError("unable to translate macro: undefined identifier `__builtin_nan`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:257:13
pub const __builtin_nansf64 = @compileError("unable to translate macro: undefined identifier `__builtin_nans`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:258:13
pub const __builtin_huge_valf32x = @compileError("unable to translate macro: undefined identifier `__builtin_huge_val`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:272:12
pub const __builtin_inff32x = @compileError("unable to translate macro: undefined identifier `__builtin_inf`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:273:12
pub const __builtin_nanf32x = @compileError("unable to translate macro: undefined identifier `__builtin_nan`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:274:12
pub const __builtin_nansf32x = @compileError("unable to translate macro: undefined identifier `__builtin_nans`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:275:12
pub const __builtin_huge_valf64x = @compileError("unable to translate macro: undefined identifier `__builtin_huge_vall`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:289:13
pub const __builtin_inff64x = @compileError("unable to translate macro: undefined identifier `__builtin_infl`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:290:13
pub const __builtin_nanf64x = @compileError("unable to translate macro: undefined identifier `__builtin_nanl`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:291:13
pub const __builtin_nansf64x = @compileError("unable to translate macro: undefined identifier `__builtin_nansl`"); // /usr/include/x86_64-linux-gnu/bits/floatn-common.h:292:13
pub const __STD_TYPE = @compileError("unable to translate C expr: unexpected token 'typedef'"); // /usr/include/x86_64-linux-gnu/bits/types.h:137:10
pub const __FSID_T_TYPE = @compileError("unable to translate macro: undefined identifier `__val`"); // /usr/include/x86_64-linux-gnu/bits/typesizes.h:73:9
pub const __FD_ZERO = @compileError("unable to translate macro: undefined identifier `__i`"); // /usr/include/x86_64-linux-gnu/bits/select.h:25:9
pub const __FD_SET = @compileError("unable to translate C expr: expected ')' instead got '|='"); // /usr/include/x86_64-linux-gnu/bits/select.h:32:9
pub const __FD_CLR = @compileError("unable to translate C expr: expected ')' instead got '&='"); // /usr/include/x86_64-linux-gnu/bits/select.h:34:9
pub const __PTHREAD_MUTEX_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'"); // /usr/include/x86_64-linux-gnu/bits/struct_mutex.h:56:10
pub const __PTHREAD_RWLOCK_ELISION_EXTRA = @compileError("unable to translate C expr: unexpected token '{'"); // /usr/include/x86_64-linux-gnu/bits/struct_rwlock.h:40:11
pub const __ONCE_FLAG_INIT = @compileError("unable to translate C expr: unexpected token '{'"); // /usr/include/x86_64-linux-gnu/bits/thread-shared-types.h:113:9
pub const HUGE_VAL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_val`"); // /usr/include/math.h:48:10
pub const HUGE_VALL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_vall`"); // /usr/include/math.h:60:11
pub const __GLIBC_FLT_EVAL_METHOD = @compileError("unable to translate macro: undefined identifier `__FLT_EVAL_METHOD__`"); // /usr/include/x86_64-linux-gnu/bits/flt-eval-method.h:27:11
pub const __SIMD_DECL = @compileError("unable to translate macro: undefined identifier `__DECL_SIMD_`"); // /usr/include/math.h:276:9
pub const __MATHCALL_VEC = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /usr/include/math.h:278:9
pub const __MATHDECL_VEC = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /usr/include/math.h:282:9
pub const __MATHDECL = @compileError("unable to translate macro: undefined identifier `__`"); // /usr/include/math.h:288:9
pub const __MATHDECLX = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/math.h:293:9
pub const __MATHDECL_1_IMPL = @compileError("unable to translate C expr: unexpected token 'extern'"); // /usr/include/math.h:296:9
pub const __MATHREDIR = @compileError("unable to translate C expr: unexpected token 'extern'"); // /usr/include/math.h:305:9
pub const __MATHCALL_NARROW_ARGS_1 = @compileError("unable to translate macro: undefined identifier `_Marg_`"); // /usr/include/math.h:550:9
pub const __MATHCALL_NARROW_ARGS_2 = @compileError("unable to translate macro: undefined identifier `_Marg_`"); // /usr/include/math.h:551:9
pub const __MATHCALL_NARROW_ARGS_3 = @compileError("unable to translate macro: undefined identifier `_Marg_`"); // /usr/include/math.h:552:9
pub const __MATHCALL_NARROW_NORMAL = @compileError("unable to translate macro: undefined identifier `_Mret_`"); // /usr/include/math.h:553:9
pub const __MATHCALL_NARROW_REDIR = @compileError("unable to translate macro: undefined identifier `_Mret_`"); // /usr/include/math.h:555:9
pub const __MATH_TG = @compileError("unable to translate macro: undefined identifier `f`"); // /usr/include/math.h:922:10
pub const fpclassify = @compileError("unable to translate macro: undefined identifier `__builtin_fpclassify`"); // /usr/include/math.h:967:11
pub const isfinite = @compileError("unable to translate macro: undefined identifier `__builtin_isfinite`"); // /usr/include/math.h:994:11
pub const isnormal = @compileError("unable to translate macro: undefined identifier `__builtin_isnormal`"); // /usr/include/math.h:1002:11
pub const isgreater = @compileError("unable to translate macro: undefined identifier `__builtin_isgreater`"); // /usr/include/math.h:1305:11
pub const isgreaterequal = @compileError("unable to translate macro: undefined identifier `__builtin_isgreaterequal`"); // /usr/include/math.h:1306:11
pub const isless = @compileError("unable to translate macro: undefined identifier `__builtin_isless`"); // /usr/include/math.h:1307:11
pub const islessequal = @compileError("unable to translate macro: undefined identifier `__builtin_islessequal`"); // /usr/include/math.h:1308:11
pub const islessgreater = @compileError("unable to translate macro: undefined identifier `__builtin_islessgreater`"); // /usr/include/math.h:1309:11
pub const isunordered = @compileError("unable to translate macro: undefined identifier `__builtin_isunordered`"); // /usr/include/math.h:1310:11
pub const cpAssertSoft = @compileError("unable to translate C expr: expected ')' instead got '...'"); // c/include/chipmunk/chipmunk.h:53:10
pub const cpAssertWarn = @compileError("unable to translate C expr: expected ')' instead got '...'"); // c/include/chipmunk/chipmunk.h:54:10
pub const cpAssertHard = @compileError("unable to translate C expr: expected ')' instead got '...'"); // c/include/chipmunk/chipmunk.h:58:9
pub const FLT_EVAL_METHOD = @compileError("unable to translate macro: undefined identifier `__FLT_EVAL_METHOD__`"); // /home/jack/dev/zig/lib/include/float.h:91:9
pub const FLT_ROUNDS = @compileError("unable to translate macro: undefined identifier `__builtin_flt_rounds`"); // /home/jack/dev/zig/lib/include/float.h:93:9
pub const CP_ARBITER_GET_SHAPES = @compileError("unable to translate C expr: unexpected token ';'"); // c/include/chipmunk/cpArbiter.h:70:9
pub const CP_ARBITER_GET_BODIES = @compileError("unable to translate C expr: unexpected token ';'"); // c/include/chipmunk/cpArbiter.h:78:9
pub const CP_CONVEX_HULL = @compileError("unable to translate C expr: unexpected token '='"); // c/include/chipmunk/chipmunk.h:177:9
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 17);
pub const __clang_minor__ = @as(c_int, 0);
pub const __clang_patchlevel__ = @as(c_int, 3);
pub const __clang_version__ = "17.0.3 (https://github.com/ziglang/zig-bootstrap 1dc1fa6a122996fcd030cc956385e055289e09d9)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __FPCLASS_SNAN = @as(c_int, 0x0001);
pub const __FPCLASS_QNAN = @as(c_int, 0x0002);
pub const __FPCLASS_NEGINF = @as(c_int, 0x0004);
pub const __FPCLASS_NEGNORMAL = @as(c_int, 0x0008);
pub const __FPCLASS_NEGSUBNORMAL = @as(c_int, 0x0010);
pub const __FPCLASS_NEGZERO = @as(c_int, 0x0020);
pub const __FPCLASS_POSZERO = @as(c_int, 0x0040);
pub const __FPCLASS_POSSUBNORMAL = @as(c_int, 0x0080);
pub const __FPCLASS_POSNORMAL = @as(c_int, 0x0100);
pub const __FPCLASS_POSINF = @as(c_int, 0x0200);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 17.0.3 (https://github.com/ziglang/zig-bootstrap 1dc1fa6a122996fcd030cc956385e055289e09d9)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-32";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 8388608, .decimal);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_FMTd__ = "ld";
pub const __INTMAX_FMTi__ = "li";
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __PTRDIFF_TYPE__ = c_long;
pub const __PTRDIFF_FMTd__ = "ld";
pub const __PTRDIFF_FMTi__ = "li";
pub const __INTPTR_TYPE__ = c_long;
pub const __INTPTR_FMTd__ = "ld";
pub const __INTPTR_FMTi__ = "li";
pub const __SIZE_TYPE__ = c_ulong;
pub const __SIZE_FMTo__ = "lo";
pub const __SIZE_FMTu__ = "lu";
pub const __SIZE_FMTx__ = "lx";
pub const __SIZE_FMTX__ = "lX";
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_uint;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __UINTPTR_FMTo__ = "lo";
pub const __UINTPTR_FMTu__ = "lu";
pub const __UINTPTR_FMTx__ = "lx";
pub const __UINTPTR_FMTX__ = "lX";
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "ld";
pub const __INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_LEAST64_FMTo__ = "lo";
pub const __UINT_LEAST64_FMTu__ = "lu";
pub const __UINT_LEAST64_FMTx__ = "lx";
pub const __UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "ld";
pub const __INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_FAST64_FMTo__ = "lo";
pub const __UINT_FAST64_FMTu__ = "lu";
pub const __UINT_FAST64_FMTx__ = "lx";
pub const __UINT_FAST64_FMTX__ = "lX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __ELF__ = @as(c_int, 1);
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __k8 = @as(c_int, 1);
pub const __k8__ = @as(c_int, 1);
pub const __tune_k8__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __VAES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __VPCLMULQDQ__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __GFNI__ = @as(c_int, 1);
pub const __AVX512CD__ = @as(c_int, 1);
pub const __AVX512VPOPCNTDQ__ = @as(c_int, 1);
pub const __AVX512VNNI__ = @as(c_int, 1);
pub const __AVX512DQ__ = @as(c_int, 1);
pub const __AVX512BITALG__ = @as(c_int, 1);
pub const __AVX512BW__ = @as(c_int, 1);
pub const __AVX512VL__ = @as(c_int, 1);
pub const __AVX512VBMI__ = @as(c_int, 1);
pub const __AVX512VBMI2__ = @as(c_int, 1);
pub const __AVX512IFMA__ = @as(c_int, 1);
pub const __AVX512VP2INTERSECT__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __PKU__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __SHSTK__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __MOVDIRI__ = @as(c_int, 1);
pub const __MOVDIR64B__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __AVX512F__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const __gnu_linux__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __GLIBC_MINOR__ = @as(c_int, 36);
pub const _DEBUG = @as(c_int, 1);
pub const CP_USE_DOUBLES = @as(c_int, 0);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const CHIPMUNK_H = "";
pub const __GLIBC_INTERNAL_STARTING_HEADER_IMPLEMENTATION = "";
pub const _FEATURES_H = @as(c_int, 1);
pub const __KERNEL_STRICT_NAMES = "";
pub inline fn __GNUC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub inline fn __glibc_clang_prereq(maj: anytype, min: anytype) @TypeOf(((__clang_major__ << @as(c_int, 16)) + __clang_minor__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__clang_major__ << @as(c_int, 16)) + __clang_minor__) >= ((maj << @as(c_int, 16)) + min);
}
pub const _DEFAULT_SOURCE = @as(c_int, 1);
pub const __GLIBC_USE_ISOC2X = @as(c_int, 0);
pub const __USE_ISOC11 = @as(c_int, 1);
pub const __USE_ISOC99 = @as(c_int, 1);
pub const __USE_ISOC95 = @as(c_int, 1);
pub const __USE_POSIX_IMPLICITLY = @as(c_int, 1);
pub const _POSIX_SOURCE = @as(c_int, 1);
pub const _POSIX_C_SOURCE = @as(c_long, 200809);
pub const __USE_POSIX = @as(c_int, 1);
pub const __USE_POSIX2 = @as(c_int, 1);
pub const __USE_POSIX199309 = @as(c_int, 1);
pub const __USE_POSIX199506 = @as(c_int, 1);
pub const __USE_XOPEN2K = @as(c_int, 1);
pub const __USE_XOPEN2K8 = @as(c_int, 1);
pub const _ATFILE_SOURCE = @as(c_int, 1);
pub const __WORDSIZE = @as(c_int, 64);
pub const __WORDSIZE_TIME64_COMPAT32 = @as(c_int, 1);
pub const __SYSCALL_WORDSIZE = @as(c_int, 64);
pub const __TIMESIZE = __WORDSIZE;
pub const __USE_MISC = @as(c_int, 1);
pub const __USE_ATFILE = @as(c_int, 1);
pub const __USE_FORTIFY_LEVEL = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_GETS = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_SCANF = @as(c_int, 0);
pub const _STDC_PREDEF_H = @as(c_int, 1);
pub const __STDC_IEC_559__ = @as(c_int, 1);
pub const __STDC_IEC_60559_BFP__ = @as(c_long, 201404);
pub const __STDC_IEC_559_COMPLEX__ = @as(c_int, 1);
pub const __STDC_IEC_60559_COMPLEX__ = @as(c_long, 201404);
pub const __STDC_ISO_10646__ = @as(c_long, 201706);
pub const __GNU_LIBRARY__ = @as(c_int, 6);
pub const __GLIBC__ = @as(c_int, 2);
pub inline fn __GLIBC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub const _SYS_CDEFS_H = @as(c_int, 1);
pub inline fn __glibc_has_builtin(name: anytype) @TypeOf(__has_builtin(name)) {
    _ = &name;
    return __has_builtin(name);
}
pub const __LEAF = "";
pub const __LEAF_ATTR = "";
pub inline fn __P(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub inline fn __PMT(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub const __ptr_t = ?*anyopaque;
pub const __BEGIN_DECLS = "";
pub const __END_DECLS = "";
pub inline fn __bos(ptr: anytype) @TypeOf(__builtin_object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1))) {
    _ = &ptr;
    return __builtin_object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1));
}
pub inline fn __bos0(ptr: anytype) @TypeOf(__builtin_object_size(ptr, @as(c_int, 0))) {
    _ = &ptr;
    return __builtin_object_size(ptr, @as(c_int, 0));
}
pub inline fn __glibc_objsize0(__o: anytype) @TypeOf(__bos0(__o)) {
    _ = &__o;
    return __bos0(__o);
}
pub inline fn __glibc_objsize(__o: anytype) @TypeOf(__bos(__o)) {
    _ = &__o;
    return __bos(__o);
}
pub const __glibc_c99_flexarr_available = @as(c_int, 1);
pub inline fn __ASMNAME(cname: anytype) @TypeOf(__ASMNAME2(__USER_LABEL_PREFIX__, cname)) {
    _ = &cname;
    return __ASMNAME2(__USER_LABEL_PREFIX__, cname);
}
pub inline fn __nonnull(params: anytype) @TypeOf(__attribute_nonnull__(params)) {
    _ = &params;
    return __attribute_nonnull__(params);
}
pub const __wur = "";
pub const __fortify_function = __extern_always_inline ++ __attribute_artificial__;
pub inline fn __glibc_unlikely(cond: anytype) @TypeOf(__builtin_expect(cond, @as(c_int, 0))) {
    _ = &cond;
    return __builtin_expect(cond, @as(c_int, 0));
}
pub inline fn __glibc_likely(cond: anytype) @TypeOf(__builtin_expect(cond, @as(c_int, 1))) {
    _ = &cond;
    return __builtin_expect(cond, @as(c_int, 1));
}
pub const __attribute_nonstring__ = "";
pub const __LDOUBLE_REDIRECTS_TO_FLOAT128_ABI = @as(c_int, 0);
pub inline fn __LDBL_REDIR1(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR(name: anytype, proto: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR1_NTH(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR_NTH(name: anytype, proto: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    return name ++ proto ++ __THROW;
}
pub inline fn __REDIRECT_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT(name, proto, alias);
}
pub inline fn __REDIRECT_NTH_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT_NTH(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT_NTH(name, proto, alias);
}
pub const __HAVE_GENERIC_SELECTION = @as(c_int, 1);
pub const __attr_dealloc_free = "";
pub const __stub___compat_bdflush = "";
pub const __stub_chflags = "";
pub const __stub_fchflags = "";
pub const __stub_gtty = "";
pub const __stub_revoke = "";
pub const __stub_setlogin = "";
pub const __stub_sigreturn = "";
pub const __stub_stty = "";
pub const __GLIBC_USE_LIB_EXT2 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT_C2X = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT_C2X = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_TYPES_EXT = @as(c_int, 0);
pub const __need_size_t = "";
pub const __need_wchar_t = "";
pub const __need_NULL = "";
pub const _SIZE_T = "";
pub const _WCHAR_T = "";
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const _STDLIB_H = @as(c_int, 1);
pub const WNOHANG = @as(c_int, 1);
pub const WUNTRACED = @as(c_int, 2);
pub const WSTOPPED = @as(c_int, 2);
pub const WEXITED = @as(c_int, 4);
pub const WCONTINUED = @as(c_int, 8);
pub const WNOWAIT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x01000000, .hexadecimal);
pub const __WNOTHREAD = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x20000000, .hexadecimal);
pub const __WALL = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x40000000, .hexadecimal);
pub const __WCLONE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hexadecimal);
pub inline fn __WEXITSTATUS(status: anytype) @TypeOf((status & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xff00, .hexadecimal)) >> @as(c_int, 8)) {
    _ = &status;
    return (status & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xff00, .hexadecimal)) >> @as(c_int, 8);
}
pub inline fn __WTERMSIG(status: anytype) @TypeOf(status & @as(c_int, 0x7f)) {
    _ = &status;
    return status & @as(c_int, 0x7f);
}
pub inline fn __WSTOPSIG(status: anytype) @TypeOf(__WEXITSTATUS(status)) {
    _ = &status;
    return __WEXITSTATUS(status);
}
pub inline fn __WIFEXITED(status: anytype) @TypeOf(__WTERMSIG(status) == @as(c_int, 0)) {
    _ = &status;
    return __WTERMSIG(status) == @as(c_int, 0);
}
pub inline fn __WIFSIGNALED(status: anytype) @TypeOf((@import("std").zig.c_translation.cast(i8, (status & @as(c_int, 0x7f)) + @as(c_int, 1)) >> @as(c_int, 1)) > @as(c_int, 0)) {
    _ = &status;
    return (@import("std").zig.c_translation.cast(i8, (status & @as(c_int, 0x7f)) + @as(c_int, 1)) >> @as(c_int, 1)) > @as(c_int, 0);
}
pub inline fn __WIFSTOPPED(status: anytype) @TypeOf((status & @as(c_int, 0xff)) == @as(c_int, 0x7f)) {
    _ = &status;
    return (status & @as(c_int, 0xff)) == @as(c_int, 0x7f);
}
pub inline fn __WIFCONTINUED(status: anytype) @TypeOf(status == __W_CONTINUED) {
    _ = &status;
    return status == __W_CONTINUED;
}
pub inline fn __WCOREDUMP(status: anytype) @TypeOf(status & __WCOREFLAG) {
    _ = &status;
    return status & __WCOREFLAG;
}
pub inline fn __W_EXITCODE(ret: anytype, sig: anytype) @TypeOf((ret << @as(c_int, 8)) | sig) {
    _ = &ret;
    _ = &sig;
    return (ret << @as(c_int, 8)) | sig;
}
pub inline fn __W_STOPCODE(sig: anytype) @TypeOf((sig << @as(c_int, 8)) | @as(c_int, 0x7f)) {
    _ = &sig;
    return (sig << @as(c_int, 8)) | @as(c_int, 0x7f);
}
pub const __W_CONTINUED = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffff, .hexadecimal);
pub const __WCOREFLAG = @as(c_int, 0x80);
pub inline fn WEXITSTATUS(status: anytype) @TypeOf(__WEXITSTATUS(status)) {
    _ = &status;
    return __WEXITSTATUS(status);
}
pub inline fn WTERMSIG(status: anytype) @TypeOf(__WTERMSIG(status)) {
    _ = &status;
    return __WTERMSIG(status);
}
pub inline fn WSTOPSIG(status: anytype) @TypeOf(__WSTOPSIG(status)) {
    _ = &status;
    return __WSTOPSIG(status);
}
pub inline fn WIFEXITED(status: anytype) @TypeOf(__WIFEXITED(status)) {
    _ = &status;
    return __WIFEXITED(status);
}
pub inline fn WIFSIGNALED(status: anytype) @TypeOf(__WIFSIGNALED(status)) {
    _ = &status;
    return __WIFSIGNALED(status);
}
pub inline fn WIFSTOPPED(status: anytype) @TypeOf(__WIFSTOPPED(status)) {
    _ = &status;
    return __WIFSTOPPED(status);
}
pub inline fn WIFCONTINUED(status: anytype) @TypeOf(__WIFCONTINUED(status)) {
    _ = &status;
    return __WIFCONTINUED(status);
}
pub const _BITS_FLOATN_H = "";
pub const __HAVE_FLOAT128 = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT128 = @as(c_int, 0);
pub const __HAVE_FLOAT64X = @as(c_int, 1);
pub const __HAVE_FLOAT64X_LONG_DOUBLE = @as(c_int, 1);
pub const _BITS_FLOATN_COMMON_H = "";
pub const __HAVE_FLOAT16 = @as(c_int, 0);
pub const __HAVE_FLOAT32 = @as(c_int, 1);
pub const __HAVE_FLOAT64 = @as(c_int, 1);
pub const __HAVE_FLOAT32X = @as(c_int, 1);
pub const __HAVE_FLOAT128X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT16 = __HAVE_FLOAT16;
pub const __HAVE_DISTINCT_FLOAT32 = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT64 = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT32X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT64X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT128X = __HAVE_FLOAT128X;
pub const __HAVE_FLOAT128_UNLIKE_LDBL = (__HAVE_DISTINCT_FLOAT128 != 0) and (__LDBL_MANT_DIG__ != @as(c_int, 113));
pub const __HAVE_FLOATN_NOT_TYPEDEF = @as(c_int, 0);
pub const __f32 = @import("std").zig.c_translation.Macros.F_SUFFIX;
pub inline fn __f64(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __f32x(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub const __f64x = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub inline fn __builtin_huge_valf32() @TypeOf(__builtin_huge_valf()) {
    return __builtin_huge_valf();
}
pub inline fn __builtin_inff32() @TypeOf(__builtin_inff()) {
    return __builtin_inff();
}
pub inline fn __builtin_nanf32(x: anytype) @TypeOf(__builtin_nanf(x)) {
    _ = &x;
    return __builtin_nanf(x);
}
pub const __ldiv_t_defined = @as(c_int, 1);
pub const __lldiv_t_defined = @as(c_int, 1);
pub const RAND_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const EXIT_FAILURE = @as(c_int, 1);
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const MB_CUR_MAX = __ctype_get_mb_cur_max();
pub const _SYS_TYPES_H = @as(c_int, 1);
pub const _BITS_TYPES_H = @as(c_int, 1);
pub const __S16_TYPE = c_short;
pub const __U16_TYPE = c_ushort;
pub const __S32_TYPE = c_int;
pub const __U32_TYPE = c_uint;
pub const __SLONGWORD_TYPE = c_long;
pub const __ULONGWORD_TYPE = c_ulong;
pub const __SQUAD_TYPE = c_long;
pub const __UQUAD_TYPE = c_ulong;
pub const __SWORD_TYPE = c_long;
pub const __UWORD_TYPE = c_ulong;
pub const __SLONG32_TYPE = c_int;
pub const __ULONG32_TYPE = c_uint;
pub const __S64_TYPE = c_long;
pub const __U64_TYPE = c_ulong;
pub const _BITS_TYPESIZES_H = @as(c_int, 1);
pub const __SYSCALL_SLONG_TYPE = __SLONGWORD_TYPE;
pub const __SYSCALL_ULONG_TYPE = __ULONGWORD_TYPE;
pub const __DEV_T_TYPE = __UQUAD_TYPE;
pub const __UID_T_TYPE = __U32_TYPE;
pub const __GID_T_TYPE = __U32_TYPE;
pub const __INO_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __INO64_T_TYPE = __UQUAD_TYPE;
pub const __MODE_T_TYPE = __U32_TYPE;
pub const __NLINK_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSWORD_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF64_T_TYPE = __SQUAD_TYPE;
pub const __PID_T_TYPE = __S32_TYPE;
pub const __RLIM_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __RLIM64_T_TYPE = __UQUAD_TYPE;
pub const __BLKCNT_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __BLKCNT64_T_TYPE = __SQUAD_TYPE;
pub const __FSBLKCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSBLKCNT64_T_TYPE = __UQUAD_TYPE;
pub const __FSFILCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSFILCNT64_T_TYPE = __UQUAD_TYPE;
pub const __ID_T_TYPE = __U32_TYPE;
pub const __CLOCK_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __TIME_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __USECONDS_T_TYPE = __U32_TYPE;
pub const __SUSECONDS_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __SUSECONDS64_T_TYPE = __SQUAD_TYPE;
pub const __DADDR_T_TYPE = __S32_TYPE;
pub const __KEY_T_TYPE = __S32_TYPE;
pub const __CLOCKID_T_TYPE = __S32_TYPE;
pub const __TIMER_T_TYPE = ?*anyopaque;
pub const __BLKSIZE_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __SSIZE_T_TYPE = __SWORD_TYPE;
pub const __CPU_MASK_TYPE = __SYSCALL_ULONG_TYPE;
pub const __OFF_T_MATCHES_OFF64_T = @as(c_int, 1);
pub const __INO_T_MATCHES_INO64_T = @as(c_int, 1);
pub const __RLIM_T_MATCHES_RLIM64_T = @as(c_int, 1);
pub const __STATFS_MATCHES_STATFS64 = @as(c_int, 1);
pub const __KERNEL_OLD_TIMEVAL_MATCHES_TIMEVAL64 = @as(c_int, 1);
pub const __FD_SETSIZE = @as(c_int, 1024);
pub const _BITS_TIME64_H = @as(c_int, 1);
pub const __TIME64_T_TYPE = __TIME_T_TYPE;
pub const __u_char_defined = "";
pub const __ino_t_defined = "";
pub const __dev_t_defined = "";
pub const __gid_t_defined = "";
pub const __mode_t_defined = "";
pub const __nlink_t_defined = "";
pub const __uid_t_defined = "";
pub const __off_t_defined = "";
pub const __pid_t_defined = "";
pub const __id_t_defined = "";
pub const __ssize_t_defined = "";
pub const __daddr_t_defined = "";
pub const __key_t_defined = "";
pub const __clock_t_defined = @as(c_int, 1);
pub const __clockid_t_defined = @as(c_int, 1);
pub const __time_t_defined = @as(c_int, 1);
pub const __timer_t_defined = @as(c_int, 1);
pub const _BITS_STDINT_INTN_H = @as(c_int, 1);
pub const __BIT_TYPES_DEFINED__ = @as(c_int, 1);
pub const _ENDIAN_H = @as(c_int, 1);
pub const _BITS_ENDIAN_H = @as(c_int, 1);
pub const __LITTLE_ENDIAN = @as(c_int, 1234);
pub const __BIG_ENDIAN = @as(c_int, 4321);
pub const __PDP_ENDIAN = @as(c_int, 3412);
pub const _BITS_ENDIANNESS_H = @as(c_int, 1);
pub const __BYTE_ORDER = __LITTLE_ENDIAN;
pub const __FLOAT_WORD_ORDER = __BYTE_ORDER;
pub inline fn __LONG_LONG_PAIR(HI: anytype, LO: anytype) @TypeOf(HI) {
    _ = &HI;
    _ = &LO;
    return blk: {
        _ = &LO;
        break :blk HI;
    };
}
pub const LITTLE_ENDIAN = __LITTLE_ENDIAN;
pub const BIG_ENDIAN = __BIG_ENDIAN;
pub const PDP_ENDIAN = __PDP_ENDIAN;
pub const BYTE_ORDER = __BYTE_ORDER;
pub const _BITS_BYTESWAP_H = @as(c_int, 1);
pub inline fn __bswap_constant_16(x: anytype) __uint16_t {
    _ = &x;
    return @import("std").zig.c_translation.cast(__uint16_t, ((x >> @as(c_int, 8)) & @as(c_int, 0xff)) | ((x & @as(c_int, 0xff)) << @as(c_int, 8)));
}
pub inline fn __bswap_constant_32(x: anytype) @TypeOf(((((x & @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xff000000, .hexadecimal)) >> @as(c_int, 24)) | ((x & @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0x00ff0000, .hexadecimal)) >> @as(c_int, 8))) | ((x & @as(c_uint, 0x0000ff00)) << @as(c_int, 8))) | ((x & @as(c_uint, 0x000000ff)) << @as(c_int, 24))) {
    _ = &x;
    return ((((x & @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xff000000, .hexadecimal)) >> @as(c_int, 24)) | ((x & @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0x00ff0000, .hexadecimal)) >> @as(c_int, 8))) | ((x & @as(c_uint, 0x0000ff00)) << @as(c_int, 8))) | ((x & @as(c_uint, 0x000000ff)) << @as(c_int, 24));
}
pub inline fn __bswap_constant_64(x: anytype) @TypeOf(((((((((x & @as(c_ulonglong, 0xff00000000000000)) >> @as(c_int, 56)) | ((x & @as(c_ulonglong, 0x00ff000000000000)) >> @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x0000ff0000000000)) >> @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000ff00000000)) >> @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x00000000ff000000)) << @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x0000000000ff0000)) << @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000000000ff00)) << @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x00000000000000ff)) << @as(c_int, 56))) {
    _ = &x;
    return ((((((((x & @as(c_ulonglong, 0xff00000000000000)) >> @as(c_int, 56)) | ((x & @as(c_ulonglong, 0x00ff000000000000)) >> @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x0000ff0000000000)) >> @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000ff00000000)) >> @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x00000000ff000000)) << @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x0000000000ff0000)) << @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000000000ff00)) << @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x00000000000000ff)) << @as(c_int, 56));
}
pub const _BITS_UINTN_IDENTITY_H = @as(c_int, 1);
pub inline fn htobe16(x: anytype) @TypeOf(__bswap_16(x)) {
    _ = &x;
    return __bswap_16(x);
}
pub inline fn htole16(x: anytype) @TypeOf(__uint16_identity(x)) {
    _ = &x;
    return __uint16_identity(x);
}
pub inline fn be16toh(x: anytype) @TypeOf(__bswap_16(x)) {
    _ = &x;
    return __bswap_16(x);
}
pub inline fn le16toh(x: anytype) @TypeOf(__uint16_identity(x)) {
    _ = &x;
    return __uint16_identity(x);
}
pub inline fn htobe32(x: anytype) @TypeOf(__bswap_32(x)) {
    _ = &x;
    return __bswap_32(x);
}
pub inline fn htole32(x: anytype) @TypeOf(__uint32_identity(x)) {
    _ = &x;
    return __uint32_identity(x);
}
pub inline fn be32toh(x: anytype) @TypeOf(__bswap_32(x)) {
    _ = &x;
    return __bswap_32(x);
}
pub inline fn le32toh(x: anytype) @TypeOf(__uint32_identity(x)) {
    _ = &x;
    return __uint32_identity(x);
}
pub inline fn htobe64(x: anytype) @TypeOf(__bswap_64(x)) {
    _ = &x;
    return __bswap_64(x);
}
pub inline fn htole64(x: anytype) @TypeOf(__uint64_identity(x)) {
    _ = &x;
    return __uint64_identity(x);
}
pub inline fn be64toh(x: anytype) @TypeOf(__bswap_64(x)) {
    _ = &x;
    return __bswap_64(x);
}
pub inline fn le64toh(x: anytype) @TypeOf(__uint64_identity(x)) {
    _ = &x;
    return __uint64_identity(x);
}
pub const _SYS_SELECT_H = @as(c_int, 1);
pub inline fn __FD_ISSET(d: anytype, s: anytype) @TypeOf((__FDS_BITS(s)[@as(usize, @intCast(__FD_ELT(d)))] & __FD_MASK(d)) != @as(c_int, 0)) {
    _ = &d;
    _ = &s;
    return (__FDS_BITS(s)[@as(usize, @intCast(__FD_ELT(d)))] & __FD_MASK(d)) != @as(c_int, 0);
}
pub const __sigset_t_defined = @as(c_int, 1);
pub const ____sigset_t_defined = "";
pub const _SIGSET_NWORDS = @import("std").zig.c_translation.MacroArithmetic.div(@as(c_int, 1024), @as(c_int, 8) * @import("std").zig.c_translation.sizeof(c_ulong));
pub const __timeval_defined = @as(c_int, 1);
pub const _STRUCT_TIMESPEC = @as(c_int, 1);
pub const __suseconds_t_defined = "";
pub const __NFDBITS = @as(c_int, 8) * @import("std").zig.c_translation.cast(c_int, @import("std").zig.c_translation.sizeof(__fd_mask));
pub inline fn __FD_ELT(d: anytype) @TypeOf(@import("std").zig.c_translation.MacroArithmetic.div(d, __NFDBITS)) {
    _ = &d;
    return @import("std").zig.c_translation.MacroArithmetic.div(d, __NFDBITS);
}
pub inline fn __FD_MASK(d: anytype) __fd_mask {
    _ = &d;
    return @import("std").zig.c_translation.cast(__fd_mask, @as(c_ulong, 1) << @import("std").zig.c_translation.MacroArithmetic.rem(d, __NFDBITS));
}
pub inline fn __FDS_BITS(set: anytype) @TypeOf(set.*.__fds_bits) {
    _ = &set;
    return set.*.__fds_bits;
}
pub const FD_SETSIZE = __FD_SETSIZE;
pub const NFDBITS = __NFDBITS;
pub inline fn FD_SET(fd: anytype, fdsetp: anytype) @TypeOf(__FD_SET(fd, fdsetp)) {
    _ = &fd;
    _ = &fdsetp;
    return __FD_SET(fd, fdsetp);
}
pub inline fn FD_CLR(fd: anytype, fdsetp: anytype) @TypeOf(__FD_CLR(fd, fdsetp)) {
    _ = &fd;
    _ = &fdsetp;
    return __FD_CLR(fd, fdsetp);
}
pub inline fn FD_ISSET(fd: anytype, fdsetp: anytype) @TypeOf(__FD_ISSET(fd, fdsetp)) {
    _ = &fd;
    _ = &fdsetp;
    return __FD_ISSET(fd, fdsetp);
}
pub inline fn FD_ZERO(fdsetp: anytype) @TypeOf(__FD_ZERO(fdsetp)) {
    _ = &fdsetp;
    return __FD_ZERO(fdsetp);
}
pub const __blksize_t_defined = "";
pub const __blkcnt_t_defined = "";
pub const __fsblkcnt_t_defined = "";
pub const __fsfilcnt_t_defined = "";
pub const _BITS_PTHREADTYPES_COMMON_H = @as(c_int, 1);
pub const _THREAD_SHARED_TYPES_H = @as(c_int, 1);
pub const _BITS_PTHREADTYPES_ARCH_H = @as(c_int, 1);
pub const __SIZEOF_PTHREAD_MUTEX_T = @as(c_int, 40);
pub const __SIZEOF_PTHREAD_ATTR_T = @as(c_int, 56);
pub const __SIZEOF_PTHREAD_RWLOCK_T = @as(c_int, 56);
pub const __SIZEOF_PTHREAD_BARRIER_T = @as(c_int, 32);
pub const __SIZEOF_PTHREAD_MUTEXATTR_T = @as(c_int, 4);
pub const __SIZEOF_PTHREAD_COND_T = @as(c_int, 48);
pub const __SIZEOF_PTHREAD_CONDATTR_T = @as(c_int, 4);
pub const __SIZEOF_PTHREAD_RWLOCKATTR_T = @as(c_int, 8);
pub const __SIZEOF_PTHREAD_BARRIERATTR_T = @as(c_int, 4);
pub const __LOCK_ALIGNMENT = "";
pub const __ONCE_ALIGNMENT = "";
pub const _BITS_ATOMIC_WIDE_COUNTER_H = "";
pub const _THREAD_MUTEX_INTERNAL_H = @as(c_int, 1);
pub const __PTHREAD_MUTEX_HAVE_PREV = @as(c_int, 1);
pub const _RWLOCK_INTERNAL_H = "";
pub inline fn __PTHREAD_RWLOCK_INITIALIZER(__flags: anytype) @TypeOf(__flags) {
    _ = &__flags;
    return blk: {
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = &__PTHREAD_RWLOCK_ELISION_EXTRA;
        _ = @as(c_int, 0);
        break :blk __flags;
    };
}
pub const __have_pthread_attr_t = @as(c_int, 1);
pub const _ALLOCA_H = @as(c_int, 1);
pub const __COMPAR_FN_T = "";
pub const _MATH_H = @as(c_int, 1);
pub const _BITS_LIBM_SIMD_DECL_STUBS_H = @as(c_int, 1);
pub const __DECL_SIMD_cos = "";
pub const __DECL_SIMD_cosf = "";
pub const __DECL_SIMD_cosl = "";
pub const __DECL_SIMD_cosf16 = "";
pub const __DECL_SIMD_cosf32 = "";
pub const __DECL_SIMD_cosf64 = "";
pub const __DECL_SIMD_cosf128 = "";
pub const __DECL_SIMD_cosf32x = "";
pub const __DECL_SIMD_cosf64x = "";
pub const __DECL_SIMD_cosf128x = "";
pub const __DECL_SIMD_sin = "";
pub const __DECL_SIMD_sinf = "";
pub const __DECL_SIMD_sinl = "";
pub const __DECL_SIMD_sinf16 = "";
pub const __DECL_SIMD_sinf32 = "";
pub const __DECL_SIMD_sinf64 = "";
pub const __DECL_SIMD_sinf128 = "";
pub const __DECL_SIMD_sinf32x = "";
pub const __DECL_SIMD_sinf64x = "";
pub const __DECL_SIMD_sinf128x = "";
pub const __DECL_SIMD_sincos = "";
pub const __DECL_SIMD_sincosf = "";
pub const __DECL_SIMD_sincosl = "";
pub const __DECL_SIMD_sincosf16 = "";
pub const __DECL_SIMD_sincosf32 = "";
pub const __DECL_SIMD_sincosf64 = "";
pub const __DECL_SIMD_sincosf128 = "";
pub const __DECL_SIMD_sincosf32x = "";
pub const __DECL_SIMD_sincosf64x = "";
pub const __DECL_SIMD_sincosf128x = "";
pub const __DECL_SIMD_log = "";
pub const __DECL_SIMD_logf = "";
pub const __DECL_SIMD_logl = "";
pub const __DECL_SIMD_logf16 = "";
pub const __DECL_SIMD_logf32 = "";
pub const __DECL_SIMD_logf64 = "";
pub const __DECL_SIMD_logf128 = "";
pub const __DECL_SIMD_logf32x = "";
pub const __DECL_SIMD_logf64x = "";
pub const __DECL_SIMD_logf128x = "";
pub const __DECL_SIMD_exp = "";
pub const __DECL_SIMD_expf = "";
pub const __DECL_SIMD_expl = "";
pub const __DECL_SIMD_expf16 = "";
pub const __DECL_SIMD_expf32 = "";
pub const __DECL_SIMD_expf64 = "";
pub const __DECL_SIMD_expf128 = "";
pub const __DECL_SIMD_expf32x = "";
pub const __DECL_SIMD_expf64x = "";
pub const __DECL_SIMD_expf128x = "";
pub const __DECL_SIMD_pow = "";
pub const __DECL_SIMD_powf = "";
pub const __DECL_SIMD_powl = "";
pub const __DECL_SIMD_powf16 = "";
pub const __DECL_SIMD_powf32 = "";
pub const __DECL_SIMD_powf64 = "";
pub const __DECL_SIMD_powf128 = "";
pub const __DECL_SIMD_powf32x = "";
pub const __DECL_SIMD_powf64x = "";
pub const __DECL_SIMD_powf128x = "";
pub const __DECL_SIMD_acos = "";
pub const __DECL_SIMD_acosf = "";
pub const __DECL_SIMD_acosl = "";
pub const __DECL_SIMD_acosf16 = "";
pub const __DECL_SIMD_acosf32 = "";
pub const __DECL_SIMD_acosf64 = "";
pub const __DECL_SIMD_acosf128 = "";
pub const __DECL_SIMD_acosf32x = "";
pub const __DECL_SIMD_acosf64x = "";
pub const __DECL_SIMD_acosf128x = "";
pub const __DECL_SIMD_atan = "";
pub const __DECL_SIMD_atanf = "";
pub const __DECL_SIMD_atanl = "";
pub const __DECL_SIMD_atanf16 = "";
pub const __DECL_SIMD_atanf32 = "";
pub const __DECL_SIMD_atanf64 = "";
pub const __DECL_SIMD_atanf128 = "";
pub const __DECL_SIMD_atanf32x = "";
pub const __DECL_SIMD_atanf64x = "";
pub const __DECL_SIMD_atanf128x = "";
pub const __DECL_SIMD_asin = "";
pub const __DECL_SIMD_asinf = "";
pub const __DECL_SIMD_asinl = "";
pub const __DECL_SIMD_asinf16 = "";
pub const __DECL_SIMD_asinf32 = "";
pub const __DECL_SIMD_asinf64 = "";
pub const __DECL_SIMD_asinf128 = "";
pub const __DECL_SIMD_asinf32x = "";
pub const __DECL_SIMD_asinf64x = "";
pub const __DECL_SIMD_asinf128x = "";
pub const __DECL_SIMD_hypot = "";
pub const __DECL_SIMD_hypotf = "";
pub const __DECL_SIMD_hypotl = "";
pub const __DECL_SIMD_hypotf16 = "";
pub const __DECL_SIMD_hypotf32 = "";
pub const __DECL_SIMD_hypotf64 = "";
pub const __DECL_SIMD_hypotf128 = "";
pub const __DECL_SIMD_hypotf32x = "";
pub const __DECL_SIMD_hypotf64x = "";
pub const __DECL_SIMD_hypotf128x = "";
pub const __DECL_SIMD_exp2 = "";
pub const __DECL_SIMD_exp2f = "";
pub const __DECL_SIMD_exp2l = "";
pub const __DECL_SIMD_exp2f16 = "";
pub const __DECL_SIMD_exp2f32 = "";
pub const __DECL_SIMD_exp2f64 = "";
pub const __DECL_SIMD_exp2f128 = "";
pub const __DECL_SIMD_exp2f32x = "";
pub const __DECL_SIMD_exp2f64x = "";
pub const __DECL_SIMD_exp2f128x = "";
pub const __DECL_SIMD_exp10 = "";
pub const __DECL_SIMD_exp10f = "";
pub const __DECL_SIMD_exp10l = "";
pub const __DECL_SIMD_exp10f16 = "";
pub const __DECL_SIMD_exp10f32 = "";
pub const __DECL_SIMD_exp10f64 = "";
pub const __DECL_SIMD_exp10f128 = "";
pub const __DECL_SIMD_exp10f32x = "";
pub const __DECL_SIMD_exp10f64x = "";
pub const __DECL_SIMD_exp10f128x = "";
pub const __DECL_SIMD_cosh = "";
pub const __DECL_SIMD_coshf = "";
pub const __DECL_SIMD_coshl = "";
pub const __DECL_SIMD_coshf16 = "";
pub const __DECL_SIMD_coshf32 = "";
pub const __DECL_SIMD_coshf64 = "";
pub const __DECL_SIMD_coshf128 = "";
pub const __DECL_SIMD_coshf32x = "";
pub const __DECL_SIMD_coshf64x = "";
pub const __DECL_SIMD_coshf128x = "";
pub const __DECL_SIMD_expm1 = "";
pub const __DECL_SIMD_expm1f = "";
pub const __DECL_SIMD_expm1l = "";
pub const __DECL_SIMD_expm1f16 = "";
pub const __DECL_SIMD_expm1f32 = "";
pub const __DECL_SIMD_expm1f64 = "";
pub const __DECL_SIMD_expm1f128 = "";
pub const __DECL_SIMD_expm1f32x = "";
pub const __DECL_SIMD_expm1f64x = "";
pub const __DECL_SIMD_expm1f128x = "";
pub const __DECL_SIMD_sinh = "";
pub const __DECL_SIMD_sinhf = "";
pub const __DECL_SIMD_sinhl = "";
pub const __DECL_SIMD_sinhf16 = "";
pub const __DECL_SIMD_sinhf32 = "";
pub const __DECL_SIMD_sinhf64 = "";
pub const __DECL_SIMD_sinhf128 = "";
pub const __DECL_SIMD_sinhf32x = "";
pub const __DECL_SIMD_sinhf64x = "";
pub const __DECL_SIMD_sinhf128x = "";
pub const __DECL_SIMD_cbrt = "";
pub const __DECL_SIMD_cbrtf = "";
pub const __DECL_SIMD_cbrtl = "";
pub const __DECL_SIMD_cbrtf16 = "";
pub const __DECL_SIMD_cbrtf32 = "";
pub const __DECL_SIMD_cbrtf64 = "";
pub const __DECL_SIMD_cbrtf128 = "";
pub const __DECL_SIMD_cbrtf32x = "";
pub const __DECL_SIMD_cbrtf64x = "";
pub const __DECL_SIMD_cbrtf128x = "";
pub const __DECL_SIMD_atan2 = "";
pub const __DECL_SIMD_atan2f = "";
pub const __DECL_SIMD_atan2l = "";
pub const __DECL_SIMD_atan2f16 = "";
pub const __DECL_SIMD_atan2f32 = "";
pub const __DECL_SIMD_atan2f64 = "";
pub const __DECL_SIMD_atan2f128 = "";
pub const __DECL_SIMD_atan2f32x = "";
pub const __DECL_SIMD_atan2f64x = "";
pub const __DECL_SIMD_atan2f128x = "";
pub const __DECL_SIMD_log10 = "";
pub const __DECL_SIMD_log10f = "";
pub const __DECL_SIMD_log10l = "";
pub const __DECL_SIMD_log10f16 = "";
pub const __DECL_SIMD_log10f32 = "";
pub const __DECL_SIMD_log10f64 = "";
pub const __DECL_SIMD_log10f128 = "";
pub const __DECL_SIMD_log10f32x = "";
pub const __DECL_SIMD_log10f64x = "";
pub const __DECL_SIMD_log10f128x = "";
pub const __DECL_SIMD_log2 = "";
pub const __DECL_SIMD_log2f = "";
pub const __DECL_SIMD_log2l = "";
pub const __DECL_SIMD_log2f16 = "";
pub const __DECL_SIMD_log2f32 = "";
pub const __DECL_SIMD_log2f64 = "";
pub const __DECL_SIMD_log2f128 = "";
pub const __DECL_SIMD_log2f32x = "";
pub const __DECL_SIMD_log2f64x = "";
pub const __DECL_SIMD_log2f128x = "";
pub const __DECL_SIMD_log1p = "";
pub const __DECL_SIMD_log1pf = "";
pub const __DECL_SIMD_log1pl = "";
pub const __DECL_SIMD_log1pf16 = "";
pub const __DECL_SIMD_log1pf32 = "";
pub const __DECL_SIMD_log1pf64 = "";
pub const __DECL_SIMD_log1pf128 = "";
pub const __DECL_SIMD_log1pf32x = "";
pub const __DECL_SIMD_log1pf64x = "";
pub const __DECL_SIMD_log1pf128x = "";
pub const __DECL_SIMD_atanh = "";
pub const __DECL_SIMD_atanhf = "";
pub const __DECL_SIMD_atanhl = "";
pub const __DECL_SIMD_atanhf16 = "";
pub const __DECL_SIMD_atanhf32 = "";
pub const __DECL_SIMD_atanhf64 = "";
pub const __DECL_SIMD_atanhf128 = "";
pub const __DECL_SIMD_atanhf32x = "";
pub const __DECL_SIMD_atanhf64x = "";
pub const __DECL_SIMD_atanhf128x = "";
pub const __DECL_SIMD_acosh = "";
pub const __DECL_SIMD_acoshf = "";
pub const __DECL_SIMD_acoshl = "";
pub const __DECL_SIMD_acoshf16 = "";
pub const __DECL_SIMD_acoshf32 = "";
pub const __DECL_SIMD_acoshf64 = "";
pub const __DECL_SIMD_acoshf128 = "";
pub const __DECL_SIMD_acoshf32x = "";
pub const __DECL_SIMD_acoshf64x = "";
pub const __DECL_SIMD_acoshf128x = "";
pub const __DECL_SIMD_erf = "";
pub const __DECL_SIMD_erff = "";
pub const __DECL_SIMD_erfl = "";
pub const __DECL_SIMD_erff16 = "";
pub const __DECL_SIMD_erff32 = "";
pub const __DECL_SIMD_erff64 = "";
pub const __DECL_SIMD_erff128 = "";
pub const __DECL_SIMD_erff32x = "";
pub const __DECL_SIMD_erff64x = "";
pub const __DECL_SIMD_erff128x = "";
pub const __DECL_SIMD_tanh = "";
pub const __DECL_SIMD_tanhf = "";
pub const __DECL_SIMD_tanhl = "";
pub const __DECL_SIMD_tanhf16 = "";
pub const __DECL_SIMD_tanhf32 = "";
pub const __DECL_SIMD_tanhf64 = "";
pub const __DECL_SIMD_tanhf128 = "";
pub const __DECL_SIMD_tanhf32x = "";
pub const __DECL_SIMD_tanhf64x = "";
pub const __DECL_SIMD_tanhf128x = "";
pub const __DECL_SIMD_asinh = "";
pub const __DECL_SIMD_asinhf = "";
pub const __DECL_SIMD_asinhl = "";
pub const __DECL_SIMD_asinhf16 = "";
pub const __DECL_SIMD_asinhf32 = "";
pub const __DECL_SIMD_asinhf64 = "";
pub const __DECL_SIMD_asinhf128 = "";
pub const __DECL_SIMD_asinhf32x = "";
pub const __DECL_SIMD_asinhf64x = "";
pub const __DECL_SIMD_asinhf128x = "";
pub const __DECL_SIMD_erfc = "";
pub const __DECL_SIMD_erfcf = "";
pub const __DECL_SIMD_erfcl = "";
pub const __DECL_SIMD_erfcf16 = "";
pub const __DECL_SIMD_erfcf32 = "";
pub const __DECL_SIMD_erfcf64 = "";
pub const __DECL_SIMD_erfcf128 = "";
pub const __DECL_SIMD_erfcf32x = "";
pub const __DECL_SIMD_erfcf64x = "";
pub const __DECL_SIMD_erfcf128x = "";
pub const __DECL_SIMD_tan = "";
pub const __DECL_SIMD_tanf = "";
pub const __DECL_SIMD_tanl = "";
pub const __DECL_SIMD_tanf16 = "";
pub const __DECL_SIMD_tanf32 = "";
pub const __DECL_SIMD_tanf64 = "";
pub const __DECL_SIMD_tanf128 = "";
pub const __DECL_SIMD_tanf32x = "";
pub const __DECL_SIMD_tanf64x = "";
pub const __DECL_SIMD_tanf128x = "";
pub const HUGE_VALF = __builtin_huge_valf();
pub const INFINITY = __builtin_inff();
pub const NAN = __builtin_nanf("");
pub const __FP_LOGB0_IS_MIN = @as(c_int, 1);
pub const __FP_LOGBNAN_IS_MIN = @as(c_int, 1);
pub const FP_ILOGB0 = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const FP_ILOGBNAN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub inline fn __MATHCALL(function: anytype, suffix: anytype, args: anytype) @TypeOf(__MATHDECL(_Mdouble_, function, suffix, args)) {
    _ = &function;
    _ = &suffix;
    _ = &args;
    return __MATHDECL(_Mdouble_, function, suffix, args);
}
pub inline fn __MATHCALLX(function: anytype, suffix: anytype, args: anytype, attrib: anytype) @TypeOf(__MATHDECLX(_Mdouble_, function, suffix, args, attrib)) {
    _ = &function;
    _ = &suffix;
    _ = &args;
    _ = &attrib;
    return __MATHDECLX(_Mdouble_, function, suffix, args, attrib);
}
pub inline fn __MATHDECL_1(@"type": anytype, function: anytype, suffix: anytype, args: anytype) @TypeOf(__MATHDECL_1_IMPL(@"type", function, suffix, args)) {
    _ = &@"type";
    _ = &function;
    _ = &suffix;
    _ = &args;
    return __MATHDECL_1_IMPL(@"type", function, suffix, args);
}
pub inline fn __MATHDECL_ALIAS(@"type": anytype, function: anytype, suffix: anytype, args: anytype, alias: anytype) @TypeOf(__MATHDECL_1(@"type", function, suffix, args)) {
    _ = &@"type";
    _ = &function;
    _ = &suffix;
    _ = &args;
    _ = &alias;
    return __MATHDECL_1(@"type", function, suffix, args);
}
pub const _Mdouble_ = f64;
pub inline fn __MATH_PRECNAME(name: anytype, r: anytype) @TypeOf(__CONCAT(name, r)) {
    _ = &name;
    _ = &r;
    return __CONCAT(name, r);
}
pub const __MATH_DECLARING_DOUBLE = @as(c_int, 1);
pub const __MATH_DECLARING_FLOATN = @as(c_int, 0);
pub const __MATH_DECLARE_LDOUBLE = @as(c_int, 1);
pub inline fn __MATHCALL_NARROW(func: anytype, redir: anytype, nargs: anytype) @TypeOf(__MATHCALL_NARROW_NORMAL(func, nargs)) {
    _ = &func;
    _ = &redir;
    _ = &nargs;
    return __MATHCALL_NARROW_NORMAL(func, nargs);
}
pub inline fn signbit(x: anytype) @TypeOf(__builtin_signbit(x)) {
    _ = &x;
    return __builtin_signbit(x);
}
pub const MATH_ERRNO = @as(c_int, 1);
pub const MATH_ERREXCEPT = @as(c_int, 2);
pub const math_errhandling = MATH_ERRNO | MATH_ERREXCEPT;
pub const M_E = @as(f64, 2.7182818284590452354);
pub const M_LOG2E = @as(f64, 1.4426950408889634074);
pub const M_LOG10E = @as(f64, 0.43429448190325182765);
pub const M_LN2 = @as(f64, 0.69314718055994530942);
pub const M_LN10 = @as(f64, 2.30258509299404568402);
pub const M_PI = @as(f64, 3.14159265358979323846);
pub const M_PI_2 = @as(f64, 1.57079632679489661923);
pub const M_PI_4 = @as(f64, 0.78539816339744830962);
pub const M_1_PI = @as(f64, 0.31830988618379067154);
pub const M_2_PI = @as(f64, 0.63661977236758134308);
pub const M_2_SQRTPI = @as(f64, 1.12837916709551257390);
pub const M_SQRT2 = @as(f64, 1.41421356237309504880);
pub const M_SQRT1_2 = @as(f64, 0.70710678118654752440);
pub const CP_EXPORT = "";
pub const CHIPMUNK_TYPES_H = "";
pub const __CLANG_STDINT_H = "";
pub const _STDINT_H = @as(c_int, 1);
pub const _BITS_WCHAR_H = @as(c_int, 1);
pub const __WCHAR_MAX = __WCHAR_MAX__;
pub const __WCHAR_MIN = -__WCHAR_MAX - @as(c_int, 1);
pub const _BITS_STDINT_UINTN_H = @as(c_int, 1);
pub const __intptr_t_defined = "";
pub const __INT64_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const __UINT64_C = @import("std").zig.c_translation.Macros.UL_SUFFIX;
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT64_MIN = -__INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = __INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT64_MAX = __UINT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_LEAST8_MIN = -@as(c_int, 128);
pub const INT_LEAST16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT_LEAST32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_LEAST64_MIN = -__INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_LEAST8_MAX = @as(c_int, 127);
pub const INT_LEAST16_MAX = @as(c_int, 32767);
pub const INT_LEAST32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT_LEAST64_MAX = __INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_LEAST8_MAX = @as(c_int, 255);
pub const UINT_LEAST16_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST64_MAX = __UINT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_FAST8_MIN = -@as(c_int, 128);
pub const INT_FAST16_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST64_MIN = -__INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_FAST8_MAX = @as(c_int, 127);
pub const INT_FAST16_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST64_MAX = __INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_FAST8_MAX = @as(c_int, 255);
pub const UINT_FAST16_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_MAX = __UINT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INTPTR_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INTPTR_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const UINTPTR_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const INTMAX_MIN = -__INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INTMAX_MAX = __INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINTMAX_MAX = __UINT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const PTRDIFF_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const PTRDIFF_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const SIG_ATOMIC_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const SIG_ATOMIC_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const SIZE_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const WCHAR_MIN = __WCHAR_MIN;
pub const WCHAR_MAX = __WCHAR_MAX;
pub const WINT_MIN = @as(c_uint, 0);
pub const WINT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub inline fn INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const INT64_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub inline fn UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const UINT64_C = @import("std").zig.c_translation.Macros.UL_SUFFIX;
pub const INTMAX_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const UINTMAX_C = @import("std").zig.c_translation.Macros.UL_SUFFIX;
pub const __CLANG_FLOAT_H = "";
pub const FLT_RADIX = __FLT_RADIX__;
pub const FLT_MANT_DIG = __FLT_MANT_DIG__;
pub const DBL_MANT_DIG = __DBL_MANT_DIG__;
pub const LDBL_MANT_DIG = __LDBL_MANT_DIG__;
pub const DECIMAL_DIG = __DECIMAL_DIG__;
pub const FLT_DIG = __FLT_DIG__;
pub const DBL_DIG = __DBL_DIG__;
pub const LDBL_DIG = __LDBL_DIG__;
pub const FLT_MIN_EXP = __FLT_MIN_EXP__;
pub const DBL_MIN_EXP = __DBL_MIN_EXP__;
pub const LDBL_MIN_EXP = __LDBL_MIN_EXP__;
pub const FLT_MIN_10_EXP = __FLT_MIN_10_EXP__;
pub const DBL_MIN_10_EXP = __DBL_MIN_10_EXP__;
pub const LDBL_MIN_10_EXP = __LDBL_MIN_10_EXP__;
pub const FLT_MAX_EXP = __FLT_MAX_EXP__;
pub const DBL_MAX_EXP = __DBL_MAX_EXP__;
pub const LDBL_MAX_EXP = __LDBL_MAX_EXP__;
pub const FLT_MAX_10_EXP = __FLT_MAX_10_EXP__;
pub const DBL_MAX_10_EXP = __DBL_MAX_10_EXP__;
pub const LDBL_MAX_10_EXP = __LDBL_MAX_10_EXP__;
pub const FLT_MAX = __FLT_MAX__;
pub const DBL_MAX = __DBL_MAX__;
pub const LDBL_MAX = __LDBL_MAX__;
pub const FLT_EPSILON = __FLT_EPSILON__;
pub const DBL_EPSILON = __DBL_EPSILON__;
pub const LDBL_EPSILON = __LDBL_EPSILON__;
pub const FLT_MIN = __FLT_MIN__;
pub const DBL_MIN = __DBL_MIN__;
pub const LDBL_MIN = __LDBL_MIN__;
pub const FLT_TRUE_MIN = __FLT_DENORM_MIN__;
pub const DBL_TRUE_MIN = __DBL_DENORM_MIN__;
pub const LDBL_TRUE_MIN = __LDBL_DENORM_MIN__;
pub const FLT_DECIMAL_DIG = __FLT_DECIMAL_DIG__;
pub const DBL_DECIMAL_DIG = __DBL_DECIMAL_DIG__;
pub const LDBL_DECIMAL_DIG = __LDBL_DECIMAL_DIG__;
pub const FLT_HAS_SUBNORM = __FLT_HAS_DENORM__;
pub const DBL_HAS_SUBNORM = __DBL_HAS_DENORM__;
pub const LDBL_HAS_SUBNORM = __LDBL_HAS_DENORM__;
pub const cpfsqrt = sqrtf;
pub const cpfsin = sinf;
pub const cpfcos = cosf;
pub const cpfacos = acosf;
pub const cpfatan2 = atan2f;
pub const cpfmod = fmodf;
pub const cpfexp = expf;
pub const cpfpow = powf;
pub const cpffloor = floorf;
pub const cpfceil = ceilf;
pub const CPFLOAT_MIN = FLT_MIN;
pub const CP_PI = @import("std").zig.c_translation.cast(cpFloat, @as(f64, 3.14159265358979323846264338327950288));
pub const cpTrue = @as(c_int, 1);
pub const cpFalse = @as(c_int, 0);
pub const CP_NO_GROUP = @import("std").zig.c_translation.cast(cpGroup, @as(c_int, 0));
pub const CP_ALL_CATEGORIES = ~@import("std").zig.c_translation.cast(cpBitmask, @as(c_int, 0));
pub const CP_WILDCARD_COLLISION_TYPE = ~@import("std").zig.c_translation.cast(cpCollisionType, @as(c_int, 0));
pub const CP_BUFFER_BYTES = @as(c_int, 32) * @as(c_int, 1024);
pub const cpcalloc = calloc;
pub const cprealloc = realloc;
pub const cpfree = free;
pub const CHIPMUNK_VECT_H = "";
pub const CHIPMUNK_BB_H = "";
pub const CHIPMUNK_TRANSFORM_H = "";
pub const CP_MAX_CONTACTS_PER_ARBITER = @as(c_int, 2);
pub const CP_VERSION_MAJOR = @as(c_int, 7);
pub const CP_VERSION_MINOR = @as(c_int, 0);
pub const CP_VERSION_RELEASE = @as(c_int, 3);
pub const timeval = struct_timeval;
pub const timespec = struct_timespec;
pub const __pthread_internal_list = struct___pthread_internal_list;
pub const __pthread_internal_slist = struct___pthread_internal_slist;
pub const __pthread_mutex_s = struct___pthread_mutex_s;
pub const __pthread_rwlock_arch_t = struct___pthread_rwlock_arch_t;
pub const __pthread_cond_s = struct___pthread_cond_s;
pub const random_data = struct_random_data;
pub const drand48_data = struct_drand48_data;
