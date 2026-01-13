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
	float2 uv = input.v_uv;
	uv += cursor / resolution / 4;
	float clr = 0;
	clr += sin(uv.x * cos(time / 15) * 80) + cos(uv.y * cos(time / 15) * 10);
	clr += sin(uv.y * sin(time / 10) * 40) + cos(uv.x * sin(time / 25) * 40);
	clr += sin(uv.x * sin(time / 5) * 10) + sin(uv.y * sin(time / 35) * 80);
	clr *= sin(time / 10) * 0.5;
	output.o_color = float4(clr, clr * 0.5, sin(clr + time / 3) * 0.75, 1);
	return output;
}
