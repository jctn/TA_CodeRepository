using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIWeatherSet : MonoBehaviour
{
    public Text CurWeather;
    public Dropdown ChooseWeather;
    public WeatherCtrl WeatherCtrlCom;

    EWeatherType curWeather = EWeatherType.Sunny;

    void Start()
    {
        if (WeatherCtrlCom != null) curWeather = WeatherCtrlCom.CurWeather;
        SetCurWeather();

        if (ChooseWeather != null)
        {
            ChooseWeather.onValueChanged.AddListener((type) =>
            {
                if(WeatherCtrlCom != null)
                {
                    WeatherCtrlCom.SetWeather((EWeatherType)type);
                }
            });
        }
    }

    void Update()
    {
        if (WeatherCtrlCom != null && curWeather != WeatherCtrlCom.CurWeather)
        {
            SetCurWeather();
        }
    }

    void SetCurWeather()
    {
        if (CurWeather != null) CurWeather.text = curWeather.ToString();
    }
}
