using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BaseOutput
{
    protected WeatherSetting mCurWeatherSetting;
    protected WeatherSetting mTargetWeatherSetting;
    protected float mTranslationInitTime;
    protected float mTranslationDurationTime;
    protected TimeCtrl mTimeCtrlCom;
    protected float mTranslationProgression;

    public BaseOutput(WeatherSetting cur, TimeCtrl timeCtrl)
    {
        mCurWeatherSetting = cur;
        mTimeCtrlCom = timeCtrl;
    }

    virtual public void  SetTranslation(WeatherSetting targetWeatherSetting, float translationInitTime, float translationDurationTime)
    {
        mTargetWeatherSetting = targetWeatherSetting;
        mTranslationInitTime = translationInitTime;
        mTranslationDurationTime = translationDurationTime;
    }

    virtual public void UpdateData()
    {
        if (mTargetWeatherSetting != null)
        {
            mTranslationProgression = mTranslationDurationTime > 0f ? Mathf.Clamp01((Time.time - mTranslationInitTime) / mTranslationDurationTime) : 1f;
            if (mTranslationProgression >= 1f)
            {
                mCurWeatherSetting = mTargetWeatherSetting;
                mTargetWeatherSetting = null;
            }
        }
    }
}
