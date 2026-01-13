cbuffer Context : register(b0, space3)
{
	float2 resolution;
	float2 cursor;
	float  time;
};

struct PSInput
{
	float4 v_pos   : SV_POSITION;
	float4 v_color : COLOR0;
	float2 v_uv    : TEXCOORD0;
};

struct PSOutput
{
	float4 o_color : SV_Target;
};

// ──────────────────────────────────────────────
// ─────────────── CONSTANTS ─────────────────────
// ──────────────────────────────────────────────

#define DRAG_MULT          0.38
#define WATER_DEPTH        1.0
#define CAMERA_HEIGHT      1.5
#define ITERATIONS_RAYMARCH 12
#define ITERATIONS_NORMAL   28   // lowered a bit from 36 for perf

#define NormalizedMouse    (cursor / resolution)

// ──────────────────────────────────────────────
// ──────── WAVE FUNCTIONS ───────────────────────
// ──────────────────────────────────────────────

float2 wavedx(float2 position, float2 direction, float frequency, float timeshift)
{
	float x = dot(direction, position) * frequency + timeshift;
	float wave = exp(sin(x) - 1.0);
	float dx   = wave * cos(x);
	return float2(wave, -dx);
}

float getwaves(float2 position, int iterations)
{
	float wavePhaseShift = length(position) * 0.1;
	float iter           = 0.0;
	float frequency      = 1.0;
	float timeMultiplier = 2.0;
	float weight         = 1.0;
	float sumOfValues    = 0.0;
	float sumOfWeights   = 0.0;

	for (int i = 0; i < iterations; i++)
	{
		float2 p = float2(sin(iter), cos(iter));

		float2 res = wavedx(position, p, frequency, time * timeMultiplier + wavePhaseShift);

		position += p * res.y * weight * DRAG_MULT;

		sumOfValues += res.x * weight;
		sumOfWeights += weight;

		weight       = lerp(weight, 0.0, 0.2);
		frequency   *= 1.18;
		timeMultiplier *= 1.07;
		iter        += 1232.399963;
	}

	return sumOfValues / sumOfWeights;
}

// ──────────────────────────────────────────────
// ──────── RAYMARCH & NORMAL ────────────────────
// ──────────────────────────────────────────────

float raymarchwater(float3 camera, float3 start, float3 end, float depth)
{
	float3 pos = start;
	float3 dir = normalize(end - start);

	for (int i = 0; i < 64; i++)
	{
		float height = getwaves(pos.xz, ITERATIONS_RAYMARCH) * depth - depth;

		if (height + 0.01 > pos.y)
		{
			return distance(pos, camera);
		}

		pos += dir * (pos.y - height);
	}

	// fallback – assume hit at top
	return distance(start, camera);
}

float3 normal(float2 pos, float e, float depth)
{
	float2 ex = float2(e, 0.0);
	float  H  = getwaves(pos, ITERATIONS_NORMAL) * depth;

	float3 a = float3(pos.x, H, pos.y);

	float3 b = float3(pos.x - e, getwaves(pos - ex.xy, ITERATIONS_NORMAL) * depth, pos.y);
	float3 c = float3(pos.x,       getwaves(pos + ex.yx, ITERATIONS_NORMAL) * depth, pos.y + e);

	return normalize(cross(a - b, a - c));
}

// ──────────────────────────────────────────────
// ──────── CAMERA & RAY ─────────────────────────
// ──────────────────────────────────────────────

float3x3 createRotationMatrixAxisAngle(float3 axis, float angle)
{
	float s = sin(angle);
	float c = cos(angle);
	float oc = 1.0 - c;

	return float3x3(
			oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
			oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
			oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c
			);
}

float3 getRay(float2 fragCoord)
{
    // 1. Calculate UVs
    float2 uv = (fragCoord * 2.0 - resolution) / resolution.y;

    // 2. FLIP THE Y-AXIS HERE
    uv.y = -uv.y;

    float3 proj = normalize(float3(uv.x, uv.y, 1.5));

    // Simple mouse look
    float mx = (NormalizedMouse.x - 0.5) * 2.0 * 3.14159 * 0.6;

    // Note: You may also need to invert your mouse Y logic
    // if the camera movement feels inverted.
    float my = (NormalizedMouse.y - 0.5) * 2.0 * 1.2 + 0.4;

    float3x3 rotY = createRotationMatrixAxisAngle(float3(0,1,0), mx);
    float3x3 rotX = createRotationMatrixAxisAngle(float3(1,0,0), my);

    return mul(rotX, mul(rotY, proj));
}

