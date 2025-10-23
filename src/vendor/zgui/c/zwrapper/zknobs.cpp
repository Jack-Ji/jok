#include "imgui.h"

#include "imgui-knobs.h"

#include "imgui_internal.h"

#ifndef ZGUI_API
#define ZGUI_API
#endif

//--------------------------------------------------------------------------------------------------
//
// imgui-knobs
//
//--------------------------------------------------------------------------------------------------
extern "C"
{
    ZGUI_API bool zknobs_Knob(
        const char *label,
        float *v,
        float v_min,
        float v_max,
        float speed,
        const char *format,
        ImGuiKnobVariant variant,
        float size,
        ImGuiKnobFlags flags,
        int steps,
        float angle_min,
        float angle_max
    ){
        return ImGuiKnobs::Knob(
            label, v, v_min, v_max, speed, format, variant, size, flags, steps, angle_min, angle_max
        );
    }

    ZGUI_API bool zknobs_KnobInt(
        const char *label,
        int *v,
        int v_min,
        int v_max,
        float speed,
        const char *format,
        ImGuiKnobVariant variant,
        float size,
        ImGuiKnobFlags flags,
        int steps,
        float angle_min,
        float angle_max        
    ){
        return ImGuiKnobs::KnobInt(
            label, v, v_min, v_max, speed, format, variant, size, flags, steps, angle_min, angle_max
        );
    }
}