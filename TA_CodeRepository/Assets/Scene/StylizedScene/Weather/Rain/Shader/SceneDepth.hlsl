#ifndef SCENEDEPTH_INCLUDED
#define SCENEDEPTH_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"

float4x4 _SceneDepthCamMatrixVP;
float3 _SceneDepthCamPram; //Near,Far,Height

TEXTURE2D(_SceneDepthTex);
float4 _SceneDepthTex_TexelSize;
//SAMPLER(sampler_SceneDepthTex);
SAMPLER(sampler_linear_clamp);
SAMPLER(sampler_point_clamp);

//深度相机可视点位置
float GetSceneDepthPosW(float3 posWS)
{
	float4 posCS = mul(_SceneDepthCamMatrixVP, float4(posWS, 1.0));
	float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
	float sceneDepth = SAMPLE_TEXTURE2D_LOD(_SceneDepthTex, sampler_linear_clamp, posNDC.xy, 0).r;
	#if UNITY_REVERSED_Z
		sceneDepth = 1.0 - sceneDepth;
	#endif
	return _SceneDepthCamPram.z - lerp(_SceneDepthCamPram.x, _SceneDepthCamPram.y, sceneDepth);
}

//高度遮挡测试_平滑
float SceneDepthTestSmmoth(float3 posWS)
{
	float4 posCS = mul(_SceneDepthCamMatrixVP, float4(posWS, 1.0));
	float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
	float sceneDepth = SAMPLE_TEXTURE2D(_SceneDepthTex, sampler_linear_clamp, posNDC.xy).r;
	#if UNITY_REVERSED_Z
		sceneDepth = 1.0 - sceneDepth;
	#endif
	return smoothstep(sceneDepth, sceneDepth - 0.02, posNDC.z);
}

//高度遮挡测试,pcf
float SceneDepthTest_PCF(float3 posWS)
{
	const float samplecount = 4;
	float weights[samplecount];
	float2 positions[samplecount];
	float4 posCS = mul(_SceneDepthCamMatrixVP, float4(posWS, 1.0));
	float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
	SampleShadow_ComputeSamples_Tent_3x3(_SceneDepthTex_TexelSize, posNDC.xy, weights, positions);
	float occlusion = 0;
	for(int i = 0; i < samplecount; i++)
	{
		float sceneDepth = SAMPLE_TEXTURE2D(_SceneDepthTex, sampler_linear_clamp, positions[i]).r;
		#if UNITY_REVERSED_Z
			sceneDepth = 1.0 - sceneDepth;
		#endif
		occlusion += weights[i] * step(posNDC.z - 0.001, sceneDepth);
	}
	//return occlusion;
	//for(int i = -1; i <= 1; i++)
	//{
	//	for(int j = -1; j <= 1; j++)
	//	{
	//		float sceneDepth = SAMPLE_TEXTURE2D(_SceneDepthTex, sampler_point_clamp, posNDC.xy + float2(i, j) * _SceneDepthTex_TexelSize.xy).r;
	//		#if UNITY_REVERSED_Z
	//			sceneDepth = 1.0 - sceneDepth;
	//		#endif
	//		occlusion += step(posNDC.z - 0.005, sceneDepth);		
	//	}
	//}
	//return occlusion / 9;

	float sceneDepth = SAMPLE_TEXTURE2D_LOD(_SceneDepthTex, sampler_linear_clamp, posNDC.xy, 10).r;
	#if UNITY_REVERSED_Z
		sceneDepth = 1.0 - sceneDepth;
	#endif
	occlusion = step(posNDC.z - 0.001, sceneDepth);		
	return occlusion;
}
#endif