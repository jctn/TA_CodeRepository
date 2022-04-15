Shader "Code Repository/Scene/GlobalFog" 
{
	Properties 
	{
		_MainTex("Source", 2D) = "white" {}
	}	

	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			float4x4 _Fog_MATRIX_I_V;

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			half3 _FogCol, _SunCol;
			half3 _ExtinctionFallOff, _InscatteringFallOff;

			float3 GetPosW(float3 farRayWS, float2 screenPos)
			{
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				float normalDepth = Linear01Depth(depthTextureValue, _ZBufferParams); //_ZBufferParams包含反转z的操作，Linear01Depth只能用于投射相机
				float3 worldSpacePos = _WorldSpaceCameraPos + farRayWS * normalDepth; //相似三角形
				return worldSpacePos;
			}

			//https://iquilezles.org/www/articles/fog/fog.htm
			void ApplyGlobalFog(inout half3 col, half3 fogCol, half3 sunCol, float distance, float3 viwDirWS, float3 sunDirWS, half3 be, half3 bi)
			{
				float sunAmount = max( dot( viwDirWS, sunDirWS ), 0.0 );
				fogCol = lerp(fogCol, sunCol, pow(sunAmount, 8.0));
				float extColor = exp(-distance * be.x);
				float insColor = exp(-distance * bi.x);
				//col = col * (1.0 - extColor) + fogCol * insColor;
				col = lerp(col, fogCol, 1 - extColor);
			}
		ENDHLSL

		Pass 
		{
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float2 uv           : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS    : SV_POSITION;
				float2 uv            : TEXCOORD0;
				float4 positionSS	 : TEXCOORD1;
				float3 farRayWS		 : TEXCOORD2;//相机经过所求点到far plane的向量
			};

			
			Varyings Vertex(Attributes IN)
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);
				float2 screenPos = OUT.positionSS.xy / OUT.positionSS.w;
				float3 farPlaneNDC = float3(screenPos.x * 2 - 1, screenPos.y * 2 - 1, 1);
				float3 farPlaneClip = farPlaneNDC * _ProjectionParams.z;//在透视投影中，远平面的clip.w = _ProjectionParams.z（视锥体far)，得到位于clip空间的点
				OUT.farRayWS = mul((float3x3)_Fog_MATRIX_I_V, mul(unity_CameraInvProjection, farPlaneClip.xyzz).xyz).xyz;//得到指向far plane的向量
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
				float2 screenPos = IN.positionSS.xy / IN.positionSS.w;
				float3 scenePosW = GetPosW(IN.farRayWS, screenPos);
				float dis = distance(_WorldSpaceCameraPos.xyz, scenePosW);
				float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - scenePosW);
				ApplyGlobalFog(col.rgb, _FogCol, _SunCol, dis, viewDirWS, -_MainLightPosition.xyz, _ExtinctionFallOff, _InscatteringFallOff);
				return col;
			}
			ENDHLSL
		}
	}
}