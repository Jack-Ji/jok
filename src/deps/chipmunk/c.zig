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
pub const __builtin_va_list = [*c]u8;
pub const __gnuc_va_list = __builtin_va_list;
pub const va_list = __gnuc_va_list; // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:584:3: warning: TODO implement translation of stmt class GCCAsmStmtClass
// D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:581:36: warning: unable to translate function, demoted to extern
pub extern fn __debugbreak() void;
pub extern fn __mingw_get_crt_info() [*c]const u8;
pub const rsize_t = usize;
pub const ptrdiff_t = c_longlong;
pub const wchar_t = c_ushort;
pub const wint_t = c_ushort;
pub const wctype_t = c_ushort;
pub const errno_t = c_int;
pub const __time32_t = c_long;
pub const __time64_t = c_longlong;
pub const time_t = __time64_t;
pub const struct_tagLC_ID = extern struct {
    wLanguage: c_ushort,
    wCountry: c_ushort,
    wCodePage: c_ushort,
};
pub const LC_ID = struct_tagLC_ID;
const struct_unnamed_1 = extern struct {
    locale: [*c]u8,
    wlocale: [*c]wchar_t,
    refcount: [*c]c_int,
    wrefcount: [*c]c_int,
};
pub const struct_lconv = opaque {};
pub const struct___lc_time_data = opaque {};
pub const struct_threadlocaleinfostruct = extern struct {
    refcount: c_int,
    lc_codepage: c_uint,
    lc_collate_cp: c_uint,
    lc_handle: [6]c_ulong,
    lc_id: [6]LC_ID,
    lc_category: [6]struct_unnamed_1,
    lc_clike: c_int,
    mb_cur_max: c_int,
    lconv_intl_refcount: [*c]c_int,
    lconv_num_refcount: [*c]c_int,
    lconv_mon_refcount: [*c]c_int,
    lconv: ?*struct_lconv,
    ctype1_refcount: [*c]c_int,
    ctype1: [*c]c_ushort,
    pctype: [*c]const c_ushort,
    pclmap: [*c]const u8,
    pcumap: [*c]const u8,
    lc_time_curr: ?*struct___lc_time_data,
};
pub const struct_threadmbcinfostruct = opaque {};
pub const pthreadlocinfo = [*c]struct_threadlocaleinfostruct;
pub const pthreadmbcinfo = ?*struct_threadmbcinfostruct;
pub const struct_localeinfo_struct = extern struct {
    locinfo: pthreadlocinfo,
    mbcinfo: pthreadmbcinfo,
};
pub const _locale_tstruct = struct_localeinfo_struct;
pub const _locale_t = [*c]struct_localeinfo_struct;
pub const LPLC_ID = [*c]struct_tagLC_ID;
pub const threadlocinfo = struct_threadlocaleinfostruct;
pub extern fn _itow_s(_Val: c_int, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ltow_s(_Val: c_long, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ultow_s(_Val: c_ulong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wgetenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]wchar_t, _DstSizeInWords: usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _wdupenv_s(_Buffer: [*c][*c]wchar_t, _BufferSizeInWords: [*c]usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _i64tow_s(_Val: c_longlong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ui64tow_s(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wmakepath_s(_PathResult: [*c]wchar_t, _SizeInWords: usize, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) errno_t;
pub extern fn _wputenv_s(_Name: [*c]const wchar_t, _Value: [*c]const wchar_t) errno_t;
pub extern fn _wsearchenv_s(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _wsplitpath_s(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _DriveSizeInWords: usize, _Dir: [*c]wchar_t, _DirSizeInWords: usize, _Filename: [*c]wchar_t, _FilenameSizeInWords: usize, _Ext: [*c]wchar_t, _ExtSizeInWords: usize) errno_t;
pub const _onexit_t = ?*const fn () callconv(.C) c_int;
pub const struct__div_t = extern struct {
    quot: c_int,
    rem: c_int,
};
pub const div_t = struct__div_t;
pub const struct__ldiv_t = extern struct {
    quot: c_long,
    rem: c_long,
};
pub const ldiv_t = struct__ldiv_t;
pub const _LDOUBLE = extern struct {
    ld: [10]u8,
};
pub const _CRT_DOUBLE = extern struct {
    x: f64,
};
pub const _CRT_FLOAT = extern struct {
    f: f32,
};
pub const _LONGDOUBLE = extern struct {
    x: c_longdouble,
};
pub const _LDBL12 = extern struct {
    ld12: [12]u8,
};
pub extern var __imp___mb_cur_max: [*c]c_int;
pub extern fn ___mb_cur_max_func() c_int;
pub const _purecall_handler = ?*const fn () callconv(.C) void;
pub extern fn _set_purecall_handler(_Handler: _purecall_handler) _purecall_handler;
pub extern fn _get_purecall_handler() _purecall_handler;
pub const _invalid_parameter_handler = ?*const fn ([*c]const wchar_t, [*c]const wchar_t, [*c]const wchar_t, c_uint, usize) callconv(.C) void;
pub extern fn _set_invalid_parameter_handler(_Handler: _invalid_parameter_handler) _invalid_parameter_handler;
pub extern fn _get_invalid_parameter_handler() _invalid_parameter_handler;
pub extern fn _errno() [*c]c_int;
pub extern fn _set_errno(_Value: c_int) errno_t;
pub extern fn _get_errno(_Value: [*c]c_int) errno_t;
pub extern fn __doserrno() [*c]c_ulong;
pub extern fn _set_doserrno(_Value: c_ulong) errno_t;
pub extern fn _get_doserrno(_Value: [*c]c_ulong) errno_t;
pub extern var _sys_errlist: [1][*c]u8;
pub extern var _sys_nerr: c_int;
pub extern fn __p___argv() [*c][*c][*c]u8;
pub extern fn __p__fmode() [*c]c_int;
pub extern fn _get_pgmptr(_Value: [*c][*c]u8) errno_t;
pub extern fn _get_wpgmptr(_Value: [*c][*c]wchar_t) errno_t;
pub extern fn _set_fmode(_Mode: c_int) errno_t;
pub extern fn _get_fmode(_PMode: [*c]c_int) errno_t;
pub extern var __imp___argc: [*c]c_int;
pub extern var __imp___argv: [*c][*c][*c]u8;
pub extern var __imp___wargv: [*c][*c][*c]wchar_t;
pub extern var __imp__environ: [*c][*c][*c]u8;
pub extern var __imp__wenviron: [*c][*c][*c]wchar_t;
pub extern var __imp__pgmptr: [*c][*c]u8;
pub extern var __imp__wpgmptr: [*c][*c]wchar_t;
pub extern var __imp__osplatform: [*c]c_uint;
pub extern var __imp__osver: [*c]c_uint;
pub extern var __imp__winver: [*c]c_uint;
pub extern var __imp__winmajor: [*c]c_uint;
pub extern var __imp__winminor: [*c]c_uint;
pub extern fn _get_osplatform(_Value: [*c]c_uint) errno_t;
pub extern fn _get_osver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winmajor(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winminor(_Value: [*c]c_uint) errno_t;
pub extern fn exit(_Code: c_int) noreturn;
pub extern fn _exit(_Code: c_int) noreturn;
pub extern fn _Exit(c_int) noreturn;
pub extern fn abort() noreturn;
pub extern fn _set_abort_behavior(_Flags: c_uint, _Mask: c_uint) c_uint;
pub extern fn abs(_X: c_int) c_int;
pub extern fn labs(_X: c_long) c_long; // D:\DevTools\zig\lib\libc\include\any-windows-any/stdlib.h:421:12: warning: TODO implement function '__builtin_llabs' in std.zig.c_builtins
// D:\DevTools\zig\lib\libc\include\any-windows-any/stdlib.h:420:41: warning: unable to translate function, demoted to extern
pub extern fn _abs64(arg_x: c_longlong) c_longlong;
pub extern fn atexit(?*const fn () callconv(.C) void) c_int;
pub extern fn atof(_String: [*c]const u8) f64;
pub extern fn _atof_l(_String: [*c]const u8, _Locale: _locale_t) f64;
pub extern fn atoi(_Str: [*c]const u8) c_int;
pub extern fn _atoi_l(_Str: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn atol(_Str: [*c]const u8) c_long;
pub extern fn _atol_l(_Str: [*c]const u8, _Locale: _locale_t) c_long;
pub extern fn bsearch(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) ?*anyopaque;
pub extern fn qsort(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) void;
pub extern fn _byteswap_ushort(_Short: c_ushort) c_ushort;
pub extern fn _byteswap_ulong(_Long: c_ulong) c_ulong;
pub extern fn _byteswap_uint64(_Int64: c_ulonglong) c_ulonglong;
pub extern fn div(_Numerator: c_int, _Denominator: c_int) div_t;
pub extern fn getenv(_VarName: [*c]const u8) [*c]u8;
pub extern fn _itoa(_Value: c_int, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _i64toa(_Val: c_longlong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _ui64toa(_Val: c_ulonglong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _atoi64(_String: [*c]const u8) c_longlong;
pub extern fn _atoi64_l(_String: [*c]const u8, _Locale: _locale_t) c_longlong;
pub extern fn _strtoi64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_longlong;
pub extern fn _strtoi64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _strtoui64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulonglong;
pub extern fn _strtoui64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn ldiv(_Numerator: c_long, _Denominator: c_long) ldiv_t;
pub extern fn _ltoa(_Value: c_long, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn mblen(_Ch: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _mblen_l(_Ch: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _mbstrlen(_Str: [*c]const u8) usize;
pub extern fn _mbstrlen_l(_Str: [*c]const u8, _Locale: _locale_t) usize;
pub extern fn _mbstrnlen(_Str: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstrnlen_l(_Str: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mbtowc(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize) c_int;
pub extern fn _mbtowc_l(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize, _Locale: _locale_t) c_int;
pub extern fn mbstowcs(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstowcs_l(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mkstemp(template_name: [*c]u8) c_int;
pub extern fn rand() c_int;
pub extern fn _set_error_mode(_Mode: c_int) c_int;
pub extern fn srand(_Seed: c_uint) void;
pub extern fn __mingw_strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub fn strtod(noalias arg__Str: [*c]const u8, noalias arg__EndPtr: [*c][*c]u8) callconv(.C) f64 {
    var _Str = arg__Str;
    var _EndPtr = arg__EndPtr;
    return __mingw_strtod(_Str, _EndPtr);
}
pub extern fn __mingw_strtof(noalias [*c]const u8, noalias [*c][*c]u8) f32;
pub fn strtof(noalias arg__Str: [*c]const u8, noalias arg__EndPtr: [*c][*c]u8) callconv(.C) f32 {
    var _Str = arg__Str;
    var _EndPtr = arg__EndPtr;
    return __mingw_strtof(_Str, _EndPtr);
}
pub extern fn strtold([*c]const u8, [*c][*c]u8) c_longdouble;
pub extern fn __strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub extern fn __mingw_strtold(noalias [*c]const u8, noalias [*c][*c]u8) c_longdouble;
pub extern fn _strtod_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Locale: _locale_t) f64;
pub extern fn strtol(_Str: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_long;
pub extern fn _strtol_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn strtoul(_Str: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulong;
pub extern fn _strtoul_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn system(_Command: [*c]const u8) c_int;
pub extern fn _ultoa(_Value: c_ulong, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn wctomb(_MbCh: [*c]u8, _WCh: wchar_t) c_int;
pub extern fn _wctomb_l(_MbCh: [*c]u8, _WCh: wchar_t, _Locale: _locale_t) c_int;
pub extern fn wcstombs(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn _wcstombs_l(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn calloc(_NumOfElements: c_ulonglong, _SizeOfElements: c_ulonglong) ?*anyopaque;
pub extern fn free(_Memory: ?*anyopaque) void;
pub extern fn malloc(_Size: c_ulonglong) ?*anyopaque;
pub extern fn realloc(_Memory: ?*anyopaque, _NewSize: c_ulonglong) ?*anyopaque;
pub extern fn _recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize) ?*anyopaque;
pub extern fn _aligned_free(_Memory: ?*anyopaque) void;
pub extern fn _aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_malloc(_Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_offset_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _itow(_Value: c_int, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ltow(_Value: c_long, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ultow(_Value: c_ulong, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn __mingw_wcstod(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t) f64;
pub extern fn __mingw_wcstof(noalias nptr: [*c]const wchar_t, noalias endptr: [*c][*c]wchar_t) f32;
pub extern fn __mingw_wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub fn wcstod(noalias arg__Str: [*c]const wchar_t, noalias arg__EndPtr: [*c][*c]wchar_t) callconv(.C) f64 {
    var _Str = arg__Str;
    var _EndPtr = arg__EndPtr;
    return __mingw_wcstod(_Str, _EndPtr);
}
pub fn wcstof(noalias arg__Str: [*c]const wchar_t, noalias arg__EndPtr: [*c][*c]wchar_t) callconv(.C) f32 {
    var _Str = arg__Str;
    var _EndPtr = arg__EndPtr;
    return __mingw_wcstof(_Str, _EndPtr);
}
pub extern fn wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub extern fn _wcstod_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Locale: _locale_t) f64;
pub extern fn wcstol(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_long;
pub extern fn _wcstol_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn wcstoul(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulong;
pub extern fn _wcstoul_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn _wgetenv(_VarName: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wsystem(_Command: [*c]const wchar_t) c_int;
pub extern fn _wtof(_Str: [*c]const wchar_t) f64;
pub extern fn _wtof_l(_Str: [*c]const wchar_t, _Locale: _locale_t) f64;
pub extern fn _wtoi(_Str: [*c]const wchar_t) c_int;
pub extern fn _wtoi_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wtol(_Str: [*c]const wchar_t) c_long;
pub extern fn _wtol_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_long;
pub extern fn _i64tow(_Val: c_longlong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ui64tow(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _wtoi64(_Str: [*c]const wchar_t) c_longlong;
pub extern fn _wtoi64_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoi64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_longlong;
pub extern fn _wcstoi64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoui64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulonglong;
pub extern fn _wcstoui64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn _putenv(_EnvString: [*c]const u8) c_int;
pub extern fn _wputenv(_EnvString: [*c]const wchar_t) c_int;
pub extern fn _fullpath(_FullPath: [*c]u8, _Path: [*c]const u8, _SizeInBytes: usize) [*c]u8;
pub extern fn _ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn _atodbl(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoldbl(_Result: [*c]_LDOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoflt(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8) c_int;
pub extern fn _atodbl_l(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoldbl_l(_Result: [*c]_LDOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoflt_l(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _lrotl(c_ulong, c_int) c_ulong;
pub extern fn _lrotr(c_ulong, c_int) c_ulong;
pub extern fn _makepath(_Path: [*c]u8, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) void;
pub extern fn _onexit(_Func: _onexit_t) _onexit_t;
pub extern fn perror(_ErrMsg: [*c]const u8) void;
pub extern fn _rotl64(_Val: c_ulonglong, _Shift: c_int) c_ulonglong;
pub extern fn _rotr64(Value: c_ulonglong, Shift: c_int) c_ulonglong;
pub extern fn _rotr(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _rotl(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _searchenv(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8) void;
pub extern fn _splitpath(_FullPath: [*c]const u8, _Drive: [*c]u8, _Dir: [*c]u8, _Filename: [*c]u8, _Ext: [*c]u8) void;
pub extern fn _swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn _wfullpath(_FullPath: [*c]wchar_t, _Path: [*c]const wchar_t, _SizeInWords: usize) [*c]wchar_t;
pub extern fn _wmakepath(_ResultPath: [*c]wchar_t, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) void;
pub extern fn _wperror(_ErrMsg: [*c]const wchar_t) void;
pub extern fn _wsearchenv(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t) void;
pub extern fn _wsplitpath(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _Dir: [*c]wchar_t, _Filename: [*c]wchar_t, _Ext: [*c]wchar_t) void;
pub const _beep = @compileError("unable to resolve function type clang.TypeClass.MacroQualified"); // D:\DevTools\zig\lib\libc\include\any-windows-any/stdlib.h:681:24
pub const _seterrormode = @compileError("unable to resolve function type clang.TypeClass.MacroQualified"); // D:\DevTools\zig\lib\libc\include\any-windows-any/stdlib.h:683:24
pub const _sleep = @compileError("unable to resolve function type clang.TypeClass.MacroQualified"); // D:\DevTools\zig\lib\libc\include\any-windows-any/stdlib.h:684:24
pub extern fn ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn itoa(_Val: c_int, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn ltoa(_Val: c_long, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn putenv(_EnvString: [*c]const u8) c_int;
pub extern fn swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn ultoa(_Val: c_ulong, _Dstbuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn onexit(_Func: _onexit_t) _onexit_t;
pub const lldiv_t = extern struct {
    quot: c_longlong,
    rem: c_longlong,
};
pub extern fn lldiv(c_longlong, c_longlong) lldiv_t;
pub extern fn llabs(c_longlong) c_longlong;
pub extern fn strtoll([*c]const u8, [*c][*c]u8, c_int) c_longlong;
pub extern fn strtoull([*c]const u8, [*c][*c]u8, c_int) c_ulonglong;
pub extern fn atoll([*c]const u8) c_longlong;
pub extern fn wtoll([*c]const wchar_t) c_longlong;
pub extern fn lltoa(c_longlong, [*c]u8, c_int) [*c]u8;
pub extern fn ulltoa(c_ulonglong, [*c]u8, c_int) [*c]u8;
pub extern fn lltow(c_longlong, [*c]wchar_t, c_int) [*c]wchar_t;
pub extern fn ulltow(c_ulonglong, [*c]wchar_t, c_int) [*c]wchar_t;
pub extern fn bsearch_s(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: rsize_t, _SizeOfElements: rsize_t, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.C) c_int, _Context: ?*anyopaque) ?*anyopaque;
pub extern fn _dupenv_s(_PBuffer: [*c][*c]u8, _PBufferSizeInBytes: [*c]usize, _VarName: [*c]const u8) errno_t;
pub extern fn getenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]u8, _DstSize: rsize_t, _VarName: [*c]const u8) errno_t;
pub extern fn _itoa_s(_Value: c_int, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _i64toa_s(_Val: c_longlong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ui64toa_s(_Val: c_ulonglong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ltoa_s(_Val: c_long, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn mbstowcs_s(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _mbstowcs_s_l(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn _ultoa_s(_Val: c_ulong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn wctomb_s(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: rsize_t, _WCh: wchar_t) errno_t;
pub extern fn _wctomb_s_l(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: usize, _WCh: wchar_t, _Locale: _locale_t) errno_t;
pub extern fn wcstombs_s(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize) errno_t;
pub extern fn _wcstombs_s_l(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize, _Locale: _locale_t) errno_t;
pub extern fn _ecvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDights: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _fcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _gcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDigits: c_int) errno_t;
pub extern fn _makepath_s(_PathResult: [*c]u8, _Size: usize, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) errno_t;
pub extern fn _putenv_s(_Name: [*c]const u8, _Value: [*c]const u8) errno_t;
pub extern fn _searchenv_s(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8, _SizeInBytes: usize) errno_t;
pub extern fn _splitpath_s(_FullPath: [*c]const u8, _Drive: [*c]u8, _DriveSize: usize, _Dir: [*c]u8, _DirSize: usize, _Filename: [*c]u8, _FilenameSize: usize, _Ext: [*c]u8, _ExtSize: usize) errno_t;
pub extern fn qsort_s(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.C) c_int, _Context: ?*anyopaque) void;
pub const struct__heapinfo = extern struct {
    _pentry: [*c]c_int,
    _size: usize,
    _useflag: c_int,
};
pub const _HEAPINFO = struct__heapinfo;
pub extern var _amblksiz: c_uint;
pub extern fn __mingw_aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn __mingw_aligned_free(_Memory: ?*anyopaque) void;
pub extern fn __mingw_aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn __mingw_aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Offset: usize) ?*anyopaque;
pub inline fn _mm_malloc(arg___size: usize, arg___align: usize) ?*anyopaque {
    var __size = arg___size;
    var __align = arg___align;
    if (__align == @bitCast(c_ulonglong, @as(c_longlong, @as(c_int, 1)))) {
        return malloc(__size);
    }
    if (!((__align & (__align -% @bitCast(c_ulonglong, @as(c_longlong, @as(c_int, 1))))) != 0) and (__align < @sizeOf(?*anyopaque))) {
        __align = @sizeOf(?*anyopaque);
    }
    var __mallocedMemory: ?*anyopaque = undefined;
    __mallocedMemory = __mingw_aligned_malloc(__size, __align);
    return __mallocedMemory;
}
pub inline fn _mm_free(arg___p: ?*anyopaque) void {
    var __p = arg___p;
    __mingw_aligned_free(__p);
}
pub extern fn _resetstkoflw() c_int;
pub extern fn _set_malloc_crt_max_wait(_NewValue: c_ulong) c_ulong;
pub extern fn _expand(_Memory: ?*anyopaque, _NewSize: usize) ?*anyopaque;
pub extern fn _msize(_Memory: ?*anyopaque) usize;
pub extern fn _get_sbh_threshold() usize;
pub extern fn _set_sbh_threshold(_NewValue: usize) c_int;
pub extern fn _set_amblksiz(_Value: usize) errno_t;
pub extern fn _get_amblksiz(_Value: [*c]usize) errno_t;
pub extern fn _heapadd(_Memory: ?*anyopaque, _Size: usize) c_int;
pub extern fn _heapchk() c_int;
pub extern fn _heapmin() c_int;
pub extern fn _heapset(_Fill: c_uint) c_int;
pub extern fn _heapwalk(_EntryInfo: [*c]_HEAPINFO) c_int;
pub extern fn _heapused(_Used: [*c]usize, _Commit: [*c]usize) usize;
pub extern fn _get_heap_handle() isize;
pub fn _MarkAllocaS(arg__Ptr: ?*anyopaque, arg__Marker: c_uint) callconv(.C) ?*anyopaque {
    var _Ptr = arg__Ptr;
    var _Marker = arg__Marker;
    if (_Ptr != null) {
        @ptrCast([*c]c_uint, @alignCast(@import("std").meta.alignment([*c]c_uint), _Ptr)).* = _Marker;
        _Ptr = @ptrCast(?*anyopaque, @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment([*c]u8), _Ptr)) + @bitCast(usize, @intCast(isize, @as(c_int, 16))));
    }
    return _Ptr;
}
pub fn _freea(arg__Memory: ?*anyopaque) callconv(.C) void {
    var _Memory = arg__Memory;
    var _Marker: c_uint = undefined;
    if (_Memory != null) {
        _Memory = @ptrCast(?*anyopaque, @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment([*c]u8), _Memory)) - @bitCast(usize, @intCast(isize, @as(c_int, 16))));
        _Marker = @ptrCast([*c]c_uint, @alignCast(@import("std").meta.alignment([*c]c_uint), _Memory)).*;
        if (_Marker == @bitCast(c_uint, @as(c_int, 56797))) {
            free(_Memory);
        }
    }
}
pub const struct__exception = extern struct {
    type: c_int,
    name: [*c]const u8,
    arg1: f64,
    arg2: f64,
    retval: f64,
};
const struct_unnamed_2 = extern struct {
    low: c_uint,
    high: c_uint,
};
pub const union___mingw_dbl_type_t = extern union {
    x: f64,
    val: c_ulonglong,
    lh: struct_unnamed_2,
};
pub const __mingw_dbl_type_t = union___mingw_dbl_type_t;
pub const union___mingw_flt_type_t = extern union {
    x: f32,
    val: c_uint,
};
pub const __mingw_flt_type_t = union___mingw_flt_type_t; // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:137:11: warning: struct demoted to opaque type - has bitfield
const struct_unnamed_3 = opaque {};
pub const union___mingw_ldbl_type_t = extern union {
    x: c_longdouble,
    lh: struct_unnamed_3,
};
pub const __mingw_ldbl_type_t = union___mingw_ldbl_type_t;
pub extern var __imp__HUGE: [*c]f64;
pub extern fn __mingw_raise_matherr(typ: c_int, name: [*c]const u8, a1: f64, a2: f64, rslt: f64) void;
pub extern fn __mingw_setusermatherr(?*const fn ([*c]struct__exception) callconv(.C) c_int) void;
pub extern fn __setusermatherr(?*const fn ([*c]struct__exception) callconv(.C) c_int) void;
pub extern fn sin(_X: f64) f64;
pub extern fn cos(_X: f64) f64;
pub extern fn tan(_X: f64) f64;
pub extern fn sinh(_X: f64) f64;
pub extern fn cosh(_X: f64) f64;
pub extern fn tanh(_X: f64) f64;
pub extern fn asin(_X: f64) f64;
pub extern fn acos(_X: f64) f64;
pub extern fn atan(_X: f64) f64;
pub extern fn atan2(_Y: f64, _X: f64) f64;
pub extern fn exp(_X: f64) f64;
pub extern fn log(_X: f64) f64;
pub extern fn log10(_X: f64) f64;
pub extern fn pow(_X: f64, _Y: f64) f64;
pub extern fn sqrt(_X: f64) f64;
pub extern fn ceil(_X: f64) f64;
pub extern fn floor(_X: f64) f64;
pub extern fn fabsf(x: f32) f32;
pub extern fn fabsl(c_longdouble) c_longdouble;
pub extern fn fabs(_X: f64) f64;
pub extern fn ldexp(_X: f64, _Y: c_int) f64;
pub extern fn frexp(_X: f64, _Y: [*c]c_int) f64;
pub extern fn modf(_X: f64, _Y: [*c]f64) f64;
pub extern fn fmod(_X: f64, _Y: f64) f64;
pub extern fn sincos(__x: f64, p_sin: [*c]f64, p_cos: [*c]f64) void;
pub extern fn sincosl(__x: c_longdouble, p_sin: [*c]c_longdouble, p_cos: [*c]c_longdouble) void;
pub extern fn sincosf(__x: f32, p_sin: [*c]f32, p_cos: [*c]f32) void;
pub const struct__complex = extern struct {
    x: f64,
    y: f64,
};
pub extern fn _cabs(_ComplexA: struct__complex) f64;
pub extern fn _hypot(_X: f64, _Y: f64) f64;
pub extern fn _j0(_X: f64) f64;
pub extern fn _j1(_X: f64) f64;
pub extern fn _jn(_X: c_int, _Y: f64) f64;
pub extern fn _y0(_X: f64) f64;
pub extern fn _y1(_X: f64) f64;
pub extern fn _yn(_X: c_int, _Y: f64) f64;
pub extern fn _matherr([*c]struct__exception) c_int;
pub extern fn _chgsign(_X: f64) f64;
pub extern fn _copysign(_Number: f64, _Sign: f64) f64;
pub extern fn _logb(f64) f64;
pub extern fn _nextafter(f64, f64) f64;
pub extern fn _scalb(f64, c_long) f64;
pub extern fn _finite(f64) c_int;
pub extern fn _fpclass(f64) c_int;
pub extern fn _isnan(f64) c_int;
pub extern fn j0(f64) f64;
pub extern fn j1(f64) f64;
pub extern fn jn(c_int, f64) f64;
pub extern fn y0(f64) f64;
pub extern fn y1(f64) f64;
pub extern fn yn(c_int, f64) f64;
pub extern fn chgsign(f64) f64;
pub extern fn finite(f64) c_int;
pub extern fn fpclass(f64) c_int;
pub const float_t = f32;
pub const double_t = f64;
pub extern fn __fpclassifyl(c_longdouble) c_int;
pub extern fn __fpclassifyf(f32) c_int;
pub extern fn __fpclassify(f64) c_int;
pub extern fn __isnan(f64) c_int;
pub extern fn __isnanf(f32) c_int;
pub extern fn __isnanl(c_longdouble) c_int;
pub extern fn __signbit(f64) c_int;
pub extern fn __signbitf(f32) c_int;
pub extern fn __signbitl(c_longdouble) c_int;
pub extern fn sinf(_X: f32) f32;
pub extern fn sinl(c_longdouble) c_longdouble;
pub extern fn cosf(_X: f32) f32;
pub extern fn cosl(c_longdouble) c_longdouble;
pub extern fn tanf(_X: f32) f32;
pub extern fn tanl(c_longdouble) c_longdouble;
pub extern fn asinf(_X: f32) f32;
pub extern fn asinl(c_longdouble) c_longdouble;
pub extern fn acosf(f32) f32;
pub extern fn acosl(c_longdouble) c_longdouble;
pub extern fn atanf(f32) f32;
pub extern fn atanl(c_longdouble) c_longdouble;
pub extern fn atan2f(f32, f32) f32;
pub extern fn atan2l(c_longdouble, c_longdouble) c_longdouble;
pub extern fn sinhf(_X: f32) f32;
pub extern fn sinhl(c_longdouble) c_longdouble;
pub extern fn coshf(_X: f32) f32;
pub extern fn coshl(c_longdouble) c_longdouble;
pub extern fn tanhf(_X: f32) f32;
pub extern fn tanhl(c_longdouble) c_longdouble;
pub extern fn acosh(f64) f64;
pub extern fn acoshf(f32) f32;
pub extern fn acoshl(c_longdouble) c_longdouble;
pub extern fn asinh(f64) f64;
pub extern fn asinhf(f32) f32;
pub extern fn asinhl(c_longdouble) c_longdouble;
pub extern fn atanh(f64) f64;
pub extern fn atanhf(f32) f32;
pub extern fn atanhl(c_longdouble) c_longdouble;
pub extern fn expf(_X: f32) f32;
pub extern fn expl(c_longdouble) c_longdouble;
pub extern fn exp2(f64) f64;
pub extern fn exp2f(f32) f32;
pub extern fn exp2l(c_longdouble) c_longdouble;
pub extern fn expm1(f64) f64;
pub extern fn expm1f(f32) f32;
pub extern fn expm1l(c_longdouble) c_longdouble;
pub extern fn frexpf(_X: f32, _Y: [*c]c_int) f32;
pub extern fn frexpl(c_longdouble, [*c]c_int) c_longdouble;
pub extern fn ilogb(f64) c_int;
pub extern fn ilogbf(f32) c_int;
pub extern fn ilogbl(c_longdouble) c_int;
pub extern fn ldexpf(_X: f32, _Y: c_int) f32;
pub extern fn ldexpl(c_longdouble, c_int) c_longdouble;
pub extern fn logf(f32) f32;
pub extern fn logl(c_longdouble) c_longdouble;
pub extern fn log10f(f32) f32;
pub extern fn log10l(c_longdouble) c_longdouble;
pub extern fn log1p(f64) f64;
pub extern fn log1pf(f32) f32;
pub extern fn log1pl(c_longdouble) c_longdouble;
pub extern fn log2(f64) f64;
pub extern fn log2f(f32) f32;
pub extern fn log2l(c_longdouble) c_longdouble;
pub extern fn logb(f64) f64;
pub extern fn logbf(f32) f32;
pub extern fn logbl(c_longdouble) c_longdouble;
pub extern fn modff(f32, [*c]f32) f32;
pub extern fn modfl(c_longdouble, [*c]c_longdouble) c_longdouble;
pub extern fn scalbn(f64, c_int) f64;
pub extern fn scalbnf(f32, c_int) f32;
pub extern fn scalbnl(c_longdouble, c_int) c_longdouble;
pub extern fn scalbln(f64, c_long) f64;
pub extern fn scalblnf(f32, c_long) f32;
pub extern fn scalblnl(c_longdouble, c_long) c_longdouble;
pub extern fn cbrt(f64) f64;
pub extern fn cbrtf(f32) f32;
pub extern fn cbrtl(c_longdouble) c_longdouble;
pub extern fn hypot(f64, f64) f64;
pub extern fn hypotf(x: f32, y: f32) f32;
pub extern fn hypotl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn powf(_X: f32, _Y: f32) f32;
pub extern fn powl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn sqrtf(f32) f32;
pub extern fn sqrtl(c_longdouble) c_longdouble;
pub extern fn erf(f64) f64;
pub extern fn erff(f32) f32;
pub extern fn erfl(c_longdouble) c_longdouble;
pub extern fn erfc(f64) f64;
pub extern fn erfcf(f32) f32;
pub extern fn erfcl(c_longdouble) c_longdouble;
pub extern fn lgamma(f64) f64;
pub extern fn lgammaf(f32) f32;
pub extern fn lgammal(c_longdouble) c_longdouble;
pub extern var signgam: c_int;
pub extern fn tgamma(f64) f64;
pub extern fn tgammaf(f32) f32;
pub extern fn tgammal(c_longdouble) c_longdouble;
pub extern fn ceilf(f32) f32;
pub extern fn ceill(c_longdouble) c_longdouble;
pub extern fn floorf(f32) f32;
pub extern fn floorl(c_longdouble) c_longdouble;
pub extern fn nearbyint(f64) f64;
pub extern fn nearbyintf(f32) f32;
pub extern fn nearbyintl(c_longdouble) c_longdouble;
pub extern fn rint(f64) f64;
pub extern fn rintf(f32) f32;
pub extern fn rintl(c_longdouble) c_longdouble;
pub extern fn lrint(f64) c_long;
pub extern fn lrintf(f32) c_long;
pub extern fn lrintl(c_longdouble) c_long;
pub extern fn llrint(f64) c_longlong;
pub extern fn llrintf(f32) c_longlong;
pub extern fn llrintl(c_longdouble) c_longlong;
pub extern fn round(f64) f64;
pub extern fn roundf(f32) f32;
pub extern fn roundl(c_longdouble) c_longdouble;
pub extern fn lround(f64) c_long;
pub extern fn lroundf(f32) c_long;
pub extern fn lroundl(c_longdouble) c_long;
pub extern fn llround(f64) c_longlong;
pub extern fn llroundf(f32) c_longlong;
pub extern fn llroundl(c_longdouble) c_longlong;
pub extern fn trunc(f64) f64;
pub extern fn truncf(f32) f32;
pub extern fn truncl(c_longdouble) c_longdouble;
pub extern fn fmodf(f32, f32) f32;
pub extern fn fmodl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn remainder(f64, f64) f64;
pub extern fn remainderf(f32, f32) f32;
pub extern fn remainderl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn remquo(f64, f64, [*c]c_int) f64;
pub extern fn remquof(f32, f32, [*c]c_int) f32;
pub extern fn remquol(c_longdouble, c_longdouble, [*c]c_int) c_longdouble;
pub extern fn copysign(f64, f64) f64;
pub extern fn copysignf(f32, f32) f32;
pub extern fn copysignl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn nan(tagp: [*c]const u8) f64;
pub extern fn nanf(tagp: [*c]const u8) f32;
pub extern fn nanl(tagp: [*c]const u8) c_longdouble;
pub extern fn nextafter(f64, f64) f64;
pub extern fn nextafterf(f32, f32) f32;
pub extern fn nextafterl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn nexttoward(f64, c_longdouble) f64;
pub extern fn nexttowardf(f32, c_longdouble) f32;
pub extern fn nexttowardl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn fdim(x: f64, y: f64) f64;
pub extern fn fdimf(x: f32, y: f32) f32;
pub extern fn fdiml(x: c_longdouble, y: c_longdouble) c_longdouble;
pub extern fn fmax(f64, f64) f64;
pub extern fn fmaxf(f32, f32) f32;
pub extern fn fmaxl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn fmin(f64, f64) f64;
pub extern fn fminf(f32, f32) f32;
pub extern fn fminl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn fma(f64, f64, f64) f64;
pub extern fn fmaf(f32, f32, f32) f32;
pub extern fn fmal(c_longdouble, c_longdouble, c_longdouble) c_longdouble;
pub extern fn _copysignf(_Number: f32, _Sign: f32) f32;
pub extern fn _chgsignf(_X: f32) f32;
pub extern fn _logbf(_X: f32) f32;
pub extern fn _nextafterf(_X: f32, _Y: f32) f32;
pub extern fn _finitef(_X: f32) c_int;
pub extern fn _isnanf(_X: f32) c_int;
pub extern fn _fpclassf(_X: f32) c_int;
pub extern fn _chgsignl(c_longdouble) c_longdouble;
pub extern fn cpMessage(condition: [*c]const u8, file: [*c]const u8, line: c_int, isError: c_int, isHardError: c_int, message: [*c]const u8, ...) void;
pub const int_least8_t = i8;
pub const uint_least8_t = u8;
pub const int_least16_t = c_short;
pub const uint_least16_t = c_ushort;
pub const int_least32_t = c_int;
pub const uint_least32_t = c_uint;
pub const int_least64_t = c_longlong;
pub const uint_least64_t = c_ulonglong;
pub const int_fast8_t = i8;
pub const uint_fast8_t = u8;
pub const int_fast16_t = c_short;
pub const uint_fast16_t = c_ushort;
pub const int_fast32_t = c_int;
pub const uint_fast32_t = c_uint;
pub const int_fast64_t = c_longlong;
pub const uint_fast64_t = c_ulonglong;
pub const intmax_t = c_longlong;
pub const uintmax_t = c_ulonglong;
pub extern fn _controlfp(_NewValue: c_uint, _Mask: c_uint) c_uint;
pub extern fn _controlfp_s(_CurrentState: [*c]c_uint, _NewValue: c_uint, _Mask: c_uint) errno_t;
pub extern fn _control87(_NewValue: c_uint, _Mask: c_uint) c_uint;
pub extern fn _clearfp() c_uint;
pub extern fn _statusfp() c_uint;
pub extern fn _fpreset() void;
pub extern fn fpreset() void;
pub extern fn __fpecode() [*c]c_int;
pub const cpFloat = f32;
pub fn cpfmax(arg_a: cpFloat, arg_b: cpFloat) callconv(.C) cpFloat {
    var a = arg_a;
    var b = arg_b;
    return if (a > b) a else b;
}
pub fn cpfmin(arg_a: cpFloat, arg_b: cpFloat) callconv(.C) cpFloat {
    var a = arg_a;
    var b = arg_b;
    return if (a < b) a else b;
}
pub fn cpfabs(arg_f: cpFloat) callconv(.C) cpFloat {
    var f = arg_f;
    return if (f < @intToFloat(f32, @as(c_int, 0))) -f else f;
}
pub fn cpfclamp(arg_f: cpFloat, arg_min: cpFloat, arg_max: cpFloat) callconv(.C) cpFloat {
    var f = arg_f;
    var min = arg_min;
    var max = arg_max;
    return cpfmin(cpfmax(f, min), max);
}
pub fn cpfclamp01(arg_f: cpFloat) callconv(.C) cpFloat {
    var f = arg_f;
    return cpfmax(0.0, cpfmin(f, 1.0));
}
pub fn cpflerp(arg_f1: cpFloat, arg_f2: cpFloat, arg_t: cpFloat) callconv(.C) cpFloat {
    var f1 = arg_f1;
    var f2 = arg_f2;
    var t = arg_t;
    return (f1 * (1.0 - t)) + (f2 * t);
}
pub fn cpflerpconst(arg_f1: cpFloat, arg_f2: cpFloat, arg_d: cpFloat) callconv(.C) cpFloat {
    var f1 = arg_f1;
    var f2 = arg_f2;
    var d = arg_d;
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
    x: cpFloat,
    y: cpFloat,
};
pub const cpVect = struct_cpVect;
pub const struct_cpTransform = extern struct {
    a: cpFloat,
    b: cpFloat,
    c: cpFloat,
    d: cpFloat,
    tx: cpFloat,
    ty: cpFloat,
};
pub const cpTransform = struct_cpTransform;
pub const struct_cpMat2x2 = extern struct {
    a: cpFloat,
    b: cpFloat,
    c: cpFloat,
    d: cpFloat,
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
    typeA: cpCollisionType,
    typeB: cpCollisionType,
    beginFunc: cpCollisionBeginFunc,
    preSolveFunc: cpCollisionPreSolveFunc,
    postSolveFunc: cpCollisionPostSolveFunc,
    separateFunc: cpCollisionSeparateFunc,
    userData: cpDataPointer,
};
pub const cpCollisionHandler = struct_cpCollisionHandler;
const struct_unnamed_4 = extern struct {
    pointA: cpVect,
    pointB: cpVect,
    distance: cpFloat,
};
pub const struct_cpContactPointSet = extern struct {
    count: c_int,
    normal: cpVect,
    points: [2]struct_unnamed_4,
};
pub const cpContactPointSet = struct_cpContactPointSet;
pub const cpvzero: cpVect = cpVect{
    .x = 0.0,
    .y = 0.0,
};
pub fn cpv(x: cpFloat, y: cpFloat) callconv(.C) cpVect {
    var v: cpVect = cpVect{
        .x = x,
        .y = y,
    };
    return v;
}
pub fn cpveql(v1: cpVect, v2: cpVect) callconv(.C) cpBool {
    return @bitCast(cpBool, @truncate(i8, @boolToInt((v1.x == v2.x) and (v1.y == v2.y))));
}
pub fn cpvadd(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv(v1.x + v2.x, v1.y + v2.y);
}
pub fn cpvsub(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv(v1.x - v2.x, v1.y - v2.y);
}
pub fn cpvneg(v: cpVect) callconv(.C) cpVect {
    return cpv(-v.x, -v.y);
}
pub fn cpvmult(v: cpVect, s: cpFloat) callconv(.C) cpVect {
    return cpv(v.x * s, v.y * s);
}
pub fn cpvdot(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return (v1.x * v2.x) + (v1.y * v2.y);
}
pub fn cpvcross(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return (v1.x * v2.y) - (v1.y * v2.x);
}
pub fn cpvperp(v: cpVect) callconv(.C) cpVect {
    return cpv(-v.y, v.x);
}
pub fn cpvrperp(v: cpVect) callconv(.C) cpVect {
    return cpv(v.y, -v.x);
}
pub fn cpvproject(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpvmult(v2, cpvdot(v1, v2) / cpvdot(v2, v2));
}
pub fn cpvforangle(a: cpFloat) callconv(.C) cpVect {
    return cpv(cosf(a), sinf(a));
}
pub fn cpvtoangle(v: cpVect) callconv(.C) cpFloat {
    return atan2f(v.y, v.x);
}
pub fn cpvrotate(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv((v1.x * v2.x) - (v1.y * v2.y), (v1.x * v2.y) + (v1.y * v2.x));
}
pub fn cpvunrotate(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv((v1.x * v2.x) + (v1.y * v2.y), (v1.y * v2.x) - (v1.x * v2.y));
}
pub fn cpvlengthsq(v: cpVect) callconv(.C) cpFloat {
    return cpvdot(v, v);
}
pub fn cpvlength(v: cpVect) callconv(.C) cpFloat {
    return sqrtf(cpvdot(v, v));
}
pub fn cpvlerp(v1: cpVect, v2: cpVect, t: cpFloat) callconv(.C) cpVect {
    return cpvadd(cpvmult(v1, 1.0 - t), cpvmult(v2, t));
}
pub fn cpvnormalize(v: cpVect) callconv(.C) cpVect {
    return cpvmult(v, 1.0 / (cpvlength(v) + 0.000000000000000000000000000000000000011754943508222875));
}
pub fn cpvslerp(v1: cpVect, v2: cpVect, t: cpFloat) callconv(.C) cpVect {
    var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2));
    var omega: cpFloat = acosf(cpfclamp(dot, -1.0, 1.0));
    if (@floatCast(f64, omega) < 0.001) {
        return cpvlerp(v1, v2, t);
    } else {
        var denom: cpFloat = 1.0 / sinf(omega);
        return cpvadd(cpvmult(v1, sinf((1.0 - t) * omega) * denom), cpvmult(v2, sinf(t * omega) * denom));
    }
    return @import("std").mem.zeroes(struct_cpVect);
}
pub fn cpvslerpconst(v1: cpVect, v2: cpVect, a: cpFloat) callconv(.C) cpVect {
    var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2));
    var omega: cpFloat = acosf(cpfclamp(dot, -1.0, 1.0));
    return cpvslerp(v1, v2, cpfmin(a, omega) / omega);
}
pub fn cpvclamp(v: cpVect, len: cpFloat) callconv(.C) cpVect {
    return if (cpvdot(v, v) > (len * len)) cpvmult(cpvnormalize(v), len) else v;
}
pub fn cpvlerpconst(arg_v1: cpVect, arg_v2: cpVect, arg_d: cpFloat) callconv(.C) cpVect {
    var v1 = arg_v1;
    var v2 = arg_v2;
    var d = arg_d;
    return cpvadd(v1, cpvclamp(cpvsub(v2, v1), d));
}
pub fn cpvdist(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return cpvlength(cpvsub(v1, v2));
}
pub fn cpvdistsq(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return cpvlengthsq(cpvsub(v1, v2));
}
pub fn cpvnear(v1: cpVect, v2: cpVect, dist: cpFloat) callconv(.C) cpBool {
    return @bitCast(cpBool, @truncate(i8, @boolToInt(cpvdistsq(v1, v2) < (dist * dist))));
}
pub fn cpMat2x2New(arg_a: cpFloat, arg_b: cpFloat, arg_c: cpFloat, arg_d: cpFloat) callconv(.C) cpMat2x2 {
    var a = arg_a;
    var b = arg_b;
    var c = arg_c;
    var d = arg_d;
    var m: cpMat2x2 = cpMat2x2{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
    };
    return m;
}
pub fn cpMat2x2Transform(arg_m: cpMat2x2, arg_v: cpVect) callconv(.C) cpVect {
    var m = arg_m;
    var v = arg_v;
    return cpv((v.x * m.a) + (v.y * m.b), (v.x * m.c) + (v.y * m.d));
}
pub const struct_cpBB = extern struct {
    l: cpFloat,
    b: cpFloat,
    r: cpFloat,
    t: cpFloat,
};
pub const cpBB = struct_cpBB;
pub fn cpBBNew(l: cpFloat, b: cpFloat, r: cpFloat, t: cpFloat) callconv(.C) cpBB {
    var bb: cpBB = cpBB{
        .l = l,
        .b = b,
        .r = r,
        .t = t,
    };
    return bb;
}
pub fn cpBBNewForExtents(c: cpVect, hw: cpFloat, hh: cpFloat) callconv(.C) cpBB {
    return cpBBNew(c.x - hw, c.y - hh, c.x + hw, c.y + hh);
}
pub fn cpBBNewForCircle(p: cpVect, r: cpFloat) callconv(.C) cpBB {
    return cpBBNewForExtents(p, r, r);
}
pub fn cpBBIntersects(a: cpBB, b: cpBB) callconv(.C) cpBool {
    return @bitCast(cpBool, @truncate(i8, @boolToInt((((a.l <= b.r) and (b.l <= a.r)) and (a.b <= b.t)) and (b.b <= a.t))));
}
pub fn cpBBContainsBB(bb: cpBB, other: cpBB) callconv(.C) cpBool {
    return @bitCast(cpBool, @truncate(i8, @boolToInt((((bb.l <= other.l) and (bb.r >= other.r)) and (bb.b <= other.b)) and (bb.t >= other.t))));
}
pub fn cpBBContainsVect(bb: cpBB, v: cpVect) callconv(.C) cpBool {
    return @bitCast(cpBool, @truncate(i8, @boolToInt((((bb.l <= v.x) and (bb.r >= v.x)) and (bb.b <= v.y)) and (bb.t >= v.y))));
}
pub fn cpBBMerge(a: cpBB, b: cpBB) callconv(.C) cpBB {
    return cpBBNew(cpfmin(a.l, b.l), cpfmin(a.b, b.b), cpfmax(a.r, b.r), cpfmax(a.t, b.t));
}
pub fn cpBBExpand(bb: cpBB, v: cpVect) callconv(.C) cpBB {
    return cpBBNew(cpfmin(bb.l, v.x), cpfmin(bb.b, v.y), cpfmax(bb.r, v.x), cpfmax(bb.t, v.y));
}
pub fn cpBBCenter(arg_bb: cpBB) callconv(.C) cpVect {
    var bb = arg_bb;
    return cpvlerp(cpv(bb.l, bb.b), cpv(bb.r, bb.t), 0.5);
}
pub fn cpBBArea(arg_bb: cpBB) callconv(.C) cpFloat {
    var bb = arg_bb;
    return (bb.r - bb.l) * (bb.t - bb.b);
}
pub fn cpBBMergedArea(arg_a: cpBB, arg_b: cpBB) callconv(.C) cpFloat {
    var a = arg_a;
    var b = arg_b;
    return (cpfmax(a.r, b.r) - cpfmin(a.l, b.l)) * (cpfmax(a.t, b.t) - cpfmin(a.b, b.b));
}
pub fn cpBBSegmentQuery(arg_bb: cpBB, arg_a: cpVect, arg_b: cpVect) callconv(.C) cpFloat {
    var bb = arg_bb;
    var a = arg_a;
    var b = arg_b;
    var delta: cpVect = cpvsub(b, a);
    var tmin: cpFloat = -__builtin_inff();
    var tmax: cpFloat = __builtin_inff();
    if (delta.x == 0.0) {
        if ((a.x < bb.l) or (bb.r < a.x)) return __builtin_inff();
    } else {
        var t1: cpFloat = (bb.l - a.x) / delta.x;
        var t2: cpFloat = (bb.r - a.x) / delta.x;
        tmin = cpfmax(tmin, cpfmin(t1, t2));
        tmax = cpfmin(tmax, cpfmax(t1, t2));
    }
    if (delta.y == 0.0) {
        if ((a.y < bb.b) or (bb.t < a.y)) return __builtin_inff();
    } else {
        var t1: cpFloat = (bb.b - a.y) / delta.y;
        var t2: cpFloat = (bb.t - a.y) / delta.y;
        tmin = cpfmax(tmin, cpfmin(t1, t2));
        tmax = cpfmin(tmax, cpfmax(t1, t2));
    }
    if (((tmin <= tmax) and (0.0 <= tmax)) and (tmin <= 1.0)) {
        return cpfmax(tmin, 0.0);
    } else {
        return __builtin_inff();
    }
    return 0;
}
pub fn cpBBIntersectsSegment(arg_bb: cpBB, arg_a: cpVect, arg_b: cpVect) callconv(.C) cpBool {
    var bb = arg_bb;
    var a = arg_a;
    var b = arg_b;
    return @bitCast(cpBool, @truncate(i8, @boolToInt(cpBBSegmentQuery(bb, a, b) != __builtin_inff())));
}
pub fn cpBBClampVect(bb: cpBB, v: cpVect) callconv(.C) cpVect {
    return cpv(cpfclamp(v.x, bb.l, bb.r), cpfclamp(v.y, bb.b, bb.t));
}
pub fn cpBBWrapVect(bb: cpBB, v: cpVect) callconv(.C) cpVect {
    var dx: cpFloat = cpfabs(bb.r - bb.l);
    var modx: cpFloat = fmodf(v.x - bb.l, dx);
    var x: cpFloat = if (modx > 0.0) modx else modx + dx;
    var dy: cpFloat = cpfabs(bb.t - bb.b);
    var mody: cpFloat = fmodf(v.y - bb.b, dy);
    var y: cpFloat = if (mody > 0.0) mody else mody + dy;
    return cpv(x + bb.l, y + bb.b);
}
pub fn cpBBOffset(bb: cpBB, v: cpVect) callconv(.C) cpBB {
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
    var b = arg_b;
    var c = arg_c;
    var d = arg_d;
    var tx = arg_tx;
    var ty = arg_ty;
    var t: cpTransform = cpTransform{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
        .tx = tx,
        .ty = ty,
    };
    return t;
}
pub fn cpTransformNewTranspose(arg_a: cpFloat, arg_c: cpFloat, arg_tx: cpFloat, arg_b: cpFloat, arg_d: cpFloat, arg_ty: cpFloat) callconv(.C) cpTransform {
    var a = arg_a;
    var c = arg_c;
    var tx = arg_tx;
    var b = arg_b;
    var d = arg_d;
    var ty = arg_ty;
    var t: cpTransform = cpTransform{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
        .tx = tx,
        .ty = ty,
    };
    return t;
}
pub fn cpTransformInverse(arg_t: cpTransform) callconv(.C) cpTransform {
    var t = arg_t;
    var inv_det: cpFloat = @floatCast(cpFloat, 1.0 / @floatCast(f64, (t.a * t.d) - (t.c * t.b)));
    return cpTransformNewTranspose(t.d * inv_det, -t.c * inv_det, ((t.c * t.ty) - (t.tx * t.d)) * inv_det, -t.b * inv_det, t.a * inv_det, ((t.tx * t.b) - (t.a * t.ty)) * inv_det);
}
pub fn cpTransformMult(arg_t1: cpTransform, arg_t2: cpTransform) callconv(.C) cpTransform {
    var t1 = arg_t1;
    var t2 = arg_t2;
    return cpTransformNewTranspose((t1.a * t2.a) + (t1.c * t2.b), (t1.a * t2.c) + (t1.c * t2.d), ((t1.a * t2.tx) + (t1.c * t2.ty)) + t1.tx, (t1.b * t2.a) + (t1.d * t2.b), (t1.b * t2.c) + (t1.d * t2.d), ((t1.b * t2.tx) + (t1.d * t2.ty)) + t1.ty);
}
pub fn cpTransformPoint(arg_t: cpTransform, arg_p: cpVect) callconv(.C) cpVect {
    var t = arg_t;
    var p = arg_p;
    return cpv(((t.a * p.x) + (t.c * p.y)) + t.tx, ((t.b * p.x) + (t.d * p.y)) + t.ty);
}
pub fn cpTransformVect(arg_t: cpTransform, arg_v: cpVect) callconv(.C) cpVect {
    var t = arg_t;
    var v = arg_v;
    return cpv((t.a * v.x) + (t.c * v.y), (t.b * v.x) + (t.d * v.y));
}
pub fn cpTransformbBB(arg_t: cpTransform, arg_bb: cpBB) callconv(.C) cpBB {
    var t = arg_t;
    var bb = arg_bb;
    var center: cpVect = cpBBCenter(bb);
    var hw: cpFloat = @floatCast(cpFloat, @floatCast(f64, bb.r - bb.l) * 0.5);
    var hh: cpFloat = @floatCast(cpFloat, @floatCast(f64, bb.t - bb.b) * 0.5);
    var a: cpFloat = t.a * hw;
    var b: cpFloat = t.c * hh;
    var d: cpFloat = t.b * hw;
    var e: cpFloat = t.d * hh;
    var hw_max: cpFloat = cpfmax(cpfabs(a + b), cpfabs(a - b));
    var hh_max: cpFloat = cpfmax(cpfabs(d + e), cpfabs(d - e));
    return cpBBNewForExtents(cpTransformPoint(t, center), hw_max, hh_max);
}
pub fn cpTransformTranslate(arg_translate: cpVect) callconv(.C) cpTransform {
    var translate = arg_translate;
    return cpTransformNewTranspose(@floatCast(cpFloat, 1.0), @floatCast(cpFloat, 0.0), translate.x, @floatCast(cpFloat, 0.0), @floatCast(cpFloat, 1.0), translate.y);
}
pub fn cpTransformScale(arg_scaleX: cpFloat, arg_scaleY: cpFloat) callconv(.C) cpTransform {
    var scaleX = arg_scaleX;
    var scaleY = arg_scaleY;
    return cpTransformNewTranspose(scaleX, @floatCast(cpFloat, 0.0), @floatCast(cpFloat, 0.0), @floatCast(cpFloat, 0.0), scaleY, @floatCast(cpFloat, 0.0));
}
pub fn cpTransformRotate(arg_radians: cpFloat) callconv(.C) cpTransform {
    var radians = arg_radians;
    var rot: cpVect = cpvforangle(radians);
    return cpTransformNewTranspose(rot.x, -rot.y, @floatCast(cpFloat, 0.0), rot.y, rot.x, @floatCast(cpFloat, 0.0));
}
pub fn cpTransformRigid(arg_translate: cpVect, arg_radians: cpFloat) callconv(.C) cpTransform {
    var translate = arg_translate;
    var radians = arg_radians;
    var rot: cpVect = cpvforangle(radians);
    return cpTransformNewTranspose(rot.x, -rot.y, translate.x, rot.y, rot.x, translate.y);
}
pub fn cpTransformRigidInverse(arg_t: cpTransform) callconv(.C) cpTransform {
    var t = arg_t;
    return cpTransformNewTranspose(t.d, -t.c, (t.c * t.ty) - (t.tx * t.d), -t.b, t.a, (t.tx * t.b) - (t.a * t.ty));
}
pub fn cpTransformWrap(arg_outer: cpTransform, arg_inner: cpTransform) callconv(.C) cpTransform {
    var outer = arg_outer;
    var inner = arg_inner;
    return cpTransformMult(cpTransformInverse(outer), cpTransformMult(inner, outer));
}
pub fn cpTransformWrapInverse(arg_outer: cpTransform, arg_inner: cpTransform) callconv(.C) cpTransform {
    var outer = arg_outer;
    var inner = arg_inner;
    return cpTransformMult(outer, cpTransformMult(inner, cpTransformInverse(outer)));
}
pub fn cpTransformOrtho(arg_bb: cpBB) callconv(.C) cpTransform {
    var bb = arg_bb;
    return cpTransformNewTranspose(@floatCast(cpFloat, 2.0 / @floatCast(f64, bb.r - bb.l)), @floatCast(cpFloat, 0.0), -(bb.r + bb.l) / (bb.r - bb.l), @floatCast(cpFloat, 0.0), @floatCast(cpFloat, 2.0 / @floatCast(f64, bb.t - bb.b)), -(bb.t + bb.b) / (bb.t - bb.b));
}
pub fn cpTransformBoneScale(arg_v0: cpVect, arg_v1: cpVect) callconv(.C) cpTransform {
    var v0 = arg_v0;
    var v1 = arg_v1;
    var d: cpVect = cpvsub(v1, v0);
    return cpTransformNewTranspose(d.x, -d.y, v0.x, d.y, d.x, v0.y);
}
pub fn cpTransformAxialScale(arg_axis: cpVect, arg_pivot: cpVect, arg_scale: cpFloat) callconv(.C) cpTransform {
    var axis = arg_axis;
    var pivot = arg_pivot;
    var scale = arg_scale;
    var A: cpFloat = @floatCast(cpFloat, @floatCast(f64, axis.x * axis.y) * (@floatCast(f64, scale) - 1.0));
    var B: cpFloat = @floatCast(cpFloat, @floatCast(f64, cpvdot(axis, pivot)) * (1.0 - @floatCast(f64, scale)));
    return cpTransformNewTranspose(((scale * axis.x) * axis.x) + (axis.y * axis.y), A, axis.x * B, A, (axis.x * axis.x) + ((scale * axis.y) * axis.y), axis.y * B);
}
pub const cpSpatialIndexBBFunc = ?*const fn (?*anyopaque) callconv(.C) cpBB;
pub const cpSpatialIndexIteratorFunc = ?*const fn (?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexQueryFunc = ?*const fn (?*anyopaque, ?*anyopaque, cpCollisionID, ?*anyopaque) callconv(.C) cpCollisionID;
pub const cpSpatialIndexSegmentQueryFunc = ?*const fn (?*anyopaque, ?*anyopaque, ?*anyopaque) callconv(.C) cpFloat;
pub const cpSpatialIndexClass = struct_cpSpatialIndexClass;
pub const struct_cpSpatialIndex = extern struct {
    klass: [*c]cpSpatialIndexClass,
    bbfunc: cpSpatialIndexBBFunc,
    staticIndex: [*c]cpSpatialIndex,
    dynamicIndex: [*c]cpSpatialIndex,
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
    destroy: cpSpatialIndexDestroyImpl,
    count: cpSpatialIndexCountImpl,
    each: cpSpatialIndexEachImpl,
    contains: cpSpatialIndexContainsImpl,
    insert: cpSpatialIndexInsertImpl,
    remove: cpSpatialIndexRemoveImpl,
    reindex: cpSpatialIndexReindexImpl,
    reindexObject: cpSpatialIndexReindexObjectImpl,
    reindexQuery: cpSpatialIndexReindexQueryImpl,
    query: cpSpatialIndexQueryImpl,
    segmentQuery: cpSpatialIndexSegmentQueryImpl,
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
    if (index.*.klass != null) {
        index.*.klass.*.destroy.?(index);
    }
}
pub fn cpSpatialIndexCount(arg_index: [*c]cpSpatialIndex) callconv(.C) c_int {
    var index = arg_index;
    return index.*.klass.*.count.?(index);
}
pub fn cpSpatialIndexEach(arg_index: [*c]cpSpatialIndex, arg_func: cpSpatialIndexIteratorFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    var func = arg_func;
    var data = arg_data;
    index.*.klass.*.each.?(index, func, data);
}
pub fn cpSpatialIndexContains(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) cpBool {
    var index = arg_index;
    var obj = arg_obj;
    var hashid = arg_hashid;
    return index.*.klass.*.contains.?(index, obj, hashid);
}
pub fn cpSpatialIndexInsert(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    var index = arg_index;
    var obj = arg_obj;
    var hashid = arg_hashid;
    index.*.klass.*.insert.?(index, obj, hashid);
}
pub fn cpSpatialIndexRemove(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    var index = arg_index;
    var obj = arg_obj;
    var hashid = arg_hashid;
    index.*.klass.*.remove.?(index, obj, hashid);
}
pub fn cpSpatialIndexReindex(arg_index: [*c]cpSpatialIndex) callconv(.C) void {
    var index = arg_index;
    index.*.klass.*.reindex.?(index);
}
pub fn cpSpatialIndexReindexObject(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    var index = arg_index;
    var obj = arg_obj;
    var hashid = arg_hashid;
    index.*.klass.*.reindexObject.?(index, obj, hashid);
}
pub fn cpSpatialIndexQuery(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_bb: cpBB, arg_func: cpSpatialIndexQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    var obj = arg_obj;
    var bb = arg_bb;
    var func = arg_func;
    var data = arg_data;
    index.*.klass.*.query.?(index, obj, bb, func, data);
}
pub fn cpSpatialIndexSegmentQuery(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_a: cpVect, arg_b: cpVect, arg_t_exit: cpFloat, arg_func: cpSpatialIndexSegmentQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    var obj = arg_obj;
    var a = arg_a;
    var b = arg_b;
    var t_exit = arg_t_exit;
    var func = arg_func;
    var data = arg_data;
    index.*.klass.*.segmentQuery.?(index, obj, a, b, t_exit, func, data);
}
pub fn cpSpatialIndexReindexQuery(arg_index: [*c]cpSpatialIndex, arg_func: cpSpatialIndexQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    var index = arg_index;
    var func = arg_func;
    var data = arg_data;
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
    shape: ?*const cpShape,
    point: cpVect,
    distance: cpFloat,
    gradient: cpVect,
};
pub const cpPointQueryInfo = struct_cpPointQueryInfo;
pub const struct_cpSegmentQueryInfo = extern struct {
    shape: ?*const cpShape,
    point: cpVect,
    normal: cpVect,
    alpha: cpFloat,
};
pub const cpSegmentQueryInfo = struct_cpSegmentQueryInfo;
pub const struct_cpShapeFilter = extern struct {
    group: cpGroup,
    categories: cpBitmask,
    mask: cpBitmask,
};
pub const cpShapeFilter = struct_cpShapeFilter;
pub const CP_SHAPE_FILTER_ALL: cpShapeFilter = cpShapeFilter{
    .group = @bitCast(cpGroup, @as(c_longlong, @as(c_int, 0))),
    .categories = ~@bitCast(cpBitmask, @as(c_int, 0)),
    .mask = ~@bitCast(cpBitmask, @as(c_int, 0)),
};
pub const CP_SHAPE_FILTER_NONE: cpShapeFilter = cpShapeFilter{
    .group = @bitCast(cpGroup, @as(c_longlong, @as(c_int, 0))),
    .categories = ~~@bitCast(cpBitmask, @as(c_int, 0)),
    .mask = ~~@bitCast(cpBitmask, @as(c_int, 0)),
};
pub fn cpShapeFilterNew(arg_group: cpGroup, arg_categories: cpBitmask, arg_mask: cpBitmask) callconv(.C) cpShapeFilter {
    var group = arg_group;
    var categories = arg_categories;
    var mask = arg_mask;
    var filter: cpShapeFilter = cpShapeFilter{
        .group = group,
        .categories = categories,
        .mask = mask,
    };
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
    r: f32,
    g: f32,
    b: f32,
    a: f32,
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
    drawCircle: cpSpaceDebugDrawCircleImpl,
    drawSegment: cpSpaceDebugDrawSegmentImpl,
    drawFatSegment: cpSpaceDebugDrawFatSegmentImpl,
    drawPolygon: cpSpaceDebugDrawPolygonImpl,
    drawDot: cpSpaceDebugDrawDotImpl,
    flags: cpSpaceDebugDrawFlags,
    shapeOutlineColor: cpSpaceDebugColor,
    colorForShape: cpSpaceDebugDrawColorForShapeImpl,
    constraintColor: cpSpaceDebugColor,
    collisionPointColor: cpSpaceDebugColor,
    data: cpDataPointer,
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
    var delta: cpVect = cpvsub(a, b);
    var t: cpFloat = cpfclamp01(cpvdot(delta, cpvsub(p, b)) / cpvlengthsq(delta));
    return cpvadd(b, cpvmult(delta, t));
}
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // (no file):79:9
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // (no file):85:9
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // (no file):169:9
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // (no file):191:9
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // (no file):199:9
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):329:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):330:9
pub const __declspec = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):410:9
pub const _cdecl = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):411:9
pub const __cdecl = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):412:9
pub const _stdcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):413:9
pub const __stdcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):414:9
pub const _fastcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):415:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):416:9
pub const _thiscall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):417:9
pub const __thiscall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):418:9
pub const _pascal = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):419:9
pub const __pascal = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):420:9
pub const __STRINGIFY = @compileError("unable to translate C expr: unexpected token '#'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:10:9
pub const __MINGW64_VERSION_STR = @compileError("unable to translate C expr: unexpected token 'StringLiteral'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:26:9
pub const __MINGW_IMP_SYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:119:11
pub const __MINGW_IMP_LSYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:120:11
pub const __MINGW_LSYMBOL = @compileError("unable to translate C expr: unexpected token '##'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:122:11
pub const __MINGW_ASM_CALL = @compileError("unable to translate macro: undefined identifier `__asm__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:130:9
pub const __MINGW_ASM_CRT_CALL = @compileError("unable to translate macro: undefined identifier `__asm__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:131:9
pub const __MINGW_EXTENSION = @compileError("unable to translate macro: undefined identifier `__extension__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:163:13
pub const __MINGW_POISON_NAME = @compileError("unable to translate macro: undefined identifier `_layout_has_not_been_verified_and_its_declaration_is_most_likely_incorrect`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:203:11
pub const __MINGW_ATTRIB_DEPRECATED_STR = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:247:11
pub const __MINGW_MS_PRINTF = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:270:9
pub const __MINGW_MS_SCANF = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:273:9
pub const __MINGW_GNU_PRINTF = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:276:9
pub const __MINGW_GNU_SCANF = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:279:9
pub const __mingw_ovr = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_mac.h:289:11
pub const __MINGW_CRT_NAME_CONCAT2 = @compileError("unable to translate macro: undefined identifier `_s`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_secapi.h:41:9
pub const __CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY_0_3_ = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw_secapi.h:69:9
pub const __MINGW_IMPORT = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:51:12
pub const _CRTIMP = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:59:15
pub const _inline = @compileError("unable to translate macro: undefined identifier `__inline`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:81:9
pub const __CRT_INLINE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:90:11
pub const __MINGW_INTRIN_INLINE = @compileError("unable to translate macro: undefined identifier `__inline__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:97:9
pub const __UNUSED_PARAM = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:111:11
pub const __restrict_arr = @compileError("unable to translate macro: undefined identifier `__restrict`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:126:10
pub const __MINGW_ATTRIB_NORETURN = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:142:9
pub const __MINGW_ATTRIB_CONST = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:143:9
pub const __MINGW_ATTRIB_MALLOC = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:153:9
pub const __MINGW_ATTRIB_PURE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:154:9
pub const __MINGW_ATTRIB_NONNULL = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:167:9
pub const __MINGW_ATTRIB_UNUSED = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:173:9
pub const __MINGW_ATTRIB_USED = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:179:9
pub const __MINGW_ATTRIB_DEPRECATED = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:180:9
pub const __MINGW_ATTRIB_DEPRECATED_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:182:9
pub const __MINGW_NOTHROW = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:197:9
pub const __MINGW_PRAGMA_PARAM = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:215:9
pub const __MINGW_BROKEN_INTERFACE = @compileError("unable to translate macro: undefined identifier `message`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:218:9
pub const __forceinline = @compileError("unable to translate macro: undefined identifier `__inline__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:267:9
pub const _crt_va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/vadefs.h:48:9
pub const _crt_va_arg = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/vadefs.h:49:9
pub const _crt_va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/vadefs.h:50:9
pub const _crt_va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/vadefs.h:51:9
pub const __CRT_STRINGIZE = @compileError("unable to translate C expr: unexpected token '#'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:286:9
pub const __CRT_WIDE = @compileError("unable to translate macro: undefined identifier `L`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:291:9
pub const _CRT_DEPRECATE_TEXT = @compileError("unable to translate macro: undefined identifier `deprecated`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:350:9
pub const _CRT_INSECURE_DEPRECATE_MEMORY = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:353:9
pub const _CRT_INSECURE_DEPRECATE_GLOBALS = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:357:9
pub const _CRT_OBSOLETE = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:365:9
pub const _CRT_ALIGN = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:392:9
pub const _CRT_glob = @compileError("unable to translate macro: undefined identifier `_dowildcard`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:456:9
pub const _UNION_NAME = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:476:9
pub const _STRUCT_NAME = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:477:9
pub const __CRT_UUID_DECL = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/_mingw.h:564:9
pub const _CRT_SECURE_CPP_NOTHROW = @compileError("unable to translate macro: undefined identifier `throw`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:148:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:267:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:268:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:269:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:270:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_4 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:271:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:272:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:273:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:274:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_2_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:275:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1_ARGLIST = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:276:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2_ARGLIST = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:277:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_SPLITPATH = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:278:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:282:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:284:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:286:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:288:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:290:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0_EX = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:427:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1_EX = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:428:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2_EX = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:429:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3_EX = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:430:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4_EX = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:431:9
pub const __crt_typefix = @compileError("unable to translate C expr: unexpected token 'Eof'"); // D:\DevTools\zig\lib\libc\include\any-windows-any/corecrt.h:491:9
pub const _SECIMP = @compileError("unable to translate macro: undefined identifier `dllimport`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/stdlib.h:22:9
pub const _countof = @compileError("unable to translate C expr: expected ')' instead got '['"); // D:\DevTools\zig\lib\libc\include\any-windows-any/stdlib.h:377:9
pub const _STATIC_ASSERT = @compileError("unable to translate macro: undefined identifier `__static_assert_t`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/malloc.h:27:9
pub const _alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/malloc.h:93:9
pub const alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/malloc.h:159:9
pub const __mingw_types_compatible_p = @compileError("unable to translate macro: undefined identifier `__builtin_types_compatible_p`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:97:9
pub const __mingw_choose_expr = @compileError("unable to translate macro: undefined identifier `__builtin_choose_expr`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:105:9
pub const HUGE_VAL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_val`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:156:9
pub const HUGE_VALL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_vall`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:350:9
pub const fpclassify = @compileError("unable to translate macro: undefined identifier `__typeof__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:492:9
pub const isnan = @compileError("unable to translate macro: undefined identifier `__typeof__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:586:9
pub const signbit = @compileError("unable to translate macro: undefined identifier `__typeof__`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:646:9
pub const isgreater = @compileError("unable to translate macro: undefined identifier `__builtin_isgreater`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:1144:9
pub const isgreaterequal = @compileError("unable to translate macro: undefined identifier `__builtin_isgreaterequal`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:1145:9
pub const isless = @compileError("unable to translate macro: undefined identifier `__builtin_isless`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:1146:9
pub const islessequal = @compileError("unable to translate macro: undefined identifier `__builtin_islessequal`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:1147:9
pub const islessgreater = @compileError("unable to translate macro: undefined identifier `__builtin_islessgreater`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:1148:9
pub const isunordered = @compileError("unable to translate macro: undefined identifier `__builtin_isunordered`"); // D:\DevTools\zig\lib\libc\include\any-windows-any/math.h:1149:9
pub const CP_EXPORT = @compileError("unable to translate macro: undefined identifier `dllexport`"); // src\deps\chipmunk\c\include\chipmunk\chipmunk.h:39:10
pub const cpAssertSoft = @compileError("unable to translate C expr: expected ')' instead got '...'"); // src\deps\chipmunk\c\include\chipmunk\chipmunk.h:53:10
pub const cpAssertWarn = @compileError("unable to translate C expr: expected ')' instead got '...'"); // src\deps\chipmunk\c\include\chipmunk\chipmunk.h:54:10
pub const cpAssertHard = @compileError("unable to translate C expr: expected ')' instead got '...'"); // src\deps\chipmunk\c\include\chipmunk\chipmunk.h:58:9
pub const FLT_ROUNDS = @compileError("unable to translate macro: undefined identifier `__builtin_flt_rounds`"); // D:\DevTools\zig\lib\include/float.h:88:9
pub const CP_ARBITER_GET_SHAPES = @compileError("unable to translate C expr: unexpected token ';'"); // src\deps\chipmunk\c\include\chipmunk/cpArbiter.h:70:9
pub const CP_ARBITER_GET_BODIES = @compileError("unable to translate C expr: unexpected token ';'"); // src\deps\chipmunk\c\include\chipmunk/cpArbiter.h:78:9
pub const CP_CONVEX_HULL = @compileError("unable to translate C expr: unexpected token '='"); // src\deps\chipmunk\c\include\chipmunk\chipmunk.h:177:9
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 14);
pub const __clang_minor__ = @as(c_int, 0);
pub const __clang_patchlevel__ = @as(c_int, 6);
pub const __clang_version__ = "14.0.6 (git@github.com:ziglang/zig-bootstrap.git fd29a724c18f51e7bce66db814bcaf4f0296ae47)";
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
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 14.0.6 (git@github.com:ziglang/zig-bootstrap.git fd29a724c18f51e7bce66db814bcaf4f0296ae47)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __SEH__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-16";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 32);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @as(c_int, 128);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @as(c_long, 2147483647);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 16);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 16);
pub const __INTMAX_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 4);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 2);
pub const __SIZEOF_WINT_T__ = @as(c_int, 2);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_longlong;
pub const __INTMAX_FMTd__ = "lld";
pub const __INTMAX_FMTi__ = "lli";
pub const __UINTMAX_TYPE__ = c_ulonglong;
pub const __UINTMAX_FMTo__ = "llo";
pub const __UINTMAX_FMTu__ = "llu";
pub const __UINTMAX_FMTx__ = "llx";
pub const __UINTMAX_FMTX__ = "llX";
pub const __PTRDIFF_TYPE__ = c_longlong;
pub const __PTRDIFF_FMTd__ = "lld";
pub const __PTRDIFF_FMTi__ = "lli";
pub const __INTPTR_TYPE__ = c_longlong;
pub const __INTPTR_FMTd__ = "lld";
pub const __INTPTR_FMTi__ = "lli";
pub const __SIZE_TYPE__ = c_ulonglong;
pub const __SIZE_FMTo__ = "llo";
pub const __SIZE_FMTu__ = "llu";
pub const __SIZE_FMTx__ = "llx";
pub const __SIZE_FMTX__ = "llX";
pub const __WCHAR_TYPE__ = c_ushort;
pub const __WINT_TYPE__ = c_ushort;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulonglong;
pub const __UINTPTR_FMTo__ = "llo";
pub const __UINTPTR_FMTu__ = "llu";
pub const __UINTPTR_FMTx__ = "llx";
pub const __UINTPTR_FMTX__ = "llX";
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
pub const __DBL_DENORM_MIN__ = 4.9406564584124654e-324;
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = 2.2204460492503131e-16;
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = 1.7976931348623157e+308;
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = 2.2250738585072014e-308;
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
pub const __WCHAR_UNSIGNED__ = @as(c_int, 1);
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
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
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
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
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
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "lld";
pub const __INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_LEAST64_FMTo__ = "llo";
pub const __UINT_LEAST64_FMTu__ = "llu";
pub const __UINT_LEAST64_FMTx__ = "llx";
pub const __UINT_LEAST64_FMTX__ = "llX";
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
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "lld";
pub const __INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_FAST64_FMTo__ = "llo";
pub const __UINT_FAST64_FMTu__ = "llu";
pub const __UINT_FAST64_FMTx__ = "llx";
pub const __UINT_FAST64_FMTX__ = "llX";
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
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
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
pub const _WIN32 = @as(c_int, 1);
pub const _WIN64 = @as(c_int, 1);
pub const WIN32 = @as(c_int, 1);
pub const __WIN32 = @as(c_int, 1);
pub const __WIN32__ = @as(c_int, 1);
pub const WINNT = @as(c_int, 1);
pub const __WINNT = @as(c_int, 1);
pub const __WINNT__ = @as(c_int, 1);
pub const WIN64 = @as(c_int, 1);
pub const __WIN64 = @as(c_int, 1);
pub const __WIN64__ = @as(c_int, 1);
pub const __MINGW64__ = @as(c_int, 1);
pub const __MSVCRT__ = @as(c_int, 1);
pub const __MINGW32__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const _DEBUG = @as(c_int, 1);
pub const CP_USE_DOUBLES = @as(c_int, 0);
pub const CHIPMUNK_H = "";
pub const _INC_STDLIB = "";
pub const _INC_CORECRT = "";
pub const _INC__MINGW_H = "";
pub const _INC_CRTDEFS_MACRO = "";
pub inline fn __MINGW64_STRINGIFY(x: anytype) @TypeOf(__STRINGIFY(x)) {
    return __STRINGIFY(x);
}
pub const __MINGW64_VERSION_MAJOR = @as(c_int, 9);
pub const __MINGW64_VERSION_MINOR = @as(c_int, 0);
pub const __MINGW64_VERSION_BUGFIX = @as(c_int, 0);
pub const __MINGW64_VERSION_RC = @as(c_int, 0);
pub const __MINGW64_VERSION_STATE = "alpha";
pub const __MINGW32_MAJOR_VERSION = @as(c_int, 3);
pub const __MINGW32_MINOR_VERSION = @as(c_int, 11);
pub const _M_AMD64 = @as(c_int, 100);
pub const _M_X64 = @as(c_int, 100);
pub const @"_" = @as(c_int, 1);
pub const __MINGW_USE_UNDERSCORE_PREFIX = @as(c_int, 0);
pub inline fn __MINGW_USYMBOL(sym: anytype) @TypeOf(sym) {
    return sym;
}
pub const __C89_NAMELESS = __MINGW_EXTENSION;
pub const __C89_NAMELESSSTRUCTNAME = "";
pub const __C89_NAMELESSSTRUCTNAME1 = "";
pub const __C89_NAMELESSSTRUCTNAME2 = "";
pub const __C89_NAMELESSSTRUCTNAME3 = "";
pub const __C89_NAMELESSSTRUCTNAME4 = "";
pub const __C89_NAMELESSSTRUCTNAME5 = "";
pub const __C89_NAMELESSUNIONNAME = "";
pub const __C89_NAMELESSUNIONNAME1 = "";
pub const __C89_NAMELESSUNIONNAME2 = "";
pub const __C89_NAMELESSUNIONNAME3 = "";
pub const __C89_NAMELESSUNIONNAME4 = "";
pub const __C89_NAMELESSUNIONNAME5 = "";
pub const __C89_NAMELESSUNIONNAME6 = "";
pub const __C89_NAMELESSUNIONNAME7 = "";
pub const __C89_NAMELESSUNIONNAME8 = "";
pub const __GNU_EXTENSION = __MINGW_EXTENSION;
pub const __MINGW_HAVE_ANSI_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_ANSI_C99_SCANF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_SCANF = @as(c_int, 1);
pub const __MSABI_LONG = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const __MINGW_GCC_VERSION = ((__GNUC__ * @as(c_int, 10000)) + (__GNUC_MINOR__ * @as(c_int, 100))) + __GNUC_PATCHLEVEL__;
pub inline fn __MINGW_GNUC_PREREQ(major: anytype, minor: anytype) @TypeOf((__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor))) {
    return (__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor));
}
pub inline fn __MINGW_MSC_PREREQ(major: anytype, minor: anytype) @TypeOf(@as(c_int, 0)) {
    _ = major;
    _ = minor;
    return @as(c_int, 0);
}
pub const __MINGW_SEC_WARN_STR = "This function or variable may be unsafe, use _CRT_SECURE_NO_WARNINGS to disable deprecation";
pub const __MINGW_MSVC2005_DEPREC_STR = "This POSIX function is deprecated beginning in Visual C++ 2005, use _CRT_NONSTDC_NO_DEPRECATE to disable deprecation";
pub const __MINGW_ATTRIB_DEPRECATED_MSVC2005 = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_MSVC2005_DEPREC_STR);
pub const __MINGW_ATTRIB_DEPRECATED_SEC_WARN = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_SEC_WARN_STR);
pub const __mingw_static_ovr = __mingw_ovr;
pub const __mingw_attribute_artificial = "";
pub const __MINGW_FORTIFY_LEVEL = @as(c_int, 0);
pub const __mingw_bos_ovr = __mingw_ovr;
pub const __MINGW_FORTIFY_VA_ARG = @as(c_int, 0);
pub const _INC_MINGW_SECAPI = "";
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES_MEMORY = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_COUNT = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY = @as(c_int, 0);
pub const __LONG32 = c_long;
pub const __USE_CRTIMP = @as(c_int, 1);
pub const __DECLSPEC_SUPPORTED = "";
pub const USE___UUIDOF = @as(c_int, 0);
pub const __CRT__NO_INLINE = @as(c_int, 1);
pub const __MINGW_ATTRIB_NO_OPTIMIZE = "";
pub const __MSVCRT_VERSION__ = @as(c_int, 0x700);
pub const _WIN32_WINNT = @as(c_int, 0x0603);
pub const _INT128_DEFINED = "";
pub const __int8 = u8;
pub const __int16 = c_short;
pub const __int32 = c_int;
pub const __int64 = c_longlong;
pub const __ptr32 = "";
pub const __ptr64 = "";
pub const __unaligned = "";
pub const __w64 = "";
pub const __nothrow = "";
pub const _INC_VADEFS = "";
pub const MINGW_SDK_INIT = "";
pub const MINGW_HAS_SECURE_API = @as(c_int, 1);
pub const __STDC_SECURE_LIB__ = @as(c_long, 200411);
pub const __GOT_SECURE_LIB__ = __STDC_SECURE_LIB__;
pub const MINGW_DDK_H = "";
pub const MINGW_HAS_DDK_H = @as(c_int, 1);
pub const _CRT_PACKING = @as(c_int, 8);
pub const __GNUC_VA_LIST = "";
pub const _VA_LIST_DEFINED = "";
pub inline fn _ADDRESSOF(v: anytype) @TypeOf(&v) {
    return &v;
}
pub inline fn _CRT_STRINGIZE(_Value: anytype) @TypeOf(__CRT_STRINGIZE(_Value)) {
    return __CRT_STRINGIZE(_Value);
}
pub inline fn _CRT_WIDE(_String: anytype) @TypeOf(__CRT_WIDE(_String)) {
    return __CRT_WIDE(_String);
}
pub const _W64 = "";
pub const _CRTIMP_NOIA64 = _CRTIMP;
pub const _CRTIMP2 = _CRTIMP;
pub const _CRTIMP_ALTERNATIVE = _CRTIMP;
pub const _CRT_ALTERNATIVE_IMPORTED = "";
pub const _MRTIMP2 = _CRTIMP;
pub const _DLL = "";
pub const _MT = "";
pub const _MCRTIMP = _CRTIMP;
pub const _CRTIMP_PURE = _CRTIMP;
pub const _PGLOBAL = "";
pub const _AGLOBAL = "";
pub const _SECURECRT_FILL_BUFFER_PATTERN = @as(c_int, 0xFD);
pub const _CRT_MANAGED_HEAP_DEPRECATE = "";
pub const _CONST_RETURN = "";
pub const UNALIGNED = __unaligned;
pub const __CRTDECL = __cdecl;
pub const _ARGMAX = @as(c_int, 100);
pub const _TRUNCATE = @import("std").zig.c_translation.cast(usize, -@as(c_int, 1));
pub inline fn _CRT_UNUSED(x: anytype) anyopaque {
    return @import("std").zig.c_translation.cast(anyopaque, x);
}
pub const __USE_MINGW_ANSI_STDIO = @as(c_int, 1);
pub const __ANONYMOUS_DEFINED = "";
pub const _ANONYMOUS_UNION = __MINGW_EXTENSION;
pub const _ANONYMOUS_STRUCT = __MINGW_EXTENSION;
pub const DUMMYUNIONNAME = "";
pub const DUMMYUNIONNAME1 = "";
pub const DUMMYUNIONNAME2 = "";
pub const DUMMYUNIONNAME3 = "";
pub const DUMMYUNIONNAME4 = "";
pub const DUMMYUNIONNAME5 = "";
pub const DUMMYUNIONNAME6 = "";
pub const DUMMYUNIONNAME7 = "";
pub const DUMMYUNIONNAME8 = "";
pub const DUMMYUNIONNAME9 = "";
pub const DUMMYSTRUCTNAME = "";
pub const DUMMYSTRUCTNAME1 = "";
pub const DUMMYSTRUCTNAME2 = "";
pub const DUMMYSTRUCTNAME3 = "";
pub const DUMMYSTRUCTNAME4 = "";
pub const DUMMYSTRUCTNAME5 = "";
pub const __MINGW_DEBUGBREAK_IMPL = !(__has_builtin(__debugbreak) != 0);
pub const _CRTNOALIAS = "";
pub const _CRTRESTRICT = "";
pub const _SIZE_T_DEFINED = "";
pub const _SSIZE_T_DEFINED = "";
pub const _RSIZE_T_DEFINED = "";
pub const _INTPTR_T_DEFINED = "";
pub const __intptr_t_defined = "";
pub const _UINTPTR_T_DEFINED = "";
pub const __uintptr_t_defined = "";
pub const _PTRDIFF_T_DEFINED = "";
pub const _PTRDIFF_T_ = "";
pub const _WCHAR_T_DEFINED = "";
pub const _WCTYPE_T_DEFINED = "";
pub const _WINT_T = "";
pub const _ERRCODE_DEFINED = "";
pub const _TIME32_T_DEFINED = "";
pub const _TIME64_T_DEFINED = "";
pub const _TIME_T_DEFINED = "";
pub const _TAGLC_ID_DEFINED = "";
pub const _THREADLOCALEINFO = "";
pub const _CRT_USE_WINAPI_FAMILY_DESKTOP_APP = "";
pub const _INC_CORECRT_WSTDLIB = "";
pub const __CLANG_LIMITS_H = "";
pub const _GCC_LIMITS_H_ = "";
pub const _INC_CRTDEFS = "";
pub const _INC_LIMITS = "";
pub const PATH_MAX = @as(c_int, 260);
pub const CHAR_BIT = @as(c_int, 8);
pub const SCHAR_MIN = -@as(c_int, 128);
pub const SCHAR_MAX = @as(c_int, 127);
pub const UCHAR_MAX = @as(c_int, 0xff);
pub const CHAR_MIN = SCHAR_MIN;
pub const CHAR_MAX = SCHAR_MAX;
pub const MB_LEN_MAX = @as(c_int, 5);
pub const SHRT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 32768, .decimal);
pub const SHRT_MAX = @as(c_int, 32767);
pub const USHRT_MAX = @as(c_uint, 0xffff);
pub const INT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const UINT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hexadecimal);
pub const LONG_MIN = -@as(c_long, 2147483647) - @as(c_int, 1);
pub const LONG_MAX = @as(c_long, 2147483647);
pub const ULONG_MAX = @as(c_ulong, 0xffffffff);
pub const LLONG_MAX = @as(c_longlong, 9223372036854775807);
pub const LLONG_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const ULLONG_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const _I8_MIN = -@as(c_int, 127) - @as(c_int, 1);
pub const _I8_MAX = @as(c_int, 127);
pub const _UI8_MAX = @as(c_uint, 0xff);
pub const _I16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const _I16_MAX = @as(c_int, 32767);
pub const _UI16_MAX = @as(c_uint, 0xffff);
pub const _I32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const _I32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _UI32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hexadecimal);
pub const LONG_LONG_MAX = @as(c_longlong, 9223372036854775807);
pub const LONG_LONG_MIN = -LONG_LONG_MAX - @as(c_int, 1);
pub const ULONG_LONG_MAX = (@as(c_ulonglong, 2) * LONG_LONG_MAX) + @as(c_ulonglong, 1);
pub const _I64_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const _I64_MAX = @as(c_longlong, 9223372036854775807);
pub const _UI64_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const SIZE_MAX = _UI64_MAX;
pub const SSIZE_MAX = _I64_MAX;
pub const __USE_MINGW_STRTOX = @as(c_int, 1);
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const EXIT_FAILURE = @as(c_int, 1);
pub const _ONEXIT_T_DEFINED = "";
pub const onexit_t = _onexit_t;
pub const _DIV_T_DEFINED = "";
pub const _CRT_DOUBLE_DEC = "";
pub inline fn _PTR_LD(x: anytype) [*c]u8 {
    return @import("std").zig.c_translation.cast([*c]u8, &x.*.ld);
}
pub const RAND_MAX = @as(c_int, 0x7fff);
pub const MB_CUR_MAX = ___mb_cur_max_func();
pub const __mb_cur_max = ___mb_cur_max_func();
pub inline fn __max(a: anytype, b: anytype) @TypeOf(if (a > b) a else b) {
    return if (a > b) a else b;
}
pub inline fn __min(a: anytype, b: anytype) @TypeOf(if (a < b) a else b) {
    return if (a < b) a else b;
}
pub const _MAX_PATH = @as(c_int, 260);
pub const _MAX_DRIVE = @as(c_int, 3);
pub const _MAX_DIR = @as(c_int, 256);
pub const _MAX_FNAME = @as(c_int, 256);
pub const _MAX_EXT = @as(c_int, 256);
pub const _OUT_TO_DEFAULT = @as(c_int, 0);
pub const _OUT_TO_STDERR = @as(c_int, 1);
pub const _OUT_TO_MSGBOX = @as(c_int, 2);
pub const _REPORT_ERRMODE = @as(c_int, 3);
pub const _WRITE_ABORT_MSG = @as(c_int, 0x1);
pub const _CALL_REPORTFAULT = @as(c_int, 0x2);
pub const _MAX_ENV = @as(c_int, 32767);
pub const _CRT_ERRNO_DEFINED = "";
pub const errno = _errno().*;
pub const _doserrno = __doserrno().*;
pub const _fmode = __p__fmode().*;
pub const __argc = __MINGW_IMP_SYMBOL(__argc).*;
pub const __argv = __p___argv().*;
pub const __wargv = __MINGW_IMP_SYMBOL(__wargv).*;
pub const _environ = __MINGW_IMP_SYMBOL(_environ).*;
pub const _wenviron = __MINGW_IMP_SYMBOL(_wenviron).*;
pub const _pgmptr = __MINGW_IMP_SYMBOL(_pgmptr).*;
pub const _wpgmptr = __MINGW_IMP_SYMBOL(_wpgmptr).*;
pub const _osplatform = __MINGW_IMP_SYMBOL(_osplatform).*;
pub const _osver = __MINGW_IMP_SYMBOL(_osver).*;
pub const _winver = __MINGW_IMP_SYMBOL(_winver).*;
pub const _winmajor = __MINGW_IMP_SYMBOL(_winmajor).*;
pub const _winminor = __MINGW_IMP_SYMBOL(_winminor).*;
pub const _CRT_TERMINATE_DEFINED = "";
pub const _CRT_ABS_DEFINED = "";
pub const _CRT_ATOF_DEFINED = "";
pub const _CRT_ALGO_DEFINED = "";
pub const _CRT_SYSTEM_DEFINED = "";
pub const _CRT_ALLOCATION_DEFINED = "";
pub const _WSTDLIB_DEFINED = "";
pub const _CRT_WSYSTEM_DEFINED = "";
pub const _CVTBUFSIZE = @as(c_int, 309) + @as(c_int, 40);
pub const _CRT_PERROR_DEFINED = "";
pub const _WSTDLIBP_DEFINED = "";
pub const _CRT_WPERROR_DEFINED = "";
pub const sys_errlist = _sys_errlist;
pub const sys_nerr = _sys_nerr;
pub const environ = _environ;
pub const _CRT_SWAB_DEFINED = "";
pub const _INC_STDLIB_S = "";
pub const _QSORT_S_DEFINED = "";
pub const _MALLOC_H_ = "";
pub const _HEAP_MAXREQ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFFFFFFFFFFFFE0, .hexadecimal);
pub const _HEAPEMPTY = -@as(c_int, 1);
pub const _HEAPOK = -@as(c_int, 2);
pub const _HEAPBADBEGIN = -@as(c_int, 3);
pub const _HEAPBADNODE = -@as(c_int, 4);
pub const _HEAPEND = -@as(c_int, 5);
pub const _HEAPBADPTR = -@as(c_int, 6);
pub const _FREEENTRY = @as(c_int, 0);
pub const _USEDENTRY = @as(c_int, 1);
pub const _HEAPINFO_DEFINED = "";
pub const __MM_MALLOC_H = "";
pub const _MAX_WAIT_MALLOC_CRT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60000, .decimal);
pub const _ALLOCA_S_THRESHOLD = @as(c_int, 1024);
pub const _ALLOCA_S_STACK_MARKER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xCCCC, .hexadecimal);
pub const _ALLOCA_S_HEAP_MARKER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xDDDD, .hexadecimal);
pub const _ALLOCA_S_MARKER_SIZE = @as(c_int, 16);
pub inline fn _malloca(size: anytype) @TypeOf(if ((size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER)) {
    return if ((size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER);
}
pub const _FREEA_INLINE = "";
pub const _MATH_H_ = "";
pub const _DOMAIN = @as(c_int, 1);
pub const _SING = @as(c_int, 2);
pub const _OVERFLOW = @as(c_int, 3);
pub const _UNDERFLOW = @as(c_int, 4);
pub const _TLOSS = @as(c_int, 5);
pub const _PLOSS = @as(c_int, 6);
pub const DOMAIN = _DOMAIN;
pub const SING = _SING;
pub const OVERFLOW = _OVERFLOW;
pub const UNDERFLOW = _UNDERFLOW;
pub const TLOSS = _TLOSS;
pub const PLOSS = _PLOSS;
pub const M_E = 2.7182818284590452354;
pub const M_LOG2E = 1.4426950408889634074;
pub const M_LOG10E = 0.43429448190325182765;
pub const M_LN2 = 0.69314718055994530942;
pub const M_LN10 = 2.30258509299404568402;
pub const M_PI = 3.14159265358979323846;
pub const M_PI_2 = 1.57079632679489661923;
pub const M_PI_4 = 0.78539816339744830962;
pub const M_1_PI = 0.31830988618379067154;
pub const M_2_PI = 0.63661977236758134308;
pub const M_2_SQRTPI = 1.12837916709551257390;
pub const M_SQRT2 = 1.41421356237309504880;
pub const M_SQRT1_2 = 0.70710678118654752440;
pub const __MINGW_FPCLASS_DEFINED = @as(c_int, 1);
pub const _FPCLASS_SNAN = @as(c_int, 0x0001);
pub const _FPCLASS_QNAN = @as(c_int, 0x0002);
pub const _FPCLASS_NINF = @as(c_int, 0x0004);
pub const _FPCLASS_NN = @as(c_int, 0x0008);
pub const _FPCLASS_ND = @as(c_int, 0x0010);
pub const _FPCLASS_NZ = @as(c_int, 0x0020);
pub const _FPCLASS_PZ = @as(c_int, 0x0040);
pub const _FPCLASS_PD = @as(c_int, 0x0080);
pub const _FPCLASS_PN = @as(c_int, 0x0100);
pub const _FPCLASS_PINF = @as(c_int, 0x0200);
pub const __MINGW_SOFTMATH = "";
pub const _HUGE = __MINGW_IMP_SYMBOL(_HUGE).*;
pub const _EXCEPTION_DEFINED = "";
pub const EDOM = @as(c_int, 33);
pub const ERANGE = @as(c_int, 34);
pub const _COMPLEX_DEFINED = "";
pub const _CRT_MATHERR_DEFINED = "";
pub const _SIGN_DEFINED = "";
pub const FP_SNAN = _FPCLASS_SNAN;
pub const FP_QNAN = _FPCLASS_QNAN;
pub const FP_NINF = _FPCLASS_NINF;
pub const FP_PINF = _FPCLASS_PINF;
pub const FP_NDENORM = _FPCLASS_ND;
pub const FP_PDENORM = _FPCLASS_PD;
pub const FP_NZERO = _FPCLASS_NZ;
pub const FP_PZERO = _FPCLASS_PZ;
pub const FP_NNORM = _FPCLASS_NN;
pub const FP_PNORM = _FPCLASS_PN;
pub const HUGE_VALF = __builtin_huge_valf();
pub const INFINITY = __builtin_inff();
pub const NAN = __builtin_nanf("");
pub const FP_NAN = @as(c_int, 0x0100);
pub const FP_NORMAL = @as(c_int, 0x0400);
pub const FP_INFINITE = FP_NAN | FP_NORMAL;
pub const FP_ZERO = @as(c_int, 0x4000);
pub const FP_SUBNORMAL = FP_NORMAL | FP_ZERO;
pub inline fn __dfp_expansion(__call: anytype, __fin: anytype, x: anytype) @TypeOf(__fin) {
    _ = __call;
    _ = x;
    return __fin;
}
pub inline fn isfinite(x: anytype) @TypeOf((fpclassify(x) & FP_NAN) == @as(c_int, 0)) {
    return (fpclassify(x) & FP_NAN) == @as(c_int, 0);
}
pub inline fn isinf(x: anytype) @TypeOf(fpclassify(x) == FP_INFINITE) {
    return fpclassify(x) == FP_INFINITE;
}
pub inline fn isnormal(x: anytype) @TypeOf(fpclassify(x) == FP_NORMAL) {
    return fpclassify(x) == FP_NORMAL;
}
pub const FP_ILOGB0 = @import("std").zig.c_translation.cast(c_int, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hexadecimal));
pub const FP_ILOGBNAN = @import("std").zig.c_translation.cast(c_int, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hexadecimal));
pub inline fn _nan() @TypeOf(nan("")) {
    return nan("");
}
pub inline fn _nanf() @TypeOf(nanf("")) {
    return nanf("");
}
pub inline fn _nanl() @TypeOf(nanl("")) {
    return nanl("");
}
pub const _copysignl = copysignl;
pub const _hypotl = hypotl;
pub const matherr = _matherr;
pub const HUGE = _HUGE;
pub const CHIPMUNK_TYPES_H = "";
pub const __CLANG_STDINT_H = "";
pub const _STDINT_H = "";
pub const __need_wint_t = "";
pub const __need_wchar_t = "";
pub const _WCHAR_T = "";
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 32768, .decimal);
pub const INT32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT64_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = @as(c_longlong, 9223372036854775807);
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hexadecimal);
pub const UINT64_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const INT_LEAST8_MIN = INT8_MIN;
pub const INT_LEAST16_MIN = INT16_MIN;
pub const INT_LEAST32_MIN = INT32_MIN;
pub const INT_LEAST64_MIN = INT64_MIN;
pub const INT_LEAST8_MAX = INT8_MAX;
pub const INT_LEAST16_MAX = INT16_MAX;
pub const INT_LEAST32_MAX = INT32_MAX;
pub const INT_LEAST64_MAX = INT64_MAX;
pub const UINT_LEAST8_MAX = UINT8_MAX;
pub const UINT_LEAST16_MAX = UINT16_MAX;
pub const UINT_LEAST32_MAX = UINT32_MAX;
pub const UINT_LEAST64_MAX = UINT64_MAX;
pub const INT_FAST8_MIN = INT8_MIN;
pub const INT_FAST16_MIN = INT16_MIN;
pub const INT_FAST32_MIN = INT32_MIN;
pub const INT_FAST64_MIN = INT64_MIN;
pub const INT_FAST8_MAX = INT8_MAX;
pub const INT_FAST16_MAX = INT16_MAX;
pub const INT_FAST32_MAX = INT32_MAX;
pub const INT_FAST64_MAX = INT64_MAX;
pub const UINT_FAST8_MAX = UINT8_MAX;
pub const UINT_FAST16_MAX = UINT16_MAX;
pub const UINT_FAST32_MAX = UINT32_MAX;
pub const UINT_FAST64_MAX = UINT64_MAX;
pub const INTPTR_MIN = INT64_MIN;
pub const INTPTR_MAX = INT64_MAX;
pub const UINTPTR_MAX = UINT64_MAX;
pub const INTMAX_MIN = INT64_MIN;
pub const INTMAX_MAX = INT64_MAX;
pub const UINTMAX_MAX = UINT64_MAX;
pub const PTRDIFF_MIN = INT64_MIN;
pub const PTRDIFF_MAX = INT64_MAX;
pub const SIG_ATOMIC_MIN = INT32_MIN;
pub const SIG_ATOMIC_MAX = INT32_MAX;
pub const WCHAR_MIN = @as(c_uint, 0);
pub const WCHAR_MAX = @as(c_uint, 0xffff);
pub const WINT_MIN = @as(c_uint, 0);
pub const WINT_MAX = @as(c_uint, 0xffff);
pub inline fn INT8_C(val: anytype) @TypeOf((INT_LEAST8_MAX - INT_LEAST8_MAX) + val) {
    return (INT_LEAST8_MAX - INT_LEAST8_MAX) + val;
}
pub inline fn INT16_C(val: anytype) @TypeOf((INT_LEAST16_MAX - INT_LEAST16_MAX) + val) {
    return (INT_LEAST16_MAX - INT_LEAST16_MAX) + val;
}
pub inline fn INT32_C(val: anytype) @TypeOf((INT_LEAST32_MAX - INT_LEAST32_MAX) + val) {
    return (INT_LEAST32_MAX - INT_LEAST32_MAX) + val;
}
pub const INT64_C = @import("std").zig.c_translation.Macros.LL_SUFFIX;
pub inline fn UINT8_C(val: anytype) @TypeOf(val) {
    return val;
}
pub inline fn UINT16_C(val: anytype) @TypeOf(val) {
    return val;
}
pub const UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const UINT64_C = @import("std").zig.c_translation.Macros.ULL_SUFFIX;
pub const INTMAX_C = @import("std").zig.c_translation.Macros.LL_SUFFIX;
pub const UINTMAX_C = @import("std").zig.c_translation.Macros.ULL_SUFFIX;
pub const __CLANG_FLOAT_H = "";
pub const _MINGW_FLOAT_H_ = "";
pub const _MCW_DN = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x03000000, .hexadecimal);
pub const _MCW_EM = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x0008001F, .hexadecimal);
pub const _MCW_IC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00040000, .hexadecimal);
pub const _MCW_RC = @as(c_int, 0x00000300);
pub const _MCW_PC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00030000, .hexadecimal);
pub const FLT_MANT_DIG = __FLT_MANT_DIG__;
pub const DBL_MANT_DIG = __DBL_MANT_DIG__;
pub const LDBL_MANT_DIG = __LDBL_MANT_DIG__;
pub const FLT_EVAL_METHOD = __FLT_EVAL_METHOD__;
pub const _DN_SAVE = @as(c_int, 0x00000000);
pub const _DN_FLUSH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x01000000, .hexadecimal);
pub const _EM_INVALID = @as(c_int, 0x00000010);
pub const _EM_DENORMAL = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hexadecimal);
pub const _EM_ZERODIVIDE = @as(c_int, 0x00000008);
pub const _EM_OVERFLOW = @as(c_int, 0x00000004);
pub const _EM_UNDERFLOW = @as(c_int, 0x00000002);
pub const _EM_INEXACT = @as(c_int, 0x00000001);
pub const _IC_AFFINE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00040000, .hexadecimal);
pub const _IC_PROJECTIVE = @as(c_int, 0x00000000);
pub const _RC_CHOP = @as(c_int, 0x00000300);
pub const _RC_UP = @as(c_int, 0x00000200);
pub const _RC_DOWN = @as(c_int, 0x00000100);
pub const _RC_NEAR = @as(c_int, 0x00000000);
pub const _PC_24 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00020000, .hexadecimal);
pub const _PC_53 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00010000, .hexadecimal);
pub const _PC_64 = @as(c_int, 0x00000000);
pub const _SW_UNEMULATED = @as(c_int, 0x0040);
pub const _SW_SQRTNEG = @as(c_int, 0x0080);
pub const _SW_STACKOVERFLOW = @as(c_int, 0x0200);
pub const _SW_STACKUNDERFLOW = @as(c_int, 0x0400);
pub const _FPE_INVALID = @as(c_int, 0x81);
pub const _FPE_DENORMAL = @as(c_int, 0x82);
pub const _FPE_ZERODIVIDE = @as(c_int, 0x83);
pub const _FPE_OVERFLOW = @as(c_int, 0x84);
pub const _FPE_UNDERFLOW = @as(c_int, 0x85);
pub const _FPE_INEXACT = @as(c_int, 0x86);
pub const _FPE_UNEMULATED = @as(c_int, 0x87);
pub const _FPE_SQRTNEG = @as(c_int, 0x88);
pub const _FPE_STACKOVERFLOW = @as(c_int, 0x8a);
pub const _FPE_STACKUNDERFLOW = @as(c_int, 0x8b);
pub const _FPE_EXPLICITGEN = @as(c_int, 0x8c);
pub const CW_DEFAULT = _CW_DEFAULT;
pub const MCW_PC = _MCW_PC;
pub const PC_24 = _PC_24;
pub const PC_53 = _PC_53;
pub const PC_64 = _PC_64;
pub const _CW_DEFAULT = (((((_RC_NEAR + _EM_INVALID) + _EM_ZERODIVIDE) + _EM_OVERFLOW) + _EM_UNDERFLOW) + _EM_INEXACT) + _EM_DENORMAL;
pub const _clear87 = _clearfp;
pub const _status87 = _statusfp;
pub const _fpecode = __fpecode().*;
pub const FLT_RADIX = __FLT_RADIX__;
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
pub const CP_PI = @import("std").zig.c_translation.cast(cpFloat, 3.14159265358979323846264338327950288);
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
pub const tagLC_ID = struct_tagLC_ID;
pub const lconv = struct_lconv;
pub const __lc_time_data = struct___lc_time_data;
pub const threadlocaleinfostruct = struct_threadlocaleinfostruct;
pub const threadmbcinfostruct = struct_threadmbcinfostruct;
pub const localeinfo_struct = struct_localeinfo_struct;
pub const _div_t = struct__div_t;
pub const _ldiv_t = struct__ldiv_t;
pub const _heapinfo = struct__heapinfo;
pub const _exception = struct__exception;
pub const _complex = struct__complex;
