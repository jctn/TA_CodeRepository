//https://catlikecoding.com/unity/tutorials/rendering/part-20/	
	
	#define PARALLAX_BIAS 0
//	#define PARALLAX_OFFSET_LIMITING
	#define PARALLAX_RAYMARCHING_STEPS 10
	#define PARALLAX_RAYMARCHING_INTERPOLATE
//	#define PARALLAX_RAYMARCHING_SEARCH_STEPS 3
	#define PARALLAX_FUNCTION ParallaxRaymarching
	#define PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING


float GetParallaxHeight (float2 uv) {
	return tex2D(_ParallaxMap, uv).g;
}

float2 ParallaxOffset (float2 uv, float2 viewDir) {
	float height = GetParallaxHeight(uv);
	height -= 0.5;
	height *= _ParallaxStrength;
	return viewDir * height;
}

float2 ParallaxRaymarching (float2 uv, float2 viewDir) {
	#if !defined(PARALLAX_RAYMARCHING_STEPS)
		#define PARALLAX_RAYMARCHING_STEPS 10
	#endif
	float2 uvOffset = 0;
	float stepSize = 1.0 / PARALLAX_RAYMARCHING_STEPS;
	float2 uvDelta = viewDir * (stepSize * _ParallaxStrength);

	float stepHeight = 1;
	float surfaceHeight = GetParallaxHeight(uv);

	float2 prevUVOffset = uvOffset;
	float prevStepHeight = stepHeight;
	float prevSurfaceHeight = surfaceHeight;

	for (
		int i = 1;
		i < PARALLAX_RAYMARCHING_STEPS && stepHeight > surfaceHeight;
		i++
	) {
		prevUVOffset = uvOffset;
		prevStepHeight = stepHeight;
		prevSurfaceHeight = surfaceHeight;
		
		uvOffset -= uvDelta;
		stepHeight -= stepSize;
		surfaceHeight = GetParallaxHeight(uv + uvOffset);
	}

	#if !defined(PARALLAX_RAYMARCHING_SEARCH_STEPS)
		#define PARALLAX_RAYMARCHING_SEARCH_STEPS 0
	#endif
	#if PARALLAX_RAYMARCHING_SEARCH_STEPS > 0
		for (int i = 0; i < PARALLAX_RAYMARCHING_SEARCH_STEPS; i++) {
			uvDelta *= 0.5;
			stepSize *= 0.5;

			if (stepHeight < surfaceHeight) {
				uvOffset += uvDelta;
				stepHeight += stepSize;
			}
			else {
				uvOffset -= uvDelta;
				stepHeight -= stepSize;
			}
			surfaceHeight = GetParallaxHeight(uv + uvOffset);
		}
	#elif defined(PARALLAX_RAYMARCHING_INTERPOLATE)
		float prevDifference = prevStepHeight - prevSurfaceHeight;
		float difference = surfaceHeight - stepHeight;
		float t = prevDifference / (prevDifference + difference);
		uvOffset = prevUVOffset - uvDelta * t;
	#endif

	return uvOffset;
}

void ApplyParallax (inout Interpolators i) {
	#if defined(_PARALLAX_MAP)
		i.tangentViewDir = normalize(i.tangentViewDir);
		#if !defined(PARALLAX_OFFSET_LIMITING)
			#if !defined(PARALLAX_BIAS)
				#define PARALLAX_BIAS 0.42
			#endif
			i.tangentViewDir.xy /= (i.tangentViewDir.z + PARALLAX_BIAS);
		#endif

		#if !defined(PARALLAX_FUNCTION)
			#define PARALLAX_FUNCTION ParallaxOffset
		#endif
		float2 uvOffset = PARALLAX_FUNCTION(i.uv.xy, i.tangentViewDir.xy);
		i.uv.xy += uvOffset;
		i.uv.zw += uvOffset * (_DetailTex_ST.xy / _MainTex_ST.xy);
	#endif
}