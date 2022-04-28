using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(TimeCtrl))]
[ExecuteAlways]
public class DynamicSkyCtrl : MonoBehaviour
{
    [Header("Sky")]
    [Range(-180f, 180f)]
    public float Longitude = 0.0f;
    [Range(-180f, 180f)]
    public float Latitude = 0.0f;
    [ColorUsage(false, true)]
    public Color BottomColor = new Color(0.65f, 0.85f, 0.9f, 1f);
    [ColorUsage(false, true)]
    public Color MiddleColor = new Color(0.15f, 0.45f, 0.9f, 1f);
    [ColorUsage(false, true)]
    public Color TopColor = new Color(0f, 0.2f, 0.7f, 1f);

    [Header("Light")]
    public Color LightColor = new Color(0.8f, 1f, 1f);
    public float LightIntensity = 1f;

    [Header("Reference Node")]
    public Renderer SkyBoxRender;
    public Transform Sun;
    public Transform Moon;
    public Transform Light;

    TimeCtrl mTimeCtrl;
    MaterialPropertyBlock mMaterialPropertyBlock;
    Light mLightCom;

    readonly int mID_BottomColor = Shader.PropertyToID("_BottomColor");
    readonly int mID_MiddleColor = Shader.PropertyToID("_MiddleColor");
    readonly int mID_TopColor = Shader.PropertyToID("_TopColor");
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
        SkyBoxRender.SetPropertyBlock(null);
    }

    void UpdateSkyBox()
    {
        if(SkyBoxRender != null)
        {
            if(mMaterialPropertyBlock == null) mMaterialPropertyBlock = new MaterialPropertyBlock();
            mMaterialPropertyBlock.SetColor(mID_BottomColor, BottomColor.gamma); //最终传给shader为BottomColor.gamma.linear
            mMaterialPropertyBlock.SetColor(mID_MiddleColor, MiddleColor.gamma);
            mMaterialPropertyBlock.SetColor(mID_TopColor, TopColor.gamma);
            SkyBoxRender.SetPropertyBlock(mMaterialPropertyBlock);
        }
    }

    void UpdateLight()
    {
        if(Sun != null && Moon != null && Light != null)
        {
            Sun.rotation = Quaternion.Euler(0.0f, Longitude, Latitude) * Quaternion.Euler(mTimeCtrl.GetTimeOfDay * 360f / 24f - 90f, 180f, 0f); //6点，太阳在地平线(0,180,0)
            Moon.rotation = Quaternion.LookRotation(-Sun.forward);
            float sunHeight = Vector3.Dot(-Sun.forward, Vector3.up);
            if (sunHeight >= 0)
            {
                Light.rotation = Sun.rotation;
                Shader.SetGlobalFloat(mID_IsNight, 0f);
            }
            else
            {
                Light.rotation = Moon.rotation;
                Shader.SetGlobalFloat(mID_IsNight, 1f);
            }
            Shader.SetGlobalMatrix(mID_LightMatrix, Light.worldToLocalMatrix);
        }
        
        if(mLightCom != null)
        {
            mLightCom.color = LightColor;
            mLightCom.intensity = LightIntensity;
        }
    }
}
