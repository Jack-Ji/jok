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
pub const va_list = __gnuc_va_list; // D:\DevTools\zig\lib\libc\include\any-windows-any\_mingw.h:584:3: warning: TODO implement translation of stmt class GCCAsmStmtClass
// D:\DevTools\zig\lib\libc\include\any-windows-any\_mingw.h:581:36: warning: unable to translate function, demoted to extern
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
pub const _onexit_t = ?fn () callconv(.C) c_int;
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
pub const _purecall_handler = ?fn () callconv(.C) void;
pub extern fn _set_purecall_handler(_Handler: _purecall_handler) _purecall_handler;
pub extern fn _get_purecall_handler() _purecall_handler;
pub const _invalid_parameter_handler = ?fn ([*c]const wchar_t, [*c]const wchar_t, [*c]const wchar_t, c_uint, usize) callconv(.C) void;
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
pub fn _Exit(arg_status: c_int) callconv(.C) noreturn {
    var status = arg_status;
    _exit(status);
}
pub extern fn abort() noreturn;
pub extern fn _set_abort_behavior(_Flags: c_uint, _Mask: c_uint) c_uint;
pub extern fn abs(_X: c_int) c_int;
pub extern fn labs(_X: c_long) c_long; // D:\DevTools\zig\lib\libc\include\any-windows-any\stdlib.h:421:12: warning: TODO implement function '__builtin_llabs' in std.zig.c_builtins
// D:\DevTools\zig\lib\libc\include\any-windows-any\stdlib.h:420:41: warning: unable to translate function, demoted to extern
pub extern fn _abs64(arg_x: c_longlong) c_longlong;
pub extern fn atexit(?fn () callconv(.C) void) c_int;
pub extern fn atof(_String: [*c]const u8) f64;
pub extern fn _atof_l(_String: [*c]const u8, _Locale: _locale_t) f64;
pub extern fn atoi(_Str: [*c]const u8) c_int;
pub extern fn _atoi_l(_Str: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn atol(_Str: [*c]const u8) c_long;
pub extern fn _atol_l(_Str: [*c]const u8, _Locale: _locale_t) c_long;
pub extern fn bsearch(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) ?*anyopaque;
pub extern fn qsort(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) void;
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
pub const _beep = @compileError("unable to resolve function type clang.TypeClass.MacroQualified"); // D:\DevTools\zig\lib\libc\include\any-windows-any\stdlib.h:681:24
pub const _seterrormode = @compileError("unable to resolve function type clang.TypeClass.MacroQualified"); // D:\DevTools\zig\lib\libc\include\any-windows-any\stdlib.h:683:24
pub const _sleep = @compileError("unable to resolve function type clang.TypeClass.MacroQualified"); // D:\DevTools\zig\lib\libc\include\any-windows-any\stdlib.h:684:24
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
pub fn llabs(arg__j: c_longlong) callconv(.C) c_longlong {
    var _j = arg__j;
    return if (_j >= @bitCast(c_longlong, @as(c_longlong, @as(c_int, 0)))) _j else -_j;
}
pub extern fn strtoll([*c]const u8, [*c][*c]u8, c_int) c_longlong;
pub extern fn strtoull([*c]const u8, [*c][*c]u8, c_int) c_ulonglong;
pub fn atoll(arg__c: [*c]const u8) callconv(.C) c_longlong {
    var _c = arg__c;
    return _atoi64(_c);
}
pub fn wtoll(arg__w: [*c]const wchar_t) callconv(.C) c_longlong {
    var _w = arg__w;
    return _wtoi64(_w);
}
pub fn lltoa(arg__n: c_longlong, arg__c: [*c]u8, arg__i: c_int) callconv(.C) [*c]u8 {
    var _n = arg__n;
    var _c = arg__c;
    var _i = arg__i;
    return _i64toa(_n, _c, _i);
}
pub fn ulltoa(arg__n: c_ulonglong, arg__c: [*c]u8, arg__i: c_int) callconv(.C) [*c]u8 {
    var _n = arg__n;
    var _c = arg__c;
    var _i = arg__i;
    return _ui64toa(_n, _c, _i);
}
pub fn lltow(arg__n: c_longlong, arg__w: [*c]wchar_t, arg__i: c_int) callconv(.C) [*c]wchar_t {
    var _n = arg__n;
    var _w = arg__w;
    var _i = arg__i;
    return _i64tow(_n, _w, _i);
}
pub fn ulltow(arg__n: c_ulonglong, arg__w: [*c]wchar_t, arg__i: c_int) callconv(.C) [*c]wchar_t {
    var _n = arg__n;
    var _w = arg__w;
    var _i = arg__i;
    return _ui64tow(_n, _w, _i);
}
pub extern fn bsearch_s(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: rsize_t, _SizeOfElements: rsize_t, _PtFuncCompare: ?fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.C) c_int, _Context: ?*anyopaque) ?*anyopaque;
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
pub extern fn qsort_s(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.C) c_int, _Context: ?*anyopaque) void;
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
        @ptrCast([*c]c_uint, @alignCast(@import("std").meta.alignment(c_uint), _Ptr)).* = _Marker;
        _Ptr = @ptrCast(?*anyopaque, @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), _Ptr)) + @bitCast(usize, @intCast(isize, @as(c_int, 16))));
    }
    return _Ptr;
}
pub fn _freea(arg__Memory: ?*anyopaque) callconv(.C) void {
    var _Memory = arg__Memory;
    var _Marker: c_uint = undefined;
    if (_Memory != null) {
        _Memory = @ptrCast(?*anyopaque, @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), _Memory)) - @bitCast(usize, @intCast(isize, @as(c_int, 16))));
        _Marker = @ptrCast([*c]c_uint, @alignCast(@import("std").meta.alignment(c_uint), _Memory)).*;
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
pub const __mingw_flt_type_t = union___mingw_flt_type_t; // D:\DevTools\zig\lib\libc\include\any-windows-any\math.h:137:11: warning: struct demoted to opaque type - has bitfield
const struct_unnamed_3 = opaque {};
pub const union___mingw_ldbl_type_t = extern union {
    x: c_longdouble,
    lh: struct_unnamed_3,
};
pub const __mingw_ldbl_type_t = union___mingw_ldbl_type_t;
pub extern var __imp__HUGE: [*c]f64;
pub extern fn __mingw_raise_matherr(typ: c_int, name: [*c]const u8, a1: f64, a2: f64, rslt: f64) void;
pub extern fn __mingw_setusermatherr(?fn ([*c]struct__exception) callconv(.C) c_int) void;
pub extern fn __setusermatherr(?fn ([*c]struct__exception) callconv(.C) c_int) void;
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
pub fn fabsf(arg_x: f32) callconv(.C) f32 {
    var x = arg_x;
    return __builtin_fabsf(x);
} // D:\DevTools\zig\lib\libc\include\any-windows-any\math.h:219:23: warning: unsupported floating point constant format clang.APFloatBaseSemantics.x86DoubleExtended
// D:\DevTools\zig\lib\libc\include\any-windows-any\math.h:214:36: warning: unable to translate function, demoted to extern
pub extern fn fabsl(arg_x: c_longdouble) callconv(.C) c_longdouble;
pub fn fabs(arg_x: f64) callconv(.C) f64 {
    var x = arg_x;
    return __builtin_fabs(x);
}
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
pub fn __fpclassifyl(arg_x: c_longdouble) callconv(.C) c_int {
    var x = arg_x;
    var hlp: __mingw_ldbl_type_t = undefined;
    var e: c_uint = undefined;
    hlp.x = x;
    e = @bitCast(c_uint, hlp.lh.sign_exponent & @as(c_int, 32767));
    if (!(e != 0)) {
        var h: c_uint = hlp.lh.high;
        if (!((hlp.lh.low | h) != 0)) return 16384 else if (!((h & @as(c_uint, 2147483648)) != 0)) return @as(c_int, 1024) | @as(c_int, 16384);
    } else if (e == @bitCast(c_uint, @as(c_int, 32767))) return if (((hlp.lh.high & @bitCast(c_uint, @as(c_int, 2147483647))) | hlp.lh.low) == @bitCast(c_uint, @as(c_int, 0))) @as(c_int, 256) | @as(c_int, 1024) else @as(c_int, 256);
    return 1024;
}
pub fn __fpclassifyf(arg_x: f32) callconv(.C) c_int {
    var x = arg_x;
    var hlp: __mingw_flt_type_t = undefined;
    hlp.x = x;
    hlp.val &= @bitCast(c_uint, @as(c_int, 2147483647));
    if (hlp.val == @bitCast(c_uint, @as(c_int, 0))) return 16384;
    if (hlp.val < @bitCast(c_uint, @as(c_int, 8388608))) return @as(c_int, 1024) | @as(c_int, 16384);
    if (hlp.val >= @bitCast(c_uint, @as(c_int, 2139095040))) return if (hlp.val > @bitCast(c_uint, @as(c_int, 2139095040))) @as(c_int, 256) else @as(c_int, 256) | @as(c_int, 1024);
    return 1024;
}
pub fn __fpclassify(arg_x: f64) callconv(.C) c_int {
    var x = arg_x;
    var hlp: __mingw_dbl_type_t = undefined;
    var l: c_uint = undefined;
    var h: c_uint = undefined;
    hlp.x = x;
    h = hlp.lh.high;
    l = hlp.lh.low | (h & @bitCast(c_uint, @as(c_int, 1048575)));
    h &= @bitCast(c_uint, @as(c_int, 2146435072));
    if ((h | l) == @bitCast(c_uint, @as(c_int, 0))) return 16384;
    if (!(h != 0)) return @as(c_int, 1024) | @as(c_int, 16384);
    if (h == @bitCast(c_uint, @as(c_int, 2146435072))) return if (l != 0) @as(c_int, 256) else @as(c_int, 256) | @as(c_int, 1024);
    return 1024;
}
pub fn __isnan(arg__x: f64) callconv(.C) c_int {
    var _x = arg__x;
    var hlp: __mingw_dbl_type_t = undefined;
    var l: c_int = undefined;
    var h: c_int = undefined;
    hlp.x = _x;
    l = @bitCast(c_int, hlp.lh.low);
    h = @bitCast(c_int, hlp.lh.high & @bitCast(c_uint, @as(c_int, 2147483647)));
    h |= @bitCast(c_int, @bitCast(c_uint, l | -l) >> @intCast(@import("std").math.Log2Int(c_uint), 31));
    h = @as(c_int, 2146435072) - h;
    return @bitCast(c_int, @bitCast(c_uint, h)) >> @intCast(@import("std").math.Log2Int(c_int), 31);
}
pub fn __isnanf(arg__x: f32) callconv(.C) c_int {
    var _x = arg__x;
    var hlp: __mingw_flt_type_t = undefined;
    var i: c_int = undefined;
    hlp.x = _x;
    i = @bitCast(c_int, hlp.val & @bitCast(c_uint, @as(c_int, 2147483647)));
    i = @as(c_int, 2139095040) - i;
    return @bitCast(c_int, @bitCast(c_uint, i) >> @intCast(@import("std").math.Log2Int(c_uint), 31));
}
pub fn __isnanl(arg__x: c_longdouble) callconv(.C) c_int {
    var _x = arg__x;
    var ld: __mingw_ldbl_type_t = undefined;
    var xx: c_int = undefined;
    var signexp: c_int = undefined;
    ld.x = _x;
    signexp = (ld.lh.sign_exponent & @as(c_int, 32767)) << @intCast(@import("std").math.Log2Int(c_int), 1);
    xx = @bitCast(c_int, ld.lh.low | (ld.lh.high & @as(c_uint, 2147483647)));
    signexp |= @bitCast(c_int, @bitCast(c_uint, xx | -xx) >> @intCast(@import("std").math.Log2Int(c_uint), 31));
    signexp = @as(c_int, 65534) - signexp;
    return @bitCast(c_int, @bitCast(c_uint, signexp)) >> @intCast(@import("std").math.Log2Int(c_int), 16);
}
pub fn __signbit(arg_x: f64) callconv(.C) c_int {
    var x = arg_x;
    var hlp: __mingw_dbl_type_t = undefined;
    hlp.x = x;
    return @boolToInt((hlp.lh.high & @as(c_uint, 2147483648)) != @bitCast(c_uint, @as(c_int, 0)));
}
pub fn __signbitf(arg_x: f32) callconv(.C) c_int {
    var x = arg_x;
    var hlp: __mingw_flt_type_t = undefined;
    hlp.x = x;
    return @boolToInt((hlp.val & @as(c_uint, 2147483648)) != @bitCast(c_uint, @as(c_int, 0)));
}
pub fn __signbitl(arg_x: c_longdouble) callconv(.C) c_int {
    var x = arg_x;
    var ld: __mingw_ldbl_type_t = undefined;
    ld.x = x;
    return @boolToInt((ld.lh.sign_exponent & @as(c_int, 32768)) != @as(c_int, 0));
}
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
pub fn sinhf(arg__X: f32) callconv(.C) f32 {
    var _X = arg__X;
    return @floatCast(f32, sinh(@floatCast(f64, _X)));
}
pub extern fn sinhl(c_longdouble) c_longdouble;
pub fn coshf(arg__X: f32) callconv(.C) f32 {
    var _X = arg__X;
    return @floatCast(f32, cosh(@floatCast(f64, _X)));
}
pub extern fn coshl(c_longdouble) c_longdouble;
pub fn tanhf(arg__X: f32) callconv(.C) f32 {
    var _X = arg__X;
    return @floatCast(f32, tanh(@floatCast(f64, _X)));
}
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
pub fn expf(arg__X: f32) callconv(.C) f32 {
    var _X = arg__X;
    return @floatCast(f32, exp(@floatCast(f64, _X)));
}
pub extern fn expl(c_longdouble) c_longdouble;
pub extern fn exp2(f64) f64;
pub extern fn exp2f(f32) f32;
pub extern fn exp2l(c_longdouble) c_longdouble;
pub extern fn expm1(f64) f64;
pub extern fn expm1f(f32) f32;
pub extern fn expm1l(c_longdouble) c_longdouble;
pub fn frexpf(arg__X: f32, arg__Y: [*c]c_int) callconv(.C) f32 {
    var _X = arg__X;
    var _Y = arg__Y;
    return @floatCast(f32, frexp(@floatCast(f64, _X), _Y));
}
pub extern fn frexpl(c_longdouble, [*c]c_int) c_longdouble;
pub extern fn ilogb(f64) c_int;
pub extern fn ilogbf(f32) c_int;
pub extern fn ilogbl(c_longdouble) c_int;
pub fn ldexpf(arg_x: f32, arg_expn: c_int) callconv(.C) f32 {
    var x = arg_x;
    var expn = arg_expn;
    return @floatCast(f32, ldexp(@floatCast(f64, x), expn));
}
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
pub fn hypotf(arg_x: f32, arg_y: f32) callconv(.C) f32 {
    var x = arg_x;
    var y = arg_y;
    return @floatCast(f32, hypot(@floatCast(f64, x), @floatCast(f64, y)));
}
pub extern fn hypotl(c_longdouble, c_longdouble) c_longdouble;
pub fn powf(arg__X: f32, arg__Y: f32) callconv(.C) f32 {
    var _X = arg__X;
    var _Y = arg__Y;
    return @floatCast(f32, pow(@floatCast(f64, _X), @floatCast(f64, _Y)));
}
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
pub fn copysign(arg_x: f64, arg_y: f64) callconv(.C) f64 {
    var x = arg_x;
    var y = arg_y;
    var hx: __mingw_dbl_type_t = undefined;
    var hy: __mingw_dbl_type_t = undefined;
    hx.x = x;
    hy.x = y;
    hx.lh.high = (hx.lh.high & @bitCast(c_uint, @as(c_int, 2147483647))) | (hy.lh.high & @as(c_uint, 2147483648));
    return hx.x;
}
pub fn copysignf(arg_x: f32, arg_y: f32) callconv(.C) f32 {
    var x = arg_x;
    var y = arg_y;
    var hx: __mingw_flt_type_t = undefined;
    var hy: __mingw_flt_type_t = undefined;
    hx.x = x;
    hy.x = y;
    hx.val = (hx.val & @bitCast(c_uint, @as(c_int, 2147483647))) | (hy.val & @as(c_uint, 2147483648));
    return hx.x;
}
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
pub const cpCollisionBeginFunc = ?fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) cpBool;
pub const cpCollisionPreSolveFunc = ?fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) cpBool;
pub const cpCollisionPostSolveFunc = ?fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) void;
pub const cpCollisionSeparateFunc = ?fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) void;
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
pub const cpSpatialIndexBBFunc = ?fn (?*anyopaque) callconv(.C) cpBB;
pub const cpSpatialIndexIteratorFunc = ?fn (?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexQueryFunc = ?fn (?*anyopaque, ?*anyopaque, cpCollisionID, ?*anyopaque) callconv(.C) cpCollisionID;
pub const cpSpatialIndexSegmentQueryFunc = ?fn (?*anyopaque, ?*anyopaque, ?*anyopaque) callconv(.C) cpFloat;
pub const cpSpatialIndexClass = struct_cpSpatialIndexClass;
pub const struct_cpSpatialIndex = extern struct {
    klass: [*c]cpSpatialIndexClass,
    bbfunc: cpSpatialIndexBBFunc,
    staticIndex: [*c]cpSpatialIndex,
    dynamicIndex: [*c]cpSpatialIndex,
};
pub const cpSpatialIndex = struct_cpSpatialIndex;
pub const cpSpatialIndexDestroyImpl = ?fn ([*c]cpSpatialIndex) callconv(.C) void;
pub const cpSpatialIndexCountImpl = ?fn ([*c]cpSpatialIndex) callconv(.C) c_int;
pub const cpSpatialIndexEachImpl = ?fn ([*c]cpSpatialIndex, cpSpatialIndexIteratorFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexContainsImpl = ?fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) cpBool;
pub const cpSpatialIndexInsertImpl = ?fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexRemoveImpl = ?fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexReindexImpl = ?fn ([*c]cpSpatialIndex) callconv(.C) void;
pub const cpSpatialIndexReindexObjectImpl = ?fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexReindexQueryImpl = ?fn ([*c]cpSpatialIndex, cpSpatialIndexQueryFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexQueryImpl = ?fn ([*c]cpSpatialIndex, ?*anyopaque, cpBB, cpSpatialIndexQueryFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexSegmentQueryImpl = ?fn ([*c]cpSpatialIndex, ?*anyopaque, cpVect, cpVect, cpFloat, cpSpatialIndexSegmentQueryFunc, ?*anyopaque) callconv(.C) void;
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
pub const cpBBTreeVelocityFunc = ?fn (?*anyopaque) callconv(.C) cpVect;
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
pub const cpBodyVelocityFunc = ?fn (?*cpBody, cpVect, cpFloat, cpFloat) callconv(.C) void;
pub const cpBodyPositionFunc = ?fn (?*cpBody, cpFloat) callconv(.C) void;
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
pub const cpBodyShapeIteratorFunc = ?fn (?*cpBody, ?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachShape(body: ?*cpBody, func: cpBodyShapeIteratorFunc, data: ?*anyopaque) void;
pub const cpBodyConstraintIteratorFunc = ?fn (?*cpBody, ?*cpConstraint, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachConstraint(body: ?*cpBody, func: cpBodyConstraintIteratorFunc, data: ?*anyopaque) void;
pub const cpBodyArbiterIteratorFunc = ?fn (?*cpBody, ?*cpArbiter, ?*anyopaque) callconv(.C) void;
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
pub const cpConstraintPreSolveFunc = ?fn (?*cpConstraint, ?*cpSpace) callconv(.C) void;
pub const cpConstraintPostSolveFunc = ?fn (?*cpConstraint, ?*cpSpace) callconv(.C) void;
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
pub const cpDampedSpringForceFunc = ?fn (?*cpConstraint, cpFloat) callconv(.C) cpFloat;
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
pub const cpDampedRotarySpringTorqueFunc = ?fn (?*struct_cpConstraint, cpFloat) callconv(.C) cpFloat;
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
pub const cpPostStepFunc = ?fn (?*cpSpace, ?*anyopaque, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceAddPostStepCallback(space: ?*cpSpace, func: cpPostStepFunc, key: ?*anyopaque, data: ?*anyopaque) cpBool;
pub const cpSpacePointQueryFunc = ?fn (?*cpShape, cpVect, cpFloat, cpVect, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpacePointQuery(space: ?*cpSpace, point: cpVect, maxDistance: cpFloat, filter: cpShapeFilter, func: cpSpacePointQueryFunc, data: ?*anyopaque) void;
pub extern fn cpSpacePointQueryNearest(space: ?*cpSpace, point: cpVect, maxDistance: cpFloat, filter: cpShapeFilter, out: [*c]cpPointQueryInfo) ?*cpShape;
pub const cpSpaceSegmentQueryFunc = ?fn (?*cpShape, cpVect, cpVect, cpFloat, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceSegmentQuery(space: ?*cpSpace, start: cpVect, end: cpVect, radius: cpFloat, filter: cpShapeFilter, func: cpSpaceSegmentQueryFunc, data: ?*anyopaque) void;
pub extern fn cpSpaceSegmentQueryFirst(space: ?*cpSpace, start: cpVect, end: cpVect, radius: cpFloat, filter: cpShapeFilter, out: [*c]cpSegmentQueryInfo) ?*cpShape;
pub const cpSpaceBBQueryFunc = ?fn (?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceBBQuery(space: ?*cpSpace, bb: cpBB, filter: cpShapeFilter, func: cpSpaceBBQueryFunc, data: ?*anyopaque) void;
pub const cpSpaceShapeQueryFunc = ?fn (?*cpShape, [*c]cpContactPointSet, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceShapeQuery(space: ?*cpSpace, shape: ?*cpShape, func: cpSpaceShapeQueryFunc, data: ?*anyopaque) cpBool;
pub const cpSpaceBodyIteratorFunc = ?fn (?*cpBody, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachBody(space: ?*cpSpace, func: cpSpaceBodyIteratorFunc, data: ?*anyopaque) void;
pub const cpSpaceShapeIteratorFunc = ?fn (?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachShape(space: ?*cpSpace, func: cpSpaceShapeIteratorFunc, data: ?*anyopaque) void;
pub const cpSpaceConstraintIteratorFunc = ?fn (?*cpConstraint, ?*anyopaque) callconv(.C) void;
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
pub const cpSpaceDebugDrawCircleImpl = ?fn (cpVect, cpFloat, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawSegmentImpl = ?fn (cpVect, cpVect, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawFatSegmentImpl = ?fn (cpVect, cpVect, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawPolygonImpl = ?fn (c_int, [*c]const cpVect, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawDotImpl = ?fn (cpFloat, cpVect, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawColorForShapeImpl = ?fn (?*cpShape, cpDataPointer) callconv(.C) cpSpaceDebugColor;
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
