Shader "Code Repository/Scene/Cloud/StylizedCloud2D_Noise_Lighting"
{
	Properties 
	{
		[Header(xxxxxxxxxxxxxxxx Cloud Shape xxxxxxxxxxxxxxxx)]
		[Space]
		[NoScaleOffset]_CloudShapeTex ("CloudShapeTex", 2D) = "white" {}
		_CloudSpeedX ("CloudSpeedX", Float) = 1
		_CloudSpeedY ("CloudSpeedY", Float) = 1
		_CloudFill ("CloudFill", Range(0, 1)) = 0.5
		[NoScaleOffset]_CloudEdgeSoftUnevenTex ("CloudEdgeSoftUnevenTex", 2D) = "white" {}
		_CloudEdgeSoftUnevenTexScale ("CloudEdgeSoftUnevenTexScale", Float) = 4
		_CloudEdgeSoftMax ("CloudEdgeSoftMax", Float) = 0.1
		_CloudEdgeSoftMin ("CloudEdgeSoftMin", Float) = 0.01
		_CloudSize ("CloudSize", FLoat) = 1
		_CloudDetailSize ("CloudDetailSize", Float) = 2
		_CloudDetailIntensity ("CloudDetailIntensity", Float) = 0.5

		[Header(xxxxxxxxxxxxxxxx Cloud Color xxxxxxxxxxxxxxxx)]
		[Space]
		[HDR]_CloudColor ("CloudColor", Color) = (1, 1, 1, 1)
		_CloudLightRadius ("CloudLightRadius", Range(0, 2)) = 0.7
		[HDR]_CloudRimColor ("CloudRimColor", Color) = (1, 1, 1, 1)
		_CloudRimEdgeSoft ("CloudRimEdgeSoft", Float) = 0
		[HDR]_CloudLightColor_NearSun ("CloudLightColor_NearSun", Color) = (1, 1, 1, 1)
		_CloudNearSunGlowRadius ("CloudNearSunGlowRadius", Range(0, 1)) = 0.3
		_CloudLightIntensity ("CloudLightIntensity", Float) = 2
		_CloudLightUVOffset ("CloudLightUVOffset", Float) = 0.01
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
				float _CloudSpeedX;
				float _CloudSpeedY;
				half _CloudFill;
				float _CloudEdgeSoftUnevenTexScale;
				half _CloudEdgeSoftMax;
				half _CloudEdgeSoftMin;
				float _CloudSize;
				float _CloudDetailSize;
				half _CloudDetailIntensity;

				half3 _CloudColor;
				float _CloudLightRadius;
				half3 _CloudRimColor;
				half _CloudRimEdgeSoft;
				half3 _CloudLightColor_NearSun;
				float _CloudNearSunGlowRadius;
				float _CloudLightIntensity;
				float _CloudLightUVOffset;
			CBUFFER_END

			TEXTURE2D(_CloudShapeTex);
			SAMPLER(sampler_CloudShapeTex);
			
			TEXTURE2D(_CloudEdgeSoftUnevenTex);
			SAMPLER(sampler_CloudEdgeSoftUnevenTex);	
		ENDHLSL

		Pass 
		{
			Name "StylizedCloud2D_Noise_Lighting"

			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				half3 Color			: COLOR;
				float3 normal		: NORMAL;
				float4 tangent		: TANGENT;				
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float4 uv			: TEXCOORD0;
				float3 viewDirWS	: TEXCOORD1;
				float3 WtoT0		: TEXCOORD2;
				float3 WtoT1		: TEXCOORD3;
				float3 WtoT2		: TEXCOORD4;				
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv.xy = IN.uv * _CloudSize * ((1 - IN.Color.r) * 0.5 + 1); //2层差异
				OUT.uv.zw = (IN.Color.r * 0.5 + 1) * _Time.x * float2(_CloudSpeedX, _CloudSpeedY);
				OUT.viewDirWS = _WorldSpaceCameraPos.xyz - TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformObjectToWorldDir(IN.tangent.xyz);
				float3 binormalWS = normalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.WtoT0 = tangentWS;
				OUT.WtoT1 = binormalWS;
				OUT.WtoT2 = normalWS;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float3 viewDirWS = normalize(IN.viewDirWS);
				float3 sunDir = -_MainLightPosition.xyz;
				//cloud shape
				float2 baseUV = IN.uv.xy;
				float2 cloudSpeed = IN.uv.zw;
				float2 uv_Main = baseUV + cloudSpeed;
				float2 uv_Detail =  baseUV * _CloudDetailSize + cloudSpeed;
				float2 uv_Edge = uv_Main  * _CloudEdgeSoftUnevenTexScale;

				half cloudEdgeSoftUneven = SAMPLE_TEXTURE2D(_CloudEdgeSoftUnevenTex, sampler_CloudEdgeSoftUnevenTex, uv_Edge).r; //边缘软硬程度有变化
				cloudEdgeSoftUneven = pow(cloudEdgeSoftUneven, 4);
				half edgeSmooth = lerp(_CloudEdgeSoftMin, _CloudEdgeSoftMax, cloudEdgeSoftUneven);
				half edgeSmoothMin = saturate(0.5 - edgeSmooth);
				half edgeSmoothMax = saturate(0.5 + edgeSmooth);

				half cloudMainShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_Main).r;
				half cloudDetailShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_Detail).r; //边缘细节云
				half detailIntensity = lerp(2 * _CloudDetailIntensity, _CloudDetailIntensity, _CloudFill);
				half detailLerp = (1 - abs(cloudMainShape - 0.5) * 2) * detailIntensity;
				detailLerp = saturate(detailLerp);
				half cloudShape = lerp(cloudMainShape, cloudDetailShape, detailLerp); //主体+细节
				half cloudFillValue = _CloudFill * 2 - 1; //[-1, 1]
				cloudShape = saturate(cloudShape + cloudFillValue);
				half cloudFinalShape = smoothstep(edgeSmoothMin, edgeSmoothMax, cloudShape);

				//cloud color=base color + sun glow + rim color + light color
				float VDotL = dot(viewDirWS, sunDir);
				float sunIntensity = saturate(dot(_MainLightColor.rgb, 1));
				float nearSunFactor = 1.0 + dot(-viewDirWS, sunDir);
				nearSunFactor = 1.0 / (0.25 + nearSunFactor * lerp(150, 5, _CloudNearSunGlowRadius));
				nearSunFactor = saturate(1 - exp(-nearSunFactor)) * sunIntensity; //得到比较平滑的渐变区域
				half3 cloudColor = lerp(_CloudColor, _CloudLightColor_NearSun, nearSunFactor);

				half rimColorFactor = smoothstep(saturate(0.5 - _CloudRimEdgeSoft * 0.1), saturate(0.5 + _CloudRimEdgeSoft * 0.1), 1 - cloudShape);
				cloudColor = lerp(cloudColor, _CloudRimColor * (1 + nearSunFactor * 5), rimColorFactor);

				float2 uvOffset = mul(float3x3(IN.WtoT0, IN.WtoT1, IN.WtoT2), normalize(viewDirWS - sunDir)).xy;
				uvOffset = uvOffset * smoothstep(0, _CloudNearSunGlowRadius, abs(VDotL - 1)) * _CloudLightUVOffset * 0.1; //距sun越远，亮部越宽
				float2 uv_MainLighted = uv_Main + uvOffset; //uv偏移
				half cloudMainShapeLighted = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_MainLighted).r;
				half detailLerpLighted = (1 - abs(cloudMainShapeLighted - 0.5) * 2) * detailIntensity;
				detailLerpLighted = saturate(detailLerpLighted);
				half cloudShapeLighted = lerp(cloudMainShapeLighted, cloudDetailShape, detailLerpLighted);
				cloudShapeLighted  = saturate(cloudShapeLighted + cloudFillValue);
				half cloudFinalShapeLighted = smoothstep(edgeSmoothMin, edgeSmoothMax, cloudShapeLighted);
				half cloudLightedFactor = sunIntensity * saturate(cloudFinalShape - cloudFinalShapeLighted);
				cloudColor = lerp(cloudColor, _MainLightColor.rgb * _CloudLightIntensity, cloudLightedFactor);  //混合光照亮部颜色

				float cloudLightRange = 1 - smoothstep(_CloudLightRadius, _CloudLightRadius * 1.5, abs(VDotL - 1)); // abs(VDotL - 1) = [0, 2]
				cloudColor = lerp(_CloudColor, cloudColor, cloudLightRange);	
				return half4(cloudColor, cloudFinalShape);
			}
			ENDHLSL
		}
	}
}
