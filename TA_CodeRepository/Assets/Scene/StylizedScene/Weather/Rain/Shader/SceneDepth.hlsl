#ifndef SCENEDEPTH_INCLUDED
#define SCENEDEPTH_INCLUDED

//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

float4x4 _SceneDepthCamMatrixVP;
float3 _SceneDepthCamPram; //Near,Far,Height

TEXTURE2D(_SceneDepthTex);
SAMPLER(sampler_SceneDepthTex);
SAMPLER(sampler_linear_clamp);

//深度相机可视点位置
float GetSceneDepthPosW(float3 posWS)
{
	float4 posCS = mul(_SceneDepthCamMatrixVP, float4(posWS, 1.0));
	float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
	float sceneDepth = SAMPLE_TEXTURE2D_LOD(_SceneDepthTex, sampler_SceneDepthTex, posNDC.xy, 0).r;
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
	float sceneDepth = SAMPLE_TEXTURE2D(_SceneDepthTex, sampler_SceneDepthTex, posNDC.xy).r;
	#if UNITY_REVERSED_Z
		sceneDepth = 1.0 - sceneDepth;
	#endif
	return smoothstep(sceneDepth, sceneDepth - 0.02, posNDC.z);
}

//高度遮挡测试
int SceneDepthTest(float3 posWS)
{
	float4 posCS = mul(_SceneDepthCamMatrixVP, float4(posWS, 1.0));
	float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
	float sceneDepth = SAMPLE_TEXTURE2D(_SceneDepthTex, sampler_linear_clamp, posNDC.xy).r;
	#if UNITY_REVERSED_Z
		sceneDepth = 1.0 - sceneDepth;
	#endif
	return step(posNDC.z, sceneDepth);
}
#endif