Shader "Code Repository/Base/Relief Parallax Mapping With SoftShadow" 
{
	Properties 
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_SpecularScale ("SpecularScale", Float) = 1
		_SpecularCol ("SpecularCol", Color) = (1, 1, 1, 1)
		_DepthTex ("DepthTex", 2D) = "white" {}
		_ParallaxScale ("ParallaxScale", Range(0, 1)) = 0.1
		_MinLayerCount ("MinLayerCount", Float) = 5
		_MaxLayerCount ("MaxLayerCount", Float) = 15
		_NormalTex ("NormalTex", 2D) = "white" {}
		_BumpScale ("BumpScale", Range(0, 20)) = 1
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			half _SpecularScale;
			half4 _SpecularCol;
			half _ParallaxScale;
			half _MinLayerCount;
			half _MaxLayerCount;
			half _BumpScale;
			uint _DivideZ;
			CBUFFER_END


			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_DepthTex);
			SAMPLER(sampler_DepthTex);

			TEXTURE2D(_NormalTex);
			SAMPLER(sampler_NormalTex);

			//浮雕视差贴图
			//https://www.jianshu.com/p/fea6c9fc610f
			//https://segmentfault.com/a/1190000003920502
			float2 ReliefParallaxMapping(float2 uv, half3 viewDirTS, out float curDepth)
			{
				half layerCount = lerp(_MaxLayerCount, _MinLayerCount, abs(viewDirTS.z));
				float layerDepth = 1 / layerCount;
				float2 deltaUV = viewDirTS.xy / viewDirTS.z * _ParallaxScale * layerDepth; //总的偏移：viewDirTS.xy / viewDirTS.z * _ParallaxScale，_ParallaxScale越小，偏移越小，效果上为视角越接近平面法线

				float currentLayerDepth = 0;
				float2 currentUV = uv;
				half currentDepth = SAMPLE_TEXTURE2D(_DepthTex, sampler_DepthTex, currentUV).r;
				//https://forum.unity.com/threads/issues-with-shaderproperty-and-for-loop.344469/
				//https://zhuanlan.zhihu.com/p/115871017
				[unroll(15)]
				while(currentDepth > currentLayerDepth)
				{
					currentUV -= deltaUV;
					currentDepth = SAMPLE_TEXTURE2D(_DepthTex, sampler_DepthTex, currentUV).r;
					currentLayerDepth += layerDepth;
				}

				//二分查找
				float2 dUV = deltaUV / 2;
				float dDepth = layerDepth / 2;
				currentUV += dUV;
				currentLayerDepth -= dDepth;
				const int searchCount = 5;
				for(int i = 0; i < searchCount; i++)
				{
					currentDepth = SAMPLE_TEXTURE2D(_DepthTex, sampler_DepthTex, currentUV).r;
					dUV /= 2;
					dDepth /= 2;
					if(currentDepth > currentLayerDepth)
					{
						currentUV -= dUV;
						currentLayerDepth += dDepth;						
					}
					else
					{
						currentUV += dUV;
						currentLayerDepth -= dDepth;						
					}
				}

				curDepth = currentLayerDepth;
				return currentUV;
			}

			//https://segmentfault.com/a/1190000003920502
			float ParallaxSoftShadowMultiplier(float3 L, float2 initialTexCoord, float initialDepth)
			{
			   float shadowMultiplier = 0;

			   if(dot(half3(0, 0, 1), L) > 0)
			   {
					float numLayers    = lerp(_MaxLayerCount, _MinLayerCount, abs(dot(float3(0, 0, 1), L)));
					float layerDepth    = initialDepth / numLayers;
				  	float2 texStep    = _ParallaxScale * L.xy / L.z / numLayers;

				  	//first layer
					float currentLayerDepth    = initialDepth - layerDepth;
					float2 currentTextureCoords    = initialTexCoord + texStep;
					float depthFromTexture    = SAMPLE_TEXTURE2D(_DepthTex, sampler_DepthTex, currentTextureCoords).r;
					int stepIndex = 1;

					//[unroll(15)]
					while(currentLayerDepth > 0)
					{
						if(depthFromTexture < currentLayerDepth)
						{
							float tempShadowMultiplier = (currentLayerDepth - depthFromTexture) * (1 - stepIndex / numLayers);
							shadowMultiplier = max(shadowMultiplier, tempShadowMultiplier);
						}

						stepIndex += 1;
						currentLayerDepth -= layerDepth;
						currentTextureCoords += texStep;
						depthFromTexture  = SAMPLE_TEXTURE2D_LOD(_DepthTex, sampler_DepthTex, currentTextureCoords, 0).r;
					}		
					shadowMultiplier = 1 - shadowMultiplier;		  
			   	}
				return shadowMultiplier;			
			}			
		ENDHLSL

		Pass {
			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
				float3 normal		: NORMAL;
				float4 tangent		: TANGENT;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				half4 TtoW0		: TEXCOORD1;
				half4 TtoW1		: TEXCOORD2;
				half4 TtoW2		: TEXCOORD3;
				half3 viewDirTS : TEXCOORD4;
				half3 lightDirTS: TEXCOORD5;
			};

			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformWorldToObjectDir(IN.tangent.xyz);
				float3 binormalWS = SafeNormalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.TtoW0 = float4(tangentWS.x, binormalWS.x, normalWS.x, posWS.x);
				OUT.TtoW1 = float4(tangentWS.y, binormalWS.y, normalWS.y, posWS.y);
				OUT.TtoW2 = float4(tangentWS.z, binormalWS.z, normalWS.z, posWS.z);

				half3 viewDirOS = normalize(TransformWorldToObject(_WorldSpaceCameraPos) - IN.positionOS.xyz);
				float3 binormalOS = normalize(cross(IN.normal, IN.tangent.xyz) * IN.tangent.w);
				float3x3 OtoT = float3x3(IN.tangent.xyz, binormalOS, IN.normal);
				OUT.viewDirTS = normalize(mul(OtoT, viewDirOS));
				OUT.lightDirTS = mul(OtoT, TransformWorldToObjectDir(_MainLightPosition.xyz));
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				float3 posWS = float3(IN.TtoW0.w, IN.TtoW1.w, IN.TtoW2.w);
				float curDepth;
				float2 uv = ReliefParallaxMapping(IN.uv, normalize(IN.viewDirTS), curDepth);
				float shadowMultiplier = ParallaxSoftShadowMultiplier(normalize(IN.lightDirTS), uv, curDepth);
				//return shadowMultiplier;
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
				half4 packNormal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uv);
				half3 normalTS = UnpackNormalScale(packNormal, _BumpScale);
				half3 normalWS = SafeNormalize(half3(dot(IN.TtoW0.xyz, normalTS), dot(IN.TtoW1.xyz, normalTS), dot(IN.TtoW2.xyz, normalTS)));

				half NdotL = max(0, dot(normalWS, _MainLightPosition.xyz));
				half3 diffuseCol = baseMap.rgb * _BaseColor.rgb * _MainLightColor.rgb * NdotL * shadowMultiplier;

				half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - posWS);
				half3 halfDir = SafeNormalize(_MainLightPosition.xyz + viewDirWS);
				half NDotH = max(0, dot(normalWS, halfDir));
				half3 specularCol = pow(NDotH, _SpecularScale * 256)  * _SpecularCol.rgb * _MainLightColor.rgb * shadowMultiplier;
				return half4(diffuseCol + specularCol, baseMap.a * _BaseColor.a);
			}
			ENDHLSL
		}
	}
}