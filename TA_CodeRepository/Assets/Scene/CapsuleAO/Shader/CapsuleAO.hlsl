#ifndef CAPSULEAO
#define CAPSULEAO

float4 Spheres[24];
int SphereCount;

float SimpleSphereAO(float4 sphere, float3 pos,float3 normal)
{
	float3 dir = sphere.xyz - pos;
	float dis = length(dir);
	dir /= dis;//normalize
	float disFade = sphere.w / dis;
	float angleFade = dot(dir, normal);
	return disFade * disFade * angleFade;
}

float SimpleSpheresAO_1(float3 pos,float3 normal)
{
	float ao = 0;
	for(int i = 0; i < SphereCount; i++)
	{
		ao += SimpleSphereAO(Spheres[i], pos, normal);
	}
	return 1 - saturate(ao);
}

float SimpleSpheresAO_2(float3 pos,float3 normal)
{
	float ao = 0;
	for(int i = 0; i < SphereCount; i++)
	{
		ao = max(ao, SimpleSphereAO(Spheres[i], pos, normal));
	}
	return 1 - ao;
}
#endif