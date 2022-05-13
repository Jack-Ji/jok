#include "imgui_impl_sdlrenderer.h"

#ifdef __cplusplus
extern "C" {
#endif

bool _ImGui_ImplSDLRenderer_Init(SDL_Renderer* renderer)
{
  return ImGui_ImplSDLRenderer_Init(renderer);
}

void _ImGui_ImplSDLRenderer_Shutdown()
{
  ImGui_ImplSDLRenderer_Shutdown();
}

void _ImGui_ImplSDLRenderer_NewFrame()
{
  ImGui_ImplSDLRenderer_NewFrame();
}

void _ImGui_ImplSDLRenderer_RenderDrawData(ImDrawData* draw_data)
{
  ImGui_ImplSDLRenderer_RenderDrawData(draw_data);
}

#ifdef __cplusplus
}
#endif
