using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeatherOutput
{
    bool isTranslation = false;
    float mTranslationInitTime;
    float mTranslationDurationTime;

    DynamicSkyOutput dynamicSkyOutput = null;
    RainOutput rainOutput = null;

    public DynamicSkyOutput DynamicSkyOutputData
    {
        get { return dynamicSkyOutput; }
    }

    public RainOutput RainOutputData
    {
        get { return rainOutput; }
    }

    public WeatherOutput(WeatherSetting cur, TimeCtrl timeCtrl)
    {
        dynamicSkyOutput = new DynamicSkyOutput(cur, timeCtrl);
        rainOutput = new RainOutput(cur, timeCtrl);
    }

    public void SetTranslation(WeatherSetting targetWeatherSetting, float translationInitTime, float translationDurationTime)
    {
        isTranslation = true;
        mTranslationInitTime = translationInitTime;
        mTranslationDurationTime = translationDurationTime;

        dynamicSkyOutput.SetTranslation(targetWeatherSetting);
        rainOutput.SetTranslation(targetWeatherSetting);
    }

    public void OutputTranslation()
    {
        if (isTranslation)
        {
            float translationProgression = mTranslationDurationTime > 0f ? Mathf.Clamp01((Time.time - mTranslationInitTime) / mTranslationDurationTime) : 1f;
            dynamicSkyOutput.OutputTranslation(translationProgression);
            rainOutput.OutputTranslation(translationProgression);

            if (translationProgression >= 1f)
            {
                isTranslation = false;
            }
        }
    }

    public void UpdateOutput()
    {
        dynamicSkyOutput.UpdateOutput();
        rainOutput.UpdateOutput();
    }
}
