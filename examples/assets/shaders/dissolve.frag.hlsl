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
	float limit = abs(2 * frac(time / 3) - 1);
	float4 color = u_texture.Sample(u_sampler, input.v_uv);
	float level = color.r;
	if (limit-0.1 < level && level < limit) {
		output.o_color = color.aaaa;
	} else {
		output.o_color = step(limit, level) * color;
	}
    return output;
}
