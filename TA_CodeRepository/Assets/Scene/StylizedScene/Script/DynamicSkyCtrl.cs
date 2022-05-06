using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(TimeCtrl))]
[ExecuteAlways]
public class DynamicSkyCtrl : MonoBehaviour
{
    [Header("Sky Color")]
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient TopColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient MiddleColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient BottomColor;

    [Header("Sun&Moon")]
    [Range(-180f, 180f)]
    public float Longitude = 0.0f;
    [Range(-180f, 180f)]
    public float Latitude = 0.0f;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunGlowColor;

    public AnimationCurve SunGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    public AnimationCurve MoonGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    public AnimationCurve StarIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    [Header("Light")]
    public Gradient LightColor;
    public AnimationCurve LightIntensity = AnimationCurve.Linear(0f, 0f, 24f, 1f);

    [Header("Reference Node")]
    public Renderer SkyBoxRender;
    public Transform Light;

    TimeCtrl mTimeCtrl;
    MaterialPropertyBlock mMaterialPropertyBlock;
    Light mLightCom;

    readonly int mID_TopColor = Shader.PropertyToID("_TopColor");
    readonly int mID_MiddleColor = Shader.PropertyToID("_MiddleColor");
    readonly int mID_BottomColor = Shader.PropertyToID("_BottomColor");
    readonly int mID_SunColor = Shader.PropertyToID("_SunColor");
    readonly int mID_SunGlowColor = Shader.PropertyToID("_SunGlowColor");
    readonly int mID_SunGlowRadius = Shader.PropertyToID("_SunGlowRadius");
    readonly int mID_MoonGlowRadius = Shader.PropertyToID("_MoonGlowRadius");
    readonly int mID_StarIntensity = Shader.PropertyToID("_StarIntensity");
    readonly int mID_IsNight = Shader.PropertyToID("_IsNight");
    readonly int mID_LightMatrix = Shader.PropertyToID("_LightMatrix");

    private void Start()
    {       
        mTimeCtrl = GetComponent<TimeCtrl>();
        if (Light != null)  mLightCom = Light.GetComponent<Light>(); 
    }

    private void Update()
    {
        UpdateLight();
        UpdateSkyBox();
    }

    private void OnDisable()
    {
        if(SkyBoxRender != null)
        {
            SkyBoxRender.SetPropertyBlock(null);
        }
    }

    void UpdateSkyBox()
    {
        if(SkyBoxRender != null)
        {
            float colorKey = 0f;
            float floatKey = 0f;
            if (mTimeCtrl != null)
            {
                colorKey = mTimeCtrl.GradientTime;
                floatKey = mTimeCtrl.CurveTime;
            }
            if (mMaterialPropertyBlock == null) mMaterialPropertyBlock = new MaterialPropertyBlock();
            mMaterialPropertyBlock.SetVector(mID_BottomColor, BottomColor.Evaluate(colorKey));
            mMaterialPropertyBlock.SetVector(mID_MiddleColor, MiddleColor.Evaluate(colorKey));
            mMaterialPropertyBlock.SetVector(mID_TopColor, TopColor.Evaluate(colorKey));
            mMaterialPropertyBlock.SetVector(mID_SunColor, SunColor.Evaluate(colorKey));
            mMaterialPropertyBlock.SetVector(mID_SunGlowColor, SunGlowColor.Evaluate(colorKey));
            mMaterialPropertyBlock.SetFloat(mID_SunGlowRadius, SunGlowRadius.Evaluate(floatKey));
            mMaterialPropertyBlock.SetFloat(mID_MoonGlowRadius, MoonGlowRadius.Evaluate(floatKey));
            mMaterialPropertyBlock.SetFloat(mID_StarIntensity, StarIntensity.Evaluate(floatKey));
            SkyBoxRender.SetPropertyBlock(mMaterialPropertyBlock);
        }
    }

    void UpdateLight()
    {
        if(Light != null)
        {
            float sunProgression = 0f;
            float moonProgression = 0f;
            bool isNight = false;
            if(mTimeCtrl != null)
            {
                sunProgression = mTimeCtrl.DayProgression;
                moonProgression = mTimeCtrl.NightProgression;
                isNight = !mTimeCtrl.IsDay;
            }

            if (!isNight)
            {
                Light.rotation = Quaternion.Euler(0.0f, Longitude, Latitude) * Quaternion.Euler(Mathf.Lerp(-5f, 185f, sunProgression), 180f, 0f);
                Shader.SetGlobalFloat(mID_IsNight, 0f);
                Shader.DisableKeyword("_NIGHT");
            }
            else
            {
                Light.rotation = Quaternion.Euler(0.0f, Longitude, Latitude) * Quaternion.Euler(Mathf.Lerp(-5f, 185f, moonProgression), 180f, 0f);
                Shader.SetGlobalFloat(mID_IsNight, 1f);
                Shader.EnableKeyword("_NIGHT");
            }
            Shader.SetGlobalMatrix(mID_LightMatrix, Light.worldToLocalMatrix);
        }
        
        if(mLightCom != null)
        {
            float colorKey = 0f;
            float floatKey = 0f;
            if (mTimeCtrl != null)
            {
                colorKey = mTimeCtrl.GradientTime;
                floatKey = mTimeCtrl.CurveTime;
            }
            mLightCom.color = LightColor.Evaluate(colorKey);
            mLightCom.intensity = LightIntensity.Evaluate(floatKey);
            RenderSettings.ambientLight = mLightCom.color * mLightCom.intensity * 0.8f;
        }
    }
}
