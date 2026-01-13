cbuffer Context : register(b0, space3) {
    float2 resolution;
    float2 cursor;
	float time;
};

Texture2D u_texture : register(t0, space2);
SamplerState u_sampler : register(s0, space2);

struct PSInput {
    float4 v_pos: SV_POSITION;
    float4 v_color : COLOR0;
    float2 v_uv : TEXCOORD0;
};

struct PSOutput {
    float4 o_color : SV_Target;
};

PSOutput main(PSInput input) {
    PSOutput output;
	float2 center = resolution / 2;
	float2 amount = (center - cursor) / (resolution.x*4);
	float3 clr;
	clr.r = u_texture.Sample(u_sampler, input.v_uv + amount).r;
	clr.g = u_texture.Sample(u_sampler, input.v_uv).g;
	clr.b = u_texture.Sample(u_sampler, input.v_uv - amount).b;
    output.o_color = float4(clr, 1);
    return output;
}