// ──────────────────────────────────────────────
// ──────── ATMOSPHERE & SUN ─────────────────────
// ──────────────────────────────────────────────

float3 extra_cheap_atmosphere(float3 raydir, float3 sundir)
{
	float special_trick  = 1.0 / (raydir.y * 1.0 + 0.1);
	float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);

	float raysundt = pow(abs(dot(sundir, raydir)), 2.0);
	float sundt    = pow(max(0.0, dot(sundir, raydir)), 8.0);
	float mymie    = sundt * special_trick * 0.2;

	float3 suncolor = lerp(float3(1.0,1.0,1.0),
			max(float3(0.0,0.0,0.0), float3(1.0,1.0,1.0) - float3(5.5,13.0,22.4)/22.4),
			special_trick2);

	float3 bluesky  = float3(5.5,13.0,22.4)/22.4 * suncolor;
	float3 bluesky2 = max(float3(0.0,0.0,0.0), bluesky - float3(5.5,13.0,22.4) * 0.002 * (special_trick - 6.0 * sundir.y * sundir.y));

	bluesky2 *= special_trick * (0.24 + raysundt * 0.24);

	return bluesky2 * (1.0 + 1.0 * pow(1.0 - raydir.y, 3.0));
}

float3 getSunDirection()
{
	return normalize(float3(-0.07735, 0.5 + sin(time * 0.2 + 2.6) * 0.45, 0.57735));
}

float3 getAtmosphere(float3 dir)
{
	return extra_cheap_atmosphere(dir, getSunDirection()) * 0.5;
}

float getSun(float3 dir)
{
	return pow(max(0.0, dot(dir, getSunDirection())), 720.0) * 210.0;
}

float3 aces_tonemap(float3 color)
{
	float3x3 m1 = float3x3(
			0.59719, 0.07600, 0.02840,
			0.35458, 0.90834, 0.13383,
			0.04823, 0.01566, 0.83777
			);

	float3x3 m2 = float3x3(
			1.60475, -0.10208, -0.00327,
			-0.53108, 1.10813, -0.07276,
			-0.07367, -0.00605, 1.07602
			);

	float3 v = mul(m1, color);
	float3 a = v * (v + 0.0245786) - 0.000090537;
	float3 b = v * (0.983729 * v + 0.4329510) + 0.238081;

	return pow(saturate(mul(m2, a / b)), 1.0 / 2.2);
}

// ──────────────────────────────────────────────
// ──────── MAIN ──────────────────────────────────
// ──────────────────────────────────────────────

PSOutput main(PSInput input)
{
	PSOutput output;

	float2 fragCoord = input.v_uv * resolution;

	float3 ray = getRay(fragCoord);

	if (ray.y >= 0.0)
	{
		// sky
		float3 C = getAtmosphere(ray) + getSun(ray);
		output.o_color = float4(aces_tonemap(C * 2.0), 1.0);
		return output;
	}

	// water
	float3 origin      = float3(time * 0.2, CAMERA_HEIGHT, 0.0);
	float3 waterPlaneHigh = float3(0,  0,          0);
	float3 waterPlaneLow  = float3(0, -WATER_DEPTH, 0);

	float highPlaneHit = max(0.0, -origin.y / ray.y);   // simplified plane intersect
	float lowPlaneHit  = max(0.0, (WATER_DEPTH - origin.y) / -ray.y);

	float3 highHitPos = origin + ray * highPlaneHit;
	float3 lowHitPos  = origin + ray * lowPlaneHit;

	float dist = raymarchwater(origin, highHitPos, lowHitPos, WATER_DEPTH);
	float3 waterHitPos = origin + ray * dist;

	float3 N = normal(waterHitPos.xz, 0.01, WATER_DEPTH);

	// distance fade normal toward flat
	N = lerp(N, float3(0,1,0), 0.8 * min(1.0, sqrt(dist * 0.01) * 1.1));

	float fresnel = 0.04 + (1.0 - 0.04) * pow(1.0 - max(0.0, dot(-N, ray)), 5.0);

	float3 R = normalize(reflect(ray, N));
	R.y = abs(R.y);   // force upward reflection

	float3 reflection = getAtmosphere(R) + getSun(R);
	float3 scattering = float3(0.0293, 0.0698, 0.1717) * 0.1 * (0.2 + (waterHitPos.y + WATER_DEPTH) / WATER_DEPTH);

	float3 C = fresnel * reflection + (1.0 - fresnel) * scattering;

	output.o_color = float4(aces_tonemap(C * 2.0), 1.0);

	return output;
}
