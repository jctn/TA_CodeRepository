using System.Collections;
using System.Collections.Generic;
using UnityEngine;

abstract public class BaseOutput
{
    protected WeatherSetting mCurWeatherSetting;
    protected WeatherSetting mTargetWeatherSetting;
    protected TimeCtrl mTimeCtrlCom;
    protected float mTranslationProgression;

    protected BaseOutput(WeatherSetting cur, TimeCtrl timeCtrl)
    {
        mCurWeatherSetting = cur;
        mTimeCtrlCom = timeCtrl;
    }

    public void SetTranslation(WeatherSetting targetWeatherSetting)
    {
        mTargetWeatherSetting = targetWeatherSetting;
        mTranslationProgression = 0f;
    }

    public void OutputTranslation(float translationProgression)
    {
        mTranslationProgression = translationProgression;
        if(mTranslationProgression >= 1f)
        {
            mCurWeatherSetting = mTargetWeatherSetting;
            mTargetWeatherSetting = null;
        }
    }

    abstract public void UpdateOutput();
}
