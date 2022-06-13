#ifndef CAPSULEAO
#define CAPSULEAO

float4 Spheres[24];
int SphereCount;
float AoIntensity;

//https://iquilezles.org/articles/sphereao/
//https://www.shadertoy.com/view/4djSDy
//https://zhuanlan.zhihu.com/p/460444838
float SphereAO_AmbientTerm(float4 sphere, float3 pos,float3 normal)
{
	float res;
	float3 dir = sphere.xyz - pos;
	float dis = length(dir);
	float cosangle = dot(dir/dis, normal);
	float disDivR =  dis / sphere.w;
	float disDivR2 = disDivR * disDivR;
	float intersecting = 1 - disDivR2 * cosangle * cosangle;
	res =  max(1 / disDivR2 * cosangle, 0);

    //if(intersecting > 0) 
    //{
    //    #if 0
    //        // EXACT : Lagarde/de Rousiers - https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
    //        res = cosangle * acos(-cosangle * sqrt((disDivR2 - 1.0) / (1.0 - cosangle * cosangle))) - sqrt(intersecting * (disDivR2 - 1.0));
    //        res = res / disDivR2 + atan(sqrt(intersecting / (disDivR2 - 1.0)));
    //        res /= 3.141593;
    //    #else
    //        // APPROXIMATED : Quilez - https://iquilezles.org/articles/sphereao
    //        res = (cosangle * disDivR + 1.0) / disDivR2;
    //        res = 0.33 * res * res;
    //    #endif
    //}
	AoIntensity = 0.5;
	res = pow(res, 1 - AoIntensity);
	return res;
}

float SpheresAO_AmbientTerm_1(float3 pos,float3 normal)
{
	float ao = 0;
	for(int i = 0; i < SphereCount; i++)
	{
		ao += SphereAO_AmbientTerm(Spheres[i], pos, normal);
	}
	return 1 - saturate(ao);
}

float SpheresAO_AmbientTerm_2(float3 pos,float3 normal)
{
	float ao = 0;
	for(int i = 0; i < SphereCount; i++)
	{
		ao = max(ao, SphereAO_AmbientTerm(Spheres[i], pos, normal));
	}
	return 1 - ao;
}
#endif