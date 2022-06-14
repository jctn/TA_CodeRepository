using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DynamicSkyOutput : BaseOutput
{
    public DynamicSkyOutput(WeatherSetting cur, TimeCtrl timeCtrl): base(cur, timeCtrl)
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
    public Color TopColor
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Color cur = mCurWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
                Color target = mTargetWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
                return Color.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
            }
        }
    }

    public Color MiddleColor
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Color cur = mCurWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
                Color target = mTargetWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
                return Color.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
            }
        }
    }

    public Color BottomColor
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Color cur = mCurWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
                Color target = mTargetWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
                return Color.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
            }
        }
    }

    public Color SunColor
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Color cur = mCurWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
                Color target = mTargetWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
                return Color.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
            }
        }
    }

    public Color SunGlowColor
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Color cur = mCurWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
                Color target = mTargetWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
                return Color.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
            }
        }
    }

    public float SunGlowRadius
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float cur = mCurWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
                float target = mTargetWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
                return Mathf.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            }
        }
    }

    public float MoonGlowRadius
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float cur = mCurWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
                float target = mTargetWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
                return Mathf.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            }
        }
    }

    public float StarIntensity
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float cur = mCurWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);
                float target = mTargetWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);
                return Mathf.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);
            }
        }
    }

    public Color LightColor
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                Color cur = mCurWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
                Color target = mTargetWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
                return Color.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
            }
        }
    }

    public float LightIntensity
    {
        get
        {
            if (mTargetWeatherSetting != null)
            {
                float cur = mCurWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
                float target = mTargetWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
                return Mathf.Lerp(cur, target, mTranslationProgression);
            }
            else
            {
                return mCurWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
            }
        }
    }
    #endregion
}
