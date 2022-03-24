Shader "Code Repository/Scene/StylizedWater"
{
	Properties 
	{
		[Header(NormalMap)]
		[NoScaleOffset]_NormalMap ("Normal Map", 2D) = "white" {}
		_NormalMapScale ("NormalMapScale", Float) = 10
		_BumpScale ("Bump Scale", Range(0, 2)) = 1
		_FlowSpeed ("Flow Speed", Float) = 2

		[Header(Water Color)]
		_ShallowColor ("Shallow Color(alpha=water transparent)", Color) = (1, 1, 1, 0.1)
		_DepthColor ("DepthColor(alpha=water transparent)", Color) = (1, 1, 1, 1)
		_DepthRange ("DepthRange", Float) = 5
		_FresnelPower ("FresnelPower", Float) = 5

		[Header(Refraction)]
		_ReflectionDistortion ("ReflectionDistortion", Range(0, 5)) = 0.5
		_ReflectionIntensity ("ReflectionIntensity", Range(0, 1)) = 0.5

		[Header(Refraction)]
		_RefractionDistortion ("RefractionDistortion", Range(0, 5)) = 0.5

		[Header(Caustics)]
		[NoScaleOffset]_CausticsTex ("CausticsTex", 2D) = "white" {}
		_CausticsScale ("CausticsScale", Float) = 1
		_CausticsFlowSpeed ("CausticsFlowSpeed", Float) = 1
		_CausticsIntensity ("CausticsIntensity", Float) = 1
		_CausticsThresholdDepth ("CausticsThresholdDepth", Float) = 2
		_CausticsSoftDepth ("CausticsSoftDepth", Float) = 0.5
		_CausticsThresholdShallow ("CausticsThresholdShallow", Float) = 0.1
		_CausticsSoftShallow ("CausticsSoftShallow", Float) = 0.1

		[Header(Shore)]
		_ShoreEdgeWidth ("ShoreEdgeWidth", Float) = 5
		_ShoreEdgeIntensity ("ShoreEdgeIntensity", Float) = 0.3

		[Header(Foam)]
		_FoamColor ("FomaColor", Color) = (1, 1, 1, 1)
		_FoamRange ("FoamRange", Float) = 1
		_FoamRangeSmooth ("_FoamRangeSmooth", Float) = 0
		_FoamSoft ("FoamSoft", Range(0, 1)) = 0.1
		_FoamWavelength ("FoamWavelength", Float) = 1
		_FoamWaveSpeed ("FoamWaveSpeed", Float) = 1
		[NoScaleOffset]_FoamNoiseTex ("FoamNoiseTex", 2D) = "white" {}
		_FoamNoiseTexScale("FoamNoiseTexScale", Vector) = (10, 5, 0, 0)
		_FoamDissolve ("FoamDissolve", Float) = 1.2
		_FoamShoreWidth ("FoamShoreWidth", Range(0, 1)) = 0.5

		[Header(Wave(xy_dir Z_steepness W_wavelength))]
		_WaveA ("Wave A", Vector) = (1,0,0.5,10)
		_WaveB ("Wave B", Vector) = (0,1,0.25,20)
		_WaveC ("Wave C", Vector) = (1,1,0.15,10)		
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Transparent"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float _NormalMapScale;
			half _BumpScale;
			half _FlowSpeed;
			half4 _ShallowColor;
			half4 _DepthColor;
			float _DepthRange;
			float _FresnelPower;
			float _ReflectionDistortion;
			float _ReflectionIntensity;
			float _RefractionDistortion;
			float _CausticsScale;
			float _CausticsFlowSpeed;
			float _CausticsIntensity;
			float _CausticsThresholdDepth;
			float _CausticsSoftDepth;
			float _CausticsThresholdShallow;
			float _CausticsSoftShallow;
			float _ShoreEdgeWidth;
			float _ShoreEdgeIntensity;
			half4 _FoamColor;
			float _FoamRange;
			float _FoamRangeSmooth;
			float _FoamSoft;
			float _FoamWavelength;
			float _FoamWaveSpeed;
			float2 _FoamNoiseTexScale;
			float _FoamDissolve;
			float _FoamShoreWidth;
			float4 _WaveA, _WaveB, _WaveC;
			CBUFFER_END

			float3 GerstnerWave (float4 wave, float3 p, inout float3 tangent, inout float3 binormal) 
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = TWO_PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, p.xz) - c * _Time.y);
				float a = steepness / k;
				
				tangent += float3(
					-d.x * d.x * (steepness * sin(f)),
					d.x * (steepness * cos(f)),
					-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
					-d.x * d.y * (steepness * sin(f)),
					d.y * (steepness * cos(f)),
					-d.y * d.y * (steepness * sin(f))
				);
				return float3(
					d.x * (a * cos(f)),
					a * sin(f),
					d.y * (a * cos(f))
				);
			}
		ENDHLSL

		Pass 
		{
			Name "StylizedWater"
			ZWrite Off

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float3 normal		: NORMAL;
				//float4 tangent		: TANGENT;
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float4 positionSS		: TEXCOORD0;
				float4 TtoW0			: TEXCOORD1;
				float4 TtoW1			: TEXCOORD2;
				float4 TtoW2			: TEXCOORD3;
				float4 normalMapUv		: TEXCOORD4;
				float4 posWSFromDepth	: TEXCOORD5; //xyz:viewDirWS,w:viewPosZ
				float3 oriNormal		: TEXCOORD6;
				//float3 viewDirWS		: TEXCOORD6;
			};

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);

			TEXTURE2D(_ReflectionTex);
			SAMPLER(sampler_ReflectionTex);

			TEXTURE2D(_CameraOpaqueTexture);
			SAMPLER(sampler_CameraOpaqueTexture);
			//SAMPLER(sampler_point_clamp);

			TEXTURE2D(_CausticsTex);
			SAMPLER(sampler_CausticsTex);

			TEXTURE2D(_FoamNoiseTex);
			SAMPLER(sampler_FoamNoiseTex);

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				//wave
				float3x3 scaleM = float3x3(UNITY_MATRIX_M[0][0], 0, 0, 0, UNITY_MATRIX_M[1][1], 0, 0, 0, UNITY_MATRIX_M[2][2]);
				float3x3 inverseScaleM = float3x3(1 / UNITY_MATRIX_M[0][0], 0, 0, 0, 1 / UNITY_MATRIX_M[1][1], 0, 0, 0, 1 / UNITY_MATRIX_M[2][2]);
				float3 gridPoint = mul(scaleM, IN.positionOS.xyz); //提前应用缩放，波形参数不会被模型尺寸影响
				float3 tangent = 0;
				float3 binormal = 0;
				float3 p = gridPoint;
				p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
				p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
				p += GerstnerWave(_WaveC, gridPoint, tangent, binormal);
				p = mul(inverseScaleM, p);
				tangent = mul(inverseScaleM, tangent);
				binormal = mul(inverseScaleM, binormal);
				float3 normal = cross(binormal, tangent);
				IN.positionOS.xyz = p;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);

				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(normal);
				float3 tangentWS = TransformObjectToWorldDir(tangent);
				float3 binormalWS = TransformObjectToWorldDir(binormal);
				OUT.TtoW0 = float4(tangentWS.x, binormalWS.x, normalWS.x, posWS.x);
				OUT.TtoW1 = float4(tangentWS.y, binormalWS.y, normalWS.y, posWS.y);
				OUT.TtoW2 = float4(tangentWS.z, binormalWS.z, normalWS.z, posWS.z);

				float2 normalUV0 = posWS.xz / max(0.0001, _NormalMapScale) + _Time.x * _FlowSpeed;
				float2 normalUV1 = 2 * posWS.xz / max(0.0001, _NormalMapScale) - _Time.x * _FlowSpeed * 0.5;
				OUT.normalMapUv.xy = normalUV0;
				OUT.normalMapUv.zw = normalUV1;

				OUT.posWSFromDepth.xyz = posWS - _WorldSpaceCameraPos;
				OUT.posWSFromDepth.w = -TransformWorldToView(posWS).z;
				OUT.oriNormal = IN.normal;
				//OUT.viewDirWS = SafeNormalize(_WorldSpaceCameraPos - posWS); //归一化后，插值结果与在fs里计算的结果相差较大，不归一化两者基本相同
				//OUT.viewDirWS = _WorldSpaceCameraPos - posWS;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float2 screenUV = IN.positionSS.xy / IN.positionSS.w;
				float3 posWS = float3(IN.TtoW0.w, IN.TtoW1.w, IN.TtoW2.w);

				//normal map
				float2 normalUV0 = IN.normalMapUv.xy;
				half4 packNormal0 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV0);
				half3 unpackNormal0 = UnpackNormalScale(packNormal0, _BumpScale);
				float2 normalUV1 = IN.normalMapUv.zw;
				half4 packNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV1);
				half3 unpackNormal1 = UnpackNormalScale(packNormal, _BumpScale);
				half3 normalOS = SafeNormalize(float3(unpackNormal0.xy + unpackNormal1.xy, unpackNormal0.z * unpackNormal1.z)); //http://wiki.amplify.pt/index.php?title=Unity_Products:Amplify_Shader_Editor/Blend_Normals
				half3 normalWS = SafeNormalize(float3(dot(IN.TtoW0.xyz, normalOS), dot(IN.TtoW1.xyz, normalOS), dot(IN.TtoW2.xyz, normalOS)));

				//scene pos
				float sceneDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
				sceneDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);				
				float3 sceneViewDirWS = sceneDepth / IN.posWSFromDepth.w * IN.posWSFromDepth.xyz; //sceneViewDirWS/viewDirWS = sceneDepth / viewPosZ,相似三角形
				float3 scenePosWS = _WorldSpaceCameraPos + sceneViewDirWS;
				//water depth difference
				float depthDifference = posWS.y - scenePosWS.y;

				//water color
				float colorLerpFactor = saturate(exp(-depthDifference * _DepthRange * 0.1));
				half4 waterColor = lerp(_DepthColor, _ShallowColor, colorLerpFactor);

				//water transparent
				half waterTransparent = 1 - saturate(waterColor.a);
				float fresnel = pow(1 - saturate(dot(SafeNormalize(IN.oriNormal), SafeNormalize(-IN.posWSFromDepth.xyz))), _FresnelPower);
				waterTransparent = lerp(waterTransparent, 0, fresnel);

				//Reflection
				float2 reflectionUV = screenUV + normalOS.xy * _ReflectionDistortion * 0.1;
				half3 reflectionColor = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, reflectionUV).rgb * _ReflectionIntensity * fresnel;

				//refraction
				float2 distortionOffset = normalOS.xy * _RefractionDistortion * 0.1;
				float2 refractionUV = screenUV + distortionOffset;
				float distortionDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, refractionUV).r;
				distortionDepth = LinearEyeDepth(distortionDepth, _ZBufferParams);
				float waterDepth = IN.positionSS.w;
				float distortionDepthDifference = saturate(distortionDepth - waterDepth);
				refractionUV = screenUV + distortionOffset * distortionDepthDifference; //水面及以上的物体不会被扭曲
				half3 refractionColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, refractionUV).rgb;
			
				//caustics
				float2 causticsUVOffset = _Time.x * _CausticsFlowSpeed;
				float2 causticsUV0 = scenePosWS.xz / max(0.0001, _CausticsScale) + causticsUVOffset;
				float2 causticsUV1 = -scenePosWS.xz / max(0.0001, _CausticsScale) + causticsUVOffset;
				half3 causticsColor0 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, causticsUV0).rgb;
				half3 causticsColor1 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, causticsUV1).rgb;
				half3 causticsColor = min(causticsColor0, causticsColor1) * max(0, _CausticsIntensity);

				half causticsDepthMask = smoothstep(_CausticsThresholdDepth, _CausticsThresholdDepth - _CausticsSoftDepth - 0.1, depthDifference);
				half causticsShalloowMask = smoothstep(_CausticsThresholdShallow, _CausticsThresholdShallow + _CausticsSoftShallow, depthDifference);
				half causticsMask =  causticsDepthMask + causticsShalloowMask - 1;
				causticsColor *= causticsMask;

				//shore
				half shoreEdge = smoothstep(_ShoreEdgeWidth * 0.01, 0, depthDifference) * _ShoreEdgeIntensity;

				//foam
				float foamRange = 1 - saturate(depthDifference / max(0.0001, _FoamRange));
				float foamMask = smoothstep(0, _FoamRangeSmooth, foamRange);
				float foamWave = sin(TWO_PI / max(_FoamWavelength * 0.1, 0.0001) * (depthDifference + _Time.x * _FoamWaveSpeed));
				half foamNoise = SAMPLE_TEXTURE2D(_FoamNoiseTex, sampler_FoamNoiseTex, posWS.xz / _FoamNoiseTexScale).r;
				float foamThreshold = max(foamRange - _FoamShoreWidth, 0);
				foamWave = smoothstep(foamThreshold, foamThreshold + _FoamSoft, foamWave + foamNoise - _FoamDissolve);
				//foamWave = saturate(foamWave + foamNoise - _FoamDissolve);
				half3 fomaColor = foamWave * foamMask * _FoamColor.rgb;

				half3 underWaterColor = refractionColor + causticsColor;
				half3 finalColor = lerp(waterColor.rgb + reflectionColor, underWaterColor, waterTransparent) + shoreEdge + fomaColor;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}
