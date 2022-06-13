Shader "Code Repository/Scene/Rain" 
{
	Properties 
	{

	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			half _RainIntensity;
			half _RainOpacityInAll;
			half3 _RainColor;
			float4 _RainScale_Layer12;
			float4 _RainScale_Layer34;
			float4 _RotateSpeed;
			float4 _RotateAmount;
			float4 _DropSpeed;
			float4 _RainDepthStart;
			float4 _RainDepthRange;
			float4 _RainOpacities;

			float4x4 _SceneDepthCamMatrixVP;
			float3 _SceneDepthCamPram; //Near,Far,Height

			TEXTURE2D(_RainSplashTex);
			SAMPLER(sampler_RainSplashTex);

			TEXTURE2D(_RainHeightmap);
			SAMPLER(sampler_RainHeightmap);
		
			TEXTURE2D(_RainShapeTex);
			SAMPLER(sampler_RainShapeTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			TEXTURE2D(_SceneDepthTex);
			SAMPLER(sampler_SceneDepthTex);

			TEXTURE2D(_RainMaskTexture);
			SAMPLER(sampler_RainMaskTexture);
		
			float CalcSceneDepth(float4 screenPosition)
			{
				float2 screenPos = screenPosition.xy / screenPosition.w;
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				float eyeDepth = LinearEyeDepth(depthTextureValue, _ZBufferParams);
				return eyeDepth;
			}

			float GetSceneDepth(float3 posWS)
			{
				float4 posCS = mul(_SceneDepthCamMatrixVP, float4(posWS, 1.0));
				float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
				float sceneDepth = SAMPLE_TEXTURE2D_LOD(_SceneDepthTex, sampler_SceneDepthTex, posNDC.xy, 0).r;
				#if UNITY_REVERSED_Z
					sceneDepth = 1.0 - sceneDepth;
				#endif
				return _SceneDepthCamPram.z - lerp(_SceneDepthCamPram.x, _SceneDepthCamPram.y, sceneDepth);
			}

			float RainHeightDepthMapTest(float3 virtualPosWS)
			{
				float4 posCS = mul(_SceneDepthCamMatrixVP, float4(virtualPosWS, 1.0));
				float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
				float sceneDepth = SAMPLE_TEXTURE2D(_SceneDepthTex, sampler_SceneDepthTex, posNDC.xy).r;
				#if UNITY_REVERSED_Z
					sceneDepth = 1.0 - sceneDepth;
				#endif
				//return step(posNDC.z, sceneDepth);
				return smoothstep(sceneDepth, sceneDepth - 0.02, posNDC.z);
			}
		ENDHLSL

		pass
		{
			Name "Rain Splash"
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			HLSLPROGRAM
			#pragma multi_compile_instancing

			#pragma vertex vertex
			#pragma fragment fragment

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
				UNITY_DEFINE_INSTANCED_PROP(float4, _SplashInfo_1)//pos.xz,scale,index
				UNITY_DEFINE_INSTANCED_PROP(half, _SplashInfo_2) //opacity
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

			struct Attributes 
			{
				float4 positionOS		: POSITION;
				float2 uv				: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float2 UV				: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				float4 splashInfo_1 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SplashInfo_1);
				float yPos = GetSceneDepth(float3(splashInfo_1.x, _SceneDepthCamPram.z-_SceneDepthCamPram.x, splashInfo_1.y));
				float3 posWS = float3(splashInfo_1.x, yPos, splashInfo_1.y) + TransformObjectToWorld(IN.positionOS.xyz * splashInfo_1.z);
				OUT.positionCS = TransformWorldToHClip(posWS);
				OUT.UV = IN.uv * 0.5 + float2(0, 0.5) + float2(splashInfo_1.w % 2, -floor(splashInfo_1.w / 2)) * 0.5;
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				half4 rainSplashColor = SAMPLE_TEXTURE2D(_RainSplashTex, sampler_RainSplashTex, IN.UV);
				rainSplashColor.a *= UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SplashInfo_2);
				return rainSplashColor;
			}
			ENDHLSL
		}

		Pass
		{
			Name "Rain Mask"

			Cull Off
			ZWrite Off
			ZTest Always

			HLSLPROGRAM
			#pragma vertex vertex
			#pragma fragment fragment

			struct Attributes 
			{
				float4 positionOS		: POSITION;
				float2 uv				: TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float2 UV				: TEXCOORD0;	
				float4 UVLayer12		: TEXCOORD1;
				float4 UVLayer34		: TEXCOORD2;
				float4 ScreenPosition	: TEXCOORD3;
				float4 ViewDirVS		: TEXCOORD4;
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.UV = IN.uv;

				float4 UVLayer12 = IN.uv.xyxy;
				float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
				float4 Cosines = float4(cos(SinT), sin(SinT));
				float4 CenteredUV = UVLayer12 - 0.5;
				float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
				UVLayer12 *= _RainScale_Layer12;
				OUT.UVLayer12 = UVLayer12;

				float4 UVLayer34 = IN.uv.xyxy;
				SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
				Cosines = float4(cos(SinT), sin(SinT));
				CenteredUV = UVLayer34 - 0.5;
				RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
				UVLayer34 *= _RainScale_Layer34;
				OUT.UVLayer34 = UVLayer34;

				OUT.ScreenPosition = ComputeScreenPos(OUT.positionCS);
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 posVS = TransformWorldToView(posWS);
				OUT.ViewDirVS.xyz = posWS - _WorldSpaceCameraPos.xyz;
				OUT.ViewDirVS.w = -posVS.z;
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				//view depth test
				float backDepthVS = CalcSceneDepth(IN.ScreenPosition);
				float4 virtualDepth = 0;
				virtualDepth.x = SAMPLE_TEXTURE2D(_RainHeightmap, sampler_RainHeightmap, IN.UVLayer12.xy).r * _RainDepthRange.x + _RainDepthStart.x + 0.01;
				virtualDepth.y = SAMPLE_TEXTURE2D(_RainHeightmap, sampler_RainHeightmap, IN.UVLayer12.zw).r * _RainDepthRange.z + _RainDepthStart.y;
				virtualDepth.z = SAMPLE_TEXTURE2D(_RainHeightmap, sampler_RainHeightmap, IN.UVLayer34.xy).r * _RainDepthRange.y + _RainDepthStart.z;
				virtualDepth.w = SAMPLE_TEXTURE2D(_RainHeightmap, sampler_RainHeightmap, IN.UVLayer34.zw).r * _RainDepthRange.w + _RainDepthStart.w;
				//float4 occlusionDistance = step(virtualDepth, backDepthVS);
				float4 occlusionDistance = smoothstep(backDepthVS, backDepthVS - 3, virtualDepth);

				// Calc virtual position
				float4 depthRatio = virtualDepth / IN.ViewDirVS.w;
				float3 virtualPosition1WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.x;
				float3 virtualPosition2WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.y;
				float3 virtualPosition3WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.z;
				float3 virtualPosition4WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.w;

				// heigth depth test
				float4 occlusionHeight = 0;
				occlusionHeight.x = RainHeightDepthMapTest(virtualPosition1WS);
				occlusionHeight.y = RainHeightDepthMapTest(virtualPosition2WS);
				occlusionHeight.z = RainHeightDepthMapTest(virtualPosition3WS);
				occlusionHeight.w = RainHeightDepthMapTest(virtualPosition4WS);

				half4 maskColor = occlusionDistance * occlusionHeight * _RainOpacities * _RainOpacityInAll;
				return maskColor;
			}
			ENDHLSL
		}

		Pass
		{
			Name "Rain Merge"
			Cull Off
			ZWrite Off
			ZTest Always
			Blend SrcAlpha One

			HLSLPROGRAM
			#pragma vertex vertex
			#pragma fragment fragment

			struct Attributes 
			{
				float4 positionOS		: POSITION;
				float2 uv				: TEXCOORD0;
				float3 color			: COLOR;
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float2 uv				: TEXCOORD0;	
				float4 UVLayer12		: TEXCOORD1;
				float4 UVLayer34		: TEXCOORD2;
				float4 ScreenPosition	: TEXCOORD3;
				half GradientFactor		: TEXCOORD4;
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;

				float4 UVLayer12 = IN.uv.xyxy;
				float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
				float4 Cosines = float4(cos(SinT), sin(SinT));
				float4 CenteredUV = UVLayer12 - 0.5;
				float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
				UVLayer12 *= _RainScale_Layer12;
				OUT.UVLayer12 = UVLayer12;

				float4 UVLayer34 = IN.uv.xyxy;
				SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
				Cosines = float4(cos(SinT), sin(SinT));
				CenteredUV = UVLayer34 - 0.5;
				RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
				UVLayer34 *= _RainScale_Layer34;
				OUT.UVLayer34 = UVLayer34;

				OUT.ScreenPosition = ComputeScreenPos(OUT.positionCS);
				OUT.GradientFactor = smoothstep(0, 1, IN.color.r);
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				float4 maskLow =  SAMPLE_TEXTURE2D(_RainMaskTexture, sampler_RainMaskTexture, IN.ScreenPosition.xy / IN.ScreenPosition.w);

				half4 layer = 0;
				layer.x = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.xy).r;
				layer.y = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.zw).r;
				layer.z = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.xy).r;
				layer.w = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.zw).r;
				layer = pow(max(0, layer), lerp(6, 1, _RainIntensity)) * (1 - step(_RainIntensity, 0));
				half rainShape = dot(layer, maskLow);
				rainShape = saturate(rainShape);

				half3 finalColor = _RainColor * rainShape;
				return half4(finalColor, IN.GradientFactor);
			}
			ENDHLSL
		}
	}
}