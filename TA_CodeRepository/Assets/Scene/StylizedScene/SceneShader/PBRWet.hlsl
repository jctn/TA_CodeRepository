#ifndef PBRWET_INCLUDED
#define PBRWET_INCLUDED

half _WetLevel;
half2 _FloodLevel;

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
    //test
    _WetLevel = 0.5;
    _FloodLevel = 1;

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
#endif