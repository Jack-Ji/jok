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
	float3 light_pos = float3(cursor, 50);
	float3 light_dir = normalize(light_pos - input.v_pos.xyz);
	float3 normal = float3(0, 0, 1);
	float ambient = 0.25;
	float diffuse = 0.75 * max(0, dot(normal, light_dir));
	output.o_color = color * (ambient + diffuse);
    return output;
}
