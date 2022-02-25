Shader "Code Repository/Scene/SimpleStylizedWater"
{
	Properties 
	{
		[Header(NormalMap)]
		_NormalMap ("NormalMap", 2D) = "white" {}
		_BumpScale ("BumpScale", Float) = 1
		_FlowSpeed ("FlowSpeed", Float) = 0.2
		[Header(Reflection)]
		_DisturbanceStart("DisturbanceStart", Float) = 0
		_DisturbanceEnd("DisturbanceEnd", Float) = 100
		_DisturbanceIntensity ("DisturbanceIntensity", Float) = 0.1
		_ReflectionIntensity ("ReflectionIntensity", Float) = 1
		[Header(Specular)]
		_SpecularStart ("SpecularStart", Float) = 0
		_SpecularEnd ("SpecularEnd", Float) = 100
		_SpecularCol ("SpecularCol", Color) = (1, 1, 1, 1)
		_SpecularScale ("SpecularScale", Float) = 1
		_SpecularIntensity ("SpecularIntensity", Float) = 1
		[Header(UnderWater)]
		_UnderWaterTex ("UnderWaterTex", 2D) = "white" {}
		_DisturbanceIntensity_UnderWater ("UnderWaterDisturbanceIntensity", Float) = 0.1
		_WaterDepth ("WaterDepth", Float) = -1
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Geometry"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _NormalMap_ST;
			half _BumpScale;
			half _FlowSpeed;
			half _DisturbanceStart;
			half _DisturbanceEnd;
			half _DisturbanceIntensity;
			half _ReflectionIntensity;
			float _SpecularStart;
			float _SpecularEnd;
			half4 _SpecularCol;
			half _SpecularScale;
			half _SpecularIntensity;
			half _DisturbanceIntensity_UnderWater;
			float4 _UnderWaterTex_ST;
			half _WaterDepth;
			CBUFFER_END

			inline float2 ParallaxOffset( half h, half height, half3 viewDir )
			{
				h = h * height - height/2.0;
				float3 v = normalize(viewDir);
				v.y += 0.42;
				return h * (v.xz / v.y);
			}
		ENDHLSL

		Pass 
		{
			Name "SimpleStylizedWater"

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
				float4 positionCS 	: SV_POSITION;
				float4 positionSS	: TEXCOORD0;
				float4 TtoW0		: TEXCOORD1;
				float4 TtoW1		: TEXCOORD2;
				float4 TtoW2		: TEXCOORD3;
			};

			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);

			TEXTURE2D(_ReflectionTex);
			SAMPLER(sampler_ReflectionTex);
	
			TEXTURE2D(_UnderWaterTex);
			SAMPLER(sampler_UnderWaterTex);

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformWorldToObjectDir(IN.tangent.xyz);
				float3 binormalWS = SafeNormalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.TtoW0 = float4(tangentWS.x, binormalWS.x, normalWS.x, posWS.x);
				OUT.TtoW1 = float4(tangentWS.y, binormalWS.y, normalWS.y, posWS.y);
				OUT.TtoW2 = float4(tangentWS.z, binormalWS.z, normalWS.z, posWS.z);
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float2 screenUV = IN.positionSS.xy / IN.positionSS.w;
				float3 posWS = float3(IN.TtoW0.w, IN.TtoW1.w, IN.TtoW2.w);

				//normal map
				float2 normalUV0 = posWS.xz * _NormalMap_ST.xy + _NormalMap_ST.zw + _Time.y * _FlowSpeed;
				half4 packNormal0 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV0);
				half3 unpackNormal0 = UnpackNormalScale(packNormal0, _BumpScale);
				float2 normalUV1 = posWS.xz * _NormalMap_ST.xy * 2 + _NormalMap_ST.zw - _Time.y * _FlowSpeed * 0.5;
				half4 packNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV1);
				half3 unpackNormal1 = UnpackNormalScale(packNormal, _BumpScale);
				half3 unpackNormal = SafeNormalize(float3(unpackNormal0.xy + unpackNormal1.xy, unpackNormal0.z * unpackNormal1.z)); //http://wiki.amplify.pt/index.php?title=Unity_Products:Amplify_Shader_Editor/Blend_Normals
				//float2 normalXY = (unpackNormal0.xy + unpackNormal1.xy) * 0.5;
				//float normalZ = sqrt(1 - dot(normalXY, normalXY));
				//float3 unpackNormal = float3(normalXY, normalZ);
				half3 normalWS = SafeNormalize(float3(dot(IN.TtoW0.xyz, unpackNormal), dot(IN.TtoW1.xyz, unpackNormal), dot(IN.TtoW2.xyz, unpackNormal)));

				//Reflection
				float viewDis = distance(posWS, _WorldSpaceCameraPos.xyz);
				half disturbanceAttenuation = saturate((_DisturbanceEnd - viewDis) / (_DisturbanceEnd - _DisturbanceStart + 1));
				disturbanceAttenuation = pow(disturbanceAttenuation, 10);
				float2 reflectionUV = screenUV + normalWS.xz * _DisturbanceIntensity * disturbanceAttenuation;
				half4 reflectionTex = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, reflectionUV);

				//Specular
				float specularAttenuation = saturate((_SpecularEnd - viewDis) / (_SpecularEnd - _SpecularStart + 1));
				half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - posWS);
				half3 halfDir = SafeNormalize(_MainLightPosition.xyz + viewDirWS);
				half NDotH = max(0, dot(normalWS, halfDir));
				half3 specularCol = pow(NDotH, _SpecularScale * 256) * _SpecularIntensity * _SpecularCol.rgb * specularAttenuation;

				//UnderWater
				float2 underaWaterUV = posWS.xz * _UnderWaterTex_ST.xy + _UnderWaterTex_ST.zw + normalWS.xz * _DisturbanceIntensity_UnderWater;
				float2 parallaxOffset = ParallaxOffset(_WaterDepth, 1, viewDirWS);
				half4 underWaterCol = SAMPLE_TEXTURE2D(_UnderWaterTex, sampler_UnderWaterTex, underaWaterUV + parallaxOffset);

				//Fresnel
				float fresnel = pow(max(0, dot(SafeNormalize(float3(IN.TtoW0.z, IN.TtoW1.z, IN.TtoW2.z)), viewDirWS)), _ReflectionIntensity);

				half3 finalCol = reflectionTex.rgb * (1 - fresnel)  + specularCol + underWaterCol.rgb * fresnel;
				return half4(finalCol, 1);
			}
			ENDHLSL
		}
	}
}
