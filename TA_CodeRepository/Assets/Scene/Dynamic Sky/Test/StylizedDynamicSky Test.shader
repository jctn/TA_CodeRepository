Shader "Code Repository/Scene/Stylized Dynamic Sky Test" 
{
	Properties 
	{
		_SkyColorTex ("SkyColorTex", 2D) = "white" {}
		[HDR]_SunGlowColor ("SunGlowColor", Color) = (1, 1, 1, 1)
		_SunGlowRadius ("SunGlowRadius", Range(0, 5)) = 0.5
		_SunGlowSoftening ("SunGlowSoftening", Range(0, 1)) = 0.5

		[Enum(Off,0,On,1)]_ZWrite("ZWrite", Float) = 1
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="AlphaTest+1"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float _SunGlowRadius, _SunGlowSoftening;
			half3 _SunGlowColor;
			CBUFFER_END

			TEXTURE2D(_SkyColorTex);
			SAMPLER(sampler_SkyColorTex);
		ENDHLSL

		Pass 
		{
			ZWrite[_ZWrite]
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes 
			{
				float4 positionOS : POSITION;
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;
				float3 positionOS : TEXCOORD0;
				float3 dirWS : TEXCOORD1;
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				#if UNITY_REVERSED_Z
					OUT.positionCS.z = 0.000001 * OUT.positionCS.w;
				#else
					OUT.positionCS.z = 0.999999 * OUT.positionCS.w;
				#endif			
				OUT.positionOS = IN.positionOS.xyz;
				float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				OUT.dirWS = positionWS - float3(UNITY_MATRIX_M[0][3], UNITY_MATRIX_M[1][3], UNITY_MATRIX_M[2][3]);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float3 dirWS = normalize(IN.dirWS);
				float2 skyColorUV = 1 - saturate(dirWS.y);
				half3 skyColor = SAMPLE_TEXTURE2D(_SkyColorTex, sampler_SkyColorTex, skyColorUV).rgb;
				float sun = 1 - smoothstep(_SunGlowRadius * (1 - _SunGlowSoftening), _SunGlowRadius, distance(_MainLightPosition.xyz, dirWS));
				half3 sunGlowColor = _SunGlowColor * sun;
				half3 finalColor = skyColor + sunGlowColor;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}