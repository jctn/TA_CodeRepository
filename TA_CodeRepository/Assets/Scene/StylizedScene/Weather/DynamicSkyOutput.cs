using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DynamicSkyOutput : BaseOutput
{
    public DynamicSkyOutput(WeatherSetting cur, TimeCtrl timeCtrl): base(cur, timeCtrl) { }

    #region Output
    public Color TopColor;
    public Color MiddleColor;
    public Color BottomColor;
    public Color SunColor;
    public Color SunGlowColor;
    public float SunGlowRadius;
    public float MoonGlowRadius;
    public float StarIntensity;
    public Color LightColor;
    public float LightIntensity;
    #endregion

    public override void UpdateOutput()
    {
        if (mTargetWeatherSetting != null)
        {
            Color cur = mCurWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
            Color target = mTargetWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
            TopColor = Color.Lerp(cur, target, mTranslationProgression);

            cur = mCurWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
            target = mTargetWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
            MiddleColor = Color.Lerp(cur, target, mTranslationProgression);

            cur = mCurWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
            target = mTargetWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
            BottomColor = Color.Lerp(cur, target, mTranslationProgression);

            cur = mCurWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
            target = mTargetWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
            SunColor = Color.Lerp(cur, target, mTranslationProgression);

            cur = mCurWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
            target = mTargetWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
            SunGlowColor= Color.Lerp(cur, target, mTranslationProgression);

            float cur_f = mCurWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            float target_f = mTargetWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            SunGlowRadius = Mathf.Lerp(cur_f, target_f, mTranslationProgression);

            cur_f = mCurWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            target_f = mTargetWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            MoonGlowRadius = Mathf.Lerp(cur_f, target_f, mTranslationProgression);

            cur_f = mCurWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);
            target_f = mTargetWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);
            StarIntensity = Mathf.Lerp(cur_f, target_f, mTranslationProgression);

            cur = mCurWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
            target = mTargetWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
            LightColor = Color.Lerp(cur, target, mTranslationProgression);

            cur_f = mCurWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
            target_f = mTargetWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
            LightIntensity = Mathf.Lerp(cur_f, target_f, mTranslationProgression);
        }
        else
        {
            TopColor = mCurWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
            MiddleColor = mCurWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
            BottomColor = mCurWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
            SunColor = mCurWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
            SunGlowColor = mCurWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
            SunGlowRadius = mCurWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            MoonGlowRadius = mCurWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
            StarIntensity = mCurWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);
            LightColor = mCurWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
            LightIntensity = mCurWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        }
    }
}
