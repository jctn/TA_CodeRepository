using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class GlobalFogSetting : MonoBehaviour
{
    public static bool EnableGlobalFog = false;

    public bool IsEnableGlobalFog = true;
    public Color GlobalFogColor;
    public Color SunColor;
    [Min(0)]
    public Vector3 ExtinctionFallOff;
    public Vector3 InscatteringFallOff;

    private void OnEnable()
    {
        SetGlobalFog();
    }

    private void OnDisable()
    {
        EnableGlobalFog = false;
    }

#if UNITY_EDITOR
    void Update()
    {
        SetGlobalFog();
    }
#endif

    void SetGlobalFog()
    {
        EnableGlobalFog = IsEnableGlobalFog;
        Shader.SetGlobalColor("_FogCol", GlobalFogColor);
        Shader.SetGlobalColor("_SunCol", SunColor);
        Shader.SetGlobalVector("_ExtinctionFallOff", ExtinctionFallOff);
        Shader.SetGlobalVector("_InscatteringFallOff", InscatteringFallOff);
    }
}
