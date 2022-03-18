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

			#if defined(MASKR)
			float4 offsetR : TEXCOORD1;

			#elif defined(MASKRG)
			float4 offsetR : TEXCOORD1;
			float4 offsetG : TEXCOORD2;

			#elif defined(MASKRGB)
			float4 offsetR : TEXCOORD1;
			float4 offsetG : TEXCOORD2;
			float4 offsetB : TEXCOORD3;

			#elif defined(MASKRGBA)
			float4 offsetR : TEXCOORD1;
			float4 offsetG : TEXCOORD2;
			float4 offsetB : TEXCOORD3;
			float4 offsetA : TEXCOORD4;

			#endif
		};
 
		TEXTURE2D(_MainTex);            
		SAMPLER(sampler_MainTex);

		CBUFFER_START(UnityPerMaterial)
		float4 _MainTex_TexelSize;
		CBUFFER_END
 
		float4x4 _BlurParams; //[blurx, blury, DistortRangeX * strengthx, DistortRangeY * strengthy]

		half4 Blur(v2f i, float2 dir)
		{
			half4 c = half4(0,0,0,0);
			#if defined(MASKR)
				half4 curColor = 0.4 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				half r = 0;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.xy * dir).r;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.zw * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.xy * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.zw * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.xy * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.zw * dir).r;
				c.r = curColor.r + r;
			#elif defined(MASKRG)
				half4 curColor = 0.4 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				half r = 0;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.xy * dir).r;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.zw * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.xy * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.zw * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.xy * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.zw * dir).r;
				c.r = curColor.r + r;

				half g = 0;
				g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetG.xy * dir).g;
				g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetG.zw * dir).g;
				g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetG.xy * dir).g;
				g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetG.zw * dir).g;
				g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetG.xy * dir).g;
				g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetG.zw * dir).g;
				c.g = curColor.g + g;
			#elif defined(MASKRGB)
				half4 curColor = 0.4 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				half r = 0;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.xy * dir).r;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.zw * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.xy * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.zw * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.xy * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.zw * dir).r;
				c.r = curColor.r + r;

				half g = 0;
				g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetG.xy * dir).g;
				g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetG.zw * dir).g;
				g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetG.xy * dir).g;
				g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetG.zw * dir).g;
				g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetG.xy * dir).g;
				g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetG.zw * dir).g;
				c.g = curColor.g + g;

				half b = 0;
				b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetB.xy * dir).b;
				b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetB.zw * dir).b;
				b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetB.xy * dir).b;
				b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetB.zw * dir).b;
				b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetB.xy * dir).b;
				b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetB.zw * dir).b;
				c.b = curColor.b + b;
			#elif defined(MASKRGBA)
				half4 curColor = 0.4 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				half r = 0;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.xy * dir).r;
				r += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetR.zw * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.xy * dir).r;
				r += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetR.zw * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.xy * dir).r;
				r += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetR.zw * dir).r;
				c.r = curColor.r + r;

				half g = 0;
				g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetG.xy * dir).g;
				g += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetG.zw * dir).g;
				g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetG.xy * dir).g;
				g += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetG.zw * dir).g;
				g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetG.xy * dir).g;
				g += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetG.zw * dir).g;
				c.g = curColor.g + g;

				half b = 0;
				b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetB.xy * dir).b;
				b += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetB.zw * dir).b;
				b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetB.xy * dir).b;
				b += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetB.zw * dir).b;
				b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetB.xy * dir).b;
				b += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetB.zw * dir).b;
				c.b = curColor.b + b;

				half a = 0;
				a += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetA.xy * dir).a;
				a += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + i.offsetA.zw * dir).a;
				a += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetA.xy * dir).a;
				a += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 2 * i.offsetA.zw * dir).a;
				a += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetA.xy * dir).a;
				a += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + 3 * i.offsetA.zw * dir).a;
				c.a = curColor.a + a;
			#else
				c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
			#endif
			return c;				
		}

		v2f Vert(appdata v)
		{
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;

			//r
			#if defined(MASKR)
				float2 offsetR = float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
				float2 signdirR = float2(_BlurParams[0][2], _BlurParams[0][3]);
				float2 positiveOfssetR = float2(lerp(1, 0.1, saturate(sign(signdirR.x))), lerp(1, 0.1, saturate(sign(signdirR.y)))); 
				float2 negativeOfssetR = float2(lerp(1, 0.1, saturate(-sign(signdirR.x))), lerp(1, 0.1, saturate(-sign(signdirR.y))));
				positiveOfssetR = positiveOfssetR * offsetR * float2(1, 1);
				negativeOfssetR = negativeOfssetR * offsetR * float2(-1, -1);
				o.offsetR.xy = positiveOfssetR;
				o.offsetR.zw = negativeOfssetR;			

			//rg
			#elif defined(MASKRG)
				float2 offsetR = float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
				float2 signdirR = float2(_BlurParams[0][2], _BlurParams[0][3]);
				float2 positiveOfssetR = float2(lerp(1, 0.1, saturate(sign(signdirR.x))), lerp(1, 0.1, saturate(sign(signdirR.y)))); 
				float2 negativeOfssetR = float2(lerp(1, 0.1, saturate(-sign(signdirR.x))), lerp(1, 0.1, saturate(-sign(signdirR.y))));
				positiveOfssetR = positiveOfssetR * offsetR * float2(1, 1);
				negativeOfssetR = negativeOfssetR * offsetR * float2(-1, -1);
				o.offsetR.xy = positiveOfssetR;
				o.offsetR.zw = negativeOfssetR;

				float2 offsetG = float2(_BlurParams[1][0], _BlurParams[1][1]) * _MainTex_TexelSize.xy;
				float2 signdirG = float2(_BlurParams[1][2], _BlurParams[1][3]);
				float2 positiveOfssetG = float2(lerp(1, 0.1, saturate(sign(signdirG.x))), lerp(1, 0.1, saturate(sign(signdirG.y)))); 
				float2 negativeOfssetG = float2(lerp(1, 0.1, saturate(-sign(signdirG.x))), lerp(1, 0.1, saturate(-sign(signdirG.y))));
				positiveOfssetG = positiveOfssetG * offsetG * float2(1, 1);
				negativeOfssetG = negativeOfssetG * offsetG * float2(-1, -1);
				o.offsetG.xy = positiveOfssetG;
				o.offsetG.zw = negativeOfssetG;

			//rgb
			#elif defined(MASKRGB)
				float2 offsetR = float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
				float2 signdirR = float2(_BlurParams[0][2], _BlurParams[0][3]);
				float2 positiveOfssetR = float2(lerp(1, 0.1, saturate(sign(signdirR.x))), lerp(1, 0.1, saturate(sign(signdirR.y)))); 
				float2 negativeOfssetR = float2(lerp(1, 0.1, saturate(-sign(signdirR.x))), lerp(1, 0.1, saturate(-sign(signdirR.y))));
				positiveOfssetR = positiveOfssetR * offsetR * float2(1, 1);
				negativeOfssetR = negativeOfssetR * offsetR * float2(-1, -1);
				o.offsetR.xy = positiveOfssetR;
				o.offsetR.zw = negativeOfssetR;

				float2 offsetG = float2(_BlurParams[1][0], _BlurParams[1][1]) * _MainTex_TexelSize.xy;
				float2 signdirG = float2(_BlurParams[1][2], _BlurParams[1][3]);
				float2 positiveOfssetG = float2(lerp(1, 0.1, saturate(sign(signdirG.x))), lerp(1, 0.1, saturate(sign(signdirG.y)))); 
				float2 negativeOfssetG = float2(lerp(1, 0.1, saturate(-sign(signdirG.x))), lerp(1, 0.1, saturate(-sign(signdirG.y))));
				positiveOfssetG = positiveOfssetG * offsetG * float2(1, 1);
				negativeOfssetG = negativeOfssetG * offsetG * float2(-1, -1);
				o.offsetG.xy = positiveOfssetG;
				o.offsetG.zw = negativeOfssetG;

				float2 offsetB = float2(_BlurParams[2][0], _BlurParams[2][1]) * _MainTex_TexelSize.xy;
				float2 signdirB = float2(_BlurParams[2][2], _BlurParams[2][3]);
				float2 positiveOfssetB = float2(lerp(1, 0.1, saturate(sign(signdirB.x))), lerp(1, 0.1, saturate(sign(signdirB.y)))); 
				float2 negativeOfssetB = float2(lerp(1, 0.1, saturate(-sign(signdirB.x))), lerp(1, 0.1, saturate(-sign(signdirB.y))));
				positiveOfssetB = positiveOfssetB * offsetB * float2(1, 1);
				negativeOfssetB = negativeOfssetB * offsetB * float2(-1, -1);
				o.offsetB.xy = positiveOfssetB;
				o.offsetB.zw = negativeOfssetB;

			//rgba
			#elif defined(MASKRGBA)
				float2 offsetR = float2(_BlurParams[0][0], _BlurParams[0][1]) * _MainTex_TexelSize.xy;
				float2 signdirR = float2(_BlurParams[0][2], _BlurParams[0][3]);
				float2 positiveOfssetR = float2(lerp(1, 0.1, saturate(sign(signdirR.x))), lerp(1, 0.1, saturate(sign(signdirR.y)))); 
				float2 negativeOfssetR = float2(lerp(1, 0.1, saturate(-sign(signdirR.x))), lerp(1, 0.1, saturate(-sign(signdirR.y))));
				positiveOfssetR = positiveOfssetR * offsetR * float2(1, 1);
				negativeOfssetR = negativeOfssetR * offsetR * float2(-1, -1);
				o.offsetR.xy = positiveOfssetR;
				o.offsetR.zw = negativeOfssetR;

				float2 offsetG = float2(_BlurParams[1][0], _BlurParams[1][1]) * _MainTex_TexelSize.xy;
				float2 signdirG = float2(_BlurParams[1][2], _BlurParams[1][3]);
				float2 positiveOfssetG = float2(lerp(1, 0.1, saturate(sign(signdirG.x))), lerp(1, 0.1, saturate(sign(signdirG.y)))); 
				float2 negativeOfssetG = float2(lerp(1, 0.1, saturate(-sign(signdirG.x))), lerp(1, 0.1, saturate(-sign(signdirG.y))));
				positiveOfssetG = positiveOfssetG * offsetG * float2(1, 1);
				negativeOfssetG = negativeOfssetG * offsetG * float2(-1, -1);
				o.offsetG.xy = positiveOfssetG;
				o.offsetG.zw = negativeOfssetG;

				float2 offsetB = float2(_BlurParams[2][0], _BlurParams[2][1]) * _MainTex_TexelSize.xy;
				float2 signdirB = float2(_BlurParams[2][2], _BlurParams[2][3]);
				float2 positiveOfssetB = float2(lerp(1, 0.1, saturate(sign(signdirB.x))), lerp(1, 0.1, saturate(sign(signdirB.y)))); 
				float2 negativeOfssetB = float2(lerp(1, 0.1, saturate(-sign(signdirB.x))), lerp(1, 0.1, saturate(-sign(signdirB.y))));
				positiveOfssetB = positiveOfssetB * offsetB * float2(1, 1);
				negativeOfssetB = negativeOfssetB * offsetB * float2(-1, -1);
				o.offsetB.xy = positiveOfssetB;
				o.offsetB.zw = negativeOfssetB;

				float2 offsetA = float2(_BlurParams[3][0], _BlurParams[3][1]) * _MainTex_TexelSize.xy;
				float2 signdirA = float2(_BlurParams[3][2], _BlurParams[3][3]);
				float2 positiveOfssetA = float2(lerp(1, 0.1, saturate(sign(signdirA.x))), lerp(1, 0.1, saturate(sign(signdirA.y)))); 
				float2 negativeOfssetA = float2(lerp(1, 0.1, saturate(-sign(signdirA.x))), lerp(1, 0.1, saturate(-sign(signdirA.y))));
				positiveOfssetA = positiveOfssetA * offsetA * float2(1, 1);
				negativeOfssetA = negativeOfssetA * offsetA * float2(-1, -1);
				o.offsetA.xy = positiveOfssetA;
				o.offsetA.zw = negativeOfssetA;

			#endif

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