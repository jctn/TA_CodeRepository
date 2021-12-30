Shader "Code Repository/Effect/FlowOutLineS/Blur"
{
 
	Properties
	{
		[HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
	}
 

	HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		struct appdata
        {
            float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
        };

		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv  : TEXCOORD0;
		};
 
		TEXTURE2D(_MainTex);            
		SAMPLER(sampler_MainTex);

		CBUFFER_START(UnityPerMaterial)
		float4 _MainTex_TexelSize;
		CBUFFER_END
 
		float4x4 _BlurParams; //[blurx, blury, isUp, 0]

		half4 Blur(v2f i, float2 dir)
		{
			half4 c = half4(0,0,0,0);
			half4 curColor = 0.4 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

			#if MASKR
			float2 offset = dir * float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
			float isUp = _BlurParams[0][2];
			half r = 0;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).r;
			c.r = curColor.r + r;

			#elif MASKRG
			float2 offset = dir * float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
			float isUp = _BlurParams[0][2];
			half r = 0;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).r;

			offset = dir * float2(_BlurParams[1][0], _BlurParams[1][1]) * _MainTex_TexelSize.xy;
			isUp = _BlurParams[1][2];
			half g = 0;
			g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).g;
			g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).g;
			g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).g;
			c.rg = curColor.rg + half2(r, g);

			#elif MASKRGB
			float2 offset = dir * float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
			float isUp = _BlurParams[0][2];
			half r = 0;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).r;

			offset = dir * float2(_BlurParams[1][0], _BlurParams[1][1]) * _MainTex_TexelSize.xy;
			isUp = _BlurParams[1][2];
			half g = 0;
			g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).g;
			g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).g;
			g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).g;

			offset = dir * float2(_BlurParams[2][0], _BlurParams[2][1]) * _MainTex_TexelSize.xy;
			isUp = _BlurParams[2][2];
			half b = 0;
			b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).b;
			b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).b;
			b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).b;
			b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).b;
			b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).b;
			b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).b;
			c.rgb = curColor.rgb + half3(r, g, b);

			#elif MASKRGBA
			float2 offset = dir * float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
			float isUp = _BlurParams[0][2];
			half r = 0;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).r;
			r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).r;

			offset = dir * float2(_BlurParams[1][0], _BlurParams[1][1]) * _MainTex_TexelSize.xy;
			isUp = _BlurParams[1][2];
			half g = 0;
			g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).g;
			g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).g;
			g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).g;
			g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).g;

			offset = dir * float2(_BlurParams[2][0], _BlurParams[2][1]) * _MainTex_TexelSize.xy;
			isUp = _BlurParams[2][2];
			half b = 0;
			b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).b;
			b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).b;
			b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).b;
			b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).b;
			b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).b;
			b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).b;

			offset = dir * float2(_BlurParams[3][0], _BlurParams[3][1]) * _MainTex_TexelSize.xy;
			isUp = _BlurParams[3][2];
			half a = 0;
			a += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp))).a;
			a += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1)).a;
			a += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp))).a;
			a += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1)).a;
			a += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp))).a;
			a += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1)).a;
			c.rgba = curColor + half4(r, g, b, a);

			#else
			float2 offset = dir * float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
			float isUp = _BlurParams[0][2];
			c += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(1, 0.1 * isUp + (1 - isUp)));
			c += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + offset * float2(-1, -1));
			c += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv +  2 * offset * float2(1, 0.1 * isUp + (1 - isUp)));
			c += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * offset * float2(-1, -1));
			c += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(1, 0.1 * isUp + (1 - isUp)));
			c += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * offset * float2(-1, -1));
			c += curColor;
			#endif

			return c;				
		}

		v2f Vert(appdata v)
		{
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;
			return o;
		}

		half4 FragBlurH(v2f i) : SV_Target
		{
			return Blur(i, float2(1, 0));
		}

		half4 FragBlurV(v2f i) : SV_Target
		{
			return Blur(i, float2(0, 1));
		}

	ENDHLSL

	SubShader
	{
		Tags {"RenderPipeline" = "UniversalPipeline" }

		ZTest Always
		Cull Off
		ZWrite Off

		//高斯模糊,H
		Pass
		{
			Name "Gaussian Blur Horizontal"
			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment FragBlurH	
			#pragma multi_compile _ MASKR MASKRG MASKRGB MASKRGBA 
			ENDHLSL
		}

		//高斯模糊,V
		Pass
		{
			Name "Gaussian Blur Vertical"
			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment FragBlurV	
			#pragma multi_compile _ MASKR MASKRG MASKRGB MASKRGBA 
			ENDHLSL
		}
	}
}