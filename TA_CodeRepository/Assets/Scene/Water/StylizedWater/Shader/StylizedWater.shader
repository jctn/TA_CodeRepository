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
		_CausticsTex ("CausticsTex", 2D) = "white" {}
		_CausticsScale ("CausticsScale", Float) = 1
		_CausticsFlowSpeed ("CausticsFlowSpeed", Float) = 1
		_CausticsIntensity ("CausticsIntensity", Float) = 1
		_CausticsThresholdDepth ("CausticsThresholdDepth", Float) = 2
		_CausticsSmoothDepth ("CausticsSmoothDepth", Float) = 0.5
		_CausticsThresholdShallow ("CausticsThresholdShallow", Float) = 0.1
		_CausticsSmoothShallow ("CausticsSmoothShallow", Float) = 0.1

		[Header(Shore)]
		_ShoreEdgeWidth ("ShoreEdgeWidth", Float) = 5
		_ShoreEdgeIntensity ("ShoreEdgeIntensity", Float) = 0.3
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
			float _CausticsSmoothDepth;
			float _CausticsThresholdShallow;
			float _CausticsSmoothShallow;
			float _ShoreEdgeWidth;
			float _ShoreEdgeIntensity;		
			CBUFFER_END

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
				float4 tangent		: TANGENT;
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

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);

				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformWorldToObjectDir(IN.tangent.xyz);
				float3 binormalWS = SafeNormalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.TtoW0 = float4(tangentWS.x, binormalWS.x, normalWS.x, posWS.x);
				OUT.TtoW1 = float4(tangentWS.y, binormalWS.y, normalWS.y, posWS.y);
				OUT.TtoW2 = float4(tangentWS.z, binormalWS.z, normalWS.z, posWS.z);

				float2 normalUV0 = posWS.xz / max(0.0001, _NormalMapScale) + _Time.x * _FlowSpeed;
				float2 normalUV1 = 2 * posWS.xz / max(0.0001, _NormalMapScale) - _Time.x * _FlowSpeed * 0.5;
				OUT.normalMapUv.xy = normalUV0;
				OUT.normalMapUv.zw = normalUV1;

				OUT.posWSFromDepth.xyz = posWS - _WorldSpaceCameraPos;
				OUT.posWSFromDepth.w = -TransformWorldToView(posWS).z;

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
				float fresnel = pow(1 - saturate(dot(SafeNormalize(float3(IN.TtoW0.z, IN.TtoW1.z, IN.TtoW2.z)), SafeNormalize(-IN.posWSFromDepth.xyz))), _FresnelPower);
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

				half causticsDepthMask = smoothstep(_CausticsThresholdDepth, _CausticsThresholdDepth - _CausticsSmoothDepth - 0.1, depthDifference);
				half causticsShalloowMask = smoothstep(_CausticsThresholdShallow, _CausticsThresholdShallow + _CausticsSmoothShallow, depthDifference);
				half causticsMask =  causticsDepthMask + causticsShalloowMask - 1;
				causticsColor *= causticsMask;

				//shore
				half shoreEdge = smoothstep(_ShoreEdgeWidth * 0.01, 0, depthDifference) * _ShoreEdgeIntensity;

				half3 underWaterColor = refractionColor + causticsColor;
				half3 finalColor = lerp(waterColor.rgb + reflectionColor, underWaterColor, waterTransparent) + shoreEdge;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}
