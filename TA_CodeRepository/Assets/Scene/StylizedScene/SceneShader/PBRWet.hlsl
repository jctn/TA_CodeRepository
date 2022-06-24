#ifndef PBRWET_INCLUDED
#define PBRWET_INCLUDED

half _WetLevel;
half2 _FloodLevel;
TEXTURE2D(_RippleTexture)
SAMPLER(sampler_RippleTexture)

struct WetData
{
    half height;
    half4 vColor;
};

void DoWetProcess(inout half3 diffuse, inout half gloss, half wetLevel)
{
   diffuse *= lerp(1.0, 0.3, wetLevel);
   gloss = min(gloss * lerp(1.0, 2.5, wetLevel), 1.0);
}

void GroundWet(inout half3 diffuse, inout half3 specular, inout half gloss, inout float3 normalWS, WetData wetdata)
{
    half height = wetdata.height;
    half4 vColor = wetdata.vColor;
    half accumulatedWater = 0;
    half accumulatedWater_hole = min(_FloodLevel.x, 1.0 - height); //缝隙内积水
    half accumulatedWater_puddle = saturate((_FloodLevel.y - vColor.g) / 0.4); //水坑内积水
    accumulatedWater  = max(accumulatedWater_hole, accumulatedWater_puddle);
    DoWetProcess(diffuse, gloss, saturate(_WetLevel + accumulatedWater));
    gloss = lerp(gloss, 1.0, accumulatedWater);
    specular = lerp(specular, 0.02, accumulatedWater);
    normalWS = lerp(normalWS, float3(0, 1, 0), accumulatedWater);
}

float3 RainRipple(float2 uv, float time, half weight)
{
   float4 ripple = SAMPLE_TEXTURE2D(_RippleTexture, sampler_RippleTexture, uv);
   ripple.gb = ripple.gb * 2 - 1;   
   float dropFrac = frac(ripple.a + time); //0-1循环
   float timeFrac = dropFrac - 1.0 + ripple.r; //0-1循环
   float dropFactor = saturate(0.2 + weight * 0.8 - dropFrac); //随时间衰减，最低0.2
   float finalFactor = dropFactor * ripple.r * sin( clamp(timeFrac * 9.0, 0.0f, 3.0) * PI);
   
   return float3(ripple.gb * finalFactor * 0.35, 1.0);
}
#endif