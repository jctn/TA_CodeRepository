using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RainOutput : BaseOutput
{
    public RainOutput(WeatherSetting cur, TimeCtrl timeCtrl) : base(cur, timeCtrl)
    {

    }

    public override void UpdateData()
    {
        base.UpdateData();
    }

    public override void SetTranslation(WeatherSetting targetWeatherSetting, float translationInitTime, float translationDurationTime)
    {
        base.SetTranslation(targetWeatherSetting, translationInitTime, translationDurationTime);
    }

    #region Output
    public Texture2D RainHeightmap
    {
        get
        {
            if(mTargetWeatherSetting != null) return mTargetWeatherSetting.RainHeightmap;
            if (mCurWeatherSetting != null) return mCurWeatherSetting.RainHeightmap;
            return null;
        }
    }

    public Texture2D RainShapeTexture
    {
        get
        {
            if (mTargetWeatherSetting != null) return mTargetWeatherSetting.RainShapeTexture;
            if (mCurWeatherSetting != null) return mCurWeatherSetting.RainShapeTexture;
            return null;
        }
    }

    public Texture2D RainSplashTex
    {
        get
        {
            if (mTargetWeatherSetting != null) return mTargetWeatherSetting.RainSplashTex;
            if (mCurWeatherSetting != null) return mCurWeatherSetting.RainSplashTex;
            return null;
        }
    }

    public float RainIntensity
    {
        get
        {
            if(mTargetWeatherSetting != null)
            {
                return Mathf.Lerp(mCurWeatherSetting.RainIntensity, mTargetWeatherSetting.RainIntensity, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.RainIntensity;
            }
        }
    }

    public float RainOpacityInAll
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                return Mathf.Lerp(mCurWeatherSetting.RainOpacityInAll, mTargetWeatherSetting.RainOpacityInAll, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.RainOpacityInAll;
            }
        }
    }

    public Color RainColor
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                return Color.Lerp(mCurWeatherSetting.RainColor, mTargetWeatherSetting.RainColor, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.RainColor;
            }
        }
    }

    public Vector4 RainScale_Layer12
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Vector2 layer1_Cur = mCurWeatherSetting.RainScale_One;
                Vector2 layer2_Cur = mCurWeatherSetting.RainScale_Two;

                Vector2 layer1_Tar = mTargetWeatherSetting.RainScale_One;
                Vector2 layer2_Tar = mTargetWeatherSetting.RainScale_Two;

                Vector2 layer1 = Vector2.Lerp(layer1_Cur, layer1_Tar, mTranslationProgression);
                Vector2 layer2 = Vector2.Lerp(layer2_Cur, layer2_Tar, mTranslationProgression);

                return new Vector4(layer1.x, layer1.y, layer2.x, layer2.y);
            }
            else
            {
                Vector2 layer1_Cur = mCurWeatherSetting.RainScale_One;
                Vector2 layer2_Cur = mCurWeatherSetting.RainScale_Two;
                return new Vector4(layer1_Cur.x, layer1_Cur.y, layer2_Cur.x, layer2_Cur.y);
            }
        }
    }

    public Vector4 RainScale_Layer34
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Vector2 layer3_Cur = mCurWeatherSetting.RainScale_Three;
                Vector2 layer4_Cur = mCurWeatherSetting.RainScale_Four;

                Vector2 layer3_Tar = mTargetWeatherSetting.RainScale_Three;
                Vector2 layer4_Tar = mTargetWeatherSetting.RainScale_Four;

                Vector2 layer3 = Vector2.Lerp(layer3_Cur, layer3_Tar, mTranslationProgression);
                Vector2 layer4 = Vector2.Lerp(layer4_Cur, layer4_Tar, mTranslationProgression);

                return new Vector4(layer3.x, layer3.y, layer4.x, layer4.y);
            }
            else
            {
                Vector2 layer1_Cur = mCurWeatherSetting.RainScale_One;
                Vector2 layer2_Cur = mCurWeatherSetting.RainScale_Two;
                return new Vector4(layer1_Cur.x, layer1_Cur.y, layer2_Cur.x, layer2_Cur.y);
            }
        }
    }

    public Vector4 RotateSpeed
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float layer1 = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_One, mTargetWeatherSetting.RotateSpeed_One, mTranslationProgression);
                float layer2 = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_Two, mTargetWeatherSetting.RotateSpeed_Two, mTranslationProgression);
                float layer3 = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_Three, mTargetWeatherSetting.RotateSpeed_Three, mTranslationProgression);
                float layer4 = Mathf.Lerp(mCurWeatherSetting.RotateSpeed_Four, mTargetWeatherSetting.RotateSpeed_Four, mTranslationProgression);
                return new Vector4(layer1, layer2, layer3, layer4);
            }
            else
            {
                return new Vector4(mCurWeatherSetting.RotateSpeed_One, mCurWeatherSetting.RotateSpeed_Two, mCurWeatherSetting.RotateSpeed_Three, mCurWeatherSetting.RotateSpeed_Four);
            }
        }
    }

    public Vector4 RotateAmount
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float layer1 = Mathf.Lerp(mCurWeatherSetting.RotateAmount_One, mTargetWeatherSetting.RotateAmount_One, mTranslationProgression);
                float layer2 = Mathf.Lerp(mCurWeatherSetting.RotateAmount_Two, mTargetWeatherSetting.RotateAmount_Two, mTranslationProgression);
                float layer3 = Mathf.Lerp(mCurWeatherSetting.RotateAmount_Three, mTargetWeatherSetting.RotateAmount_Three, mTranslationProgression);
                float layer4 = Mathf.Lerp(mCurWeatherSetting.RotateAmount_Four, mTargetWeatherSetting.RotateAmount_Four, mTranslationProgression);
                return new Vector4(layer1, layer2, layer3, layer4);
            }
            else
            {
                return new Vector4(mCurWeatherSetting.RotateAmount_One, mCurWeatherSetting.RotateAmount_Two, mCurWeatherSetting.RotateAmount_Three, mCurWeatherSetting.RotateAmount_Four);
            }
        }
    }

    public Vector4 DropSpeed
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float layer1 = Mathf.Lerp(mCurWeatherSetting.DropSpeed_One, mTargetWeatherSetting.DropSpeed_One, mTranslationProgression);
                float layer2 = Mathf.Lerp(mCurWeatherSetting.DropSpeed_Two, mTargetWeatherSetting.DropSpeed_Two, mTranslationProgression);
                float layer3 = Mathf.Lerp(mCurWeatherSetting.DropSpeed_Three, mTargetWeatherSetting.DropSpeed_Three, mTranslationProgression);
                float layer4 = Mathf.Lerp(mCurWeatherSetting.DropSpeed_Four, mTargetWeatherSetting.DropSpeed_Four, mTranslationProgression);
                return new Vector4(layer1, layer2, layer3, layer4);
            }
            else
            {
                return new Vector4(mCurWeatherSetting.DropSpeed_One, mCurWeatherSetting.DropSpeed_Two, mCurWeatherSetting.DropSpeed_Three, mCurWeatherSetting.DropSpeed_Four);
            }
        }
    }

    public Vector4 RainOpacity
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float layer1 = Mathf.Lerp(mCurWeatherSetting.RainOpacity_One, mTargetWeatherSetting.RainOpacity_One, mTranslationProgression);
                float layer2 = Mathf.Lerp(mCurWeatherSetting.RainOpacity_Two, mTargetWeatherSetting.RainOpacity_Two, mTranslationProgression);
                float layer3 = Mathf.Lerp(mCurWeatherSetting.RainOpacity_Three, mTargetWeatherSetting.RainOpacity_Three, mTranslationProgression);
                float layer4 = Mathf.Lerp(mCurWeatherSetting.RainOpacity_Four, mTargetWeatherSetting.RainOpacity_Four, mTranslationProgression);
                return new Vector4(layer1, layer2, layer3, layer4);
            }
            else
            {
                return new Vector4(mCurWeatherSetting.RainOpacity_One, mCurWeatherSetting.RainOpacity_Two, mCurWeatherSetting.RainOpacity_Three, mCurWeatherSetting.RainOpacity_Four);
            }
        }
    }

    #endregion
}
