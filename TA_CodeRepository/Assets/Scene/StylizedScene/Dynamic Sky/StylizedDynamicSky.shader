Shader "Code Repository/Scene/Stylized Dynamic Sky" 
{
	Properties 
	{
    	[HDR]_TopColor ("TopColor", Color) = (0, 0.2, 0.7, 1)		
		[HDR]_MiddleColor ("MiddleColor", Color) = (0.15, 0.45, 0.9, 1)
		[HDR]_BottomColor ("BottomColor", Color) = (0.65, 0.85, 0.9, 1)

		[NoScaleOffset]_SunTex ("SunTex", 2D) = "white" {}
		[Toggle(_SIMULATIONSUNSHAPE)] _SimulationSunShape ("SimulationSunShape", Float) = 1
		[HDR]_SunColor ("SunColor", Color) = (1, 1, 1, 1)
		_SunSize ("SunSize", Float) = 5		
		[HDR]_SunGlowColor ("SunGlowColor", Color) = (1, 1, 1, 1)
		_SunGlowRadius ("SunGlowRadius", Range(0, 1)) = 0.5

		[NoScaleOffset]_MoonTex ("MoonTex", 2D) = "white" {}
		[HDR]_MoonColor ("MoonColor", Color) = (1, 1, 1, 1)
		_MoonSize ("MoonSize", Float) = 5
		[HDR]_MoonGlowColor ("MoonGlowColor", Color) = (1, 1, 1, 1)
		_MoonGlowRadius ("MoonGlowRadius", Range(0, 1)) = 0.5

		_StarTex ("StarTex", 2D) = "white" {}
		_StarIntensity ("StarIntensity", Float) = 3
		_StarReduceValue ("StarReduceValue", Range(0, 1)) = 0.1

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
			half3 _TopColor;	
			half4 _MiddleColor;
			half3 _BottomColor;
			half3 _HorizonColor;
			float _HorizonHeight;

			half3 _SunColor;
			float _SunSize;
			half3 _SunGlowColor;
			float _SunGlowRadius;

			half3 _MoonColor;
			float _MoonSize;
			half3 _MoonGlowColor;
			float _MoonGlowRadius;
			half _StarIntensity;
			float4 _StarTex_ST;
			half _StarReduceValue;
			CBUFFER_END

			half _IsNight;
			float4x4 _LightMatrix;

			// TEXTURE2D(_SkyColorTex);
			// SAMPLER(sampler_SkyColorTex);

			TEXTURE2D(_SunTex);	
			SAMPLER(sampler_SunTex);

			TEXTURE2D(_MoonTex);
			SAMPLER(sampler_MoonTex);

			TEXTURE2D(_StarTex);
			SAMPLER(sampler_StarTex);			
		ENDHLSL

		Pass 
		{
			ZWrite[_ZWrite]
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			#pragma shader_feature_local _SIMULATIONSUNSHAPE
			#pragma multi_compile _ _NIGHT

			struct Attributes 
			{
				float4 positionOS : POSITION;
				float2 uv		  : TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;
				//float3 positionWS : TEXCOORD0;
				float3 dirWS : TEXCOORD0;
				float4 sunAndMoonUV : TEXCOORD1;
				float2 starUV   : TEXCOORD2;
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
				float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				//OUT.positionWS = positionWS;			
				OUT.dirWS = positionWS - float3(UNITY_MATRIX_M[0][3], UNITY_MATRIX_M[1][3], UNITY_MATRIX_M[2][3]);
				float3 posInLight = mul((float3x3)_LightMatrix, normalize(OUT.dirWS));
				OUT.sunAndMoonUV.xy = (posInLight * _SunSize).xy;
				OUT.sunAndMoonUV.zw = (posInLight * _MoonSize).xy;
				OUT.starUV = IN.uv * _StarTex_ST.xy + _StarTex_ST.zw;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				//float3 viewDirWS = normalize(IN.positionWS - _WorldSpaceCameraPos.xyz);
				float3 dirWS = normalize(IN.dirWS);
				//float2 skyColorUV = 1 - saturate(dirWS.y);
				//float2 skyColorUV = 1 - saturate(dot(viewDirWS, float3(0, 1, 0)));
				//half3 skyColor = SAMPLE_TEXTURE2D(_SkyColorTex, sampler_SkyColorTex, skyColorUV).rgb;

				//float skyHeight = saturate(dot(viewDirWS, float3(0, 1, 0)));
				float skyHeight = saturate(dirWS.y);
				half middleHeight = _MiddleColor.a + 0.0001;
				half3 skyColor = lerp(_BottomColor, _MiddleColor.rgb, saturate(skyHeight / middleHeight));
				skyColor = lerp(skyColor, _TopColor, saturate(saturate(skyHeight - middleHeight) / (1 - middleHeight)));

				#if !defined(_NIGHT)
					//sun				
					float glowRadius = 1.0 + dot(dirWS, -_MainLightPosition.xyz); //[0, 2]
					float lightRange = saturate(dot(dirWS, _MainLightPosition.xyz));  //消除另一面
					float shapeMask = smoothstep(-0.01, 0.1, skyHeight);

					float sunGlow = 1.0 / (1 + glowRadius * lerp(150, 10, _SunGlowRadius));
					sunGlow *= pow(_SunGlowRadius, 0.5);
					half3 sunGlowColor = _SunGlowColor * sunGlow;

					#if !defined(_SIMULATIONSUNSHAPE)
						float2 sunUV = IN.sunAndMoonUV.xy + 0.5;
						half3 sunColor = SAMPLE_TEXTURE2D(_SunTex, sampler_SunTex, sunUV).rgb * _SunColor;
					#else
						half3 sunColor = smoothstep(0.3, 0.25, distance(IN.sunAndMoonUV.xy, float2(0, 0))) * _SunColor;
					#endif								
					sunColor = sunColor * lightRange * shapeMask;

					skyColor = skyColor + sunColor + sunGlowColor;
				#else
					//moon
					float glowRadius = 1.0 + dot(dirWS, -_MainLightPosition.xyz); //[0, 2]
					float lightRange = saturate(dot(dirWS, _MainLightPosition.xyz));
					float shapeMask = smoothstep(-0.01, 0.1, skyHeight);

					float moonGlow = 1.0 / (1 + glowRadius * lerp(150, 10, _MoonGlowRadius));
					moonGlow *= pow(_MoonGlowRadius, 0.5);
					half3 moonGlowColor = _MoonGlowColor * moonGlow;

					float2 moonUV = IN.sunAndMoonUV.zw + 0.5;
					half4 moonTexColor = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, moonUV);
					half3 moonColor = moonTexColor.r  * moonTexColor.g * _MoonColor;
					moonColor = moonColor * lightRange * shapeMask;

					//star
					float2 starUV = IN.starUV;
					half3 starColor = SAMPLE_TEXTURE2D(_StarTex, sampler_StarTex, starUV).rgb;
					starColor = saturate(starColor - _StarReduceValue) * _StarIntensity * (1 - moonTexColor.g) * shapeMask;

					skyColor = skyColor + moonColor + moonGlowColor + starColor;
				#endif

				return half4(skyColor, 1);
			}
			ENDHLSL
		}
	}
}