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
	float4 color = u_texture.Sample(u_sampler, input.v_uv);
	float border = resolution.y * 0.6 + 4 * cos(time * 3 + input.v_pos.y / 10);
	if (input.v_pos.y < border) {
		output.o_color = color;
	} else {
		float xoffset = 4 * cos(time * 3 + input.v_pos.y / 10) / resolution.x;
		float yoffset = 20 * (1 + cos(time * 3 + input.v_pos.y / 40)) / resolution.y;
		float3 clr = u_texture.Sample(u_sampler, float2(
					input.v_uv.x + xoffset, -(input.v_uv.y + yoffset) + border*2)).rgb;
		float3 overlay = float3(0.5, 1, 1);
		output.o_color = float4(lerp(clr, overlay, 0.05), 1);
	}
	return output;
}
