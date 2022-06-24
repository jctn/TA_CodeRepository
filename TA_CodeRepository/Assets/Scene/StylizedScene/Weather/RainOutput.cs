using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RainOutput : BaseOutput
{
    public RainOutput(WeatherSetting cur, TimeCtrl timeCtrl) : base(cur, timeCtrl) { }

    #region Output
    public Texture2D RainHeightmap;
    public Texture2D RainShapeTexture;
    public Texture2D RainSplashTex;

    public float RainIntensity;
    public float RainOpacityInAll;
    public Color RainColor;
    public Vector4 RainScale_Layer12;
    public Vector4 RainScale_Layer34;
    public Vector4 RotateSpeed;
    public Vector4 RotateAmount;
    public Vector4 DropSpeed;
    public Vector4 RainOpacity;
    //SplashInterval,SplashPlayTime
    public Vector3 SplashData_1;
    //SplashScale, SplashOpacity
    public Vector4 SplashData_2;
    //WetLevel,GapFloodLevel,PuddleFloodLevel
    public Vector3 WetData;
    #endregion

    public override void UpdateOutput()
    {
        //贴图,目标在下雨：目标贴图，否者当前贴图
        if (mTargetWeatherSetting != null)
        {
            if (mTargetWeatherSetting.RainIntensity > 0)
            {
                RainHeightmap = mTargetWeatherSetting.RainHeightmap;
                RainShapeTexture = mTargetWeatherSetting.RainShapeTexture;
                RainSplashTex = mTargetWeatherSetting.RainSplashTex;
            }
            else
            {
                RainHeightmap = mCurWeatherSetting.RainHeightmap;
                RainShapeTexture = mCurWeatherSetting.RainShapeTexture;
                RainSplashTex = mCurWeatherSetting.RainSplashTex;
            }
        }
        else
        {
            RainHeightmap = mCurWeatherSetting.RainHeightmap;
            RainShapeTexture = mCurWeatherSetting.RainShapeTexture;
            RainSplashTex = mCurWeatherSetting.RainSplashTex;
        }

        //参数混合
        if (mTargetWeatherSetting != null)
        {
            RainIntensity = Mathf.Lerp(mCurWeatherSetting.RainIntensity, mTargetWeatherSetting.RainIntensity, mTranslationProgression);

            //都在下雨，混合；只有目标在下雨，取目标；否者，取当前
            if (mCurWeatherSetting.RainIntensity > 0 && mTargetWeatherSetting.RainIntensity > 0)
            {
                RainOpacityInAll = Mathf.Lerp(mCurWeatherSetting.RainOpacityInAll, mTargetWeatherSetting.RainOpacityInAll, mTranslationProgression);    
                RainColor = Color.Lerp(mCurWeatherSetting.RainColor, mTargetWeatherSetting.RainColor, mTranslationProgression);

                //RainScale_Layer12
                Vector2 layer1 = Vector2.Lerp(mCurWeatherSetting.RainScale_One, mTargetWeatherSetting.RainScale_One, mTranslationProgression);
                Vector2 layer2 = Vector2.Lerp(mCurWeatherSetting.RainScale_Two, mTargetWeatherSetting.RainScale_Two, mTranslationProgression);
                RainScale_Layer12 = new Vector4(layer1.x, layer1.y, layer2.x, layer2.y);

                //RainScale_Layer34
                Vector2 layer3 = Vector2.Lerp(mCurWeatherSetting.RainScale_Three, mTargetWeatherSetting.RainScale_Three, mTranslationProgression);
                Vector2 layer4 = Vector2.Lerp(mCurWeatherSetting.RainScale_Four, mTargetWeatherSetting.RainScale_Four, mTranslationProgression);
                RainScale_Layer34 = new Vector4(layer3.x, layer3.y, layer4.x, layer4.y);

                //RotateSpeed
                float layer1_f = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_One, mTargetWeatherSetting.RotateSpeed_One, mTranslationProgression);
                float layer2_f = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_Two, mTargetWeatherSetting.RotateSpeed_Two, mTranslationProgression);
                float layer3_f = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_Three, mTargetWeatherSetting.RotateSpeed_Three, mTranslationProgression);
                float layer4_f = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_Four, mTargetWeatherSetting.RotateSpeed_Four, mTranslationProgression);
                RotateSpeed = new Vector4(layer1_f, layer2_f, layer3_f, layer4_f);

                //RotateAmount
                layer1_f = Mathf.Lerp(mCurWeatherSetting.RotateAmount_One, mTargetWeatherSetting.RotateAmount_One, mTranslationProgression);
                layer2_f = Mathf.Lerp(mCurWeatherSetting.RotateAmount_Two, mTargetWeatherSetting.RotateAmount_Two, mTranslationProgression);
                layer3_f = Mathf.Lerp(mCurWeatherSetting.RotateAmount_Three, mTargetWeatherSetting.RotateAmount_Three, mTranslationProgression);
                layer4_f = Mathf.Lerp(mCurWeatherSetting.RotateAmount_Four, mTargetWeatherSetting.RotateAmount_Four, mTranslationProgression);
                RotateAmount = new Vector4(layer1_f, layer2_f, layer3_f, layer4_f);

                //DropSpeed
                layer1_f = Mathf.Lerp(mCurWeatherSetting.DropSpeed_One, mTargetWeatherSetting.DropSpeed_One, mTranslationProgression);
                layer2_f = Mathf.Lerp(mCurWeatherSetting.DropSpeed_Two, mTargetWeatherSetting.DropSpeed_Two, mTranslationProgression);
                layer3_f = Mathf.Lerp(mCurWeatherSetting.DropSpeed_Three, mTargetWeatherSetting.DropSpeed_Three, mTranslationProgression);
                layer4_f = Mathf.Lerp(mCurWeatherSetting.DropSpeed_Four, mTargetWeatherSetting.DropSpeed_Four, mTranslationProgression);
                DropSpeed = new Vector4(layer1_f, layer2_f, layer3_f, layer4_f);

                //RainOpacity
                layer1_f = Mathf.Lerp(mCurWeatherSetting.RainOpacity_One, mTargetWeatherSetting.RainOpacity_One, mTranslationProgression);
                layer2_f = Mathf.Lerp(mCurWeatherSetting.RainOpacity_Two, mTargetWeatherSetting.RainOpacity_Two, mTranslationProgression);
                layer3_f = Mathf.Lerp(mCurWeatherSetting.RainOpacity_Three, mTargetWeatherSetting.RainOpacity_Three, mTranslationProgression);
                layer4_f = Mathf.Lerp(mCurWeatherSetting.RainOpacity_Four, mTargetWeatherSetting.RainOpacity_Four, mTranslationProgression);
                RainOpacity = new Vector4(layer1_f, layer2_f, layer3_f, layer4_f);

                //SplashData_1
                Vector3 cur = new Vector3(mCurWeatherSetting.SplashIntervalMin, mCurWeatherSetting.SplashIntervalMax, mCurWeatherSetting.SplashPlayTime);
                Vector3 tar = new Vector3(mTargetWeatherSetting.SplashIntervalMin, mTargetWeatherSetting.SplashIntervalMax, mTargetWeatherSetting.SplashPlayTime);
                SplashData_1 =  Vector3.Lerp(cur, tar, mTranslationProgression);

                //SplashData_2
                Vector4 cur_vec4 = new Vector4(mCurWeatherSetting.SplashScaleMin, mCurWeatherSetting.SplashScaleMax, mCurWeatherSetting.SplashOpacityMin, mCurWeatherSetting.SplashOpacityMax);
                Vector4 tar_vec4 = new Vector4(mTargetWeatherSetting.SplashScaleMin, mTargetWeatherSetting.SplashScaleMax, mTargetWeatherSetting.SplashOpacityMin, mTargetWeatherSetting.SplashOpacityMax);
                SplashData_2 = Vector4.Lerp(cur_vec4, tar_vec4, mTranslationProgression);

                //WetData
                cur = new Vector3(mCurWeatherSetting.MaxWetLevel, mCurWeatherSetting.MaxGapFloodLevel, mCurWeatherSetting.MaxPuddleFloodLevel);
                tar = new Vector3(mTargetWeatherSetting.MaxWetLevel, mTargetWeatherSetting.MaxGapFloodLevel, mTargetWeatherSetting.MaxPuddleFloodLevel);
                WetData = Vector3.Lerp(cur, tar, mTranslationProgression);
            }
            else if (mTargetWeatherSetting.RainIntensity > 0)
            {
                UpdateSingleOutput(mTargetWeatherSetting);
            }
            else
            {
                UpdateSingleOutput(mCurWeatherSetting);
            }
        }
        else
        {
            RainIntensity = mCurWeatherSetting.RainIntensity;

            UpdateSingleOutput(mCurWeatherSetting);
        }
    }

    void UpdateSingleOutput(WeatherSetting setting)
    {
        RainOpacityInAll = setting.RainOpacityInAll;
        RainColor = setting.RainColor;

        //RainScale_Layer12
        Vector2 layer1_Cur = setting.RainScale_One;
        Vector2 layer2_Cur = setting.RainScale_Two;
        RainScale_Layer12 = new Vector4(layer1_Cur.x, layer1_Cur.y, layer2_Cur.x, layer2_Cur.y);

        //RainScale_Layer34
        Vector2 layer3_Cur = setting.RainScale_Three;
        Vector2 layer4_Cur = setting.RainScale_Four;
        RainScale_Layer34 = new Vector4(layer3_Cur.x, layer3_Cur.y, layer4_Cur.x, layer4_Cur.y);

        //RotateSpeed
        RotateSpeed = new Vector4(setting.RotateSpeed_One, setting.RotateSpeed_Two, setting.RotateSpeed_Three, setting.RotateSpeed_Four);

        //RotateAmount
        RotateAmount = new Vector4(setting.RotateAmount_One, setting.RotateAmount_Two, setting.RotateAmount_Three, setting.RotateAmount_Four);

        //DropSpeed
        DropSpeed = new Vector4(setting.DropSpeed_One, setting.DropSpeed_Two, setting.DropSpeed_Three, setting.DropSpeed_Four);

        //RainOpacity
        RainOpacity = new Vector4(setting.RainOpacity_One, setting.RainOpacity_Two, setting.RainOpacity_Three, setting.RainOpacity_Four);

        //SplashData_1
        SplashData_1 = new Vector3(setting.SplashIntervalMin, setting.SplashIntervalMax, setting.SplashPlayTime);

        //SplashData_2
        SplashData_2 = new Vector4(setting.SplashScaleMin, setting.SplashScaleMax, setting.SplashOpacityMin, setting.SplashOpacityMax);

        //WetData
        WetData = new Vector3(setting.MaxWetLevel, setting.MaxGapFloodLevel, setting.MaxPuddleFloodLevel);
    }
}
