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
pub const ImGuiID = c_uint;
pub const ImS8 = i8;
pub const ImGuiTableColumnIdx = ImS8; // cimgui.h:2324:10: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTableColumnSettings = opaque {};
pub const ImGuiTableColumnSettings = struct_ImGuiTableColumnSettings;
pub const ImU32 = c_uint;
pub const struct_ImGuiTableCellData = extern struct {
    BgColor: ImU32,
    Column: ImGuiTableColumnIdx,
};
pub const ImGuiTableCellData = struct_ImGuiTableCellData;
pub const struct_ImGuiStackLevelInfo = extern struct {
    ID: ImGuiID,
    QueryFrameCount: ImS8,
    QuerySuccess: bool,
    Desc: [58]u8,
};
pub const ImGuiStackLevelInfo = struct_ImGuiStackLevelInfo;
pub const struct_ImVector_ImGuiStackLevelInfo = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiStackLevelInfo,
};
pub const ImVector_ImGuiStackLevelInfo = struct_ImVector_ImGuiStackLevelInfo;
pub const struct_ImGuiStackTool = extern struct {
    LastActiveFrame: c_int,
    StackLevel: c_int,
    QueryId: ImGuiID,
    Results: ImVector_ImGuiStackLevelInfo,
};
pub const ImGuiStackTool = struct_ImGuiStackTool;
pub const ImGuiViewportFlags = c_int;
pub const struct_ImVec2 = extern struct {
    x: f32,
    y: f32,
};
pub const ImVec2 = struct_ImVec2;
pub const struct_ImGuiViewport = extern struct {
    Flags: ImGuiViewportFlags,
    Pos: ImVec2,
    Size: ImVec2,
    WorkPos: ImVec2,
    WorkSize: ImVec2,
};
pub const ImGuiViewport = struct_ImGuiViewport;
pub const struct_ImVec4 = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};
pub const ImVec4 = struct_ImVec4;
pub const ImTextureID = ?*anyopaque;
pub const ImDrawCallback = ?fn ([*c]const ImDrawList, [*c]const ImDrawCmd) callconv(.C) void;
pub const struct_ImDrawCmd = extern struct {
    ClipRect: ImVec4,
    TextureId: ImTextureID,
    VtxOffset: c_uint,
    IdxOffset: c_uint,
    ElemCount: c_uint,
    UserCallback: ImDrawCallback,
    UserCallbackData: ?*anyopaque,
};
pub const ImDrawCmd = struct_ImDrawCmd;
pub const struct_ImVector_ImDrawCmd = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawCmd,
};
pub const ImVector_ImDrawCmd = struct_ImVector_ImDrawCmd;
pub const ImDrawIdx = c_ushort;
pub const struct_ImVector_ImDrawIdx = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawIdx,
};
pub const ImVector_ImDrawIdx = struct_ImVector_ImDrawIdx;
pub const struct_ImDrawVert = extern struct {
    pos: ImVec2,
    uv: ImVec2,
    col: ImU32,
};
pub const ImDrawVert = struct_ImDrawVert;
pub const struct_ImVector_ImDrawVert = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawVert,
};
pub const ImVector_ImDrawVert = struct_ImVector_ImDrawVert;
pub const ImDrawListFlags = c_int;
pub const struct_ImVector_float = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]f32,
};
pub const ImVector_float = struct_ImVector_float;
pub const ImWchar16 = c_ushort;
pub const ImWchar = ImWchar16;
pub const struct_ImVector_ImWchar = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImWchar,
};
pub const ImVector_ImWchar = struct_ImVector_ImWchar; // cimgui.h:1142:18: warning: struct demoted to opaque type - has bitfield
pub const struct_ImFontGlyph = opaque {};
pub const ImFontGlyph = struct_ImFontGlyph;
pub const struct_ImVector_ImFontGlyph = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: ?*ImFontGlyph,
};
pub const ImVector_ImFontGlyph = struct_ImVector_ImFontGlyph;
pub const ImFontAtlasFlags = c_int;
pub const struct_ImVector_ImFontPtr = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImFont,
};
pub const ImVector_ImFontPtr = struct_ImVector_ImFontPtr;
pub const struct_ImFontAtlasCustomRect = extern struct {
    Width: c_ushort,
    Height: c_ushort,
    X: c_ushort,
    Y: c_ushort,
    GlyphID: c_uint,
    GlyphAdvanceX: f32,
    GlyphOffset: ImVec2,
    Font: [*c]ImFont,
};
pub const ImFontAtlasCustomRect = struct_ImFontAtlasCustomRect;
pub const struct_ImVector_ImFontAtlasCustomRect = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImFontAtlasCustomRect,
};
pub const ImVector_ImFontAtlasCustomRect = struct_ImVector_ImFontAtlasCustomRect;
pub const struct_ImFontConfig = extern struct {
    FontData: ?*anyopaque,
    FontDataSize: c_int,
    FontDataOwnedByAtlas: bool,
    FontNo: c_int,
    SizePixels: f32,
    OversampleH: c_int,
    OversampleV: c_int,
    PixelSnapH: bool,
    GlyphExtraSpacing: ImVec2,
    GlyphOffset: ImVec2,
    GlyphRanges: [*c]const ImWchar,
    GlyphMinAdvanceX: f32,
    GlyphMaxAdvanceX: f32,
    MergeMode: bool,
    FontBuilderFlags: c_uint,
    RasterizerMultiply: f32,
    EllipsisChar: ImWchar,
    Name: [40]u8,
    DstFont: [*c]ImFont,
};
pub const ImFontConfig = struct_ImFontConfig;
pub const struct_ImVector_ImFontConfig = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImFontConfig,
};
pub const ImVector_ImFontConfig = struct_ImVector_ImFontConfig;
pub const struct_ImFontBuilderIO = extern struct {
    FontBuilder_Build: ?fn ([*c]ImFontAtlas) callconv(.C) bool,
};
pub const ImFontBuilderIO = struct_ImFontBuilderIO;
pub const struct_ImFontAtlas = extern struct {
    Flags: ImFontAtlasFlags,
    TexID: ImTextureID,
    TexDesiredWidth: c_int,
    TexGlyphPadding: c_int,
    Locked: bool,
    TexReady: bool,
    TexPixelsUseColors: bool,
    TexPixelsAlpha8: [*c]u8,
    TexPixelsRGBA32: [*c]c_uint,
    TexWidth: c_int,
    TexHeight: c_int,
    TexUvScale: ImVec2,
    TexUvWhitePixel: ImVec2,
    Fonts: ImVector_ImFontPtr,
    CustomRects: ImVector_ImFontAtlasCustomRect,
    ConfigData: ImVector_ImFontConfig,
    TexUvLines: [64]ImVec4,
    FontBuilderIO: [*c]const ImFontBuilderIO,
    FontBuilderFlags: c_uint,
    PackIdMouseCursors: c_int,
    PackIdLines: c_int,
};
pub const ImFontAtlas = struct_ImFontAtlas;
pub const ImU8 = u8;
pub const struct_ImFont = extern struct {
    IndexAdvanceX: ImVector_float,
    FallbackAdvanceX: f32,
    FontSize: f32,
    IndexLookup: ImVector_ImWchar,
    Glyphs: ImVector_ImFontGlyph,
    FallbackGlyph: ?*const ImFontGlyph,
    ContainerAtlas: [*c]ImFontAtlas,
    ConfigData: [*c]const ImFontConfig,
    ConfigDataCount: c_short,
    FallbackChar: ImWchar,
    EllipsisChar: ImWchar,
    DotChar: ImWchar,
    DirtyLookupTables: bool,
    Scale: f32,
    Ascent: f32,
    Descent: f32,
    MetricsTotalSurface: c_int,
    Used4kPagesMap: [2]ImU8,
};
pub const ImFont = struct_ImFont;
pub const struct_ImDrawListSharedData = extern struct {
    TexUvWhitePixel: ImVec2,
    Font: [*c]ImFont,
    FontSize: f32,
    CurveTessellationTol: f32,
    CircleSegmentMaxError: f32,
    ClipRectFullscreen: ImVec4,
    InitialFlags: ImDrawListFlags,
    ArcFastVtx: [48]ImVec2,
    ArcFastRadiusCutoff: f32,
    CircleSegmentCounts: [64]ImU8,
    TexUvLines: [*c]const ImVec4,
};
pub const ImDrawListSharedData = struct_ImDrawListSharedData;
pub const struct_ImVector_ImVec4 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImVec4,
};
pub const ImVector_ImVec4 = struct_ImVector_ImVec4;
pub const struct_ImVector_ImTextureID = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImTextureID,
};
pub const ImVector_ImTextureID = struct_ImVector_ImTextureID;
pub const struct_ImVector_ImVec2 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImVec2,
};
pub const ImVector_ImVec2 = struct_ImVector_ImVec2;
pub const struct_ImDrawCmdHeader = extern struct {
    ClipRect: ImVec4,
    TextureId: ImTextureID,
    VtxOffset: c_uint,
};
pub const ImDrawCmdHeader = struct_ImDrawCmdHeader;
pub const struct_ImDrawChannel = extern struct {
    _CmdBuffer: ImVector_ImDrawCmd,
    _IdxBuffer: ImVector_ImDrawIdx,
};
pub const ImDrawChannel = struct_ImDrawChannel;
pub const struct_ImVector_ImDrawChannel = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawChannel,
};
pub const ImVector_ImDrawChannel = struct_ImVector_ImDrawChannel;
pub const struct_ImDrawListSplitter = extern struct {
    _Current: c_int,
    _Count: c_int,
    _Channels: ImVector_ImDrawChannel,
};
pub const ImDrawListSplitter = struct_ImDrawListSplitter;
pub const struct_ImDrawList = extern struct {
    CmdBuffer: ImVector_ImDrawCmd,
    IdxBuffer: ImVector_ImDrawIdx,
    VtxBuffer: ImVector_ImDrawVert,
    Flags: ImDrawListFlags,
    _VtxCurrentIdx: c_uint,
    _Data: [*c]const ImDrawListSharedData,
    _OwnerName: [*c]const u8,
    _VtxWritePtr: [*c]ImDrawVert,
    _IdxWritePtr: [*c]ImDrawIdx,
    _ClipRectStack: ImVector_ImVec4,
    _TextureIdStack: ImVector_ImTextureID,
    _Path: ImVector_ImVec2,
    _CmdHeader: ImDrawCmdHeader,
    _Splitter: ImDrawListSplitter,
    _FringeScale: f32,
};
pub const ImDrawList = struct_ImDrawList;
pub const struct_ImDrawData = extern struct {
    Valid: bool,
    CmdListsCount: c_int,
    TotalIdxCount: c_int,
    TotalVtxCount: c_int,
    CmdLists: [*c][*c]ImDrawList,
    DisplayPos: ImVec2,
    DisplaySize: ImVec2,
    FramebufferScale: ImVec2,
};
pub const ImDrawData = struct_ImDrawData;
pub const struct_ImVector_ImDrawListPtr = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImDrawList,
};
pub const ImVector_ImDrawListPtr = struct_ImVector_ImDrawListPtr;
pub const struct_ImDrawDataBuilder = extern struct {
    Layers: [2]ImVector_ImDrawListPtr,
};
pub const ImDrawDataBuilder = struct_ImDrawDataBuilder;
pub const struct_ImGuiViewportP = extern struct {
    _ImGuiViewport: ImGuiViewport,
    DrawListsLastFrame: [2]c_int,
    DrawLists: [2][*c]ImDrawList,
    DrawDataP: ImDrawData,
    DrawDataBuilder: ImDrawDataBuilder,
    WorkOffsetMin: ImVec2,
    WorkOffsetMax: ImVec2,
    BuildWorkOffsetMin: ImVec2,
    BuildWorkOffsetMax: ImVec2,
};
pub const ImGuiViewportP = struct_ImGuiViewportP;
pub const struct_ImGuiPtrOrIndex = extern struct {
    Ptr: ?*anyopaque,
    Index: c_int,
};
pub const ImGuiPtrOrIndex = struct_ImGuiPtrOrIndex;
pub const struct_ImGuiShrinkWidthItem = extern struct {
    Index: c_int,
    Width: f32,
};
pub const ImGuiShrinkWidthItem = struct_ImGuiShrinkWidthItem;
pub const ImGuiWindowFlags = c_int;
pub const ImGuiDir = c_int; // cimgui.h:2052:15: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiWindow = opaque {};
pub const ImGuiWindow = struct_ImGuiWindow;
pub const ImGuiItemFlags = c_int;
pub const ImGuiItemStatusFlags = c_int;
pub const struct_ImRect = extern struct {
    Min: ImVec2,
    Max: ImVec2,
};
pub const ImRect = struct_ImRect;
pub const struct_ImGuiLastItemData = extern struct {
    ID: ImGuiID,
    InFlags: ImGuiItemFlags,
    StatusFlags: ImGuiItemStatusFlags,
    Rect: ImRect,
    NavRect: ImRect,
    DisplayRect: ImRect,
};
pub const ImGuiLastItemData = struct_ImGuiLastItemData;
pub const struct_ImGuiStackSizes = extern struct {
    SizeOfIDStack: c_short,
    SizeOfColorStack: c_short,
    SizeOfStyleVarStack: c_short,
    SizeOfFontStack: c_short,
    SizeOfFocusScopeStack: c_short,
    SizeOfGroupStack: c_short,
    SizeOfItemFlagsStack: c_short,
    SizeOfBeginPopupStack: c_short,
    SizeOfDisabledStack: c_short,
};
pub const ImGuiStackSizes = struct_ImGuiStackSizes;
pub const struct_ImGuiWindowStackData = extern struct {
    Window: ?*ImGuiWindow,
    ParentLastItemDataBackup: ImGuiLastItemData,
    StackSizesOnBegin: ImGuiStackSizes,
};
pub const ImGuiWindowStackData = struct_ImGuiWindowStackData;
pub const ImGuiLayoutType = c_int;
pub const struct_ImGuiComboPreviewData = extern struct {
    PreviewRect: ImRect,
    BackupCursorPos: ImVec2,
    BackupCursorMaxPos: ImVec2,
    BackupCursorPosPrevLine: ImVec2,
    BackupPrevLineTextBaseOffset: f32,
    BackupLayout: ImGuiLayoutType,
};
pub const ImGuiComboPreviewData = struct_ImGuiComboPreviewData;
pub const struct_ImGuiDataTypeTempStorage = extern struct {
    Data: [8]ImU8,
};
pub const ImGuiDataTypeTempStorage = struct_ImGuiDataTypeTempStorage;
pub const struct_ImVec2ih = extern struct {
    x: c_short,
    y: c_short,
};
pub const ImVec2ih = struct_ImVec2ih;
pub const struct_ImVec1 = extern struct {
    x: f32,
};
pub const ImVec1 = struct_ImVec1;
pub const struct_StbTexteditRow = extern struct {
    x0: f32,
    x1: f32,
    baseline_y_delta: f32,
    ymin: f32,
    ymax: f32,
    num_chars: c_int,
};
pub const StbTexteditRow = struct_StbTexteditRow;
pub const struct_StbUndoRecord = extern struct {
    where: c_int,
    insert_length: c_int,
    delete_length: c_int,
    char_storage: c_int,
};
pub const StbUndoRecord = struct_StbUndoRecord;
pub const struct_StbUndoState = extern struct {
    undo_rec: [99]StbUndoRecord,
    undo_char: [999]ImWchar,
    undo_point: c_short,
    redo_point: c_short,
    undo_char_point: c_int,
    redo_char_point: c_int,
};
pub const StbUndoState = struct_StbUndoState;
pub const struct_STB_TexteditState = extern struct {
    cursor: c_int,
    select_start: c_int,
    select_end: c_int,
    insert_mode: u8,
    row_count_per_page: c_int,
    cursor_at_end_of_line: u8,
    initialized: u8,
    has_preferred_x: u8,
    single_line: u8,
    padding1: u8,
    padding2: u8,
    padding3: u8,
    preferred_x: f32,
    undostate: StbUndoState,
};
pub const STB_TexteditState = struct_STB_TexteditState;
pub const struct_ImGuiWindowSettings = extern struct {
    ID: ImGuiID,
    Pos: ImVec2ih,
    Size: ImVec2ih,
    Collapsed: bool,
    WantApply: bool,
};
pub const ImGuiWindowSettings = struct_ImGuiWindowSettings;
pub const ImU16 = c_ushort;
pub const struct_ImGuiMenuColumns = extern struct {
    TotalWidth: ImU32,
    NextTotalWidth: ImU32,
    Spacing: ImU16,
    OffsetIcon: ImU16,
    OffsetLabel: ImU16,
    OffsetShortcut: ImU16,
    OffsetMark: ImU16,
    Widths: [4]ImU16,
};
pub const ImGuiMenuColumns = struct_ImGuiMenuColumns;
pub const struct_ImVector_ImGuiWindowPtr = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]?*ImGuiWindow,
};
pub const ImVector_ImGuiWindowPtr = struct_ImVector_ImGuiWindowPtr;
const union_unnamed_2 = extern union {
    val_i: c_int,
    val_f: f32,
    val_p: ?*anyopaque,
};
pub const struct_ImGuiStoragePair = extern struct {
    key: ImGuiID,
    unnamed_0: union_unnamed_2,
};
pub const ImGuiStoragePair = struct_ImGuiStoragePair;
pub const struct_ImVector_ImGuiStoragePair = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiStoragePair,
};
pub const ImVector_ImGuiStoragePair = struct_ImVector_ImGuiStoragePair;
pub const struct_ImGuiStorage = extern struct {
    Data: ImVector_ImGuiStoragePair,
};
pub const ImGuiStorage = struct_ImGuiStorage;
pub const ImGuiOldColumnFlags = c_int;
pub const struct_ImGuiOldColumnData = extern struct {
    OffsetNorm: f32,
    OffsetNormBeforeResize: f32,
    Flags: ImGuiOldColumnFlags,
    ClipRect: ImRect,
};
pub const ImGuiOldColumnData = struct_ImGuiOldColumnData;
pub const struct_ImVector_ImGuiOldColumnData = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiOldColumnData,
};
pub const ImVector_ImGuiOldColumnData = struct_ImVector_ImGuiOldColumnData;
pub const struct_ImGuiOldColumns = extern struct {
    ID: ImGuiID,
    Flags: ImGuiOldColumnFlags,
    IsFirstFrame: bool,
    IsBeingResized: bool,
    Current: c_int,
    Count: c_int,
    OffMinX: f32,
    OffMaxX: f32,
    LineMinY: f32,
    LineMaxY: f32,
    HostCursorPosY: f32,
    HostCursorMaxPosX: f32,
    HostInitialClipRect: ImRect,
    HostBackupClipRect: ImRect,
    HostBackupParentWorkRect: ImRect,
    Columns: ImVector_ImGuiOldColumnData,
    Splitter: ImDrawListSplitter,
};
pub const ImGuiOldColumns = struct_ImGuiOldColumns;
pub const struct_ImGuiWindowTempData = extern struct {
    CursorPos: ImVec2,
    CursorPosPrevLine: ImVec2,
    CursorStartPos: ImVec2,
    CursorMaxPos: ImVec2,
    IdealMaxPos: ImVec2,
    CurrLineSize: ImVec2,
    PrevLineSize: ImVec2,
    CurrLineTextBaseOffset: f32,
    PrevLineTextBaseOffset: f32,
    Indent: ImVec1,
    ColumnsOffset: ImVec1,
    GroupOffset: ImVec1,
    NavLayerCurrent: ImGuiNavLayer,
    NavLayersActiveMask: c_short,
    NavLayersActiveMaskNext: c_short,
    NavFocusScopeIdCurrent: ImGuiID,
    NavHideHighlightOneFrame: bool,
    NavHasScroll: bool,
    MenuBarAppending: bool,
    MenuBarOffset: ImVec2,
    MenuColumns: ImGuiMenuColumns,
    TreeDepth: c_int,
    TreeJumpToParentOnPopMask: ImU32,
    ChildWindows: ImVector_ImGuiWindowPtr,
    StateStorage: [*c]ImGuiStorage,
    CurrentColumns: [*c]ImGuiOldColumns,
    CurrentTableIdx: c_int,
    LayoutType: ImGuiLayoutType,
    ParentLayoutType: ImGuiLayoutType,
    FocusCounterTabStop: c_int,
    ItemWidth: f32,
    TextWrapPos: f32,
    ItemWidthStack: ImVector_float,
    TextWrapPosStack: ImVector_float,
};
pub const ImGuiWindowTempData = struct_ImGuiWindowTempData;
pub const struct_ImGuiTableColumnsSettings = opaque {};
pub const ImGuiTableColumnsSettings = struct_ImGuiTableColumnsSettings;
pub const ImGuiTableFlags = c_int;
pub const struct_ImGuiTableSettings = extern struct {
    ID: ImGuiID,
    SaveFlags: ImGuiTableFlags,
    RefScale: f32,
    ColumnsCount: ImGuiTableColumnIdx,
    ColumnsCountMax: ImGuiTableColumnIdx,
    WantApply: bool,
};
pub const ImGuiTableSettings = struct_ImGuiTableSettings;
pub const struct_ImGuiTableTempData = extern struct {
    TableIndex: c_int,
    LastTimeActive: f32,
    UserOuterSize: ImVec2,
    DrawSplitter: ImDrawListSplitter,
    HostBackupWorkRect: ImRect,
    HostBackupParentWorkRect: ImRect,
    HostBackupPrevLineSize: ImVec2,
    HostBackupCurrLineSize: ImVec2,
    HostBackupCursorMaxPos: ImVec2,
    HostBackupColumnsOffset: ImVec1,
    HostBackupItemWidth: f32,
    HostBackupItemWidthStackSize: c_int,
};
pub const ImGuiTableTempData = struct_ImGuiTableTempData;
pub const ImGuiTableColumnFlags = c_int;
pub const ImS16 = c_short;
pub const ImGuiTableDrawChannelIdx = ImU8; // cimgui.h:2186:10: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTableColumn = opaque {};
pub const ImGuiTableColumn = struct_ImGuiTableColumn;
pub const struct_ImSpan_ImGuiTableColumn = extern struct {
    Data: ?*ImGuiTableColumn,
    DataEnd: ?*ImGuiTableColumn,
};
pub const ImSpan_ImGuiTableColumn = struct_ImSpan_ImGuiTableColumn;
pub const struct_ImSpan_ImGuiTableColumnIdx = extern struct {
    Data: [*c]ImGuiTableColumnIdx,
    DataEnd: [*c]ImGuiTableColumnIdx,
};
pub const ImSpan_ImGuiTableColumnIdx = struct_ImSpan_ImGuiTableColumnIdx;
pub const struct_ImSpan_ImGuiTableCellData = extern struct {
    Data: [*c]ImGuiTableCellData,
    DataEnd: [*c]ImGuiTableCellData,
};
pub const ImSpan_ImGuiTableCellData = struct_ImSpan_ImGuiTableCellData;
pub const ImU64 = u64; // cimgui.h:2222:24: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTable = opaque {};
pub const ImGuiTable = struct_ImGuiTable;
pub const ImGuiTabItemFlags = c_int;
pub const ImS32 = c_int;
pub const struct_ImGuiTabItem = extern struct {
    ID: ImGuiID,
    Flags: ImGuiTabItemFlags,
    LastFrameVisible: c_int,
    LastFrameSelected: c_int,
    Offset: f32,
    Width: f32,
    ContentWidth: f32,
    NameOffset: ImS32,
    BeginOrder: ImS16,
    IndexDuringLayout: ImS16,
    WantClose: bool,
};
pub const ImGuiTabItem = struct_ImGuiTabItem;
pub const struct_ImVector_ImGuiTabItem = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiTabItem,
};
pub const ImVector_ImGuiTabItem = struct_ImVector_ImGuiTabItem;
pub const ImGuiTabBarFlags = c_int;
pub const struct_ImVector_char = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]u8,
};
pub const ImVector_char = struct_ImVector_char;
pub const struct_ImGuiTextBuffer = extern struct {
    Buf: ImVector_char,
};
pub const ImGuiTextBuffer = struct_ImGuiTextBuffer;
pub const struct_ImGuiTabBar = extern struct {
    Tabs: ImVector_ImGuiTabItem,
    Flags: ImGuiTabBarFlags,
    ID: ImGuiID,
    SelectedTabId: ImGuiID,
    NextSelectedTabId: ImGuiID,
    VisibleTabId: ImGuiID,
    CurrFrameVisible: c_int,
    PrevFrameVisible: c_int,
    BarRect: ImRect,
    CurrTabsContentsHeight: f32,
    PrevTabsContentsHeight: f32,
    WidthAllTabs: f32,
    WidthAllTabsIdeal: f32,
    ScrollingAnim: f32,
    ScrollingTarget: f32,
    ScrollingTargetDistToVisibility: f32,
    ScrollingSpeed: f32,
    ScrollingRectMinX: f32,
    ScrollingRectMaxX: f32,
    ReorderRequestTabId: ImGuiID,
    ReorderRequestOffset: ImS16,
    BeginCount: ImS8,
    WantLayout: bool,
    VisibleTabWasSubmitted: bool,
    TabsAddedNew: bool,
    TabsActiveCount: ImS16,
    LastTabItemIdx: ImS16,
    ItemSpacingY: f32,
    FramePadding: ImVec2,
    BackupCursorPos: ImVec2,
    TabsNames: ImGuiTextBuffer,
};
pub const ImGuiTabBar = struct_ImGuiTabBar;
pub const ImGuiStyleVar = c_int;
const union_unnamed_3 = extern union {
    BackupInt: [2]c_int,
    BackupFloat: [2]f32,
};
pub const struct_ImGuiStyleMod = extern struct {
    VarIdx: ImGuiStyleVar,
    unnamed_0: union_unnamed_3,
};
pub const ImGuiStyleMod = struct_ImGuiStyleMod;
pub const ImGuiConfigFlags = c_int;
pub const ImGuiBackendFlags = c_int;
pub const ImGuiKeyModFlags = c_int;
pub const struct_ImGuiIO = extern struct {
    ConfigFlags: ImGuiConfigFlags,
    BackendFlags: ImGuiBackendFlags,
    DisplaySize: ImVec2,
    DeltaTime: f32,
    IniSavingRate: f32,
    IniFilename: [*c]const u8,
    LogFilename: [*c]const u8,
    MouseDoubleClickTime: f32,
    MouseDoubleClickMaxDist: f32,
    MouseDragThreshold: f32,
    KeyMap: [22]c_int,
    KeyRepeatDelay: f32,
    KeyRepeatRate: f32,
    UserData: ?*anyopaque,
    Fonts: [*c]ImFontAtlas,
    FontGlobalScale: f32,
    FontAllowUserScaling: bool,
    FontDefault: [*c]ImFont,
    DisplayFramebufferScale: ImVec2,
    MouseDrawCursor: bool,
    ConfigMacOSXBehaviors: bool,
    ConfigInputTextCursorBlink: bool,
    ConfigDragClickToInputText: bool,
    ConfigWindowsResizeFromEdges: bool,
    ConfigWindowsMoveFromTitleBarOnly: bool,
    ConfigMemoryCompactTimer: f32,
    BackendPlatformName: [*c]const u8,
    BackendRendererName: [*c]const u8,
    BackendPlatformUserData: ?*anyopaque,
    BackendRendererUserData: ?*anyopaque,
    BackendLanguageUserData: ?*anyopaque,
    GetClipboardTextFn: ?fn (?*anyopaque) callconv(.C) [*c]const u8,
    SetClipboardTextFn: ?fn (?*anyopaque, [*c]const u8) callconv(.C) void,
    ClipboardUserData: ?*anyopaque,
    ImeSetInputScreenPosFn: ?fn (c_int, c_int) callconv(.C) void,
    ImeWindowHandle: ?*anyopaque,
    MousePos: ImVec2,
    MouseDown: [5]bool,
    MouseWheel: f32,
    MouseWheelH: f32,
    KeyCtrl: bool,
    KeyShift: bool,
    KeyAlt: bool,
    KeySuper: bool,
    KeysDown: [512]bool,
    NavInputs: [20]f32,
    WantCaptureMouse: bool,
    WantCaptureKeyboard: bool,
    WantTextInput: bool,
    WantSetMousePos: bool,
    WantSaveIniSettings: bool,
    NavActive: bool,
    NavVisible: bool,
    Framerate: f32,
    MetricsRenderVertices: c_int,
    MetricsRenderIndices: c_int,
    MetricsRenderWindows: c_int,
    MetricsActiveWindows: c_int,
    MetricsActiveAllocations: c_int,
    MouseDelta: ImVec2,
    WantCaptureMouseUnlessPopupClose: bool,
    KeyMods: ImGuiKeyModFlags,
    KeyModsPrev: ImGuiKeyModFlags,
    MousePosPrev: ImVec2,
    MouseClickedPos: [5]ImVec2,
    MouseClickedTime: [5]f64,
    MouseClicked: [5]bool,
    MouseDoubleClicked: [5]bool,
    MouseReleased: [5]bool,
    MouseDownOwned: [5]bool,
    MouseDownOwnedUnlessPopupClose: [5]bool,
    MouseDownWasDoubleClick: [5]bool,
    MouseDownDuration: [5]f32,
    MouseDownDurationPrev: [5]f32,
    MouseDragMaxDistanceAbs: [5]ImVec2,
    MouseDragMaxDistanceSqr: [5]f32,
    KeysDownDuration: [512]f32,
    KeysDownDurationPrev: [512]f32,
    NavInputsDownDuration: [20]f32,
    NavInputsDownDurationPrev: [20]f32,
    PenPressure: f32,
    AppFocusLost: bool,
    InputQueueSurrogate: ImWchar16,
    InputQueueCharacters: ImVector_ImWchar,
};
pub const ImGuiIO = struct_ImGuiIO;
pub const struct_ImGuiStyle = extern struct {
    Alpha: f32,
    DisabledAlpha: f32,
    WindowPadding: ImVec2,
    WindowRounding: f32,
    WindowBorderSize: f32,
    WindowMinSize: ImVec2,
    WindowTitleAlign: ImVec2,
    WindowMenuButtonPosition: ImGuiDir,
    ChildRounding: f32,
    ChildBorderSize: f32,
    PopupRounding: f32,
    PopupBorderSize: f32,
    FramePadding: ImVec2,
    FrameRounding: f32,
    FrameBorderSize: f32,
    ItemSpacing: ImVec2,
    ItemInnerSpacing: ImVec2,
    CellPadding: ImVec2,
    TouchExtraPadding: ImVec2,
    IndentSpacing: f32,
    ColumnsMinSpacing: f32,
    ScrollbarSize: f32,
    ScrollbarRounding: f32,
    GrabMinSize: f32,
    GrabRounding: f32,
    LogSliderDeadzone: f32,
    TabRounding: f32,
    TabBorderSize: f32,
    TabMinWidthForCloseButton: f32,
    ColorButtonPosition: ImGuiDir,
    ButtonTextAlign: ImVec2,
    SelectableTextAlign: ImVec2,
    DisplayWindowPadding: ImVec2,
    DisplaySafeAreaPadding: ImVec2,
    MouseCursorScale: f32,
    AntiAliasedLines: bool,
    AntiAliasedLinesUseTex: bool,
    AntiAliasedFill: bool,
    CurveTessellationTol: f32,
    CircleTessellationMaxError: f32,
    Colors: [53]ImVec4,
};
pub const ImGuiStyle = struct_ImGuiStyle;
pub const struct_ImVector_ImGuiWindowStackData = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiWindowStackData,
};
pub const ImVector_ImGuiWindowStackData = struct_ImVector_ImGuiWindowStackData;
pub const ImGuiNextItemDataFlags = c_int;
pub const ImGuiCond = c_int;
pub const struct_ImGuiNextItemData = extern struct {
    Flags: ImGuiNextItemDataFlags,
    Width: f32,
    FocusScopeId: ImGuiID,
    OpenCond: ImGuiCond,
    OpenVal: bool,
};
pub const ImGuiNextItemData = struct_ImGuiNextItemData;
pub const ImGuiNextWindowDataFlags = c_int;
pub const struct_ImGuiSizeCallbackData = extern struct {
    UserData: ?*anyopaque,
    Pos: ImVec2,
    CurrentSize: ImVec2,
    DesiredSize: ImVec2,
};
pub const ImGuiSizeCallbackData = struct_ImGuiSizeCallbackData;
pub const ImGuiSizeCallback = ?fn ([*c]ImGuiSizeCallbackData) callconv(.C) void;
pub const struct_ImGuiNextWindowData = extern struct {
    Flags: ImGuiNextWindowDataFlags,
    PosCond: ImGuiCond,
    SizeCond: ImGuiCond,
    CollapsedCond: ImGuiCond,
    PosVal: ImVec2,
    PosPivotVal: ImVec2,
    SizeVal: ImVec2,
    ContentSizeVal: ImVec2,
    ScrollVal: ImVec2,
    CollapsedVal: bool,
    SizeConstraintRect: ImRect,
    SizeCallback: ImGuiSizeCallback,
    SizeCallbackUserData: ?*anyopaque,
    BgAlphaVal: f32,
    MenuBarOffsetMinVal: ImVec2,
};
pub const ImGuiNextWindowData = struct_ImGuiNextWindowData;
pub const ImGuiCol = c_int;
pub const struct_ImGuiColorMod = extern struct {
    Col: ImGuiCol,
    BackupValue: ImVec4,
};
pub const ImGuiColorMod = struct_ImGuiColorMod;
pub const struct_ImVector_ImGuiColorMod = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiColorMod,
};
pub const ImVector_ImGuiColorMod = struct_ImVector_ImGuiColorMod;
pub const struct_ImVector_ImGuiStyleMod = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiStyleMod,
};
pub const ImVector_ImGuiStyleMod = struct_ImVector_ImGuiStyleMod;
pub const struct_ImVector_ImGuiID = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiID,
};
pub const ImVector_ImGuiID = struct_ImVector_ImGuiID;
pub const struct_ImVector_ImGuiItemFlags = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiItemFlags,
};
pub const ImVector_ImGuiItemFlags = struct_ImVector_ImGuiItemFlags;
pub const struct_ImGuiGroupData = extern struct {
    WindowID: ImGuiID,
    BackupCursorPos: ImVec2,
    BackupCursorMaxPos: ImVec2,
    BackupIndent: ImVec1,
    BackupGroupOffset: ImVec1,
    BackupCurrLineSize: ImVec2,
    BackupCurrLineTextBaseOffset: f32,
    BackupActiveIdIsAlive: ImGuiID,
    BackupActiveIdPreviousFrameIsAlive: bool,
    BackupHoveredIdIsAlive: bool,
    EmitItem: bool,
};
pub const ImGuiGroupData = struct_ImGuiGroupData;
pub const struct_ImVector_ImGuiGroupData = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiGroupData,
};
pub const ImVector_ImGuiGroupData = struct_ImVector_ImGuiGroupData;
pub const struct_ImGuiPopupData = extern struct {
    PopupId: ImGuiID,
    Window: ?*ImGuiWindow,
    SourceWindow: ?*ImGuiWindow,
    OpenFrameCount: c_int,
    OpenParentId: ImGuiID,
    OpenPopupPos: ImVec2,
    OpenMousePos: ImVec2,
};
pub const ImGuiPopupData = struct_ImGuiPopupData;
pub const struct_ImVector_ImGuiPopupData = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiPopupData,
};
pub const ImVector_ImGuiPopupData = struct_ImVector_ImGuiPopupData;
pub const struct_ImVector_ImGuiViewportPPtr = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImGuiViewportP,
};
pub const ImVector_ImGuiViewportPPtr = struct_ImVector_ImGuiViewportPPtr;
pub const ImGuiActivateFlags = c_int;
pub const ImGuiNavMoveFlags = c_int;
pub const ImGuiScrollFlags = c_int;
pub const struct_ImGuiNavItemData = extern struct {
    Window: ?*ImGuiWindow,
    ID: ImGuiID,
    FocusScopeId: ImGuiID,
    RectRel: ImRect,
    InFlags: ImGuiItemFlags,
    DistBox: f32,
    DistCenter: f32,
    DistAxial: f32,
};
pub const ImGuiNavItemData = struct_ImGuiNavItemData;
pub const ImGuiMouseCursor = c_int;
pub const ImGuiDragDropFlags = c_int;
pub const struct_ImGuiPayload = extern struct {
    Data: ?*anyopaque,
    DataSize: c_int,
    SourceId: ImGuiID,
    SourceParentId: ImGuiID,
    DataFrameCount: c_int,
    DataType: [33]u8,
    Preview: bool,
    Delivery: bool,
};
pub const ImGuiPayload = struct_ImGuiPayload;
pub const struct_ImVector_unsigned_char = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]u8,
};
pub const ImVector_unsigned_char = struct_ImVector_unsigned_char;
pub const struct_ImVector_ImGuiTable = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: ?*ImGuiTable,
};
pub const ImVector_ImGuiTable = struct_ImVector_ImGuiTable;
pub const ImPoolIdx = c_int;
pub const struct_ImPool_ImGuiTable = extern struct {
    Buf: ImVector_ImGuiTable,
    Map: ImGuiStorage,
    FreeIdx: ImPoolIdx,
};
pub const ImPool_ImGuiTable = struct_ImPool_ImGuiTable;
pub const struct_ImVector_ImGuiTableTempData = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiTableTempData,
};
pub const ImVector_ImGuiTableTempData = struct_ImVector_ImGuiTableTempData;
pub const struct_ImVector_ImGuiTabBar = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiTabBar,
};
pub const ImVector_ImGuiTabBar = struct_ImVector_ImGuiTabBar;
pub const struct_ImPool_ImGuiTabBar = extern struct {
    Buf: ImVector_ImGuiTabBar,
    Map: ImGuiStorage,
    FreeIdx: ImPoolIdx,
};
pub const ImPool_ImGuiTabBar = struct_ImPool_ImGuiTabBar;
pub const struct_ImVector_ImGuiPtrOrIndex = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiPtrOrIndex,
};
pub const ImVector_ImGuiPtrOrIndex = struct_ImVector_ImGuiPtrOrIndex;
pub const struct_ImVector_ImGuiShrinkWidthItem = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiShrinkWidthItem,
};
pub const ImVector_ImGuiShrinkWidthItem = struct_ImVector_ImGuiShrinkWidthItem;
pub const ImGuiInputTextFlags = c_int;
pub const ImGuiKey = c_int;
pub const struct_ImGuiInputTextCallbackData = extern struct {
    EventFlag: ImGuiInputTextFlags,
    Flags: ImGuiInputTextFlags,
    UserData: ?*anyopaque,
    EventChar: ImWchar,
    EventKey: ImGuiKey,
    Buf: [*c]u8,
    BufTextLen: c_int,
    BufSize: c_int,
    BufDirty: bool,
    CursorPos: c_int,
    SelectionStart: c_int,
    SelectionEnd: c_int,
};
pub const ImGuiInputTextCallbackData = struct_ImGuiInputTextCallbackData;
pub const ImGuiInputTextCallback = ?fn ([*c]ImGuiInputTextCallbackData) callconv(.C) c_int;
pub const struct_ImGuiInputTextState = extern struct {
    ID: ImGuiID,
    CurLenW: c_int,
    CurLenA: c_int,
    TextW: ImVector_ImWchar,
    TextA: ImVector_char,
    InitialTextA: ImVector_char,
    TextAIsValid: bool,
    BufCapacityA: c_int,
    ScrollX: f32,
    Stb: STB_TexteditState,
    CursorAnim: f32,
    CursorFollow: bool,
    SelectedAllMouseLock: bool,
    Edited: bool,
    Flags: ImGuiInputTextFlags,
    UserCallback: ImGuiInputTextCallback,
    UserCallbackData: ?*anyopaque,
};
pub const ImGuiInputTextState = struct_ImGuiInputTextState;
pub const ImGuiColorEditFlags = c_int;
pub const ImGuiSettingsHandler = struct_ImGuiSettingsHandler;
pub const struct_ImVector_ImGuiSettingsHandler = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiSettingsHandler,
};
pub const ImVector_ImGuiSettingsHandler = struct_ImVector_ImGuiSettingsHandler;
pub const struct_ImVector_ImGuiWindowSettings = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiWindowSettings,
};
pub const ImVector_ImGuiWindowSettings = struct_ImVector_ImGuiWindowSettings;
pub const struct_ImChunkStream_ImGuiWindowSettings = extern struct {
    Buf: ImVector_ImGuiWindowSettings,
};
pub const ImChunkStream_ImGuiWindowSettings = struct_ImChunkStream_ImGuiWindowSettings;
pub const struct_ImVector_ImGuiTableSettings = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiTableSettings,
};
pub const ImVector_ImGuiTableSettings = struct_ImVector_ImGuiTableSettings;
pub const struct_ImChunkStream_ImGuiTableSettings = extern struct {
    Buf: ImVector_ImGuiTableSettings,
};
pub const ImChunkStream_ImGuiTableSettings = struct_ImChunkStream_ImGuiTableSettings;
pub const ImGuiContextHookCallback = ?fn ([*c]ImGuiContext, [*c]ImGuiContextHook) callconv(.C) void;
pub const struct_ImGuiContextHook = extern struct {
    HookId: ImGuiID,
    Type: ImGuiContextHookType,
    Owner: ImGuiID,
    Callback: ImGuiContextHookCallback,
    UserData: ?*anyopaque,
};
pub const ImGuiContextHook = struct_ImGuiContextHook;
pub const struct_ImVector_ImGuiContextHook = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiContextHook,
};
pub const ImVector_ImGuiContextHook = struct_ImVector_ImGuiContextHook;
pub const ImFileHandle = [*c]FILE;
pub const struct_ImGuiMetricsConfig = extern struct {
    ShowStackTool: bool,
    ShowWindowsRects: bool,
    ShowWindowsBeginOrder: bool,
    ShowTablesRects: bool,
    ShowDrawCmdMesh: bool,
    ShowDrawCmdBoundingBoxes: bool,
    ShowWindowsRectsType: c_int,
    ShowTablesRectsType: c_int,
};
pub const ImGuiMetricsConfig = struct_ImGuiMetricsConfig;
pub const struct_ImGuiContext = extern struct {
    Initialized: bool,
    FontAtlasOwnedByContext: bool,
    IO: ImGuiIO,
    Style: ImGuiStyle,
    Font: [*c]ImFont,
    FontSize: f32,
    FontBaseSize: f32,
    DrawListSharedData: ImDrawListSharedData,
    Time: f64,
    FrameCount: c_int,
    FrameCountEnded: c_int,
    FrameCountRendered: c_int,
    WithinFrameScope: bool,
    WithinFrameScopeWithImplicitWindow: bool,
    WithinEndChild: bool,
    GcCompactAll: bool,
    TestEngineHookItems: bool,
    TestEngine: ?*anyopaque,
    Windows: ImVector_ImGuiWindowPtr,
    WindowsFocusOrder: ImVector_ImGuiWindowPtr,
    WindowsTempSortBuffer: ImVector_ImGuiWindowPtr,
    CurrentWindowStack: ImVector_ImGuiWindowStackData,
    WindowsById: ImGuiStorage,
    WindowsActiveCount: c_int,
    WindowsHoverPadding: ImVec2,
    CurrentWindow: ?*ImGuiWindow,
    HoveredWindow: ?*ImGuiWindow,
    HoveredWindowUnderMovingWindow: ?*ImGuiWindow,
    MovingWindow: ?*ImGuiWindow,
    WheelingWindow: ?*ImGuiWindow,
    WheelingWindowRefMousePos: ImVec2,
    WheelingWindowTimer: f32,
    DebugHookIdInfo: ImGuiID,
    HoveredId: ImGuiID,
    HoveredIdPreviousFrame: ImGuiID,
    HoveredIdAllowOverlap: bool,
    HoveredIdUsingMouseWheel: bool,
    HoveredIdPreviousFrameUsingMouseWheel: bool,
    HoveredIdDisabled: bool,
    HoveredIdTimer: f32,
    HoveredIdNotActiveTimer: f32,
    ActiveId: ImGuiID,
    ActiveIdIsAlive: ImGuiID,
    ActiveIdTimer: f32,
    ActiveIdIsJustActivated: bool,
    ActiveIdAllowOverlap: bool,
    ActiveIdNoClearOnFocusLoss: bool,
    ActiveIdHasBeenPressedBefore: bool,
    ActiveIdHasBeenEditedBefore: bool,
    ActiveIdHasBeenEditedThisFrame: bool,
    ActiveIdUsingMouseWheel: bool,
    ActiveIdUsingNavDirMask: ImU32,
    ActiveIdUsingNavInputMask: ImU32,
    ActiveIdUsingKeyInputMask: ImU64,
    ActiveIdClickOffset: ImVec2,
    ActiveIdWindow: ?*ImGuiWindow,
    ActiveIdSource: ImGuiInputSource,
    ActiveIdMouseButton: c_int,
    ActiveIdPreviousFrame: ImGuiID,
    ActiveIdPreviousFrameIsAlive: bool,
    ActiveIdPreviousFrameHasBeenEditedBefore: bool,
    ActiveIdPreviousFrameWindow: ?*ImGuiWindow,
    LastActiveId: ImGuiID,
    LastActiveIdTimer: f32,
    CurrentItemFlags: ImGuiItemFlags,
    NextItemData: ImGuiNextItemData,
    LastItemData: ImGuiLastItemData,
    NextWindowData: ImGuiNextWindowData,
    ColorStack: ImVector_ImGuiColorMod,
    StyleVarStack: ImVector_ImGuiStyleMod,
    FontStack: ImVector_ImFontPtr,
    FocusScopeStack: ImVector_ImGuiID,
    ItemFlagsStack: ImVector_ImGuiItemFlags,
    GroupStack: ImVector_ImGuiGroupData,
    OpenPopupStack: ImVector_ImGuiPopupData,
    BeginPopupStack: ImVector_ImGuiPopupData,
    Viewports: ImVector_ImGuiViewportPPtr,
    NavWindow: ?*ImGuiWindow,
    NavId: ImGuiID,
    NavFocusScopeId: ImGuiID,
    NavActivateId: ImGuiID,
    NavActivateDownId: ImGuiID,
    NavActivatePressedId: ImGuiID,
    NavActivateInputId: ImGuiID,
    NavActivateFlags: ImGuiActivateFlags,
    NavJustTabbedId: ImGuiID,
    NavJustMovedToId: ImGuiID,
    NavJustMovedToFocusScopeId: ImGuiID,
    NavJustMovedToKeyMods: ImGuiKeyModFlags,
    NavNextActivateId: ImGuiID,
    NavNextActivateFlags: ImGuiActivateFlags,
    NavInputSource: ImGuiInputSource,
    NavLayer: ImGuiNavLayer,
    NavIdTabCounter: c_int,
    NavIdIsAlive: bool,
    NavMousePosDirty: bool,
    NavDisableHighlight: bool,
    NavDisableMouseHover: bool,
    NavAnyRequest: bool,
    NavInitRequest: bool,
    NavInitRequestFromMove: bool,
    NavInitResultId: ImGuiID,
    NavInitResultRectRel: ImRect,
    NavMoveSubmitted: bool,
    NavMoveScoringItems: bool,
    NavMoveForwardToNextFrame: bool,
    NavMoveFlags: ImGuiNavMoveFlags,
    NavMoveScrollFlags: ImGuiScrollFlags,
    NavMoveKeyMods: ImGuiKeyModFlags,
    NavMoveDir: ImGuiDir,
    NavMoveDirForDebug: ImGuiDir,
    NavMoveClipDir: ImGuiDir,
    NavScoringRect: ImRect,
    NavScoringDebugCount: c_int,
    NavTabbingInputableRemaining: c_int,
    NavMoveResultLocal: ImGuiNavItemData,
    NavMoveResultLocalVisible: ImGuiNavItemData,
    NavMoveResultOther: ImGuiNavItemData,
    NavWindowingTarget: ?*ImGuiWindow,
    NavWindowingTargetAnim: ?*ImGuiWindow,
    NavWindowingListWindow: ?*ImGuiWindow,
    NavWindowingTimer: f32,
    NavWindowingHighlightAlpha: f32,
    NavWindowingToggleLayer: bool,
    TabFocusRequestCurrWindow: ?*ImGuiWindow,
    TabFocusRequestNextWindow: ?*ImGuiWindow,
    TabFocusRequestCurrCounterTabStop: c_int,
    TabFocusRequestNextCounterTabStop: c_int,
    TabFocusPressed: bool,
    DimBgRatio: f32,
    MouseCursor: ImGuiMouseCursor,
    DragDropActive: bool,
    DragDropWithinSource: bool,
    DragDropWithinTarget: bool,
    DragDropSourceFlags: ImGuiDragDropFlags,
    DragDropSourceFrameCount: c_int,
    DragDropMouseButton: c_int,
    DragDropPayload: ImGuiPayload,
    DragDropTargetRect: ImRect,
    DragDropTargetId: ImGuiID,
    DragDropAcceptFlags: ImGuiDragDropFlags,
    DragDropAcceptIdCurrRectSurface: f32,
    DragDropAcceptIdCurr: ImGuiID,
    DragDropAcceptIdPrev: ImGuiID,
    DragDropAcceptFrameCount: c_int,
    DragDropHoldJustPressedId: ImGuiID,
    DragDropPayloadBufHeap: ImVector_unsigned_char,
    DragDropPayloadBufLocal: [16]u8,
    CurrentTable: ?*ImGuiTable,
    CurrentTableStackIdx: c_int,
    Tables: ImPool_ImGuiTable,
    TablesTempDataStack: ImVector_ImGuiTableTempData,
    TablesLastTimeActive: ImVector_float,
    DrawChannelsTempMergeBuffer: ImVector_ImDrawChannel,
    CurrentTabBar: [*c]ImGuiTabBar,
    TabBars: ImPool_ImGuiTabBar,
    CurrentTabBarStack: ImVector_ImGuiPtrOrIndex,
    ShrinkWidthBuffer: ImVector_ImGuiShrinkWidthItem,
    MouseLastValidPos: ImVec2,
    InputTextState: ImGuiInputTextState,
    InputTextPasswordFont: ImFont,
    TempInputId: ImGuiID,
    ColorEditOptions: ImGuiColorEditFlags,
    ColorEditLastHue: f32,
    ColorEditLastSat: f32,
    ColorEditLastColor: ImU32,
    ColorPickerRef: ImVec4,
    ComboPreviewData: ImGuiComboPreviewData,
    SliderCurrentAccum: f32,
    SliderCurrentAccumDirty: bool,
    DragCurrentAccumDirty: bool,
    DragCurrentAccum: f32,
    DragSpeedDefaultRatio: f32,
    ScrollbarClickDeltaToGrabCenter: f32,
    DisabledAlphaBackup: f32,
    DisabledStackSize: c_short,
    TooltipOverrideCount: c_short,
    TooltipSlowDelay: f32,
    ClipboardHandlerData: ImVector_char,
    MenusIdSubmittedThisFrame: ImVector_ImGuiID,
    PlatformImePos: ImVec2,
    PlatformImeLastPos: ImVec2,
    PlatformLocaleDecimalPoint: u8,
    SettingsLoaded: bool,
    SettingsDirtyTimer: f32,
    SettingsIniData: ImGuiTextBuffer,
    SettingsHandlers: ImVector_ImGuiSettingsHandler,
    SettingsWindows: ImChunkStream_ImGuiWindowSettings,
    SettingsTables: ImChunkStream_ImGuiTableSettings,
    Hooks: ImVector_ImGuiContextHook,
    HookIdNext: ImGuiID,
    LogEnabled: bool,
    LogType: ImGuiLogType,
    LogFile: ImFileHandle,
    LogBuffer: ImGuiTextBuffer,
    LogNextPrefix: [*c]const u8,
    LogNextSuffix: [*c]const u8,
    LogLinePosY: f32,
    LogLineFirstItem: bool,
    LogDepthRef: c_int,
    LogDepthToExpand: c_int,
    LogDepthToExpandDefault: c_int,
    DebugItemPickerActive: bool,
    DebugItemPickerBreakId: ImGuiID,
    DebugMetricsConfig: ImGuiMetricsConfig,
    DebugStackTool: ImGuiStackTool,
    FramerateSecPerFrame: [120]f32,
    FramerateSecPerFrameIdx: c_int,
    FramerateSecPerFrameCount: c_int,
    FramerateSecPerFrameAccum: f32,
    WantCaptureMouseNextFrame: c_int,
    WantCaptureKeyboardNextFrame: c_int,
    WantTextInputNextFrame: c_int,
    TempBuffer: [3073]u8,
};
pub const ImGuiContext = struct_ImGuiContext;
pub const struct_ImGuiSettingsHandler = extern struct {
    TypeName: [*c]const u8,
    TypeHash: ImGuiID,
    ClearAllFn: ?fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void,
    ReadInitFn: ?fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void,
    ReadOpenFn: ?fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, [*c]const u8) callconv(.C) ?*anyopaque,
    ReadLineFn: ?fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, ?*anyopaque, [*c]const u8) callconv(.C) void,
    ApplyAllFn: ?fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void,
    WriteAllFn: ?fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, [*c]ImGuiTextBuffer) callconv(.C) void,
    UserData: ?*anyopaque,
};
pub const struct_ImGuiDataTypeInfo = extern struct {
    Size: usize,
    Name: [*c]const u8,
    PrintFmt: [*c]const u8,
    ScanFmt: [*c]const u8,
};
pub const ImGuiDataTypeInfo = struct_ImGuiDataTypeInfo;
pub const struct_ImVector_ImU32 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImU32,
};
pub const ImVector_ImU32 = struct_ImVector_ImU32;
pub const struct_ImBitVector = extern struct {
    Storage: ImVector_ImU32,
};
pub const ImBitVector = struct_ImBitVector;
pub const struct_ImGuiTextRange = extern struct {
    b: [*c]const u8,
    e: [*c]const u8,
};
pub const ImGuiTextRange = struct_ImGuiTextRange;
pub const struct_ImVector_ImGuiTextRange = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiTextRange,
};
pub const ImVector_ImGuiTextRange = struct_ImVector_ImGuiTextRange;
pub const struct_ImGuiTextFilter = extern struct {
    InputBuf: [256]u8,
    Filters: ImVector_ImGuiTextRange,
    CountGrep: c_int,
};
pub const ImGuiTextFilter = struct_ImGuiTextFilter; // cimgui.h:979:24: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTableColumnSortSpecs = opaque {};
pub const ImGuiTableColumnSortSpecs = struct_ImGuiTableColumnSortSpecs;
pub const struct_ImGuiTableSortSpecs = extern struct {
    Specs: ?*const ImGuiTableColumnSortSpecs,
    SpecsCount: c_int,
    SpecsDirty: bool,
};
pub const ImGuiTableSortSpecs = struct_ImGuiTableSortSpecs;
pub const struct_ImGuiOnceUponAFrame = extern struct {
    RefFrame: c_int,
};
pub const ImGuiOnceUponAFrame = struct_ImGuiOnceUponAFrame;
pub const struct_ImGuiListClipper = extern struct {
    DisplayStart: c_int,
    DisplayEnd: c_int,
    ItemsCount: c_int,
    StepNo: c_int,
    ItemsFrozen: c_int,
    ItemsHeight: f32,
    StartPosY: f32,
};
pub const ImGuiListClipper = struct_ImGuiListClipper;
pub const struct_ImColor = extern struct {
    Value: ImVec4,
};
pub const ImColor = struct_ImColor;
pub const struct_ImFontGlyphRangesBuilder = extern struct {
    UsedChars: ImVector_ImU32,
};
pub const ImFontGlyphRangesBuilder = struct_ImFontGlyphRangesBuilder;
pub const ImGuiDataType = c_int;
pub const ImGuiNavInput = c_int;
pub const ImGuiMouseButton = c_int;
pub const ImGuiSortDirection = c_int;
pub const ImGuiTableBgTarget = c_int;
pub const ImDrawFlags = c_int;
pub const ImGuiButtonFlags = c_int;
pub const ImGuiComboFlags = c_int;
pub const ImGuiFocusedFlags = c_int;
pub const ImGuiHoveredFlags = c_int;
pub const ImGuiPopupFlags = c_int;
pub const ImGuiSelectableFlags = c_int;
pub const ImGuiSliderFlags = c_int;
pub const ImGuiTableRowFlags = c_int;
pub const ImGuiTreeNodeFlags = c_int;
pub const ImS64 = i64;
pub const ImWchar32 = c_uint;
pub const ImGuiMemAllocFunc = ?fn (usize, ?*anyopaque) callconv(.C) ?*anyopaque;
pub const ImGuiMemFreeFunc = ?fn (?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const ImGuiNavHighlightFlags = c_int;
pub const ImGuiNavDirSourceFlags = c_int;
pub const ImGuiSeparatorFlags = c_int;
pub const ImGuiTextFlags = c_int;
pub const ImGuiTooltipFlags = c_int;
pub const ImGuiErrorLogCallback = ?fn (?*anyopaque, [*c]const u8, ...) callconv(.C) void;
pub extern var GImGui: [*c]ImGuiContext;
pub const struct_ImVector = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: ?*anyopaque,
};
pub const ImVector = struct_ImVector;
pub const struct_ImVector_ImGuiOldColumns = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiOldColumns,
};
pub const ImVector_ImGuiOldColumns = struct_ImVector_ImGuiOldColumns;
pub const struct_ImVector_ImGuiTableColumnSortSpecs = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: ?*ImGuiTableColumnSortSpecs,
};
pub const ImVector_ImGuiTableColumnSortSpecs = struct_ImVector_ImGuiTableColumnSortSpecs;
pub const ImGuiWindowFlags_None: c_int = 0;
pub const ImGuiWindowFlags_NoTitleBar: c_int = 1;
pub const ImGuiWindowFlags_NoResize: c_int = 2;
pub const ImGuiWindowFlags_NoMove: c_int = 4;
pub const ImGuiWindowFlags_NoScrollbar: c_int = 8;
pub const ImGuiWindowFlags_NoScrollWithMouse: c_int = 16;
pub const ImGuiWindowFlags_NoCollapse: c_int = 32;
pub const ImGuiWindowFlags_AlwaysAutoResize: c_int = 64;
pub const ImGuiWindowFlags_NoBackground: c_int = 128;
pub const ImGuiWindowFlags_NoSavedSettings: c_int = 256;
pub const ImGuiWindowFlags_NoMouseInputs: c_int = 512;
pub const ImGuiWindowFlags_MenuBar: c_int = 1024;
pub const ImGuiWindowFlags_HorizontalScrollbar: c_int = 2048;
pub const ImGuiWindowFlags_NoFocusOnAppearing: c_int = 4096;
pub const ImGuiWindowFlags_NoBringToFrontOnFocus: c_int = 8192;
pub const ImGuiWindowFlags_AlwaysVerticalScrollbar: c_int = 16384;
pub const ImGuiWindowFlags_AlwaysHorizontalScrollbar: c_int = 32768;
pub const ImGuiWindowFlags_AlwaysUseWindowPadding: c_int = 65536;
pub const ImGuiWindowFlags_NoNavInputs: c_int = 262144;
pub const ImGuiWindowFlags_NoNavFocus: c_int = 524288;
pub const ImGuiWindowFlags_UnsavedDocument: c_int = 1048576;
pub const ImGuiWindowFlags_NoNav: c_int = 786432;
pub const ImGuiWindowFlags_NoDecoration: c_int = 43;
pub const ImGuiWindowFlags_NoInputs: c_int = 786944;
pub const ImGuiWindowFlags_NavFlattened: c_int = 8388608;
pub const ImGuiWindowFlags_ChildWindow: c_int = 16777216;
pub const ImGuiWindowFlags_Tooltip: c_int = 33554432;
pub const ImGuiWindowFlags_Popup: c_int = 67108864;
pub const ImGuiWindowFlags_Modal: c_int = 134217728;
pub const ImGuiWindowFlags_ChildMenu: c_int = 268435456;
pub const ImGuiWindowFlags_ = c_uint;
pub const ImGuiInputTextFlags_None: c_int = 0;
pub const ImGuiInputTextFlags_CharsDecimal: c_int = 1;
pub const ImGuiInputTextFlags_CharsHexadecimal: c_int = 2;
pub const ImGuiInputTextFlags_CharsUppercase: c_int = 4;
pub const ImGuiInputTextFlags_CharsNoBlank: c_int = 8;
pub const ImGuiInputTextFlags_AutoSelectAll: c_int = 16;
pub const ImGuiInputTextFlags_EnterReturnsTrue: c_int = 32;
pub const ImGuiInputTextFlags_CallbackCompletion: c_int = 64;
pub const ImGuiInputTextFlags_CallbackHistory: c_int = 128;
pub const ImGuiInputTextFlags_CallbackAlways: c_int = 256;
pub const ImGuiInputTextFlags_CallbackCharFilter: c_int = 512;
pub const ImGuiInputTextFlags_AllowTabInput: c_int = 1024;
pub const ImGuiInputTextFlags_CtrlEnterForNewLine: c_int = 2048;
pub const ImGuiInputTextFlags_NoHorizontalScroll: c_int = 4096;
pub const ImGuiInputTextFlags_AlwaysOverwrite: c_int = 8192;
pub const ImGuiInputTextFlags_ReadOnly: c_int = 16384;
pub const ImGuiInputTextFlags_Password: c_int = 32768;
pub const ImGuiInputTextFlags_NoUndoRedo: c_int = 65536;
pub const ImGuiInputTextFlags_CharsScientific: c_int = 131072;
pub const ImGuiInputTextFlags_CallbackResize: c_int = 262144;
pub const ImGuiInputTextFlags_CallbackEdit: c_int = 524288;
pub const ImGuiInputTextFlags_ = c_uint;
pub const ImGuiTreeNodeFlags_None: c_int = 0;
pub const ImGuiTreeNodeFlags_Selected: c_int = 1;
pub const ImGuiTreeNodeFlags_Framed: c_int = 2;
pub const ImGuiTreeNodeFlags_AllowItemOverlap: c_int = 4;
pub const ImGuiTreeNodeFlags_NoTreePushOnOpen: c_int = 8;
pub const ImGuiTreeNodeFlags_NoAutoOpenOnLog: c_int = 16;
pub const ImGuiTreeNodeFlags_DefaultOpen: c_int = 32;
pub const ImGuiTreeNodeFlags_OpenOnDoubleClick: c_int = 64;
pub const ImGuiTreeNodeFlags_OpenOnArrow: c_int = 128;
pub const ImGuiTreeNodeFlags_Leaf: c_int = 256;
pub const ImGuiTreeNodeFlags_Bullet: c_int = 512;
pub const ImGuiTreeNodeFlags_FramePadding: c_int = 1024;
pub const ImGuiTreeNodeFlags_SpanAvailWidth: c_int = 2048;
pub const ImGuiTreeNodeFlags_SpanFullWidth: c_int = 4096;
pub const ImGuiTreeNodeFlags_NavLeftJumpsBackHere: c_int = 8192;
pub const ImGuiTreeNodeFlags_CollapsingHeader: c_int = 26;
pub const ImGuiTreeNodeFlags_ = c_uint;
pub const ImGuiPopupFlags_None: c_int = 0;
pub const ImGuiPopupFlags_MouseButtonLeft: c_int = 0;
pub const ImGuiPopupFlags_MouseButtonRight: c_int = 1;
pub const ImGuiPopupFlags_MouseButtonMiddle: c_int = 2;
pub const ImGuiPopupFlags_MouseButtonMask_: c_int = 31;
pub const ImGuiPopupFlags_MouseButtonDefault_: c_int = 1;
pub const ImGuiPopupFlags_NoOpenOverExistingPopup: c_int = 32;
pub const ImGuiPopupFlags_NoOpenOverItems: c_int = 64;
pub const ImGuiPopupFlags_AnyPopupId: c_int = 128;
pub const ImGuiPopupFlags_AnyPopupLevel: c_int = 256;
pub const ImGuiPopupFlags_AnyPopup: c_int = 384;
pub const ImGuiPopupFlags_ = c_uint;
pub const ImGuiSelectableFlags_None: c_int = 0;
pub const ImGuiSelectableFlags_DontClosePopups: c_int = 1;
pub const ImGuiSelectableFlags_SpanAllColumns: c_int = 2;
pub const ImGuiSelectableFlags_AllowDoubleClick: c_int = 4;
pub const ImGuiSelectableFlags_Disabled: c_int = 8;
pub const ImGuiSelectableFlags_AllowItemOverlap: c_int = 16;
pub const ImGuiSelectableFlags_ = c_uint;
pub const ImGuiComboFlags_None: c_int = 0;
pub const ImGuiComboFlags_PopupAlignLeft: c_int = 1;
pub const ImGuiComboFlags_HeightSmall: c_int = 2;
pub const ImGuiComboFlags_HeightRegular: c_int = 4;
pub const ImGuiComboFlags_HeightLarge: c_int = 8;
pub const ImGuiComboFlags_HeightLargest: c_int = 16;
pub const ImGuiComboFlags_NoArrowButton: c_int = 32;
pub const ImGuiComboFlags_NoPreview: c_int = 64;
pub const ImGuiComboFlags_HeightMask_: c_int = 30;
pub const ImGuiComboFlags_ = c_uint;
pub const ImGuiTabBarFlags_None: c_int = 0;
pub const ImGuiTabBarFlags_Reorderable: c_int = 1;
pub const ImGuiTabBarFlags_AutoSelectNewTabs: c_int = 2;
pub const ImGuiTabBarFlags_TabListPopupButton: c_int = 4;
pub const ImGuiTabBarFlags_NoCloseWithMiddleMouseButton: c_int = 8;
pub const ImGuiTabBarFlags_NoTabListScrollingButtons: c_int = 16;
pub const ImGuiTabBarFlags_NoTooltip: c_int = 32;
pub const ImGuiTabBarFlags_FittingPolicyResizeDown: c_int = 64;
pub const ImGuiTabBarFlags_FittingPolicyScroll: c_int = 128;
pub const ImGuiTabBarFlags_FittingPolicyMask_: c_int = 192;
pub const ImGuiTabBarFlags_FittingPolicyDefault_: c_int = 64;
pub const ImGuiTabBarFlags_ = c_uint;
pub const ImGuiTabItemFlags_None: c_int = 0;
pub const ImGuiTabItemFlags_UnsavedDocument: c_int = 1;
pub const ImGuiTabItemFlags_SetSelected: c_int = 2;
pub const ImGuiTabItemFlags_NoCloseWithMiddleMouseButton: c_int = 4;
pub const ImGuiTabItemFlags_NoPushId: c_int = 8;
pub const ImGuiTabItemFlags_NoTooltip: c_int = 16;
pub const ImGuiTabItemFlags_NoReorder: c_int = 32;
pub const ImGuiTabItemFlags_Leading: c_int = 64;
pub const ImGuiTabItemFlags_Trailing: c_int = 128;
pub const ImGuiTabItemFlags_ = c_uint;
pub const ImGuiTableFlags_None: c_int = 0;
pub const ImGuiTableFlags_Resizable: c_int = 1;
pub const ImGuiTableFlags_Reorderable: c_int = 2;
pub const ImGuiTableFlags_Hideable: c_int = 4;
pub const ImGuiTableFlags_Sortable: c_int = 8;
pub const ImGuiTableFlags_NoSavedSettings: c_int = 16;
pub const ImGuiTableFlags_ContextMenuInBody: c_int = 32;
pub const ImGuiTableFlags_RowBg: c_int = 64;
pub const ImGuiTableFlags_BordersInnerH: c_int = 128;
pub const ImGuiTableFlags_BordersOuterH: c_int = 256;
pub const ImGuiTableFlags_BordersInnerV: c_int = 512;
pub const ImGuiTableFlags_BordersOuterV: c_int = 1024;
pub const ImGuiTableFlags_BordersH: c_int = 384;
pub const ImGuiTableFlags_BordersV: c_int = 1536;
pub const ImGuiTableFlags_BordersInner: c_int = 640;
pub const ImGuiTableFlags_BordersOuter: c_int = 1280;
pub const ImGuiTableFlags_Borders: c_int = 1920;
pub const ImGuiTableFlags_NoBordersInBody: c_int = 2048;
pub const ImGuiTableFlags_NoBordersInBodyUntilResize: c_int = 4096;
pub const ImGuiTableFlags_SizingFixedFit: c_int = 8192;
pub const ImGuiTableFlags_SizingFixedSame: c_int = 16384;
pub const ImGuiTableFlags_SizingStretchProp: c_int = 24576;
pub const ImGuiTableFlags_SizingStretchSame: c_int = 32768;
pub const ImGuiTableFlags_NoHostExtendX: c_int = 65536;
pub const ImGuiTableFlags_NoHostExtendY: c_int = 131072;
pub const ImGuiTableFlags_NoKeepColumnsVisible: c_int = 262144;
pub const ImGuiTableFlags_PreciseWidths: c_int = 524288;
pub const ImGuiTableFlags_NoClip: c_int = 1048576;
pub const ImGuiTableFlags_PadOuterX: c_int = 2097152;
pub const ImGuiTableFlags_NoPadOuterX: c_int = 4194304;
pub const ImGuiTableFlags_NoPadInnerX: c_int = 8388608;
pub const ImGuiTableFlags_ScrollX: c_int = 16777216;
pub const ImGuiTableFlags_ScrollY: c_int = 33554432;
pub const ImGuiTableFlags_SortMulti: c_int = 67108864;
pub const ImGuiTableFlags_SortTristate: c_int = 134217728;
pub const ImGuiTableFlags_SizingMask_: c_int = 57344;
pub const ImGuiTableFlags_ = c_uint;
pub const ImGuiTableColumnFlags_None: c_int = 0;
pub const ImGuiTableColumnFlags_Disabled: c_int = 1;
pub const ImGuiTableColumnFlags_DefaultHide: c_int = 2;
pub const ImGuiTableColumnFlags_DefaultSort: c_int = 4;
pub const ImGuiTableColumnFlags_WidthStretch: c_int = 8;
pub const ImGuiTableColumnFlags_WidthFixed: c_int = 16;
pub const ImGuiTableColumnFlags_NoResize: c_int = 32;
pub const ImGuiTableColumnFlags_NoReorder: c_int = 64;
pub const ImGuiTableColumnFlags_NoHide: c_int = 128;
pub const ImGuiTableColumnFlags_NoClip: c_int = 256;
pub const ImGuiTableColumnFlags_NoSort: c_int = 512;
pub const ImGuiTableColumnFlags_NoSortAscending: c_int = 1024;
pub const ImGuiTableColumnFlags_NoSortDescending: c_int = 2048;
pub const ImGuiTableColumnFlags_NoHeaderLabel: c_int = 4096;
pub const ImGuiTableColumnFlags_NoHeaderWidth: c_int = 8192;
pub const ImGuiTableColumnFlags_PreferSortAscending: c_int = 16384;
pub const ImGuiTableColumnFlags_PreferSortDescending: c_int = 32768;
pub const ImGuiTableColumnFlags_IndentEnable: c_int = 65536;
pub const ImGuiTableColumnFlags_IndentDisable: c_int = 131072;
pub const ImGuiTableColumnFlags_IsEnabled: c_int = 16777216;
pub const ImGuiTableColumnFlags_IsVisible: c_int = 33554432;
pub const ImGuiTableColumnFlags_IsSorted: c_int = 67108864;
pub const ImGuiTableColumnFlags_IsHovered: c_int = 134217728;
pub const ImGuiTableColumnFlags_WidthMask_: c_int = 24;
pub const ImGuiTableColumnFlags_IndentMask_: c_int = 196608;
pub const ImGuiTableColumnFlags_StatusMask_: c_int = 251658240;
pub const ImGuiTableColumnFlags_NoDirectResize_: c_int = 1073741824;
pub const ImGuiTableColumnFlags_ = c_uint;
pub const ImGuiTableRowFlags_None: c_int = 0;
pub const ImGuiTableRowFlags_Headers: c_int = 1;
pub const ImGuiTableRowFlags_ = c_uint;
pub const ImGuiTableBgTarget_None: c_int = 0;
pub const ImGuiTableBgTarget_RowBg0: c_int = 1;
pub const ImGuiTableBgTarget_RowBg1: c_int = 2;
pub const ImGuiTableBgTarget_CellBg: c_int = 3;
pub const ImGuiTableBgTarget_ = c_uint;
pub const ImGuiFocusedFlags_None: c_int = 0;
pub const ImGuiFocusedFlags_ChildWindows: c_int = 1;
pub const ImGuiFocusedFlags_RootWindow: c_int = 2;
pub const ImGuiFocusedFlags_AnyWindow: c_int = 4;
pub const ImGuiFocusedFlags_NoPopupHierarchy: c_int = 8;
pub const ImGuiFocusedFlags_RootAndChildWindows: c_int = 3;
pub const ImGuiFocusedFlags_ = c_uint;
pub const ImGuiHoveredFlags_None: c_int = 0;
pub const ImGuiHoveredFlags_ChildWindows: c_int = 1;
pub const ImGuiHoveredFlags_RootWindow: c_int = 2;
pub const ImGuiHoveredFlags_AnyWindow: c_int = 4;
pub const ImGuiHoveredFlags_NoPopupHierarchy: c_int = 8;
pub const ImGuiHoveredFlags_AllowWhenBlockedByPopup: c_int = 32;
pub const ImGuiHoveredFlags_AllowWhenBlockedByActiveItem: c_int = 128;
pub const ImGuiHoveredFlags_AllowWhenOverlapped: c_int = 256;
pub const ImGuiHoveredFlags_AllowWhenDisabled: c_int = 512;
pub const ImGuiHoveredFlags_RectOnly: c_int = 416;
pub const ImGuiHoveredFlags_RootAndChildWindows: c_int = 3;
pub const ImGuiHoveredFlags_ = c_uint;
pub const ImGuiDragDropFlags_None: c_int = 0;
pub const ImGuiDragDropFlags_SourceNoPreviewTooltip: c_int = 1;
pub const ImGuiDragDropFlags_SourceNoDisableHover: c_int = 2;
pub const ImGuiDragDropFlags_SourceNoHoldToOpenOthers: c_int = 4;
pub const ImGuiDragDropFlags_SourceAllowNullID: c_int = 8;
pub const ImGuiDragDropFlags_SourceExtern: c_int = 16;
pub const ImGuiDragDropFlags_SourceAutoExpirePayload: c_int = 32;
pub const ImGuiDragDropFlags_AcceptBeforeDelivery: c_int = 1024;
pub const ImGuiDragDropFlags_AcceptNoDrawDefaultRect: c_int = 2048;
pub const ImGuiDragDropFlags_AcceptNoPreviewTooltip: c_int = 4096;
pub const ImGuiDragDropFlags_AcceptPeekOnly: c_int = 3072;
pub const ImGuiDragDropFlags_ = c_uint;
pub const ImGuiDataType_S8: c_int = 0;
pub const ImGuiDataType_U8: c_int = 1;
pub const ImGuiDataType_S16: c_int = 2;
pub const ImGuiDataType_U16: c_int = 3;
pub const ImGuiDataType_S32: c_int = 4;
pub const ImGuiDataType_U32: c_int = 5;
pub const ImGuiDataType_S64: c_int = 6;
pub const ImGuiDataType_U64: c_int = 7;
pub const ImGuiDataType_Float: c_int = 8;
pub const ImGuiDataType_Double: c_int = 9;
pub const ImGuiDataType_COUNT: c_int = 10;
pub const ImGuiDataType_ = c_uint;
pub const ImGuiDir_None: c_int = -1;
pub const ImGuiDir_Left: c_int = 0;
pub const ImGuiDir_Right: c_int = 1;
pub const ImGuiDir_Up: c_int = 2;
pub const ImGuiDir_Down: c_int = 3;
pub const ImGuiDir_COUNT: c_int = 4;
pub const ImGuiDir_ = c_int;
pub const ImGuiSortDirection_None: c_int = 0;
pub const ImGuiSortDirection_Ascending: c_int = 1;
pub const ImGuiSortDirection_Descending: c_int = 2;
pub const ImGuiSortDirection_ = c_uint;
pub const ImGuiKey_Tab: c_int = 0;
pub const ImGuiKey_LeftArrow: c_int = 1;
pub const ImGuiKey_RightArrow: c_int = 2;
pub const ImGuiKey_UpArrow: c_int = 3;
pub const ImGuiKey_DownArrow: c_int = 4;
pub const ImGuiKey_PageUp: c_int = 5;
pub const ImGuiKey_PageDown: c_int = 6;
pub const ImGuiKey_Home: c_int = 7;
pub const ImGuiKey_End: c_int = 8;
pub const ImGuiKey_Insert: c_int = 9;
pub const ImGuiKey_Delete: c_int = 10;
pub const ImGuiKey_Backspace: c_int = 11;
pub const ImGuiKey_Space: c_int = 12;
pub const ImGuiKey_Enter: c_int = 13;
pub const ImGuiKey_Escape: c_int = 14;
pub const ImGuiKey_KeyPadEnter: c_int = 15;
pub const ImGuiKey_A: c_int = 16;
pub const ImGuiKey_C: c_int = 17;
pub const ImGuiKey_V: c_int = 18;
pub const ImGuiKey_X: c_int = 19;
pub const ImGuiKey_Y: c_int = 20;
pub const ImGuiKey_Z: c_int = 21;
pub const ImGuiKey_COUNT: c_int = 22;
pub const ImGuiKey_ = c_uint;
pub const ImGuiKeyModFlags_None: c_int = 0;
pub const ImGuiKeyModFlags_Ctrl: c_int = 1;
pub const ImGuiKeyModFlags_Shift: c_int = 2;
pub const ImGuiKeyModFlags_Alt: c_int = 4;
pub const ImGuiKeyModFlags_Super: c_int = 8;
pub const ImGuiKeyModFlags_ = c_uint;
pub const ImGuiNavInput_Activate: c_int = 0;
pub const ImGuiNavInput_Cancel: c_int = 1;
pub const ImGuiNavInput_Input: c_int = 2;
pub const ImGuiNavInput_Menu: c_int = 3;
pub const ImGuiNavInput_DpadLeft: c_int = 4;
pub const ImGuiNavInput_DpadRight: c_int = 5;
pub const ImGuiNavInput_DpadUp: c_int = 6;
pub const ImGuiNavInput_DpadDown: c_int = 7;
pub const ImGuiNavInput_LStickLeft: c_int = 8;
pub const ImGuiNavInput_LStickRight: c_int = 9;
pub const ImGuiNavInput_LStickUp: c_int = 10;
pub const ImGuiNavInput_LStickDown: c_int = 11;
pub const ImGuiNavInput_FocusPrev: c_int = 12;
pub const ImGuiNavInput_FocusNext: c_int = 13;
pub const ImGuiNavInput_TweakSlow: c_int = 14;
pub const ImGuiNavInput_TweakFast: c_int = 15;
pub const ImGuiNavInput_KeyLeft_: c_int = 16;
pub const ImGuiNavInput_KeyRight_: c_int = 17;
pub const ImGuiNavInput_KeyUp_: c_int = 18;
pub const ImGuiNavInput_KeyDown_: c_int = 19;
pub const ImGuiNavInput_COUNT: c_int = 20;
pub const ImGuiNavInput_InternalStart_: c_int = 16;
pub const ImGuiNavInput_ = c_uint;
pub const ImGuiConfigFlags_None: c_int = 0;
pub const ImGuiConfigFlags_NavEnableKeyboard: c_int = 1;
pub const ImGuiConfigFlags_NavEnableGamepad: c_int = 2;
pub const ImGuiConfigFlags_NavEnableSetMousePos: c_int = 4;
pub const ImGuiConfigFlags_NavNoCaptureKeyboard: c_int = 8;
pub const ImGuiConfigFlags_NoMouse: c_int = 16;
pub const ImGuiConfigFlags_NoMouseCursorChange: c_int = 32;
pub const ImGuiConfigFlags_IsSRGB: c_int = 1048576;
pub const ImGuiConfigFlags_IsTouchScreen: c_int = 2097152;
pub const ImGuiConfigFlags_ = c_uint;
pub const ImGuiBackendFlags_None: c_int = 0;
pub const ImGuiBackendFlags_HasGamepad: c_int = 1;
pub const ImGuiBackendFlags_HasMouseCursors: c_int = 2;
pub const ImGuiBackendFlags_HasSetMousePos: c_int = 4;
pub const ImGuiBackendFlags_RendererHasVtxOffset: c_int = 8;
pub const ImGuiBackendFlags_ = c_uint;
pub const ImGuiCol_Text: c_int = 0;
pub const ImGuiCol_TextDisabled: c_int = 1;
pub const ImGuiCol_WindowBg: c_int = 2;
pub const ImGuiCol_ChildBg: c_int = 3;
pub const ImGuiCol_PopupBg: c_int = 4;
pub const ImGuiCol_Border: c_int = 5;
pub const ImGuiCol_BorderShadow: c_int = 6;
pub const ImGuiCol_FrameBg: c_int = 7;
pub const ImGuiCol_FrameBgHovered: c_int = 8;
pub const ImGuiCol_FrameBgActive: c_int = 9;
pub const ImGuiCol_TitleBg: c_int = 10;
pub const ImGuiCol_TitleBgActive: c_int = 11;
pub const ImGuiCol_TitleBgCollapsed: c_int = 12;
pub const ImGuiCol_MenuBarBg: c_int = 13;
pub const ImGuiCol_ScrollbarBg: c_int = 14;
pub const ImGuiCol_ScrollbarGrab: c_int = 15;
pub const ImGuiCol_ScrollbarGrabHovered: c_int = 16;
pub const ImGuiCol_ScrollbarGrabActive: c_int = 17;
pub const ImGuiCol_CheckMark: c_int = 18;
pub const ImGuiCol_SliderGrab: c_int = 19;
pub const ImGuiCol_SliderGrabActive: c_int = 20;
pub const ImGuiCol_Button: c_int = 21;
pub const ImGuiCol_ButtonHovered: c_int = 22;
pub const ImGuiCol_ButtonActive: c_int = 23;
pub const ImGuiCol_Header: c_int = 24;
pub const ImGuiCol_HeaderHovered: c_int = 25;
pub const ImGuiCol_HeaderActive: c_int = 26;
pub const ImGuiCol_Separator: c_int = 27;
pub const ImGuiCol_SeparatorHovered: c_int = 28;
pub const ImGuiCol_SeparatorActive: c_int = 29;
pub const ImGuiCol_ResizeGrip: c_int = 30;
pub const ImGuiCol_ResizeGripHovered: c_int = 31;
pub const ImGuiCol_ResizeGripActive: c_int = 32;
pub const ImGuiCol_Tab: c_int = 33;
pub const ImGuiCol_TabHovered: c_int = 34;
pub const ImGuiCol_TabActive: c_int = 35;
pub const ImGuiCol_TabUnfocused: c_int = 36;
pub const ImGuiCol_TabUnfocusedActive: c_int = 37;
pub const ImGuiCol_PlotLines: c_int = 38;
pub const ImGuiCol_PlotLinesHovered: c_int = 39;
pub const ImGuiCol_PlotHistogram: c_int = 40;
pub const ImGuiCol_PlotHistogramHovered: c_int = 41;
pub const ImGuiCol_TableHeaderBg: c_int = 42;
pub const ImGuiCol_TableBorderStrong: c_int = 43;
pub const ImGuiCol_TableBorderLight: c_int = 44;
pub const ImGuiCol_TableRowBg: c_int = 45;
pub const ImGuiCol_TableRowBgAlt: c_int = 46;
pub const ImGuiCol_TextSelectedBg: c_int = 47;
pub const ImGuiCol_DragDropTarget: c_int = 48;
pub const ImGuiCol_NavHighlight: c_int = 49;
pub const ImGuiCol_NavWindowingHighlight: c_int = 50;
pub const ImGuiCol_NavWindowingDimBg: c_int = 51;
pub const ImGuiCol_ModalWindowDimBg: c_int = 52;
pub const ImGuiCol_COUNT: c_int = 53;
pub const ImGuiCol_ = c_uint;
pub const ImGuiStyleVar_Alpha: c_int = 0;
pub const ImGuiStyleVar_DisabledAlpha: c_int = 1;
pub const ImGuiStyleVar_WindowPadding: c_int = 2;
pub const ImGuiStyleVar_WindowRounding: c_int = 3;
pub const ImGuiStyleVar_WindowBorderSize: c_int = 4;
pub const ImGuiStyleVar_WindowMinSize: c_int = 5;
pub const ImGuiStyleVar_WindowTitleAlign: c_int = 6;
pub const ImGuiStyleVar_ChildRounding: c_int = 7;
pub const ImGuiStyleVar_ChildBorderSize: c_int = 8;
pub const ImGuiStyleVar_PopupRounding: c_int = 9;
pub const ImGuiStyleVar_PopupBorderSize: c_int = 10;
pub const ImGuiStyleVar_FramePadding: c_int = 11;
pub const ImGuiStyleVar_FrameRounding: c_int = 12;
pub const ImGuiStyleVar_FrameBorderSize: c_int = 13;
pub const ImGuiStyleVar_ItemSpacing: c_int = 14;
pub const ImGuiStyleVar_ItemInnerSpacing: c_int = 15;
pub const ImGuiStyleVar_IndentSpacing: c_int = 16;
pub const ImGuiStyleVar_CellPadding: c_int = 17;
pub const ImGuiStyleVar_ScrollbarSize: c_int = 18;
pub const ImGuiStyleVar_ScrollbarRounding: c_int = 19;
pub const ImGuiStyleVar_GrabMinSize: c_int = 20;
pub const ImGuiStyleVar_GrabRounding: c_int = 21;
pub const ImGuiStyleVar_TabRounding: c_int = 22;
pub const ImGuiStyleVar_ButtonTextAlign: c_int = 23;
pub const ImGuiStyleVar_SelectableTextAlign: c_int = 24;
pub const ImGuiStyleVar_COUNT: c_int = 25;
pub const ImGuiStyleVar_ = c_uint;
pub const ImGuiButtonFlags_None: c_int = 0;
pub const ImGuiButtonFlags_MouseButtonLeft: c_int = 1;
pub const ImGuiButtonFlags_MouseButtonRight: c_int = 2;
pub const ImGuiButtonFlags_MouseButtonMiddle: c_int = 4;
pub const ImGuiButtonFlags_MouseButtonMask_: c_int = 7;
pub const ImGuiButtonFlags_MouseButtonDefault_: c_int = 1;
pub const ImGuiButtonFlags_ = c_uint;
pub const ImGuiColorEditFlags_None: c_int = 0;
pub const ImGuiColorEditFlags_NoAlpha: c_int = 2;
pub const ImGuiColorEditFlags_NoPicker: c_int = 4;
pub const ImGuiColorEditFlags_NoOptions: c_int = 8;
pub const ImGuiColorEditFlags_NoSmallPreview: c_int = 16;
pub const ImGuiColorEditFlags_NoInputs: c_int = 32;
pub const ImGuiColorEditFlags_NoTooltip: c_int = 64;
pub const ImGuiColorEditFlags_NoLabel: c_int = 128;
pub const ImGuiColorEditFlags_NoSidePreview: c_int = 256;
pub const ImGuiColorEditFlags_NoDragDrop: c_int = 512;
pub const ImGuiColorEditFlags_NoBorder: c_int = 1024;
pub const ImGuiColorEditFlags_AlphaBar: c_int = 65536;
pub const ImGuiColorEditFlags_AlphaPreview: c_int = 131072;
pub const ImGuiColorEditFlags_AlphaPreviewHalf: c_int = 262144;
pub const ImGuiColorEditFlags_HDR: c_int = 524288;
pub const ImGuiColorEditFlags_DisplayRGB: c_int = 1048576;
pub const ImGuiColorEditFlags_DisplayHSV: c_int = 2097152;
pub const ImGuiColorEditFlags_DisplayHex: c_int = 4194304;
pub const ImGuiColorEditFlags_Uint8: c_int = 8388608;
pub const ImGuiColorEditFlags_Float: c_int = 16777216;
pub const ImGuiColorEditFlags_PickerHueBar: c_int = 33554432;
pub const ImGuiColorEditFlags_PickerHueWheel: c_int = 67108864;
pub const ImGuiColorEditFlags_InputRGB: c_int = 134217728;
pub const ImGuiColorEditFlags_InputHSV: c_int = 268435456;
pub const ImGuiColorEditFlags_DefaultOptions_: c_int = 177209344;
pub const ImGuiColorEditFlags_DisplayMask_: c_int = 7340032;
pub const ImGuiColorEditFlags_DataTypeMask_: c_int = 25165824;
pub const ImGuiColorEditFlags_PickerMask_: c_int = 100663296;
pub const ImGuiColorEditFlags_InputMask_: c_int = 402653184;
pub const ImGuiColorEditFlags_ = c_uint;
pub const ImGuiSliderFlags_None: c_int = 0;
pub const ImGuiSliderFlags_AlwaysClamp: c_int = 16;
pub const ImGuiSliderFlags_Logarithmic: c_int = 32;
pub const ImGuiSliderFlags_NoRoundToFormat: c_int = 64;
pub const ImGuiSliderFlags_NoInput: c_int = 128;
pub const ImGuiSliderFlags_InvalidMask_: c_int = 1879048207;
pub const ImGuiSliderFlags_ = c_uint;
pub const ImGuiMouseButton_Left: c_int = 0;
pub const ImGuiMouseButton_Right: c_int = 1;
pub const ImGuiMouseButton_Middle: c_int = 2;
pub const ImGuiMouseButton_COUNT: c_int = 5;
pub const ImGuiMouseButton_ = c_uint;
pub const ImGuiMouseCursor_None: c_int = -1;
pub const ImGuiMouseCursor_Arrow: c_int = 0;
pub const ImGuiMouseCursor_TextInput: c_int = 1;
pub const ImGuiMouseCursor_ResizeAll: c_int = 2;
pub const ImGuiMouseCursor_ResizeNS: c_int = 3;
pub const ImGuiMouseCursor_ResizeEW: c_int = 4;
pub const ImGuiMouseCursor_ResizeNESW: c_int = 5;
pub const ImGuiMouseCursor_ResizeNWSE: c_int = 6;
pub const ImGuiMouseCursor_Hand: c_int = 7;
pub const ImGuiMouseCursor_NotAllowed: c_int = 8;
pub const ImGuiMouseCursor_COUNT: c_int = 9;
pub const ImGuiMouseCursor_ = c_int;
pub const ImGuiCond_None: c_int = 0;
pub const ImGuiCond_Always: c_int = 1;
pub const ImGuiCond_Once: c_int = 2;
pub const ImGuiCond_FirstUseEver: c_int = 4;
pub const ImGuiCond_Appearing: c_int = 8;
pub const ImGuiCond_ = c_uint;
pub const ImDrawFlags_None: c_int = 0;
pub const ImDrawFlags_Closed: c_int = 1;
pub const ImDrawFlags_RoundCornersTopLeft: c_int = 16;
pub const ImDrawFlags_RoundCornersTopRight: c_int = 32;
pub const ImDrawFlags_RoundCornersBottomLeft: c_int = 64;
pub const ImDrawFlags_RoundCornersBottomRight: c_int = 128;
pub const ImDrawFlags_RoundCornersNone: c_int = 256;
pub const ImDrawFlags_RoundCornersTop: c_int = 48;
pub const ImDrawFlags_RoundCornersBottom: c_int = 192;
pub const ImDrawFlags_RoundCornersLeft: c_int = 80;
pub const ImDrawFlags_RoundCornersRight: c_int = 160;
pub const ImDrawFlags_RoundCornersAll: c_int = 240;
pub const ImDrawFlags_RoundCornersDefault_: c_int = 240;
pub const ImDrawFlags_RoundCornersMask_: c_int = 496;
pub const ImDrawFlags_ = c_uint;
pub const ImDrawListFlags_None: c_int = 0;
pub const ImDrawListFlags_AntiAliasedLines: c_int = 1;
pub const ImDrawListFlags_AntiAliasedLinesUseTex: c_int = 2;
pub const ImDrawListFlags_AntiAliasedFill: c_int = 4;
pub const ImDrawListFlags_AllowVtxOffset: c_int = 8;
pub const ImDrawListFlags_ = c_uint;
pub const ImFontAtlasFlags_None: c_int = 0;
pub const ImFontAtlasFlags_NoPowerOfTwoHeight: c_int = 1;
pub const ImFontAtlasFlags_NoMouseCursors: c_int = 2;
pub const ImFontAtlasFlags_NoBakedLines: c_int = 4;
pub const ImFontAtlasFlags_ = c_uint;
pub const ImGuiViewportFlags_None: c_int = 0;
pub const ImGuiViewportFlags_IsPlatformWindow: c_int = 1;
pub const ImGuiViewportFlags_IsPlatformMonitor: c_int = 2;
pub const ImGuiViewportFlags_OwnedByApp: c_int = 4;
pub const ImGuiViewportFlags_ = c_uint;
pub const ImGuiItemFlags_None: c_int = 0;
pub const ImGuiItemFlags_NoTabStop: c_int = 1;
pub const ImGuiItemFlags_ButtonRepeat: c_int = 2;
pub const ImGuiItemFlags_Disabled: c_int = 4;
pub const ImGuiItemFlags_NoNav: c_int = 8;
pub const ImGuiItemFlags_NoNavDefaultFocus: c_int = 16;
pub const ImGuiItemFlags_SelectableDontClosePopup: c_int = 32;
pub const ImGuiItemFlags_MixedValue: c_int = 64;
pub const ImGuiItemFlags_ReadOnly: c_int = 128;
pub const ImGuiItemFlags_Inputable: c_int = 256;
pub const ImGuiItemFlags_ = c_uint;
pub const ImGuiItemStatusFlags_None: c_int = 0;
pub const ImGuiItemStatusFlags_HoveredRect: c_int = 1;
pub const ImGuiItemStatusFlags_HasDisplayRect: c_int = 2;
pub const ImGuiItemStatusFlags_Edited: c_int = 4;
pub const ImGuiItemStatusFlags_ToggledSelection: c_int = 8;
pub const ImGuiItemStatusFlags_ToggledOpen: c_int = 16;
pub const ImGuiItemStatusFlags_HasDeactivated: c_int = 32;
pub const ImGuiItemStatusFlags_Deactivated: c_int = 64;
pub const ImGuiItemStatusFlags_HoveredWindow: c_int = 128;
pub const ImGuiItemStatusFlags_FocusedByTabbing: c_int = 256;
pub const ImGuiItemStatusFlags_ = c_uint;
pub const ImGuiInputTextFlags_Multiline: c_int = 67108864;
pub const ImGuiInputTextFlags_NoMarkEdited: c_int = 134217728;
pub const ImGuiInputTextFlags_MergedItem: c_int = 268435456;
pub const ImGuiInputTextFlagsPrivate_ = c_uint;
pub const ImGuiButtonFlags_PressedOnClick: c_int = 16;
pub const ImGuiButtonFlags_PressedOnClickRelease: c_int = 32;
pub const ImGuiButtonFlags_PressedOnClickReleaseAnywhere: c_int = 64;
pub const ImGuiButtonFlags_PressedOnRelease: c_int = 128;
pub const ImGuiButtonFlags_PressedOnDoubleClick: c_int = 256;
pub const ImGuiButtonFlags_PressedOnDragDropHold: c_int = 512;
pub const ImGuiButtonFlags_Repeat: c_int = 1024;
pub const ImGuiButtonFlags_FlattenChildren: c_int = 2048;
pub const ImGuiButtonFlags_AllowItemOverlap: c_int = 4096;
pub const ImGuiButtonFlags_DontClosePopups: c_int = 8192;
pub const ImGuiButtonFlags_AlignTextBaseLine: c_int = 32768;
pub const ImGuiButtonFlags_NoKeyModifiers: c_int = 65536;
pub const ImGuiButtonFlags_NoHoldingActiveId: c_int = 131072;
pub const ImGuiButtonFlags_NoNavFocus: c_int = 262144;
pub const ImGuiButtonFlags_NoHoveredOnFocus: c_int = 524288;
pub const ImGuiButtonFlags_PressedOnMask_: c_int = 1008;
pub const ImGuiButtonFlags_PressedOnDefault_: c_int = 32;
pub const ImGuiButtonFlagsPrivate_ = c_uint;
pub const ImGuiComboFlags_CustomPreview: c_int = 1048576;
pub const ImGuiComboFlagsPrivate_ = c_uint;
pub const ImGuiSliderFlags_Vertical: c_int = 1048576;
pub const ImGuiSliderFlags_ReadOnly: c_int = 2097152;
pub const ImGuiSliderFlagsPrivate_ = c_uint;
pub const ImGuiSelectableFlags_NoHoldingActiveID: c_int = 1048576;
pub const ImGuiSelectableFlags_SelectOnNav: c_int = 2097152;
pub const ImGuiSelectableFlags_SelectOnClick: c_int = 4194304;
pub const ImGuiSelectableFlags_SelectOnRelease: c_int = 8388608;
pub const ImGuiSelectableFlags_SpanAvailWidth: c_int = 16777216;
pub const ImGuiSelectableFlags_DrawHoveredWhenHeld: c_int = 33554432;
pub const ImGuiSelectableFlags_SetNavIdOnHover: c_int = 67108864;
pub const ImGuiSelectableFlags_NoPadWithHalfSpacing: c_int = 134217728;
pub const ImGuiSelectableFlagsPrivate_ = c_uint;
pub const ImGuiTreeNodeFlags_ClipLabelForTrailingButton: c_int = 1048576;
pub const ImGuiTreeNodeFlagsPrivate_ = c_uint;
pub const ImGuiSeparatorFlags_None: c_int = 0;
pub const ImGuiSeparatorFlags_Horizontal: c_int = 1;
pub const ImGuiSeparatorFlags_Vertical: c_int = 2;
pub const ImGuiSeparatorFlags_SpanAllColumns: c_int = 4;
pub const ImGuiSeparatorFlags_ = c_uint;
pub const ImGuiTextFlags_None: c_int = 0;
pub const ImGuiTextFlags_NoWidthForLargeClippedText: c_int = 1;
pub const ImGuiTextFlags_ = c_uint;
pub const ImGuiTooltipFlags_None: c_int = 0;
pub const ImGuiTooltipFlags_OverridePreviousTooltip: c_int = 1;
pub const ImGuiTooltipFlags_ = c_uint;
pub const ImGuiLayoutType_Horizontal: c_int = 0;
pub const ImGuiLayoutType_Vertical: c_int = 1;
pub const ImGuiLayoutType_ = c_uint;
pub const ImGuiLogType_None: c_int = 0;
pub const ImGuiLogType_TTY: c_int = 1;
pub const ImGuiLogType_File: c_int = 2;
pub const ImGuiLogType_Buffer: c_int = 3;
pub const ImGuiLogType_Clipboard: c_int = 4;
pub const ImGuiLogType = c_uint;
pub const ImGuiAxis_None: c_int = -1;
pub const ImGuiAxis_X: c_int = 0;
pub const ImGuiAxis_Y: c_int = 1;
pub const ImGuiAxis = c_int;
pub const ImGuiPlotType_Lines: c_int = 0;
pub const ImGuiPlotType_Histogram: c_int = 1;
pub const ImGuiPlotType = c_uint;
pub const ImGuiInputSource_None: c_int = 0;
pub const ImGuiInputSource_Mouse: c_int = 1;
pub const ImGuiInputSource_Keyboard: c_int = 2;
pub const ImGuiInputSource_Gamepad: c_int = 3;
pub const ImGuiInputSource_Nav: c_int = 4;
pub const ImGuiInputSource_Clipboard: c_int = 5;
pub const ImGuiInputSource_COUNT: c_int = 6;
pub const ImGuiInputSource = c_uint;
pub const ImGuiInputReadMode_Down: c_int = 0;
pub const ImGuiInputReadMode_Pressed: c_int = 1;
pub const ImGuiInputReadMode_Released: c_int = 2;
pub const ImGuiInputReadMode_Repeat: c_int = 3;
pub const ImGuiInputReadMode_RepeatSlow: c_int = 4;
pub const ImGuiInputReadMode_RepeatFast: c_int = 5;
pub const ImGuiInputReadMode = c_uint;
pub const ImGuiPopupPositionPolicy_Default: c_int = 0;
pub const ImGuiPopupPositionPolicy_ComboBox: c_int = 1;
pub const ImGuiPopupPositionPolicy_Tooltip: c_int = 2;
pub const ImGuiPopupPositionPolicy = c_uint;
pub const ImGuiDataType_String: c_int = 11;
pub const ImGuiDataType_Pointer: c_int = 12;
pub const ImGuiDataType_ID: c_int = 13;
pub const ImGuiDataTypePrivate_ = c_uint;
pub const ImGuiNextWindowDataFlags_None: c_int = 0;
pub const ImGuiNextWindowDataFlags_HasPos: c_int = 1;
pub const ImGuiNextWindowDataFlags_HasSize: c_int = 2;
pub const ImGuiNextWindowDataFlags_HasContentSize: c_int = 4;
pub const ImGuiNextWindowDataFlags_HasCollapsed: c_int = 8;
pub const ImGuiNextWindowDataFlags_HasSizeConstraint: c_int = 16;
pub const ImGuiNextWindowDataFlags_HasFocus: c_int = 32;
pub const ImGuiNextWindowDataFlags_HasBgAlpha: c_int = 64;
pub const ImGuiNextWindowDataFlags_HasScroll: c_int = 128;
pub const ImGuiNextWindowDataFlags_ = c_uint;
pub const ImGuiNextItemDataFlags_None: c_int = 0;
pub const ImGuiNextItemDataFlags_HasWidth: c_int = 1;
pub const ImGuiNextItemDataFlags_HasOpen: c_int = 2;
pub const ImGuiNextItemDataFlags_ = c_uint;
pub const ImGuiActivateFlags_None: c_int = 0;
pub const ImGuiActivateFlags_PreferInput: c_int = 1;
pub const ImGuiActivateFlags_PreferTweak: c_int = 2;
pub const ImGuiActivateFlags_TryToPreserveState: c_int = 4;
pub const ImGuiActivateFlags_ = c_uint;
pub const ImGuiScrollFlags_None: c_int = 0;
pub const ImGuiScrollFlags_KeepVisibleEdgeX: c_int = 1;
pub const ImGuiScrollFlags_KeepVisibleEdgeY: c_int = 2;
pub const ImGuiScrollFlags_KeepVisibleCenterX: c_int = 4;
pub const ImGuiScrollFlags_KeepVisibleCenterY: c_int = 8;
pub const ImGuiScrollFlags_AlwaysCenterX: c_int = 16;
pub const ImGuiScrollFlags_AlwaysCenterY: c_int = 32;
pub const ImGuiScrollFlags_NoScrollParent: c_int = 64;
pub const ImGuiScrollFlags_MaskX_: c_int = 21;
pub const ImGuiScrollFlags_MaskY_: c_int = 42;
pub const ImGuiScrollFlags_ = c_uint;
pub const ImGuiNavHighlightFlags_None: c_int = 0;
pub const ImGuiNavHighlightFlags_TypeDefault: c_int = 1;
pub const ImGuiNavHighlightFlags_TypeThin: c_int = 2;
pub const ImGuiNavHighlightFlags_AlwaysDraw: c_int = 4;
pub const ImGuiNavHighlightFlags_NoRounding: c_int = 8;
pub const ImGuiNavHighlightFlags_ = c_uint;
pub const ImGuiNavDirSourceFlags_None: c_int = 0;
pub const ImGuiNavDirSourceFlags_Keyboard: c_int = 1;
pub const ImGuiNavDirSourceFlags_PadDPad: c_int = 2;
pub const ImGuiNavDirSourceFlags_PadLStick: c_int = 4;
pub const ImGuiNavDirSourceFlags_ = c_uint;
pub const ImGuiNavMoveFlags_None: c_int = 0;
pub const ImGuiNavMoveFlags_LoopX: c_int = 1;
pub const ImGuiNavMoveFlags_LoopY: c_int = 2;
pub const ImGuiNavMoveFlags_WrapX: c_int = 4;
pub const ImGuiNavMoveFlags_WrapY: c_int = 8;
pub const ImGuiNavMoveFlags_AllowCurrentNavId: c_int = 16;
pub const ImGuiNavMoveFlags_AlsoScoreVisibleSet: c_int = 32;
pub const ImGuiNavMoveFlags_ScrollToEdgeY: c_int = 64;
pub const ImGuiNavMoveFlags_Forwarded: c_int = 128;
pub const ImGuiNavMoveFlags_DebugNoResult: c_int = 256;
pub const ImGuiNavMoveFlags_Tabbing: c_int = 512;
pub const ImGuiNavMoveFlags_Activate: c_int = 1024;
pub const ImGuiNavMoveFlags_DontSetNavHighlight: c_int = 2048;
pub const ImGuiNavMoveFlags_ = c_uint;
pub const ImGuiNavLayer_Main: c_int = 0;
pub const ImGuiNavLayer_Menu: c_int = 1;
pub const ImGuiNavLayer_COUNT: c_int = 2;
pub const ImGuiNavLayer = c_uint;
pub const ImGuiOldColumnFlags_None: c_int = 0;
pub const ImGuiOldColumnFlags_NoBorder: c_int = 1;
pub const ImGuiOldColumnFlags_NoResize: c_int = 2;
pub const ImGuiOldColumnFlags_NoPreserveWidths: c_int = 4;
pub const ImGuiOldColumnFlags_NoForceWithinWindow: c_int = 8;
pub const ImGuiOldColumnFlags_GrowParentContentsSize: c_int = 16;
pub const ImGuiOldColumnFlags_ = c_uint;
pub const ImGuiContextHookType_NewFramePre: c_int = 0;
pub const ImGuiContextHookType_NewFramePost: c_int = 1;
pub const ImGuiContextHookType_EndFramePre: c_int = 2;
pub const ImGuiContextHookType_EndFramePost: c_int = 3;
pub const ImGuiContextHookType_RenderPre: c_int = 4;
pub const ImGuiContextHookType_RenderPost: c_int = 5;
pub const ImGuiContextHookType_Shutdown: c_int = 6;
pub const ImGuiContextHookType_PendingRemoval_: c_int = 7;
pub const ImGuiContextHookType = c_uint;
pub const ImGuiTabBarFlags_DockNode: c_int = 1048576;
pub const ImGuiTabBarFlags_IsFocused: c_int = 2097152;
pub const ImGuiTabBarFlags_SaveSettings: c_int = 4194304;
pub const ImGuiTabBarFlagsPrivate_ = c_uint;
pub const ImGuiTabItemFlags_SectionMask_: c_int = 192;
pub const ImGuiTabItemFlags_NoCloseButton: c_int = 1048576;
pub const ImGuiTabItemFlags_Button: c_int = 2097152;
pub const ImGuiTabItemFlagsPrivate_ = c_uint;
pub extern fn ImVec2_ImVec2_Nil() [*c]ImVec2;
pub extern fn ImVec2_destroy(self: [*c]ImVec2) void;
pub extern fn ImVec2_ImVec2_Float(_x: f32, _y: f32) [*c]ImVec2;
pub extern fn ImVec4_ImVec4_Nil() [*c]ImVec4;
pub extern fn ImVec4_destroy(self: [*c]ImVec4) void;
pub extern fn ImVec4_ImVec4_Float(_x: f32, _y: f32, _z: f32, _w: f32) [*c]ImVec4;
pub extern fn igCreateContext(shared_font_atlas: [*c]ImFontAtlas) [*c]ImGuiContext;
pub extern fn igDestroyContext(ctx: [*c]ImGuiContext) void;
pub extern fn igGetCurrentContext() [*c]ImGuiContext;
pub extern fn igSetCurrentContext(ctx: [*c]ImGuiContext) void;
pub extern fn igGetIO() [*c]ImGuiIO;
pub extern fn igGetStyle() [*c]ImGuiStyle;
pub extern fn igNewFrame() void;
pub extern fn igEndFrame() void;
pub extern fn igRender() void;
pub extern fn igGetDrawData() [*c]ImDrawData;
pub extern fn igShowDemoWindow(p_open: [*c]bool) void;
pub extern fn igShowMetricsWindow(p_open: [*c]bool) void;
pub extern fn igShowStackToolWindow(p_open: [*c]bool) void;
pub extern fn igShowAboutWindow(p_open: [*c]bool) void;
pub extern fn igShowStyleEditor(ref: [*c]ImGuiStyle) void;
pub extern fn igShowStyleSelector(label: [*c]const u8) bool;
pub extern fn igShowFontSelector(label: [*c]const u8) void;
pub extern fn igShowUserGuide() void;
pub extern fn igGetVersion() [*c]const u8;
pub extern fn igStyleColorsDark(dst: [*c]ImGuiStyle) void;
pub extern fn igStyleColorsLight(dst: [*c]ImGuiStyle) void;
pub extern fn igStyleColorsClassic(dst: [*c]ImGuiStyle) void;
pub extern fn igBegin(name: [*c]const u8, p_open: [*c]bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEnd() void;
pub extern fn igBeginChild_Str(str_id: [*c]const u8, size: ImVec2, border: bool, flags: ImGuiWindowFlags) bool;
pub extern fn igBeginChild_ID(id: ImGuiID, size: ImVec2, border: bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEndChild() void;
pub extern fn igIsWindowAppearing() bool;
pub extern fn igIsWindowCollapsed() bool;
pub extern fn igIsWindowFocused(flags: ImGuiFocusedFlags) bool;
pub extern fn igIsWindowHovered(flags: ImGuiHoveredFlags) bool;
pub extern fn igGetWindowDrawList() [*c]ImDrawList;
pub extern fn igGetWindowPos(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowSize(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowWidth() f32;
pub extern fn igGetWindowHeight() f32;
pub extern fn igSetNextWindowPos(pos: ImVec2, cond: ImGuiCond, pivot: ImVec2) void;
pub extern fn igSetNextWindowSize(size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetNextWindowSizeConstraints(size_min: ImVec2, size_max: ImVec2, custom_callback: ImGuiSizeCallback, custom_callback_data: ?*anyopaque) void;
pub extern fn igSetNextWindowContentSize(size: ImVec2) void;
pub extern fn igSetNextWindowCollapsed(collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetNextWindowFocus() void;
pub extern fn igSetNextWindowBgAlpha(alpha: f32) void;
pub extern fn igSetWindowPos_Vec2(pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSize_Vec2(size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsed_Bool(collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowFocus_Nil() void;
pub extern fn igSetWindowFontScale(scale: f32) void;
pub extern fn igSetWindowPos_Str(name: [*c]const u8, pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSize_Str(name: [*c]const u8, size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsed_Str(name: [*c]const u8, collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowFocus_Str(name: [*c]const u8) void;
pub extern fn igGetContentRegionAvail(pOut: [*c]ImVec2) void;
pub extern fn igGetContentRegionMax(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowContentRegionMin(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowContentRegionMax(pOut: [*c]ImVec2) void;
pub extern fn igGetScrollX() f32;
pub extern fn igGetScrollY() f32;
pub extern fn igSetScrollX_Float(scroll_x: f32) void;
pub extern fn igSetScrollY_Float(scroll_y: f32) void;
pub extern fn igGetScrollMaxX() f32;
pub extern fn igGetScrollMaxY() f32;
pub extern fn igSetScrollHereX(center_x_ratio: f32) void;
pub extern fn igSetScrollHereY(center_y_ratio: f32) void;
pub extern fn igSetScrollFromPosX_Float(local_x: f32, center_x_ratio: f32) void;
pub extern fn igSetScrollFromPosY_Float(local_y: f32, center_y_ratio: f32) void;
pub extern fn igPushFont(font: [*c]ImFont) void;
pub extern fn igPopFont() void;
pub extern fn igPushStyleColor_U32(idx: ImGuiCol, col: ImU32) void;
pub extern fn igPushStyleColor_Vec4(idx: ImGuiCol, col: ImVec4) void;
pub extern fn igPopStyleColor(count: c_int) void;
pub extern fn igPushStyleVar_Float(idx: ImGuiStyleVar, val: f32) void;
pub extern fn igPushStyleVar_Vec2(idx: ImGuiStyleVar, val: ImVec2) void;
pub extern fn igPopStyleVar(count: c_int) void;
pub extern fn igPushAllowKeyboardFocus(allow_keyboard_focus: bool) void;
pub extern fn igPopAllowKeyboardFocus() void;
pub extern fn igPushButtonRepeat(repeat: bool) void;
pub extern fn igPopButtonRepeat() void;
pub extern fn igPushItemWidth(item_width: f32) void;
pub extern fn igPopItemWidth() void;
pub extern fn igSetNextItemWidth(item_width: f32) void;
pub extern fn igCalcItemWidth() f32;
pub extern fn igPushTextWrapPos(wrap_local_pos_x: f32) void;
pub extern fn igPopTextWrapPos() void;
pub extern fn igGetFont() [*c]ImFont;
pub extern fn igGetFontSize() f32;
pub extern fn igGetFontTexUvWhitePixel(pOut: [*c]ImVec2) void;
pub extern fn igGetColorU32_Col(idx: ImGuiCol, alpha_mul: f32) ImU32;
pub extern fn igGetColorU32_Vec4(col: ImVec4) ImU32;
pub extern fn igGetColorU32_U32(col: ImU32) ImU32;
pub extern fn igGetStyleColorVec4(idx: ImGuiCol) [*c]const ImVec4;
pub extern fn igSeparator() void;
pub extern fn igSameLine(offset_from_start_x: f32, spacing: f32) void;
pub extern fn igNewLine() void;
pub extern fn igSpacing() void;
pub extern fn igDummy(size: ImVec2) void;
pub extern fn igIndent(indent_w: f32) void;
pub extern fn igUnindent(indent_w: f32) void;
pub extern fn igBeginGroup() void;
pub extern fn igEndGroup() void;
pub extern fn igGetCursorPos(pOut: [*c]ImVec2) void;
pub extern fn igGetCursorPosX() f32;
pub extern fn igGetCursorPosY() f32;
pub extern fn igSetCursorPos(local_pos: ImVec2) void;
pub extern fn igSetCursorPosX(local_x: f32) void;
pub extern fn igSetCursorPosY(local_y: f32) void;
pub extern fn igGetCursorStartPos(pOut: [*c]ImVec2) void;
pub extern fn igGetCursorScreenPos(pOut: [*c]ImVec2) void;
pub extern fn igSetCursorScreenPos(pos: ImVec2) void;
pub extern fn igAlignTextToFramePadding() void;
pub extern fn igGetTextLineHeight() f32;
pub extern fn igGetTextLineHeightWithSpacing() f32;
pub extern fn igGetFrameHeight() f32;
pub extern fn igGetFrameHeightWithSpacing() f32;
pub extern fn igPushID_Str(str_id: [*c]const u8) void;
pub extern fn igPushID_StrStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) void;
pub extern fn igPushID_Ptr(ptr_id: ?*const anyopaque) void;
pub extern fn igPushID_Int(int_id: c_int) void;
pub extern fn igPopID() void;
pub extern fn igGetID_Str(str_id: [*c]const u8) ImGuiID;
pub extern fn igGetID_StrStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) ImGuiID;
pub extern fn igGetID_Ptr(ptr_id: ?*const anyopaque) ImGuiID;
pub extern fn igTextUnformatted(text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn igText(fmt: [*c]const u8, ...) void;
pub extern fn igTextColored(col: ImVec4, fmt: [*c]const u8, ...) void;
pub extern fn igTextDisabled(fmt: [*c]const u8, ...) void;
pub extern fn igTextWrapped(fmt: [*c]const u8, ...) void;
pub extern fn igLabelText(label: [*c]const u8, fmt: [*c]const u8, ...) void;
pub extern fn igBulletText(fmt: [*c]const u8, ...) void;
pub extern fn igButton(label: [*c]const u8, size: ImVec2) bool;
pub extern fn igSmallButton(label: [*c]const u8) bool;
pub extern fn igInvisibleButton(str_id: [*c]const u8, size: ImVec2, flags: ImGuiButtonFlags) bool;
pub extern fn igArrowButton(str_id: [*c]const u8, dir: ImGuiDir) bool;
pub extern fn igImage(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2, uv1: ImVec2, tint_col: ImVec4, border_col: ImVec4) void;
pub extern fn igImageButton(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2, uv1: ImVec2, frame_padding: c_int, bg_col: ImVec4, tint_col: ImVec4) bool;
pub extern fn igCheckbox(label: [*c]const u8, v: [*c]bool) bool;
pub extern fn igCheckboxFlags_IntPtr(label: [*c]const u8, flags: [*c]c_int, flags_value: c_int) bool;
pub extern fn igCheckboxFlags_UintPtr(label: [*c]const u8, flags: [*c]c_uint, flags_value: c_uint) bool;
pub extern fn igRadioButton_Bool(label: [*c]const u8, active: bool) bool;
pub extern fn igRadioButton_IntPtr(label: [*c]const u8, v: [*c]c_int, v_button: c_int) bool;
pub extern fn igProgressBar(fraction: f32, size_arg: ImVec2, overlay: [*c]const u8) void;
pub extern fn igBullet() void;
pub extern fn igBeginCombo(label: [*c]const u8, preview_value: [*c]const u8, flags: ImGuiComboFlags) bool;
pub extern fn igEndCombo() void;
pub extern fn igCombo_Str_arr(label: [*c]const u8, current_item: [*c]c_int, items: [*c]const [*c]const u8, items_count: c_int, popup_max_height_in_items: c_int) bool;
pub extern fn igCombo_Str(label: [*c]const u8, current_item: [*c]c_int, items_separated_by_zeros: [*c]const u8, popup_max_height_in_items: c_int) bool;
pub extern fn igCombo_FnBoolPtr(label: [*c]const u8, current_item: [*c]c_int, items_getter: ?fn (?*anyopaque, c_int, [*c][*c]const u8) callconv(.C) bool, data: ?*anyopaque, items_count: c_int, popup_max_height_in_items: c_int) bool;
pub extern fn igDragFloat(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat2(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat3(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat4(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloatRange2(label: [*c]const u8, v_current_min: [*c]f32, v_current_max: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, format_max: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt2(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt3(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt4(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragIntRange2(label: [*c]const u8, v_current_min: [*c]c_int, v_current_max: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, format_max: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat2(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat3(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat4(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderAngle(label: [*c]const u8, v_rad: [*c]f32, v_degrees_min: f32, v_degrees_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt2(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt3(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt4(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderFloat(label: [*c]const u8, size: ImVec2, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderInt(label: [*c]const u8, size: ImVec2, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderScalar(label: [*c]const u8, size: ImVec2, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igInputText(label: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputTextMultiline(label: [*c]const u8, buf: [*c]u8, buf_size: usize, size: ImVec2, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputTextWithHint(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputFloat(label: [*c]const u8, v: [*c]f32, step: f32, step_fast: f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat2(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat3(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat4(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt(label: [*c]const u8, v: [*c]c_int, step: c_int, step_fast: c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt2(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt3(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt4(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputDouble(label: [*c]const u8, v: [*c]f64, step: f64, step_fast: f64, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, p_step: ?*const anyopaque, p_step_fast: ?*const anyopaque, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, p_step: ?*const anyopaque, p_step_fast: ?*const anyopaque, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igColorEdit3(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorEdit4(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorPicker3(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorPicker4(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags, ref_col: [*c]const f32) bool;
pub extern fn igColorButton(desc_id: [*c]const u8, col: ImVec4, flags: ImGuiColorEditFlags, size: ImVec2) bool;
pub extern fn igSetColorEditOptions(flags: ImGuiColorEditFlags) void;
pub extern fn igTreeNode_Str(label: [*c]const u8) bool;
pub extern fn igTreeNode_StrStr(str_id: [*c]const u8, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNode_Ptr(ptr_id: ?*const anyopaque, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeEx_Str(label: [*c]const u8, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igTreeNodeEx_StrStr(str_id: [*c]const u8, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeEx_Ptr(ptr_id: ?*const anyopaque, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, ...) bool;
pub extern fn igTreePush_Str(str_id: [*c]const u8) void;
pub extern fn igTreePush_Ptr(ptr_id: ?*const anyopaque) void;
pub extern fn igTreePop() void;
pub extern fn igGetTreeNodeToLabelSpacing() f32;
pub extern fn igCollapsingHeader_TreeNodeFlags(label: [*c]const u8, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igCollapsingHeader_BoolPtr(label: [*c]const u8, p_visible: [*c]bool, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igSetNextItemOpen(is_open: bool, cond: ImGuiCond) void;
pub extern fn igSelectable_Bool(label: [*c]const u8, selected: bool, flags: ImGuiSelectableFlags, size: ImVec2) bool;
pub extern fn igSelectable_BoolPtr(label: [*c]const u8, p_selected: [*c]bool, flags: ImGuiSelectableFlags, size: ImVec2) bool;
pub extern fn igBeginListBox(label: [*c]const u8, size: ImVec2) bool;
pub extern fn igEndListBox() void;
pub extern fn igListBox_Str_arr(label: [*c]const u8, current_item: [*c]c_int, items: [*c]const [*c]const u8, items_count: c_int, height_in_items: c_int) bool;
pub extern fn igListBox_FnBoolPtr(label: [*c]const u8, current_item: [*c]c_int, items_getter: ?fn (?*anyopaque, c_int, [*c][*c]const u8) callconv(.C) bool, data: ?*anyopaque, items_count: c_int, height_in_items: c_int) bool;
pub extern fn igPlotLines_FloatPtr(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2, stride: c_int) void;
pub extern fn igPlotLines_FnFloatPtr(label: [*c]const u8, values_getter: ?fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2) void;
pub extern fn igPlotHistogram_FloatPtr(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2, stride: c_int) void;
pub extern fn igPlotHistogram_FnFloatPtr(label: [*c]const u8, values_getter: ?fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2) void;
pub extern fn igValue_Bool(prefix: [*c]const u8, b: bool) void;
pub extern fn igValue_Int(prefix: [*c]const u8, v: c_int) void;
pub extern fn igValue_Uint(prefix: [*c]const u8, v: c_uint) void;
pub extern fn igValue_Float(prefix: [*c]const u8, v: f32, float_format: [*c]const u8) void;
pub extern fn igBeginMenuBar() bool;
pub extern fn igEndMenuBar() void;
pub extern fn igBeginMainMenuBar() bool;
pub extern fn igEndMainMenuBar() void;
pub extern fn igBeginMenu(label: [*c]const u8, enabled: bool) bool;
pub extern fn igEndMenu() void;
pub extern fn igMenuItem_Bool(label: [*c]const u8, shortcut: [*c]const u8, selected: bool, enabled: bool) bool;
pub extern fn igMenuItem_BoolPtr(label: [*c]const u8, shortcut: [*c]const u8, p_selected: [*c]bool, enabled: bool) bool;
pub extern fn igBeginTooltip() void;
pub extern fn igEndTooltip() void;
pub extern fn igSetTooltip(fmt: [*c]const u8, ...) void;
pub extern fn igBeginPopup(str_id: [*c]const u8, flags: ImGuiWindowFlags) bool;
pub extern fn igBeginPopupModal(name: [*c]const u8, p_open: [*c]bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEndPopup() void;
pub extern fn igOpenPopup_Str(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) void;
pub extern fn igOpenPopup_ID(id: ImGuiID, popup_flags: ImGuiPopupFlags) void;
pub extern fn igOpenPopupOnItemClick(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) void;
pub extern fn igCloseCurrentPopup() void;
pub extern fn igBeginPopupContextItem(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupContextWindow(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupContextVoid(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igIsPopupOpen_Str(str_id: [*c]const u8, flags: ImGuiPopupFlags) bool;
pub extern fn igBeginTable(str_id: [*c]const u8, column: c_int, flags: ImGuiTableFlags, outer_size: ImVec2, inner_width: f32) bool;
pub extern fn igEndTable() void;
pub extern fn igTableNextRow(row_flags: ImGuiTableRowFlags, min_row_height: f32) void;
pub extern fn igTableNextColumn() bool;
pub extern fn igTableSetColumnIndex(column_n: c_int) bool;
pub extern fn igTableSetupColumn(label: [*c]const u8, flags: ImGuiTableColumnFlags, init_width_or_weight: f32, user_id: ImGuiID) void;
pub extern fn igTableSetupScrollFreeze(cols: c_int, rows: c_int) void;
pub extern fn igTableHeadersRow() void;
pub extern fn igTableHeader(label: [*c]const u8) void;
pub extern fn igTableGetSortSpecs() [*c]ImGuiTableSortSpecs;
pub extern fn igTableGetColumnCount() c_int;
pub extern fn igTableGetColumnIndex() c_int;
pub extern fn igTableGetRowIndex() c_int;
pub extern fn igTableGetColumnName_Int(column_n: c_int) [*c]const u8;
pub extern fn igTableGetColumnFlags(column_n: c_int) ImGuiTableColumnFlags;
pub extern fn igTableSetColumnEnabled(column_n: c_int, v: bool) void;
pub extern fn igTableSetBgColor(target: ImGuiTableBgTarget, color: ImU32, column_n: c_int) void;
pub extern fn igColumns(count: c_int, id: [*c]const u8, border: bool) void;
pub extern fn igNextColumn() void;
pub extern fn igGetColumnIndex() c_int;
pub extern fn igGetColumnWidth(column_index: c_int) f32;
pub extern fn igSetColumnWidth(column_index: c_int, width: f32) void;
pub extern fn igGetColumnOffset(column_index: c_int) f32;
pub extern fn igSetColumnOffset(column_index: c_int, offset_x: f32) void;
pub extern fn igGetColumnsCount() c_int;
pub extern fn igBeginTabBar(str_id: [*c]const u8, flags: ImGuiTabBarFlags) bool;
pub extern fn igEndTabBar() void;
pub extern fn igBeginTabItem(label: [*c]const u8, p_open: [*c]bool, flags: ImGuiTabItemFlags) bool;
pub extern fn igEndTabItem() void;
pub extern fn igTabItemButton(label: [*c]const u8, flags: ImGuiTabItemFlags) bool;
pub extern fn igSetTabItemClosed(tab_or_docked_window_label: [*c]const u8) void;
pub extern fn igLogToTTY(auto_open_depth: c_int) void;
pub extern fn igLogToFile(auto_open_depth: c_int, filename: [*c]const u8) void;
pub extern fn igLogToClipboard(auto_open_depth: c_int) void;
pub extern fn igLogFinish() void;
pub extern fn igLogButtons() void;
pub extern fn igBeginDragDropSource(flags: ImGuiDragDropFlags) bool;
pub extern fn igSetDragDropPayload(@"type": [*c]const u8, data: ?*const anyopaque, sz: usize, cond: ImGuiCond) bool;
pub extern fn igEndDragDropSource() void;
pub extern fn igBeginDragDropTarget() bool;
pub extern fn igAcceptDragDropPayload(@"type": [*c]const u8, flags: ImGuiDragDropFlags) [*c]const ImGuiPayload;
pub extern fn igEndDragDropTarget() void;
pub extern fn igGetDragDropPayload() [*c]const ImGuiPayload;
pub extern fn igBeginDisabled(disabled: bool) void;
pub extern fn igEndDisabled() void;
pub extern fn igPushClipRect(clip_rect_min: ImVec2, clip_rect_max: ImVec2, intersect_with_current_clip_rect: bool) void;
pub extern fn igPopClipRect() void;
pub extern fn igSetItemDefaultFocus() void;
pub extern fn igSetKeyboardFocusHere(offset: c_int) void;
pub extern fn igIsItemHovered(flags: ImGuiHoveredFlags) bool;
pub extern fn igIsItemActive() bool;
pub extern fn igIsItemFocused() bool;
pub extern fn igIsItemClicked(mouse_button: ImGuiMouseButton) bool;
pub extern fn igIsItemVisible() bool;
pub extern fn igIsItemEdited() bool;
pub extern fn igIsItemActivated() bool;
pub extern fn igIsItemDeactivated() bool;
pub extern fn igIsItemDeactivatedAfterEdit() bool;
pub extern fn igIsItemToggledOpen() bool;
pub extern fn igIsAnyItemHovered() bool;
pub extern fn igIsAnyItemActive() bool;
pub extern fn igIsAnyItemFocused() bool;
pub extern fn igGetItemRectMin(pOut: [*c]ImVec2) void;
pub extern fn igGetItemRectMax(pOut: [*c]ImVec2) void;
pub extern fn igGetItemRectSize(pOut: [*c]ImVec2) void;
pub extern fn igSetItemAllowOverlap() void;
pub extern fn igGetMainViewport() [*c]ImGuiViewport;
pub extern fn igIsRectVisible_Nil(size: ImVec2) bool;
pub extern fn igIsRectVisible_Vec2(rect_min: ImVec2, rect_max: ImVec2) bool;
pub extern fn igGetTime() f64;
pub extern fn igGetFrameCount() c_int;
pub extern fn igGetBackgroundDrawList_Nil() [*c]ImDrawList;
pub extern fn igGetForegroundDrawList_Nil() [*c]ImDrawList;
pub extern fn igGetDrawListSharedData() [*c]ImDrawListSharedData;
pub extern fn igGetStyleColorName(idx: ImGuiCol) [*c]const u8;
pub extern fn igSetStateStorage(storage: [*c]ImGuiStorage) void;
pub extern fn igGetStateStorage() [*c]ImGuiStorage;
pub extern fn igCalcListClipping(items_count: c_int, items_height: f32, out_items_display_start: [*c]c_int, out_items_display_end: [*c]c_int) void;
pub extern fn igBeginChildFrame(id: ImGuiID, size: ImVec2, flags: ImGuiWindowFlags) bool;
pub extern fn igEndChildFrame() void;
pub extern fn igCalcTextSize(pOut: [*c]ImVec2, text: [*c]const u8, text_end: [*c]const u8, hide_text_after_double_hash: bool, wrap_width: f32) void;
pub extern fn igColorConvertU32ToFloat4(pOut: [*c]ImVec4, in: ImU32) void;
pub extern fn igColorConvertFloat4ToU32(in: ImVec4) ImU32;
pub extern fn igColorConvertRGBtoHSV(r: f32, g: f32, b: f32, out_h: [*c]f32, out_s: [*c]f32, out_v: [*c]f32) void;
pub extern fn igColorConvertHSVtoRGB(h: f32, s: f32, v: f32, out_r: [*c]f32, out_g: [*c]f32, out_b: [*c]f32) void;
pub extern fn igGetKeyIndex(imgui_key: ImGuiKey) c_int;
pub extern fn igIsKeyDown(user_key_index: c_int) bool;
pub extern fn igIsKeyPressed(user_key_index: c_int, repeat: bool) bool;
pub extern fn igIsKeyReleased(user_key_index: c_int) bool;
pub extern fn igGetKeyPressedAmount(key_index: c_int, repeat_delay: f32, rate: f32) c_int;
pub extern fn igCaptureKeyboardFromApp(want_capture_keyboard_value: bool) void;
pub extern fn igIsMouseDown(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseClicked(button: ImGuiMouseButton, repeat: bool) bool;
pub extern fn igIsMouseReleased(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseDoubleClicked(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseHoveringRect(r_min: ImVec2, r_max: ImVec2, clip: bool) bool;
pub extern fn igIsMousePosValid(mouse_pos: [*c]const ImVec2) bool;
pub extern fn igIsAnyMouseDown() bool;
pub extern fn igGetMousePos(pOut: [*c]ImVec2) void;
pub extern fn igGetMousePosOnOpeningCurrentPopup(pOut: [*c]ImVec2) void;
pub extern fn igIsMouseDragging(button: ImGuiMouseButton, lock_threshold: f32) bool;
pub extern fn igGetMouseDragDelta(pOut: [*c]ImVec2, button: ImGuiMouseButton, lock_threshold: f32) void;
pub extern fn igResetMouseDragDelta(button: ImGuiMouseButton) void;
pub extern fn igGetMouseCursor() ImGuiMouseCursor;
pub extern fn igSetMouseCursor(cursor_type: ImGuiMouseCursor) void;
pub extern fn igCaptureMouseFromApp(want_capture_mouse_value: bool) void;
pub extern fn igGetClipboardText() [*c]const u8;
pub extern fn igSetClipboardText(text: [*c]const u8) void;
pub extern fn igLoadIniSettingsFromDisk(ini_filename: [*c]const u8) void;
pub extern fn igLoadIniSettingsFromMemory(ini_data: [*c]const u8, ini_size: usize) void;
pub extern fn igSaveIniSettingsToDisk(ini_filename: [*c]const u8) void;
pub extern fn igSaveIniSettingsToMemory(out_ini_size: [*c]usize) [*c]const u8;
pub extern fn igDebugCheckVersionAndDataLayout(version_str: [*c]const u8, sz_io: usize, sz_style: usize, sz_vec2: usize, sz_vec4: usize, sz_drawvert: usize, sz_drawidx: usize) bool;
pub extern fn igSetAllocatorFunctions(alloc_func: ImGuiMemAllocFunc, free_func: ImGuiMemFreeFunc, user_data: ?*anyopaque) void;
pub extern fn igGetAllocatorFunctions(p_alloc_func: [*c]ImGuiMemAllocFunc, p_free_func: [*c]ImGuiMemFreeFunc, p_user_data: [*c]?*anyopaque) void;
pub extern fn igMemAlloc(size: usize) ?*anyopaque;
pub extern fn igMemFree(ptr: ?*anyopaque) void;
pub extern fn ImGuiStyle_ImGuiStyle() [*c]ImGuiStyle;
pub extern fn ImGuiStyle_destroy(self: [*c]ImGuiStyle) void;
pub extern fn ImGuiStyle_ScaleAllSizes(self: [*c]ImGuiStyle, scale_factor: f32) void;
pub extern fn ImGuiIO_AddInputCharacter(self: [*c]ImGuiIO, c: c_uint) void;
pub extern fn ImGuiIO_AddInputCharacterUTF16(self: [*c]ImGuiIO, c: ImWchar16) void;
pub extern fn ImGuiIO_AddInputCharactersUTF8(self: [*c]ImGuiIO, str: [*c]const u8) void;
pub extern fn ImGuiIO_AddFocusEvent(self: [*c]ImGuiIO, focused: bool) void;
pub extern fn ImGuiIO_ClearInputCharacters(self: [*c]ImGuiIO) void;
pub extern fn ImGuiIO_ClearInputKeys(self: [*c]ImGuiIO) void;
pub extern fn ImGuiIO_ImGuiIO() [*c]ImGuiIO;
pub extern fn ImGuiIO_destroy(self: [*c]ImGuiIO) void;
pub extern fn ImGuiInputTextCallbackData_ImGuiInputTextCallbackData() [*c]ImGuiInputTextCallbackData;
pub extern fn ImGuiInputTextCallbackData_destroy(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_DeleteChars(self: [*c]ImGuiInputTextCallbackData, pos: c_int, bytes_count: c_int) void;
pub extern fn ImGuiInputTextCallbackData_InsertChars(self: [*c]ImGuiInputTextCallbackData, pos: c_int, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImGuiInputTextCallbackData_SelectAll(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_ClearSelection(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_HasSelection(self: [*c]ImGuiInputTextCallbackData) bool;
pub extern fn ImGuiPayload_ImGuiPayload() [*c]ImGuiPayload;
pub extern fn ImGuiPayload_destroy(self: [*c]ImGuiPayload) void;
pub extern fn ImGuiPayload_Clear(self: [*c]ImGuiPayload) void;
pub extern fn ImGuiPayload_IsDataType(self: [*c]ImGuiPayload, @"type": [*c]const u8) bool;
pub extern fn ImGuiPayload_IsPreview(self: [*c]ImGuiPayload) bool;
pub extern fn ImGuiPayload_IsDelivery(self: [*c]ImGuiPayload) bool;
pub extern fn ImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs() ?*ImGuiTableColumnSortSpecs;
pub extern fn ImGuiTableColumnSortSpecs_destroy(self: ?*ImGuiTableColumnSortSpecs) void;
pub extern fn ImGuiTableSortSpecs_ImGuiTableSortSpecs() [*c]ImGuiTableSortSpecs;
pub extern fn ImGuiTableSortSpecs_destroy(self: [*c]ImGuiTableSortSpecs) void;
pub extern fn ImGuiOnceUponAFrame_ImGuiOnceUponAFrame() [*c]ImGuiOnceUponAFrame;
pub extern fn ImGuiOnceUponAFrame_destroy(self: [*c]ImGuiOnceUponAFrame) void;
pub extern fn ImGuiTextFilter_ImGuiTextFilter(default_filter: [*c]const u8) [*c]ImGuiTextFilter;
pub extern fn ImGuiTextFilter_destroy(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_Draw(self: [*c]ImGuiTextFilter, label: [*c]const u8, width: f32) bool;
pub extern fn ImGuiTextFilter_PassFilter(self: [*c]ImGuiTextFilter, text: [*c]const u8, text_end: [*c]const u8) bool;
pub extern fn ImGuiTextFilter_Build(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_Clear(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_IsActive(self: [*c]ImGuiTextFilter) bool;
pub extern fn ImGuiTextRange_ImGuiTextRange_Nil() [*c]ImGuiTextRange;
pub extern fn ImGuiTextRange_destroy(self: [*c]ImGuiTextRange) void;
pub extern fn ImGuiTextRange_ImGuiTextRange_Str(_b: [*c]const u8, _e: [*c]const u8) [*c]ImGuiTextRange;
pub extern fn ImGuiTextRange_empty(self: [*c]ImGuiTextRange) bool;
pub extern fn ImGuiTextRange_split(self: [*c]ImGuiTextRange, separator: u8, out: [*c]ImVector_ImGuiTextRange) void;
pub extern fn ImGuiTextBuffer_ImGuiTextBuffer() [*c]ImGuiTextBuffer;
pub extern fn ImGuiTextBuffer_destroy(self: [*c]ImGuiTextBuffer) void;
pub extern fn ImGuiTextBuffer_begin(self: [*c]ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_end(self: [*c]ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_size(self: [*c]ImGuiTextBuffer) c_int;
pub extern fn ImGuiTextBuffer_empty(self: [*c]ImGuiTextBuffer) bool;
pub extern fn ImGuiTextBuffer_clear(self: [*c]ImGuiTextBuffer) void;
pub extern fn ImGuiTextBuffer_reserve(self: [*c]ImGuiTextBuffer, capacity: c_int) void;
pub extern fn ImGuiTextBuffer_c_str(self: [*c]ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_append(self: [*c]ImGuiTextBuffer, str: [*c]const u8, str_end: [*c]const u8) void;
pub extern fn ImGuiStoragePair_ImGuiStoragePair_Int(_key: ImGuiID, _val_i: c_int) [*c]ImGuiStoragePair;
pub extern fn ImGuiStoragePair_destroy(self: [*c]ImGuiStoragePair) void;
pub extern fn ImGuiStoragePair_ImGuiStoragePair_Float(_key: ImGuiID, _val_f: f32) [*c]ImGuiStoragePair;
pub extern fn ImGuiStoragePair_ImGuiStoragePair_Ptr(_key: ImGuiID, _val_p: ?*anyopaque) [*c]ImGuiStoragePair;
pub extern fn ImGuiStorage_Clear(self: [*c]ImGuiStorage) void;
pub extern fn ImGuiStorage_GetInt(self: [*c]ImGuiStorage, key: ImGuiID, default_val: c_int) c_int;
pub extern fn ImGuiStorage_SetInt(self: [*c]ImGuiStorage, key: ImGuiID, val: c_int) void;
pub extern fn ImGuiStorage_GetBool(self: [*c]ImGuiStorage, key: ImGuiID, default_val: bool) bool;
pub extern fn ImGuiStorage_SetBool(self: [*c]ImGuiStorage, key: ImGuiID, val: bool) void;
pub extern fn ImGuiStorage_GetFloat(self: [*c]ImGuiStorage, key: ImGuiID, default_val: f32) f32;
pub extern fn ImGuiStorage_SetFloat(self: [*c]ImGuiStorage, key: ImGuiID, val: f32) void;
pub extern fn ImGuiStorage_GetVoidPtr(self: [*c]ImGuiStorage, key: ImGuiID) ?*anyopaque;
pub extern fn ImGuiStorage_SetVoidPtr(self: [*c]ImGuiStorage, key: ImGuiID, val: ?*anyopaque) void;
pub extern fn ImGuiStorage_GetIntRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: c_int) [*c]c_int;
pub extern fn ImGuiStorage_GetBoolRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: bool) [*c]bool;
pub extern fn ImGuiStorage_GetFloatRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: f32) [*c]f32;
pub extern fn ImGuiStorage_GetVoidPtrRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: ?*anyopaque) [*c]?*anyopaque;
pub extern fn ImGuiStorage_SetAllInt(self: [*c]ImGuiStorage, val: c_int) void;
pub extern fn ImGuiStorage_BuildSortByKey(self: [*c]ImGuiStorage) void;
pub extern fn ImGuiListClipper_ImGuiListClipper() [*c]ImGuiListClipper;
pub extern fn ImGuiListClipper_destroy(self: [*c]ImGuiListClipper) void;
pub extern fn ImGuiListClipper_Begin(self: [*c]ImGuiListClipper, items_count: c_int, items_height: f32) void;
pub extern fn ImGuiListClipper_End(self: [*c]ImGuiListClipper) void;
pub extern fn ImGuiListClipper_Step(self: [*c]ImGuiListClipper) bool;
pub extern fn ImColor_ImColor_Nil() [*c]ImColor;
pub extern fn ImColor_destroy(self: [*c]ImColor) void;
pub extern fn ImColor_ImColor_Int(r: c_int, g: c_int, b: c_int, a: c_int) [*c]ImColor;
pub extern fn ImColor_ImColor_U32(rgba: ImU32) [*c]ImColor;
pub extern fn ImColor_ImColor_Float(r: f32, g: f32, b: f32, a: f32) [*c]ImColor;
pub extern fn ImColor_ImColor_Vec4(col: ImVec4) [*c]ImColor;
pub extern fn ImColor_SetHSV(self: [*c]ImColor, h: f32, s: f32, v: f32, a: f32) void;
pub extern fn ImColor_HSV(pOut: [*c]ImColor, h: f32, s: f32, v: f32, a: f32) void;
pub extern fn ImDrawCmd_ImDrawCmd() [*c]ImDrawCmd;
pub extern fn ImDrawCmd_destroy(self: [*c]ImDrawCmd) void;
pub extern fn ImDrawCmd_GetTexID(self: [*c]ImDrawCmd) ImTextureID;
pub extern fn ImDrawListSplitter_ImDrawListSplitter() [*c]ImDrawListSplitter;
pub extern fn ImDrawListSplitter_destroy(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_Clear(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_ClearFreeMemory(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_Split(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList, count: c_int) void;
pub extern fn ImDrawListSplitter_Merge(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList) void;
pub extern fn ImDrawListSplitter_SetCurrentChannel(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList, channel_idx: c_int) void;
pub extern fn ImDrawList_ImDrawList(shared_data: [*c]const ImDrawListSharedData) [*c]ImDrawList;
pub extern fn ImDrawList_destroy(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PushClipRect(self: [*c]ImDrawList, clip_rect_min: ImVec2, clip_rect_max: ImVec2, intersect_with_current_clip_rect: bool) void;
pub extern fn ImDrawList_PushClipRectFullScreen(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PopClipRect(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PushTextureID(self: [*c]ImDrawList, texture_id: ImTextureID) void;
pub extern fn ImDrawList_PopTextureID(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_GetClipRectMin(pOut: [*c]ImVec2, self: [*c]ImDrawList) void;
pub extern fn ImDrawList_GetClipRectMax(pOut: [*c]ImVec2, self: [*c]ImDrawList) void;
pub extern fn ImDrawList_AddLine(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddRect(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_AddRectFilled(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddRectFilledMultiColor(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col_upr_left: ImU32, col_upr_right: ImU32, col_bot_right: ImU32, col_bot_left: ImU32) void;
pub extern fn ImDrawList_AddQuad(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddQuadFilled(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddTriangle(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddTriangleFilled(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddCircle(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int, thickness: f32) void;
pub extern fn ImDrawList_AddCircleFilled(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int) void;
pub extern fn ImDrawList_AddNgon(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int, thickness: f32) void;
pub extern fn ImDrawList_AddNgonFilled(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int) void;
pub extern fn ImDrawList_AddText_Vec2(self: [*c]ImDrawList, pos: ImVec2, col: ImU32, text_begin: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImDrawList_AddText_FontPtr(self: [*c]ImDrawList, font: [*c]const ImFont, font_size: f32, pos: ImVec2, col: ImU32, text_begin: [*c]const u8, text_end: [*c]const u8, wrap_width: f32, cpu_fine_clip_rect: [*c]const ImVec4) void;
pub extern fn ImDrawList_AddPolyline(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_AddConvexPolyFilled(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32) void;
pub extern fn ImDrawList_AddBezierCubic(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: f32, num_segments: c_int) void;
pub extern fn ImDrawList_AddBezierQuadratic(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: f32, num_segments: c_int) void;
pub extern fn ImDrawList_AddImage(self: [*c]ImDrawList, user_texture_id: ImTextureID, p_min: ImVec2, p_max: ImVec2, uv_min: ImVec2, uv_max: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddImageQuad(self: [*c]ImDrawList, user_texture_id: ImTextureID, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, uv1: ImVec2, uv2: ImVec2, uv3: ImVec2, uv4: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddImageRounded(self: [*c]ImDrawList, user_texture_id: ImTextureID, p_min: ImVec2, p_max: ImVec2, uv_min: ImVec2, uv_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_PathClear(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PathLineTo(self: [*c]ImDrawList, pos: ImVec2) void;
pub extern fn ImDrawList_PathLineToMergeDuplicate(self: [*c]ImDrawList, pos: ImVec2) void;
pub extern fn ImDrawList_PathFillConvex(self: [*c]ImDrawList, col: ImU32) void;
pub extern fn ImDrawList_PathStroke(self: [*c]ImDrawList, col: ImU32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_PathArcTo(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min: f32, a_max: f32, num_segments: c_int) void;
pub extern fn ImDrawList_PathArcToFast(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min_of_12: c_int, a_max_of_12: c_int) void;
pub extern fn ImDrawList_PathBezierCubicCurveTo(self: [*c]ImDrawList, p2: ImVec2, p3: ImVec2, p4: ImVec2, num_segments: c_int) void;
pub extern fn ImDrawList_PathBezierQuadraticCurveTo(self: [*c]ImDrawList, p2: ImVec2, p3: ImVec2, num_segments: c_int) void;
pub extern fn ImDrawList_PathRect(self: [*c]ImDrawList, rect_min: ImVec2, rect_max: ImVec2, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddCallback(self: [*c]ImDrawList, callback: ImDrawCallback, callback_data: ?*anyopaque) void;
pub extern fn ImDrawList_AddDrawCmd(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_CloneOutput(self: [*c]ImDrawList) [*c]ImDrawList;
pub extern fn ImDrawList_ChannelsSplit(self: [*c]ImDrawList, count: c_int) void;
pub extern fn ImDrawList_ChannelsMerge(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_ChannelsSetCurrent(self: [*c]ImDrawList, n: c_int) void;
pub extern fn ImDrawList_PrimReserve(self: [*c]ImDrawList, idx_count: c_int, vtx_count: c_int) void;
pub extern fn ImDrawList_PrimUnreserve(self: [*c]ImDrawList, idx_count: c_int, vtx_count: c_int) void;
pub extern fn ImDrawList_PrimRect(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimRectUV(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, uv_a: ImVec2, uv_b: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimQuadUV(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, c: ImVec2, d: ImVec2, uv_a: ImVec2, uv_b: ImVec2, uv_c: ImVec2, uv_d: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimWriteVtx(self: [*c]ImDrawList, pos: ImVec2, uv: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimWriteIdx(self: [*c]ImDrawList, idx: ImDrawIdx) void;
pub extern fn ImDrawList_PrimVtx(self: [*c]ImDrawList, pos: ImVec2, uv: ImVec2, col: ImU32) void;
pub extern fn ImDrawList__ResetForNewFrame(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__ClearFreeMemory(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__PopUnusedDrawCmd(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__TryMergeDrawCmds(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedClipRect(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedTextureID(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedVtxOffset(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__CalcCircleAutoSegmentCount(self: [*c]ImDrawList, radius: f32) c_int;
pub extern fn ImDrawList__PathArcToFastEx(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min_sample: c_int, a_max_sample: c_int, a_step: c_int) void;
pub extern fn ImDrawList__PathArcToN(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min: f32, a_max: f32, num_segments: c_int) void;
pub extern fn ImDrawData_ImDrawData() [*c]ImDrawData;
pub extern fn ImDrawData_destroy(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_Clear(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_DeIndexAllBuffers(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_ScaleClipRects(self: [*c]ImDrawData, fb_scale: ImVec2) void;
pub extern fn ImFontConfig_ImFontConfig() [*c]ImFontConfig;
pub extern fn ImFontConfig_destroy(self: [*c]ImFontConfig) void;
pub extern fn ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder() [*c]ImFontGlyphRangesBuilder;
pub extern fn ImFontGlyphRangesBuilder_destroy(self: [*c]ImFontGlyphRangesBuilder) void;
pub extern fn ImFontGlyphRangesBuilder_Clear(self: [*c]ImFontGlyphRangesBuilder) void;
pub extern fn ImFontGlyphRangesBuilder_GetBit(self: [*c]ImFontGlyphRangesBuilder, n: usize) bool;
pub extern fn ImFontGlyphRangesBuilder_SetBit(self: [*c]ImFontGlyphRangesBuilder, n: usize) void;
pub extern fn ImFontGlyphRangesBuilder_AddChar(self: [*c]ImFontGlyphRangesBuilder, c: ImWchar) void;
pub extern fn ImFontGlyphRangesBuilder_AddText(self: [*c]ImFontGlyphRangesBuilder, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImFontGlyphRangesBuilder_AddRanges(self: [*c]ImFontGlyphRangesBuilder, ranges: [*c]const ImWchar) void;
pub extern fn ImFontGlyphRangesBuilder_BuildRanges(self: [*c]ImFontGlyphRangesBuilder, out_ranges: [*c]ImVector_ImWchar) void;
pub extern fn ImFontAtlasCustomRect_ImFontAtlasCustomRect() [*c]ImFontAtlasCustomRect;
pub extern fn ImFontAtlasCustomRect_destroy(self: [*c]ImFontAtlasCustomRect) void;
pub extern fn ImFontAtlasCustomRect_IsPacked(self: [*c]ImFontAtlasCustomRect) bool;
pub extern fn ImFontAtlas_ImFontAtlas() [*c]ImFontAtlas;
pub extern fn ImFontAtlas_destroy(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_AddFont(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontDefault(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromFileTTF(self: [*c]ImFontAtlas, filename: [*c]const u8, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryTTF(self: [*c]ImFontAtlas, font_data: ?*anyopaque, font_size: c_int, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryCompressedTTF(self: [*c]ImFontAtlas, compressed_font_data: ?*const anyopaque, compressed_font_size: c_int, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(self: [*c]ImFontAtlas, compressed_font_data_base85: [*c]const u8, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_ClearInputData(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_ClearTexData(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_ClearFonts(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_Clear(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_Build(self: [*c]ImFontAtlas) bool;
pub extern fn ImFontAtlas_GetTexDataAsAlpha8(self: [*c]ImFontAtlas, out_pixels: [*c][*c]u8, out_width: [*c]c_int, out_height: [*c]c_int, out_bytes_per_pixel: [*c]c_int) void;
pub extern fn ImFontAtlas_GetTexDataAsRGBA32(self: [*c]ImFontAtlas, out_pixels: [*c][*c]u8, out_width: [*c]c_int, out_height: [*c]c_int, out_bytes_per_pixel: [*c]c_int) void;
pub extern fn ImFontAtlas_IsBuilt(self: [*c]ImFontAtlas) bool;
pub extern fn ImFontAtlas_SetTexID(self: [*c]ImFontAtlas, id: ImTextureID) void;
pub extern fn ImFontAtlas_GetGlyphRangesDefault(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesKorean(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesJapanese(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesChineseFull(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesCyrillic(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesThai(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesVietnamese(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_AddCustomRectRegular(self: [*c]ImFontAtlas, width: c_int, height: c_int) c_int;
pub extern fn ImFontAtlas_AddCustomRectFontGlyph(self: [*c]ImFontAtlas, font: [*c]ImFont, id: ImWchar, width: c_int, height: c_int, advance_x: f32, offset: ImVec2) c_int;
pub extern fn ImFontAtlas_GetCustomRectByIndex(self: [*c]ImFontAtlas, index: c_int) [*c]ImFontAtlasCustomRect;
pub extern fn ImFontAtlas_CalcCustomRectUV(self: [*c]ImFontAtlas, rect: [*c]const ImFontAtlasCustomRect, out_uv_min: [*c]ImVec2, out_uv_max: [*c]ImVec2) void;
pub extern fn ImFontAtlas_GetMouseCursorTexData(self: [*c]ImFontAtlas, cursor: ImGuiMouseCursor, out_offset: [*c]ImVec2, out_size: [*c]ImVec2, out_uv_border: [*c]ImVec2, out_uv_fill: [*c]ImVec2) bool;
pub extern fn ImFont_ImFont() [*c]ImFont;
pub extern fn ImFont_destroy(self: [*c]ImFont) void;
pub extern fn ImFont_FindGlyph(self: [*c]ImFont, c: ImWchar) ?*const ImFontGlyph;
pub extern fn ImFont_FindGlyphNoFallback(self: [*c]ImFont, c: ImWchar) ?*const ImFontGlyph;
pub extern fn ImFont_GetCharAdvance(self: [*c]ImFont, c: ImWchar) f32;
pub extern fn ImFont_IsLoaded(self: [*c]ImFont) bool;
pub extern fn ImFont_GetDebugName(self: [*c]ImFont) [*c]const u8;
pub extern fn ImFont_CalcTextSizeA(pOut: [*c]ImVec2, self: [*c]ImFont, size: f32, max_width: f32, wrap_width: f32, text_begin: [*c]const u8, text_end: [*c]const u8, remaining: [*c][*c]const u8) void;
pub extern fn ImFont_CalcWordWrapPositionA(self: [*c]ImFont, scale: f32, text: [*c]const u8, text_end: [*c]const u8, wrap_width: f32) [*c]const u8;
pub extern fn ImFont_RenderChar(self: [*c]ImFont, draw_list: [*c]ImDrawList, size: f32, pos: ImVec2, col: ImU32, c: ImWchar) void;
pub extern fn ImFont_RenderText(self: [*c]ImFont, draw_list: [*c]ImDrawList, size: f32, pos: ImVec2, col: ImU32, clip_rect: ImVec4, text_begin: [*c]const u8, text_end: [*c]const u8, wrap_width: f32, cpu_fine_clip: bool) void;
pub extern fn ImFont_BuildLookupTable(self: [*c]ImFont) void;
pub extern fn ImFont_ClearOutputData(self: [*c]ImFont) void;
pub extern fn ImFont_GrowIndex(self: [*c]ImFont, new_size: c_int) void;
pub extern fn ImFont_AddGlyph(self: [*c]ImFont, src_cfg: [*c]const ImFontConfig, c: ImWchar, x0: f32, y0: f32, x1: f32, y1: f32, @"u0": f32, v0: f32, @"u1": f32, v1: f32, advance_x: f32) void;
pub extern fn ImFont_AddRemapChar(self: [*c]ImFont, dst: ImWchar, src: ImWchar, overwrite_dst: bool) void;
pub extern fn ImFont_SetGlyphVisible(self: [*c]ImFont, c: ImWchar, visible: bool) void;
pub extern fn ImFont_IsGlyphRangeUnused(self: [*c]ImFont, c_begin: c_uint, c_last: c_uint) bool;
pub extern fn ImGuiViewport_ImGuiViewport() [*c]ImGuiViewport;
pub extern fn ImGuiViewport_destroy(self: [*c]ImGuiViewport) void;
pub extern fn ImGuiViewport_GetCenter(pOut: [*c]ImVec2, self: [*c]ImGuiViewport) void;
pub extern fn ImGuiViewport_GetWorkCenter(pOut: [*c]ImVec2, self: [*c]ImGuiViewport) void;
pub extern fn igImHashData(data: ?*const anyopaque, data_size: usize, seed: ImU32) ImGuiID;
pub extern fn igImHashStr(data: [*c]const u8, data_size: usize, seed: ImU32) ImGuiID;
pub extern fn igImAlphaBlendColors(col_a: ImU32, col_b: ImU32) ImU32;
pub extern fn igImIsPowerOfTwo_Int(v: c_int) bool;
pub extern fn igImIsPowerOfTwo_U64(v: ImU64) bool;
pub extern fn igImUpperPowerOfTwo(v: c_int) c_int;
pub extern fn igImStricmp(str1: [*c]const u8, str2: [*c]const u8) c_int;
pub extern fn igImStrnicmp(str1: [*c]const u8, str2: [*c]const u8, count: usize) c_int;
pub extern fn igImStrncpy(dst: [*c]u8, src: [*c]const u8, count: usize) void;
pub extern fn igImStrdup(str: [*c]const u8) [*c]u8;
pub extern fn igImStrdupcpy(dst: [*c]u8, p_dst_size: [*c]usize, str: [*c]const u8) [*c]u8;
pub extern fn igImStrchrRange(str_begin: [*c]const u8, str_end: [*c]const u8, c: u8) [*c]const u8;
pub extern fn igImStrlenW(str: [*c]const ImWchar) c_int;
pub extern fn igImStreolRange(str: [*c]const u8, str_end: [*c]const u8) [*c]const u8;
pub extern fn igImStrbolW(buf_mid_line: [*c]const ImWchar, buf_begin: [*c]const ImWchar) [*c]const ImWchar;
pub extern fn igImStristr(haystack: [*c]const u8, haystack_end: [*c]const u8, needle: [*c]const u8, needle_end: [*c]const u8) [*c]const u8;
pub extern fn igImStrTrimBlanks(str: [*c]u8) void;
pub extern fn igImStrSkipBlank(str: [*c]const u8) [*c]const u8;
pub extern fn igImFormatString(buf: [*c]u8, buf_size: usize, fmt: [*c]const u8, ...) c_int;
pub extern fn igImParseFormatFindStart(format: [*c]const u8) [*c]const u8;
pub extern fn igImParseFormatFindEnd(format: [*c]const u8) [*c]const u8;
pub extern fn igImParseFormatTrimDecorations(format: [*c]const u8, buf: [*c]u8, buf_size: usize) [*c]const u8;
pub extern fn igImParseFormatPrecision(format: [*c]const u8, default_value: c_int) c_int;
pub extern fn igImCharIsBlankA(c: u8) bool;
pub extern fn igImCharIsBlankW(c: c_uint) bool;
pub extern fn igImTextCharToUtf8(out_buf: [*c]u8, c: c_uint) [*c]const u8;
pub extern fn igImTextStrToUtf8(out_buf: [*c]u8, out_buf_size: c_int, in_text: [*c]const ImWchar, in_text_end: [*c]const ImWchar) c_int;
pub extern fn igImTextCharFromUtf8(out_char: [*c]c_uint, in_text: [*c]const u8, in_text_end: [*c]const u8) c_int;
pub extern fn igImTextStrFromUtf8(out_buf: [*c]ImWchar, out_buf_size: c_int, in_text: [*c]const u8, in_text_end: [*c]const u8, in_remaining: [*c][*c]const u8) c_int;
pub extern fn igImTextCountCharsFromUtf8(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int;
pub extern fn igImTextCountUtf8BytesFromChar(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int;
pub extern fn igImTextCountUtf8BytesFromStr(in_text: [*c]const ImWchar, in_text_end: [*c]const ImWchar) c_int;
pub extern fn igImFileOpen(filename: [*c]const u8, mode: [*c]const u8) ImFileHandle;
pub extern fn igImFileClose(file: ImFileHandle) bool;
pub extern fn igImFileGetSize(file: ImFileHandle) ImU64;
pub extern fn igImFileRead(data: ?*anyopaque, size: ImU64, count: ImU64, file: ImFileHandle) ImU64;
pub extern fn igImFileWrite(data: ?*const anyopaque, size: ImU64, count: ImU64, file: ImFileHandle) ImU64;
pub extern fn igImFileLoadToMemory(filename: [*c]const u8, mode: [*c]const u8, out_file_size: [*c]usize, padding_bytes: c_int) ?*anyopaque;
pub extern fn igImPow_Float(x: f32, y: f32) f32;
pub extern fn igImPow_double(x: f64, y: f64) f64;
pub extern fn igImLog_Float(x: f32) f32;
pub extern fn igImLog_double(x: f64) f64;
pub extern fn igImAbs_Int(x: c_int) c_int;
pub extern fn igImAbs_Float(x: f32) f32;
pub extern fn igImAbs_double(x: f64) f64;
pub extern fn igImSign_Float(x: f32) f32;
pub extern fn igImSign_double(x: f64) f64;
pub extern fn igImRsqrt_Float(x: f32) f32;
pub extern fn igImRsqrt_double(x: f64) f64;
pub extern fn igImMin(pOut: [*c]ImVec2, lhs: ImVec2, rhs: ImVec2) void;
pub extern fn igImMax(pOut: [*c]ImVec2, lhs: ImVec2, rhs: ImVec2) void;
pub extern fn igImClamp(pOut: [*c]ImVec2, v: ImVec2, mn: ImVec2, mx: ImVec2) void;
pub extern fn igImLerp_Vec2Float(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, t: f32) void;
pub extern fn igImLerp_Vec2Vec2(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, t: ImVec2) void;
pub extern fn igImLerp_Vec4(pOut: [*c]ImVec4, a: ImVec4, b: ImVec4, t: f32) void;
pub extern fn igImSaturate(f: f32) f32;
pub extern fn igImLengthSqr_Vec2(lhs: ImVec2) f32;
pub extern fn igImLengthSqr_Vec4(lhs: ImVec4) f32;
pub extern fn igImInvLength(lhs: ImVec2, fail_value: f32) f32;
pub extern fn igImFloor_Float(f: f32) f32;
pub extern fn igImFloorSigned(f: f32) f32;
pub extern fn igImFloor_Vec2(pOut: [*c]ImVec2, v: ImVec2) void;
pub extern fn igImModPositive(a: c_int, b: c_int) c_int;
pub extern fn igImDot(a: ImVec2, b: ImVec2) f32;
pub extern fn igImRotate(pOut: [*c]ImVec2, v: ImVec2, cos_a: f32, sin_a: f32) void;
pub extern fn igImLinearSweep(current: f32, target: f32, speed: f32) f32;
pub extern fn igImMul(pOut: [*c]ImVec2, lhs: ImVec2, rhs: ImVec2) void;
pub extern fn igImBezierCubicCalc(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, t: f32) void;
pub extern fn igImBezierCubicClosestPoint(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, p: ImVec2, num_segments: c_int) void;
pub extern fn igImBezierCubicClosestPointCasteljau(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, p: ImVec2, tess_tol: f32) void;
pub extern fn igImBezierQuadraticCalc(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, t: f32) void;
pub extern fn igImLineClosestPoint(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, p: ImVec2) void;
pub extern fn igImTriangleContainsPoint(a: ImVec2, b: ImVec2, c: ImVec2, p: ImVec2) bool;
pub extern fn igImTriangleClosestPoint(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, c: ImVec2, p: ImVec2) void;
pub extern fn igImTriangleBarycentricCoords(a: ImVec2, b: ImVec2, c: ImVec2, p: ImVec2, out_u: [*c]f32, out_v: [*c]f32, out_w: [*c]f32) void;
pub extern fn igImTriangleArea(a: ImVec2, b: ImVec2, c: ImVec2) f32;
pub extern fn igImGetDirQuadrantFromDelta(dx: f32, dy: f32) ImGuiDir;
pub extern fn ImVec1_ImVec1_Nil() [*c]ImVec1;
pub extern fn ImVec1_destroy(self: [*c]ImVec1) void;
pub extern fn ImVec1_ImVec1_Float(_x: f32) [*c]ImVec1;
pub extern fn ImVec2ih_ImVec2ih_Nil() [*c]ImVec2ih;
pub extern fn ImVec2ih_destroy(self: [*c]ImVec2ih) void;
pub extern fn ImVec2ih_ImVec2ih_short(_x: c_short, _y: c_short) [*c]ImVec2ih;
pub extern fn ImVec2ih_ImVec2ih_Vec2(rhs: ImVec2) [*c]ImVec2ih;
pub extern fn ImRect_ImRect_Nil() [*c]ImRect;
pub extern fn ImRect_destroy(self: [*c]ImRect) void;
pub extern fn ImRect_ImRect_Vec2(min: ImVec2, max: ImVec2) [*c]ImRect;
pub extern fn ImRect_ImRect_Vec4(v: ImVec4) [*c]ImRect;
pub extern fn ImRect_ImRect_Float(x1: f32, y1: f32, x2: f32, y2: f32) [*c]ImRect;
pub extern fn ImRect_GetCenter(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetSize(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetWidth(self: [*c]ImRect) f32;
pub extern fn ImRect_GetHeight(self: [*c]ImRect) f32;
pub extern fn ImRect_GetArea(self: [*c]ImRect) f32;
pub extern fn ImRect_GetTL(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetTR(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetBL(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetBR(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_Contains_Vec2(self: [*c]ImRect, p: ImVec2) bool;
pub extern fn ImRect_Contains_Rect(self: [*c]ImRect, r: ImRect) bool;
pub extern fn ImRect_Overlaps(self: [*c]ImRect, r: ImRect) bool;
pub extern fn ImRect_Add_Vec2(self: [*c]ImRect, p: ImVec2) void;
pub extern fn ImRect_Add_Rect(self: [*c]ImRect, r: ImRect) void;
pub extern fn ImRect_Expand_Float(self: [*c]ImRect, amount: f32) void;
pub extern fn ImRect_Expand_Vec2(self: [*c]ImRect, amount: ImVec2) void;
pub extern fn ImRect_Translate(self: [*c]ImRect, d: ImVec2) void;
pub extern fn ImRect_TranslateX(self: [*c]ImRect, dx: f32) void;
pub extern fn ImRect_TranslateY(self: [*c]ImRect, dy: f32) void;
pub extern fn ImRect_ClipWith(self: [*c]ImRect, r: ImRect) void;
pub extern fn ImRect_ClipWithFull(self: [*c]ImRect, r: ImRect) void;
pub extern fn ImRect_Floor(self: [*c]ImRect) void;
pub extern fn ImRect_IsInverted(self: [*c]ImRect) bool;
pub extern fn ImRect_ToVec4(pOut: [*c]ImVec4, self: [*c]ImRect) void;
pub extern fn igImBitArrayTestBit(arr: [*c]const ImU32, n: c_int) bool;
pub extern fn igImBitArrayClearBit(arr: [*c]ImU32, n: c_int) void;
pub extern fn igImBitArraySetBit(arr: [*c]ImU32, n: c_int) void;
pub extern fn igImBitArraySetBitRange(arr: [*c]ImU32, n: c_int, n2: c_int) void;
pub extern fn ImBitVector_Create(self: [*c]ImBitVector, sz: c_int) void;
pub extern fn ImBitVector_Clear(self: [*c]ImBitVector) void;
pub extern fn ImBitVector_TestBit(self: [*c]ImBitVector, n: c_int) bool;
pub extern fn ImBitVector_SetBit(self: [*c]ImBitVector, n: c_int) void;
pub extern fn ImBitVector_ClearBit(self: [*c]ImBitVector, n: c_int) void;
pub extern fn ImDrawListSharedData_ImDrawListSharedData() [*c]ImDrawListSharedData;
pub extern fn ImDrawListSharedData_destroy(self: [*c]ImDrawListSharedData) void;
pub extern fn ImDrawListSharedData_SetCircleTessellationMaxError(self: [*c]ImDrawListSharedData, max_error: f32) void;
pub extern fn ImDrawDataBuilder_Clear(self: [*c]ImDrawDataBuilder) void;
pub extern fn ImDrawDataBuilder_ClearFreeMemory(self: [*c]ImDrawDataBuilder) void;
pub extern fn ImDrawDataBuilder_GetDrawListCount(self: [*c]ImDrawDataBuilder) c_int;
pub extern fn ImDrawDataBuilder_FlattenIntoSingleLayer(self: [*c]ImDrawDataBuilder) void;
pub extern fn ImGuiStyleMod_ImGuiStyleMod_Int(idx: ImGuiStyleVar, v: c_int) [*c]ImGuiStyleMod;
pub extern fn ImGuiStyleMod_destroy(self: [*c]ImGuiStyleMod) void;
pub extern fn ImGuiStyleMod_ImGuiStyleMod_Float(idx: ImGuiStyleVar, v: f32) [*c]ImGuiStyleMod;
pub extern fn ImGuiStyleMod_ImGuiStyleMod_Vec2(idx: ImGuiStyleVar, v: ImVec2) [*c]ImGuiStyleMod;
pub extern fn ImGuiComboPreviewData_ImGuiComboPreviewData() [*c]ImGuiComboPreviewData;
pub extern fn ImGuiComboPreviewData_destroy(self: [*c]ImGuiComboPreviewData) void;
pub extern fn ImGuiMenuColumns_ImGuiMenuColumns() [*c]ImGuiMenuColumns;
pub extern fn ImGuiMenuColumns_destroy(self: [*c]ImGuiMenuColumns) void;
pub extern fn ImGuiMenuColumns_Update(self: [*c]ImGuiMenuColumns, spacing: f32, window_reappearing: bool) void;
pub extern fn ImGuiMenuColumns_DeclColumns(self: [*c]ImGuiMenuColumns, w_icon: f32, w_label: f32, w_shortcut: f32, w_mark: f32) f32;
pub extern fn ImGuiMenuColumns_CalcNextTotalWidth(self: [*c]ImGuiMenuColumns, update_offsets: bool) void;
pub extern fn ImGuiInputTextState_ImGuiInputTextState() [*c]ImGuiInputTextState;
pub extern fn ImGuiInputTextState_destroy(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_ClearText(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_ClearFreeMemory(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_GetUndoAvailCount(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_GetRedoAvailCount(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_OnKeyPressed(self: [*c]ImGuiInputTextState, key: c_int) void;
pub extern fn ImGuiInputTextState_CursorAnimReset(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_CursorClamp(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_HasSelection(self: [*c]ImGuiInputTextState) bool;
pub extern fn ImGuiInputTextState_ClearSelection(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_GetCursorPos(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_GetSelectionStart(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_GetSelectionEnd(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_SelectAll(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiPopupData_ImGuiPopupData() [*c]ImGuiPopupData;
pub extern fn ImGuiPopupData_destroy(self: [*c]ImGuiPopupData) void;
pub extern fn ImGuiNextWindowData_ImGuiNextWindowData() [*c]ImGuiNextWindowData;
pub extern fn ImGuiNextWindowData_destroy(self: [*c]ImGuiNextWindowData) void;
pub extern fn ImGuiNextWindowData_ClearFlags(self: [*c]ImGuiNextWindowData) void;
pub extern fn ImGuiNextItemData_ImGuiNextItemData() [*c]ImGuiNextItemData;
pub extern fn ImGuiNextItemData_destroy(self: [*c]ImGuiNextItemData) void;
pub extern fn ImGuiNextItemData_ClearFlags(self: [*c]ImGuiNextItemData) void;
pub extern fn ImGuiLastItemData_ImGuiLastItemData() [*c]ImGuiLastItemData;
pub extern fn ImGuiLastItemData_destroy(self: [*c]ImGuiLastItemData) void;
pub extern fn ImGuiStackSizes_ImGuiStackSizes() [*c]ImGuiStackSizes;
pub extern fn ImGuiStackSizes_destroy(self: [*c]ImGuiStackSizes) void;
pub extern fn ImGuiStackSizes_SetToCurrentState(self: [*c]ImGuiStackSizes) void;
pub extern fn ImGuiStackSizes_CompareWithCurrentState(self: [*c]ImGuiStackSizes) void;
pub extern fn ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr(ptr: ?*anyopaque) [*c]ImGuiPtrOrIndex;
pub extern fn ImGuiPtrOrIndex_destroy(self: [*c]ImGuiPtrOrIndex) void;
pub extern fn ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int(index: c_int) [*c]ImGuiPtrOrIndex;
pub extern fn ImGuiNavItemData_ImGuiNavItemData() [*c]ImGuiNavItemData;
pub extern fn ImGuiNavItemData_destroy(self: [*c]ImGuiNavItemData) void;
pub extern fn ImGuiNavItemData_Clear(self: [*c]ImGuiNavItemData) void;
pub extern fn ImGuiOldColumnData_ImGuiOldColumnData() [*c]ImGuiOldColumnData;
pub extern fn ImGuiOldColumnData_destroy(self: [*c]ImGuiOldColumnData) void;
pub extern fn ImGuiOldColumns_ImGuiOldColumns() [*c]ImGuiOldColumns;
pub extern fn ImGuiOldColumns_destroy(self: [*c]ImGuiOldColumns) void;
pub extern fn ImGuiViewportP_ImGuiViewportP() [*c]ImGuiViewportP;
pub extern fn ImGuiViewportP_destroy(self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_CalcWorkRectPos(pOut: [*c]ImVec2, self: [*c]ImGuiViewportP, off_min: ImVec2) void;
pub extern fn ImGuiViewportP_CalcWorkRectSize(pOut: [*c]ImVec2, self: [*c]ImGuiViewportP, off_min: ImVec2, off_max: ImVec2) void;
pub extern fn ImGuiViewportP_UpdateWorkRect(self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_GetMainRect(pOut: [*c]ImRect, self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_GetWorkRect(pOut: [*c]ImRect, self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_GetBuildWorkRect(pOut: [*c]ImRect, self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiWindowSettings_ImGuiWindowSettings() [*c]ImGuiWindowSettings;
pub extern fn ImGuiWindowSettings_destroy(self: [*c]ImGuiWindowSettings) void;
pub extern fn ImGuiWindowSettings_GetName(self: [*c]ImGuiWindowSettings) [*c]u8;
pub extern fn ImGuiSettingsHandler_ImGuiSettingsHandler() [*c]ImGuiSettingsHandler;
pub extern fn ImGuiSettingsHandler_destroy(self: [*c]ImGuiSettingsHandler) void;
pub extern fn ImGuiMetricsConfig_ImGuiMetricsConfig() [*c]ImGuiMetricsConfig;
pub extern fn ImGuiMetricsConfig_destroy(self: [*c]ImGuiMetricsConfig) void;
pub extern fn ImGuiStackLevelInfo_ImGuiStackLevelInfo() [*c]ImGuiStackLevelInfo;
pub extern fn ImGuiStackLevelInfo_destroy(self: [*c]ImGuiStackLevelInfo) void;
pub extern fn ImGuiStackTool_ImGuiStackTool() [*c]ImGuiStackTool;
pub extern fn ImGuiStackTool_destroy(self: [*c]ImGuiStackTool) void;
pub extern fn ImGuiContextHook_ImGuiContextHook() [*c]ImGuiContextHook;
pub extern fn ImGuiContextHook_destroy(self: [*c]ImGuiContextHook) void;
pub extern fn ImGuiContext_ImGuiContext(shared_font_atlas: [*c]ImFontAtlas) [*c]ImGuiContext;
pub extern fn ImGuiContext_destroy(self: [*c]ImGuiContext) void;
pub extern fn ImGuiWindow_ImGuiWindow(context: [*c]ImGuiContext, name: [*c]const u8) ?*ImGuiWindow;
pub extern fn ImGuiWindow_destroy(self: ?*ImGuiWindow) void;
pub extern fn ImGuiWindow_GetID_Str(self: ?*ImGuiWindow, str: [*c]const u8, str_end: [*c]const u8) ImGuiID;
pub extern fn ImGuiWindow_GetID_Ptr(self: ?*ImGuiWindow, ptr: ?*const anyopaque) ImGuiID;
pub extern fn ImGuiWindow_GetID_Int(self: ?*ImGuiWindow, n: c_int) ImGuiID;
pub extern fn ImGuiWindow_GetIDNoKeepAlive_Str(self: ?*ImGuiWindow, str: [*c]const u8, str_end: [*c]const u8) ImGuiID;
pub extern fn ImGuiWindow_GetIDNoKeepAlive_Ptr(self: ?*ImGuiWindow, ptr: ?*const anyopaque) ImGuiID;
pub extern fn ImGuiWindow_GetIDNoKeepAlive_Int(self: ?*ImGuiWindow, n: c_int) ImGuiID;
pub extern fn ImGuiWindow_GetIDFromRectangle(self: ?*ImGuiWindow, r_abs: ImRect) ImGuiID;
pub extern fn ImGuiWindow_Rect(pOut: [*c]ImRect, self: ?*ImGuiWindow) void;
pub extern fn ImGuiWindow_CalcFontSize(self: ?*ImGuiWindow) f32;
pub extern fn ImGuiWindow_TitleBarHeight(self: ?*ImGuiWindow) f32;
pub extern fn ImGuiWindow_TitleBarRect(pOut: [*c]ImRect, self: ?*ImGuiWindow) void;
pub extern fn ImGuiWindow_MenuBarHeight(self: ?*ImGuiWindow) f32;
pub extern fn ImGuiWindow_MenuBarRect(pOut: [*c]ImRect, self: ?*ImGuiWindow) void;
pub extern fn ImGuiTabItem_ImGuiTabItem() [*c]ImGuiTabItem;
pub extern fn ImGuiTabItem_destroy(self: [*c]ImGuiTabItem) void;
pub extern fn ImGuiTabBar_ImGuiTabBar() [*c]ImGuiTabBar;
pub extern fn ImGuiTabBar_destroy(self: [*c]ImGuiTabBar) void;
pub extern fn ImGuiTabBar_GetTabOrder(self: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem) c_int;
pub extern fn ImGuiTabBar_GetTabName(self: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem) [*c]const u8;
pub extern fn ImGuiTableColumn_ImGuiTableColumn() ?*ImGuiTableColumn;
pub extern fn ImGuiTableColumn_destroy(self: ?*ImGuiTableColumn) void;
pub extern fn ImGuiTable_ImGuiTable() ?*ImGuiTable;
pub extern fn ImGuiTable_destroy(self: ?*ImGuiTable) void;
pub extern fn ImGuiTableTempData_ImGuiTableTempData() [*c]ImGuiTableTempData;
pub extern fn ImGuiTableTempData_destroy(self: [*c]ImGuiTableTempData) void;
pub extern fn ImGuiTableColumnSettings_ImGuiTableColumnSettings() ?*ImGuiTableColumnSettings;
pub extern fn ImGuiTableColumnSettings_destroy(self: ?*ImGuiTableColumnSettings) void;
pub extern fn ImGuiTableSettings_ImGuiTableSettings() [*c]ImGuiTableSettings;
pub extern fn ImGuiTableSettings_destroy(self: [*c]ImGuiTableSettings) void;
pub extern fn ImGuiTableSettings_GetColumnSettings(self: [*c]ImGuiTableSettings) ?*ImGuiTableColumnSettings;
pub extern fn igGetCurrentWindowRead() ?*ImGuiWindow;
pub extern fn igGetCurrentWindow() ?*ImGuiWindow;
pub extern fn igFindWindowByID(id: ImGuiID) ?*ImGuiWindow;
pub extern fn igFindWindowByName(name: [*c]const u8) ?*ImGuiWindow;
pub extern fn igUpdateWindowParentAndRootLinks(window: ?*ImGuiWindow, flags: ImGuiWindowFlags, parent_window: ?*ImGuiWindow) void;
pub extern fn igCalcWindowNextAutoFitSize(pOut: [*c]ImVec2, window: ?*ImGuiWindow) void;
pub extern fn igIsWindowChildOf(window: ?*ImGuiWindow, potential_parent: ?*ImGuiWindow, popup_hierarchy: bool) bool;
pub extern fn igIsWindowAbove(potential_above: ?*ImGuiWindow, potential_below: ?*ImGuiWindow) bool;
pub extern fn igIsWindowNavFocusable(window: ?*ImGuiWindow) bool;
pub extern fn igSetWindowPos_WindowPtr(window: ?*ImGuiWindow, pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSize_WindowPtr(window: ?*ImGuiWindow, size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsed_WindowPtr(window: ?*ImGuiWindow, collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowHitTestHole(window: ?*ImGuiWindow, pos: ImVec2, size: ImVec2) void;
pub extern fn igFocusWindow(window: ?*ImGuiWindow) void;
pub extern fn igFocusTopMostWindowUnderOne(under_this_window: ?*ImGuiWindow, ignore_window: ?*ImGuiWindow) void;
pub extern fn igBringWindowToFocusFront(window: ?*ImGuiWindow) void;
pub extern fn igBringWindowToDisplayFront(window: ?*ImGuiWindow) void;
pub extern fn igBringWindowToDisplayBack(window: ?*ImGuiWindow) void;
pub extern fn igSetCurrentFont(font: [*c]ImFont) void;
pub extern fn igGetDefaultFont() [*c]ImFont;
pub extern fn igGetForegroundDrawList_WindowPtr(window: ?*ImGuiWindow) [*c]ImDrawList;
pub extern fn igGetBackgroundDrawList_ViewportPtr(viewport: [*c]ImGuiViewport) [*c]ImDrawList;
pub extern fn igGetForegroundDrawList_ViewportPtr(viewport: [*c]ImGuiViewport) [*c]ImDrawList;
pub extern fn igInitialize(context: [*c]ImGuiContext) void;
pub extern fn igShutdown(context: [*c]ImGuiContext) void;
pub extern fn igUpdateHoveredWindowAndCaptureFlags() void;
pub extern fn igStartMouseMovingWindow(window: ?*ImGuiWindow) void;
pub extern fn igUpdateMouseMovingWindowNewFrame() void;
pub extern fn igUpdateMouseMovingWindowEndFrame() void;
pub extern fn igAddContextHook(context: [*c]ImGuiContext, hook: [*c]const ImGuiContextHook) ImGuiID;
pub extern fn igRemoveContextHook(context: [*c]ImGuiContext, hook_to_remove: ImGuiID) void;
pub extern fn igCallContextHooks(context: [*c]ImGuiContext, @"type": ImGuiContextHookType) void;
pub extern fn igMarkIniSettingsDirty_Nil() void;
pub extern fn igMarkIniSettingsDirty_WindowPtr(window: ?*ImGuiWindow) void;
pub extern fn igClearIniSettings() void;
pub extern fn igCreateNewWindowSettings(name: [*c]const u8) [*c]ImGuiWindowSettings;
pub extern fn igFindWindowSettings(id: ImGuiID) [*c]ImGuiWindowSettings;
pub extern fn igFindOrCreateWindowSettings(name: [*c]const u8) [*c]ImGuiWindowSettings;
pub extern fn igFindSettingsHandler(type_name: [*c]const u8) [*c]ImGuiSettingsHandler;
pub extern fn igSetNextWindowScroll(scroll: ImVec2) void;
pub extern fn igSetScrollX_WindowPtr(window: ?*ImGuiWindow, scroll_x: f32) void;
pub extern fn igSetScrollY_WindowPtr(window: ?*ImGuiWindow, scroll_y: f32) void;
pub extern fn igSetScrollFromPosX_WindowPtr(window: ?*ImGuiWindow, local_x: f32, center_x_ratio: f32) void;
pub extern fn igSetScrollFromPosY_WindowPtr(window: ?*ImGuiWindow, local_y: f32, center_y_ratio: f32) void;
pub extern fn igScrollToItem(flags: ImGuiScrollFlags) void;
pub extern fn igScrollToRect(window: ?*ImGuiWindow, rect: ImRect, flags: ImGuiScrollFlags) void;
pub extern fn igScrollToRectEx(pOut: [*c]ImVec2, window: ?*ImGuiWindow, rect: ImRect, flags: ImGuiScrollFlags) void;
pub extern fn igScrollToBringRectIntoView(window: ?*ImGuiWindow, rect: ImRect) void;
pub extern fn igGetItemID() ImGuiID;
pub extern fn igGetItemStatusFlags() ImGuiItemStatusFlags;
pub extern fn igGetItemFlags() ImGuiItemFlags;
pub extern fn igGetActiveID() ImGuiID;
pub extern fn igGetFocusID() ImGuiID;
pub extern fn igSetActiveID(id: ImGuiID, window: ?*ImGuiWindow) void;
pub extern fn igSetFocusID(id: ImGuiID, window: ?*ImGuiWindow) void;
pub extern fn igClearActiveID() void;
pub extern fn igGetHoveredID() ImGuiID;
pub extern fn igSetHoveredID(id: ImGuiID) void;
pub extern fn igKeepAliveID(id: ImGuiID) void;
pub extern fn igMarkItemEdited(id: ImGuiID) void;
pub extern fn igPushOverrideID(id: ImGuiID) void;
pub extern fn igGetIDWithSeed(str_id_begin: [*c]const u8, str_id_end: [*c]const u8, seed: ImGuiID) ImGuiID;
pub extern fn igItemSize_Vec2(size: ImVec2, text_baseline_y: f32) void;
pub extern fn igItemSize_Rect(bb: ImRect, text_baseline_y: f32) void;
pub extern fn igItemAdd(bb: ImRect, id: ImGuiID, nav_bb: [*c]const ImRect, extra_flags: ImGuiItemFlags) bool;
pub extern fn igItemHoverable(bb: ImRect, id: ImGuiID) bool;
pub extern fn igIsClippedEx(bb: ImRect, id: ImGuiID) bool;
pub extern fn igCalcItemSize(pOut: [*c]ImVec2, size: ImVec2, default_w: f32, default_h: f32) void;
pub extern fn igCalcWrapWidthForPos(pos: ImVec2, wrap_pos_x: f32) f32;
pub extern fn igPushMultiItemsWidths(components: c_int, width_full: f32) void;
pub extern fn igIsItemToggledSelection() bool;
pub extern fn igGetContentRegionMaxAbs(pOut: [*c]ImVec2) void;
pub extern fn igShrinkWidths(items: [*c]ImGuiShrinkWidthItem, count: c_int, width_excess: f32) void;
pub extern fn igPushItemFlag(option: ImGuiItemFlags, enabled: bool) void;
pub extern fn igPopItemFlag() void;
pub extern fn igLogBegin(@"type": ImGuiLogType, auto_open_depth: c_int) void;
pub extern fn igLogToBuffer(auto_open_depth: c_int) void;
pub extern fn igLogRenderedText(ref_pos: [*c]const ImVec2, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn igLogSetNextTextDecoration(prefix: [*c]const u8, suffix: [*c]const u8) void;
pub extern fn igBeginChildEx(name: [*c]const u8, id: ImGuiID, size_arg: ImVec2, border: bool, flags: ImGuiWindowFlags) bool;
pub extern fn igOpenPopupEx(id: ImGuiID, popup_flags: ImGuiPopupFlags) void;
pub extern fn igClosePopupToLevel(remaining: c_int, restore_focus_to_window_under_popup: bool) void;
pub extern fn igClosePopupsOverWindow(ref_window: ?*ImGuiWindow, restore_focus_to_window_under_popup: bool) void;
pub extern fn igClosePopupsExceptModals() void;
pub extern fn igIsPopupOpen_ID(id: ImGuiID, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupEx(id: ImGuiID, extra_flags: ImGuiWindowFlags) bool;
pub extern fn igBeginTooltipEx(extra_flags: ImGuiWindowFlags, tooltip_flags: ImGuiTooltipFlags) void;
pub extern fn igGetPopupAllowedExtentRect(pOut: [*c]ImRect, window: ?*ImGuiWindow) void;
pub extern fn igGetTopMostPopupModal() ?*ImGuiWindow;
pub extern fn igFindBestWindowPosForPopup(pOut: [*c]ImVec2, window: ?*ImGuiWindow) void;
pub extern fn igFindBestWindowPosForPopupEx(pOut: [*c]ImVec2, ref_pos: ImVec2, size: ImVec2, last_dir: [*c]ImGuiDir, r_outer: ImRect, r_avoid: ImRect, policy: ImGuiPopupPositionPolicy) void;
pub extern fn igBeginViewportSideBar(name: [*c]const u8, viewport: [*c]ImGuiViewport, dir: ImGuiDir, size: f32, window_flags: ImGuiWindowFlags) bool;
pub extern fn igBeginMenuEx(label: [*c]const u8, icon: [*c]const u8, enabled: bool) bool;
pub extern fn igMenuItemEx(label: [*c]const u8, icon: [*c]const u8, shortcut: [*c]const u8, selected: bool, enabled: bool) bool;
pub extern fn igBeginComboPopup(popup_id: ImGuiID, bb: ImRect, flags: ImGuiComboFlags) bool;
pub extern fn igBeginComboPreview() bool;
pub extern fn igEndComboPreview() void;
pub extern fn igNavInitWindow(window: ?*ImGuiWindow, force_reinit: bool) void;
pub extern fn igNavInitRequestApplyResult() void;
pub extern fn igNavMoveRequestButNoResultYet() bool;
pub extern fn igNavMoveRequestSubmit(move_dir: ImGuiDir, clip_dir: ImGuiDir, move_flags: ImGuiNavMoveFlags, scroll_flags: ImGuiScrollFlags) void;
pub extern fn igNavMoveRequestForward(move_dir: ImGuiDir, clip_dir: ImGuiDir, move_flags: ImGuiNavMoveFlags, scroll_flags: ImGuiScrollFlags) void;
pub extern fn igNavMoveRequestResolveWithLastItem() void;
pub extern fn igNavMoveRequestCancel() void;
pub extern fn igNavMoveRequestApplyResult() void;
pub extern fn igNavMoveRequestTryWrapping(window: ?*ImGuiWindow, move_flags: ImGuiNavMoveFlags) void;
pub extern fn igGetNavInputAmount(n: ImGuiNavInput, mode: ImGuiInputReadMode) f32;
pub extern fn igGetNavInputAmount2d(pOut: [*c]ImVec2, dir_sources: ImGuiNavDirSourceFlags, mode: ImGuiInputReadMode, slow_factor: f32, fast_factor: f32) void;
pub extern fn igCalcTypematicRepeatAmount(t0: f32, t1: f32, repeat_delay: f32, repeat_rate: f32) c_int;
pub extern fn igActivateItem(id: ImGuiID) void;
pub extern fn igSetNavID(id: ImGuiID, nav_layer: ImGuiNavLayer, focus_scope_id: ImGuiID, rect_rel: ImRect) void;
pub extern fn igPushFocusScope(id: ImGuiID) void;
pub extern fn igPopFocusScope() void;
pub extern fn igGetFocusedFocusScope() ImGuiID;
pub extern fn igGetFocusScope() ImGuiID;
pub extern fn igSetItemUsingMouseWheel() void;
pub extern fn igSetActiveIdUsingNavAndKeys() void;
pub extern fn igIsActiveIdUsingNavDir(dir: ImGuiDir) bool;
pub extern fn igIsActiveIdUsingNavInput(input: ImGuiNavInput) bool;
pub extern fn igIsActiveIdUsingKey(key: ImGuiKey) bool;
pub extern fn igIsMouseDragPastThreshold(button: ImGuiMouseButton, lock_threshold: f32) bool;
pub extern fn igIsKeyPressedMap(key: ImGuiKey, repeat: bool) bool;
pub extern fn igIsNavInputDown(n: ImGuiNavInput) bool;
pub extern fn igIsNavInputTest(n: ImGuiNavInput, rm: ImGuiInputReadMode) bool;
pub extern fn igGetMergedKeyModFlags() ImGuiKeyModFlags;
pub extern fn igBeginDragDropTargetCustom(bb: ImRect, id: ImGuiID) bool;
pub extern fn igClearDragDrop() void;
pub extern fn igIsDragDropPayloadBeingAccepted() bool;
pub extern fn igSetWindowClipRectBeforeSetChannel(window: ?*ImGuiWindow, clip_rect: ImRect) void;
pub extern fn igBeginColumns(str_id: [*c]const u8, count: c_int, flags: ImGuiOldColumnFlags) void;
pub extern fn igEndColumns() void;
pub extern fn igPushColumnClipRect(column_index: c_int) void;
pub extern fn igPushColumnsBackground() void;
pub extern fn igPopColumnsBackground() void;
pub extern fn igGetColumnsID(str_id: [*c]const u8, count: c_int) ImGuiID;
pub extern fn igFindOrCreateColumns(window: ?*ImGuiWindow, id: ImGuiID) [*c]ImGuiOldColumns;
pub extern fn igGetColumnOffsetFromNorm(columns: [*c]const ImGuiOldColumns, offset_norm: f32) f32;
pub extern fn igGetColumnNormFromOffset(columns: [*c]const ImGuiOldColumns, offset: f32) f32;
pub extern fn igTableOpenContextMenu(column_n: c_int) void;
pub extern fn igTableSetColumnWidth(column_n: c_int, width: f32) void;
pub extern fn igTableSetColumnSortDirection(column_n: c_int, sort_direction: ImGuiSortDirection, append_to_sort_specs: bool) void;
pub extern fn igTableGetHoveredColumn() c_int;
pub extern fn igTableGetHeaderRowHeight() f32;
pub extern fn igTablePushBackgroundChannel() void;
pub extern fn igTablePopBackgroundChannel() void;
pub extern fn igGetCurrentTable() ?*ImGuiTable;
pub extern fn igTableFindByID(id: ImGuiID) ?*ImGuiTable;
pub extern fn igBeginTableEx(name: [*c]const u8, id: ImGuiID, columns_count: c_int, flags: ImGuiTableFlags, outer_size: ImVec2, inner_width: f32) bool;
pub extern fn igTableBeginInitMemory(table: ?*ImGuiTable, columns_count: c_int) void;
pub extern fn igTableBeginApplyRequests(table: ?*ImGuiTable) void;
pub extern fn igTableSetupDrawChannels(table: ?*ImGuiTable) void;
pub extern fn igTableUpdateLayout(table: ?*ImGuiTable) void;
pub extern fn igTableUpdateBorders(table: ?*ImGuiTable) void;
pub extern fn igTableUpdateColumnsWeightFromWidth(table: ?*ImGuiTable) void;
pub extern fn igTableDrawBorders(table: ?*ImGuiTable) void;
pub extern fn igTableDrawContextMenu(table: ?*ImGuiTable) void;
pub extern fn igTableMergeDrawChannels(table: ?*ImGuiTable) void;
pub extern fn igTableSortSpecsSanitize(table: ?*ImGuiTable) void;
pub extern fn igTableSortSpecsBuild(table: ?*ImGuiTable) void;
pub extern fn igTableGetColumnNextSortDirection(column: ?*ImGuiTableColumn) ImGuiSortDirection;
pub extern fn igTableFixColumnSortDirection(table: ?*ImGuiTable, column: ?*ImGuiTableColumn) void;
pub extern fn igTableGetColumnWidthAuto(table: ?*ImGuiTable, column: ?*ImGuiTableColumn) f32;
pub extern fn igTableBeginRow(table: ?*ImGuiTable) void;
pub extern fn igTableEndRow(table: ?*ImGuiTable) void;
pub extern fn igTableBeginCell(table: ?*ImGuiTable, column_n: c_int) void;
pub extern fn igTableEndCell(table: ?*ImGuiTable) void;
pub extern fn igTableGetCellBgRect(pOut: [*c]ImRect, table: ?*const ImGuiTable, column_n: c_int) void;
pub extern fn igTableGetColumnName_TablePtr(table: ?*const ImGuiTable, column_n: c_int) [*c]const u8;
pub extern fn igTableGetColumnResizeID(table: ?*const ImGuiTable, column_n: c_int, instance_no: c_int) ImGuiID;
pub extern fn igTableGetMaxColumnWidth(table: ?*const ImGuiTable, column_n: c_int) f32;
pub extern fn igTableSetColumnWidthAutoSingle(table: ?*ImGuiTable, column_n: c_int) void;
pub extern fn igTableSetColumnWidthAutoAll(table: ?*ImGuiTable) void;
pub extern fn igTableRemove(table: ?*ImGuiTable) void;
pub extern fn igTableGcCompactTransientBuffers_TablePtr(table: ?*ImGuiTable) void;
pub extern fn igTableGcCompactTransientBuffers_TableTempDataPtr(table: [*c]ImGuiTableTempData) void;
pub extern fn igTableGcCompactSettings() void;
pub extern fn igTableLoadSettings(table: ?*ImGuiTable) void;
pub extern fn igTableSaveSettings(table: ?*ImGuiTable) void;
pub extern fn igTableResetSettings(table: ?*ImGuiTable) void;
pub extern fn igTableGetBoundSettings(table: ?*ImGuiTable) [*c]ImGuiTableSettings;
pub extern fn igTableSettingsInstallHandler(context: [*c]ImGuiContext) void;
pub extern fn igTableSettingsCreate(id: ImGuiID, columns_count: c_int) [*c]ImGuiTableSettings;
pub extern fn igTableSettingsFindByID(id: ImGuiID) [*c]ImGuiTableSettings;
pub extern fn igBeginTabBarEx(tab_bar: [*c]ImGuiTabBar, bb: ImRect, flags: ImGuiTabBarFlags) bool;
pub extern fn igTabBarFindTabByID(tab_bar: [*c]ImGuiTabBar, tab_id: ImGuiID) [*c]ImGuiTabItem;
pub extern fn igTabBarRemoveTab(tab_bar: [*c]ImGuiTabBar, tab_id: ImGuiID) void;
pub extern fn igTabBarCloseTab(tab_bar: [*c]ImGuiTabBar, tab: [*c]ImGuiTabItem) void;
pub extern fn igTabBarQueueReorder(tab_bar: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem, offset: c_int) void;
pub extern fn igTabBarQueueReorderFromMousePos(tab_bar: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem, mouse_pos: ImVec2) void;
pub extern fn igTabBarProcessReorder(tab_bar: [*c]ImGuiTabBar) bool;
pub extern fn igTabItemEx(tab_bar: [*c]ImGuiTabBar, label: [*c]const u8, p_open: [*c]bool, flags: ImGuiTabItemFlags) bool;
pub extern fn igTabItemCalcSize(pOut: [*c]ImVec2, label: [*c]const u8, has_close_button: bool) void;
pub extern fn igTabItemBackground(draw_list: [*c]ImDrawList, bb: ImRect, flags: ImGuiTabItemFlags, col: ImU32) void;
pub extern fn igTabItemLabelAndCloseButton(draw_list: [*c]ImDrawList, bb: ImRect, flags: ImGuiTabItemFlags, frame_padding: ImVec2, label: [*c]const u8, tab_id: ImGuiID, close_button_id: ImGuiID, is_contents_visible: bool, out_just_closed: [*c]bool, out_text_clipped: [*c]bool) void;
pub extern fn igRenderText(pos: ImVec2, text: [*c]const u8, text_end: [*c]const u8, hide_text_after_hash: bool) void;
pub extern fn igRenderTextWrapped(pos: ImVec2, text: [*c]const u8, text_end: [*c]const u8, wrap_width: f32) void;
pub extern fn igRenderTextClipped(pos_min: ImVec2, pos_max: ImVec2, text: [*c]const u8, text_end: [*c]const u8, text_size_if_known: [*c]const ImVec2, @"align": ImVec2, clip_rect: [*c]const ImRect) void;
pub extern fn igRenderTextClippedEx(draw_list: [*c]ImDrawList, pos_min: ImVec2, pos_max: ImVec2, text: [*c]const u8, text_end: [*c]const u8, text_size_if_known: [*c]const ImVec2, @"align": ImVec2, clip_rect: [*c]const ImRect) void;
pub extern fn igRenderTextEllipsis(draw_list: [*c]ImDrawList, pos_min: ImVec2, pos_max: ImVec2, clip_max_x: f32, ellipsis_max_x: f32, text: [*c]const u8, text_end: [*c]const u8, text_size_if_known: [*c]const ImVec2) void;
pub extern fn igRenderFrame(p_min: ImVec2, p_max: ImVec2, fill_col: ImU32, border: bool, rounding: f32) void;
pub extern fn igRenderFrameBorder(p_min: ImVec2, p_max: ImVec2, rounding: f32) void;
pub extern fn igRenderColorRectWithAlphaCheckerboard(draw_list: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, fill_col: ImU32, grid_step: f32, grid_off: ImVec2, rounding: f32, flags: ImDrawFlags) void;
pub extern fn igRenderNavHighlight(bb: ImRect, id: ImGuiID, flags: ImGuiNavHighlightFlags) void;
pub extern fn igFindRenderedTextEnd(text: [*c]const u8, text_end: [*c]const u8) [*c]const u8;
pub extern fn igRenderArrow(draw_list: [*c]ImDrawList, pos: ImVec2, col: ImU32, dir: ImGuiDir, scale: f32) void;
pub extern fn igRenderBullet(draw_list: [*c]ImDrawList, pos: ImVec2, col: ImU32) void;
pub extern fn igRenderCheckMark(draw_list: [*c]ImDrawList, pos: ImVec2, col: ImU32, sz: f32) void;
pub extern fn igRenderMouseCursor(draw_list: [*c]ImDrawList, pos: ImVec2, scale: f32, mouse_cursor: ImGuiMouseCursor, col_fill: ImU32, col_border: ImU32, col_shadow: ImU32) void;
pub extern fn igRenderArrowPointingAt(draw_list: [*c]ImDrawList, pos: ImVec2, half_sz: ImVec2, direction: ImGuiDir, col: ImU32) void;
pub extern fn igRenderRectFilledRangeH(draw_list: [*c]ImDrawList, rect: ImRect, col: ImU32, x_start_norm: f32, x_end_norm: f32, rounding: f32) void;
pub extern fn igRenderRectFilledWithHole(draw_list: [*c]ImDrawList, outer: ImRect, inner: ImRect, col: ImU32, rounding: f32) void;
pub extern fn igTextEx(text: [*c]const u8, text_end: [*c]const u8, flags: ImGuiTextFlags) void;
pub extern fn igButtonEx(label: [*c]const u8, size_arg: ImVec2, flags: ImGuiButtonFlags) bool;
pub extern fn igCloseButton(id: ImGuiID, pos: ImVec2) bool;
pub extern fn igCollapseButton(id: ImGuiID, pos: ImVec2) bool;
pub extern fn igArrowButtonEx(str_id: [*c]const u8, dir: ImGuiDir, size_arg: ImVec2, flags: ImGuiButtonFlags) bool;
pub extern fn igScrollbar(axis: ImGuiAxis) void;
pub extern fn igScrollbarEx(bb: ImRect, id: ImGuiID, axis: ImGuiAxis, p_scroll_v: [*c]ImS64, avail_v: ImS64, contents_v: ImS64, flags: ImDrawFlags) bool;
pub extern fn igImageButtonEx(id: ImGuiID, texture_id: ImTextureID, size: ImVec2, uv0: ImVec2, uv1: ImVec2, padding: ImVec2, bg_col: ImVec4, tint_col: ImVec4) bool;
pub extern fn igGetWindowScrollbarRect(pOut: [*c]ImRect, window: ?*ImGuiWindow, axis: ImGuiAxis) void;
pub extern fn igGetWindowScrollbarID(window: ?*ImGuiWindow, axis: ImGuiAxis) ImGuiID;
pub extern fn igGetWindowResizeCornerID(window: ?*ImGuiWindow, n: c_int) ImGuiID;
pub extern fn igGetWindowResizeBorderID(window: ?*ImGuiWindow, dir: ImGuiDir) ImGuiID;
pub extern fn igSeparatorEx(flags: ImGuiSeparatorFlags) void;
pub extern fn igCheckboxFlags_S64Ptr(label: [*c]const u8, flags: [*c]ImS64, flags_value: ImS64) bool;
pub extern fn igCheckboxFlags_U64Ptr(label: [*c]const u8, flags: [*c]ImU64, flags_value: ImU64) bool;
pub extern fn igButtonBehavior(bb: ImRect, id: ImGuiID, out_hovered: [*c]bool, out_held: [*c]bool, flags: ImGuiButtonFlags) bool;
pub extern fn igDragBehavior(id: ImGuiID, data_type: ImGuiDataType, p_v: ?*anyopaque, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderBehavior(bb: ImRect, id: ImGuiID, data_type: ImGuiDataType, p_v: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags, out_grab_bb: [*c]ImRect) bool;
pub extern fn igSplitterBehavior(bb: ImRect, id: ImGuiID, axis: ImGuiAxis, size1: [*c]f32, size2: [*c]f32, min_size1: f32, min_size2: f32, hover_extend: f32, hover_visibility_delay: f32) bool;
pub extern fn igTreeNodeBehavior(id: ImGuiID, flags: ImGuiTreeNodeFlags, label: [*c]const u8, label_end: [*c]const u8) bool;
pub extern fn igTreeNodeBehaviorIsOpen(id: ImGuiID, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igTreePushOverrideID(id: ImGuiID) void;
pub extern fn igDataTypeGetInfo(data_type: ImGuiDataType) [*c]const ImGuiDataTypeInfo;
pub extern fn igDataTypeFormatString(buf: [*c]u8, buf_size: c_int, data_type: ImGuiDataType, p_data: ?*const anyopaque, format: [*c]const u8) c_int;
pub extern fn igDataTypeApplyOp(data_type: ImGuiDataType, op: c_int, output: ?*anyopaque, arg_1: ?*const anyopaque, arg_2: ?*const anyopaque) void;
pub extern fn igDataTypeApplyOpFromText(buf: [*c]const u8, initial_value_buf: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, format: [*c]const u8) bool;
pub extern fn igDataTypeCompare(data_type: ImGuiDataType, arg_1: ?*const anyopaque, arg_2: ?*const anyopaque) c_int;
pub extern fn igDataTypeClamp(data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque) bool;
pub extern fn igInputTextEx(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: c_int, size_arg: ImVec2, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igTempInputText(bb: ImRect, id: ImGuiID, label: [*c]const u8, buf: [*c]u8, buf_size: c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igTempInputScalar(bb: ImRect, id: ImGuiID, label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, format: [*c]const u8, p_clamp_min: ?*const anyopaque, p_clamp_max: ?*const anyopaque) bool;
pub extern fn igTempInputIsActive(id: ImGuiID) bool;
pub extern fn igGetInputTextState(id: ImGuiID) [*c]ImGuiInputTextState;
pub extern fn igColorTooltip(text: [*c]const u8, col: [*c]const f32, flags: ImGuiColorEditFlags) void;
pub extern fn igColorEditOptionsPopup(col: [*c]const f32, flags: ImGuiColorEditFlags) void;
pub extern fn igColorPickerOptionsPopup(ref_col: [*c]const f32, flags: ImGuiColorEditFlags) void;
pub extern fn igPlotEx(plot_type: ImGuiPlotType, label: [*c]const u8, values_getter: ?fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, frame_size: ImVec2) c_int;
pub extern fn igShadeVertsLinearColorGradientKeepAlpha(draw_list: [*c]ImDrawList, vert_start_idx: c_int, vert_end_idx: c_int, gradient_p0: ImVec2, gradient_p1: ImVec2, col0: ImU32, col1: ImU32) void;
pub extern fn igShadeVertsLinearUV(draw_list: [*c]ImDrawList, vert_start_idx: c_int, vert_end_idx: c_int, a: ImVec2, b: ImVec2, uv_a: ImVec2, uv_b: ImVec2, clamp: bool) void;
pub extern fn igGcCompactTransientMiscBuffers() void;
pub extern fn igGcCompactTransientWindowBuffers(window: ?*ImGuiWindow) void;
pub extern fn igGcAwakeTransientWindowBuffers(window: ?*ImGuiWindow) void;
pub extern fn igErrorCheckEndFrameRecover(log_callback: ImGuiErrorLogCallback, user_data: ?*anyopaque) void;
pub extern fn igErrorCheckEndWindowRecover(log_callback: ImGuiErrorLogCallback, user_data: ?*anyopaque) void;
pub extern fn igDebugDrawItemRect(col: ImU32) void;
pub extern fn igDebugStartItemPicker() void;
pub extern fn igShowFontAtlas(atlas: [*c]ImFontAtlas) void;
pub extern fn igDebugHookIdInfo(id: ImGuiID, data_type: ImGuiDataType, data_id: ?*const anyopaque, data_id_end: ?*const anyopaque) void;
pub extern fn igDebugNodeColumns(columns: [*c]ImGuiOldColumns) void;
pub extern fn igDebugNodeDrawList(window: ?*ImGuiWindow, draw_list: [*c]const ImDrawList, label: [*c]const u8) void;
pub extern fn igDebugNodeDrawCmdShowMeshAndBoundingBox(out_draw_list: [*c]ImDrawList, draw_list: [*c]const ImDrawList, draw_cmd: [*c]const ImDrawCmd, show_mesh: bool, show_aabb: bool) void;
pub extern fn igDebugNodeFont(font: [*c]ImFont) void;
pub extern fn igDebugNodeStorage(storage: [*c]ImGuiStorage, label: [*c]const u8) void;
pub extern fn igDebugNodeTabBar(tab_bar: [*c]ImGuiTabBar, label: [*c]const u8) void;
pub extern fn igDebugNodeTable(table: ?*ImGuiTable) void;
pub extern fn igDebugNodeTableSettings(settings: [*c]ImGuiTableSettings) void;
pub extern fn igDebugNodeWindow(window: ?*ImGuiWindow, label: [*c]const u8) void;
pub extern fn igDebugNodeWindowSettings(settings: [*c]ImGuiWindowSettings) void;
pub extern fn igDebugNodeWindowsList(windows: [*c]ImVector_ImGuiWindowPtr, label: [*c]const u8) void;
pub extern fn igDebugNodeViewport(viewport: [*c]ImGuiViewportP) void;
pub extern fn igDebugRenderViewportThumbnail(draw_list: [*c]ImDrawList, viewport: [*c]ImGuiViewportP, bb: ImRect) void;
pub extern fn igImFontAtlasGetBuilderForStbTruetype() [*c]const ImFontBuilderIO;
pub extern fn igImFontAtlasBuildInit(atlas: [*c]ImFontAtlas) void;
pub extern fn igImFontAtlasBuildSetupFont(atlas: [*c]ImFontAtlas, font: [*c]ImFont, font_config: [*c]ImFontConfig, ascent: f32, descent: f32) void;
pub extern fn igImFontAtlasBuildPackCustomRects(atlas: [*c]ImFontAtlas, stbrp_context_opaque: ?*anyopaque) void;
pub extern fn igImFontAtlasBuildFinish(atlas: [*c]ImFontAtlas) void;
pub extern fn igImFontAtlasBuildRender8bppRectFromString(atlas: [*c]ImFontAtlas, x: c_int, y: c_int, w: c_int, h: c_int, in_str: [*c]const u8, in_marker_char: u8, in_marker_pixel_value: u8) void;
pub extern fn igImFontAtlasBuildRender32bppRectFromString(atlas: [*c]ImFontAtlas, x: c_int, y: c_int, w: c_int, h: c_int, in_str: [*c]const u8, in_marker_char: u8, in_marker_pixel_value: c_uint) void;
pub extern fn igImFontAtlasBuildMultiplyCalcLookupTable(out_table: [*c]u8, in_multiply_factor: f32) void;
pub extern fn igImFontAtlasBuildMultiplyRectAlpha8(table: [*c]const u8, pixels: [*c]u8, x: c_int, y: c_int, w: c_int, h: c_int, stride: c_int) void;
pub extern fn igLogText(fmt: [*c]const u8, ...) void;
pub extern fn ImGuiTextBuffer_appendf(buffer: [*c]struct_ImGuiTextBuffer, fmt: [*c]const u8, ...) void;
pub extern fn igGET_FLT_MAX(...) f32;
pub extern fn igGET_FLT_MIN(...) f32;
pub extern fn ImVector_ImWchar_create(...) [*c]ImVector_ImWchar;
pub extern fn ImVector_ImWchar_destroy(self: [*c]ImVector_ImWchar) void;
pub extern fn ImVector_ImWchar_Init(p: [*c]ImVector_ImWchar) void;
pub extern fn ImVector_ImWchar_UnInit(p: [*c]ImVector_ImWchar) void;
