#ifndef PBRWET_INCLUDED
#define PBRWET_INCLUDED
#include "Assets/Scene/StylizedScene/Weather/Rain/Shader/SceneDepth.hlsl"

half _WetLevel;
half2 _FloodLevel;
half _RainIntensity;
TEXTURE2D(_RippleTexture); //r距离衰减，sin波参数,gb法线在t,b方向的扰动；a,时间偏移
SAMPLER(sampler_RippleTexture);

struct WetData
{
    half height;
    half4 vColor;
    float3 posWS;
    half3x3 tTOw;
};

half2 SingleRipple(float2 uv, half time, half weight)
{
   half4 ripple = SAMPLE_TEXTURE2D(_RippleTexture, sampler_RippleTexture, uv);
   ripple.gb = ripple.gb * 2 - 1; //0-1>>-1-1
   half dropFrac = frac(ripple.a + time); //0-1循环
   half timeFrac = dropFrac - 1.0 + ripple.r; //0-1循环,sin参数
   half dropFactor = saturate(0.2 + weight * 0.8 - dropFrac); //最低0.2,随时间衰减
   half finalFactor = dropFactor * ripple.r * sin( clamp(timeFrac * 9.0, 0.0f, 3.0) * PI);
   return ripple.gb * finalFactor * 0.35;    
}

half3 RainRipple(float2 uv)
{
    half4 timeMul = half4(1, 0.85, 0.93, 1.13); 
    half4 timeAdd = half4(0, 0.f, 0.45, 0.7);
    half4 times = (_Time.y * timeMul + timeAdd) * 1.6;
    times = frac(times);

    half4 weights = _RainIntensity - half4(0, 0.25, 0.5, 0.75);
    weights = saturate(weights * 4);
    half2 ripple1 = SingleRipple(uv + float2( 0.25f,0.0f), times.x, weights.x);
    half2 ripple2 = SingleRipple(uv + float2(-0.55f,0.3f), times.y, weights.y);
    half2 ripple3 = SingleRipple(uv + float2(0.6f, 0.85f), times.z, weights.z);
    half2 ripple4 = SingleRipple(uv + float2(0.5f,-0.75f), times.w, weights.w);

    half3 waterNormal = half3(ripple1 * weights.x + ripple2 * weights.y + ripple3 * weights.z + ripple4 * weights.w, 1);
    waterNormal.xy = lerp(0, waterNormal.xy, saturate(_RainIntensity * 100));
    waterNormal = normalize(waterNormal);
    return waterNormal;
}

void DoWetProcess(inout half3 diffuse, inout half gloss, half wetLevel)
{
   diffuse *= lerp(1.0, 0.3, wetLevel);
   gloss = min(gloss * lerp(1.0, 2.5, wetLevel), 1.0);
}

void GroundWet(inout half3 diffuse, inout half3 specular, inout half gloss, inout float3 normalWS, WetData wetdata)
{
    int occlusion = SceneDepthTest(wetdata.posWS);//0遮挡
    half3 waterNormal = RainRipple(wetdata.posWS.xz * 0.05);//可以放到低分辨率的全屏处理上计算
    waterNormal = TransformTangentToWorld(waterNormal, wetdata.tTOw);

    half height = wetdata.height;
    half4 vColor = wetdata.vColor;
    half accumulatedWater = 0;
    half accumulatedWater_hole = min(_FloodLevel.x, 1.0 - height) * occlusion; //缝隙内积水
    half accumulatedWater_puddle = saturate((_FloodLevel.y - vColor.g) / 0.4); //水坑内积水
    accumulatedWater  = max(accumulatedWater_hole, accumulatedWater_puddle);
    DoWetProcess(diffuse, gloss, saturate(_WetLevel * occlusion + accumulatedWater));
    gloss = lerp(gloss, 1.0, accumulatedWater);
    specular = lerp(specular, 0.02, accumulatedWater);
    normalWS = lerp(normalWS, waterNormal, accumulatedWater);
}
#endif