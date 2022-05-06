using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(TimeCtrl))]
[ExecuteAlways]
public class WeatherCtrl : MonoBehaviour
{
    public EWeatherType InitWeather;
    public float TranslationTime = 2f;
    public Weather [] Weathers;

    DynamicSkyOutput mDynamicSkyOutput = null;

    public DynamicSkyOutput DynamicSkyOutputData
    {
        get { return mDynamicSkyOutput; }
    }

    private void OnValidate()
    {
        Awake();
    }

    private void Awake()
    {
        TimeCtrl timeCtrl = GetComponent<TimeCtrl>();

        for (int i = 0; i < Weathers.Length; i++)
        {
            if (Weathers[i].WeatherType == InitWeather)
            {
                mDynamicSkyOutput = new DynamicSkyOutput(Weathers[i].WeatherSettingData, timeCtrl);
                break;
            }
        }
    }

    private void Update()
    {
        mDynamicSkyOutput?.UpdateData();
    }

    public void SetWeather(EWeatherType weatherType)
    {
        for(int i = 0; i < Weathers.Length; i++)
        {
            if(Weathers[i].WeatherType == weatherType)
            {
                mDynamicSkyOutput?.SetTranslation(Weathers[i].WeatherSettingData, Time.time, TranslationTime);
                break;
            }
        }
    }

    public void SetWeather(EWeatherType weatherType, float duration)
    {
        for (int i = 0; i < Weathers.Length; i++)
        {
            if (Weathers[i].WeatherType == weatherType)
            {
                mDynamicSkyOutput?.SetTranslation(Weathers[i].WeatherSettingData, Time.time, duration);
                break;
            }
        }
    }
}
