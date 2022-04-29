using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Weather Setting", menuName = "Code Repository/Scene/WeatherSetting")]
public class WeatherSetting : ScriptableObject
{
    [Header("Sky")]
    [ColorUsage(false, true)]
    public Gradient BottomColor;

    [ColorUsage(false, true)]
    public Gradient MiddleColor;

    [ColorUsage(false, true)]
    public Gradient TopColor;

    [ColorUsage(false, true)]
    public Gradient SunColor;

    [ColorUsage(false, true)]
    public Gradient SunGlowColor;

    [ColorUsage(false, true)]
    public Gradient MoonColor;

    [ColorUsage(false, true)]
    public Gradient MoonGlowColor;

    public AnimationCurve StarIntensity = AnimationCurve.Linear(0f, 0f, 24f, 1f);

    [Header("Light")]
    public Gradient LightColor;
    public AnimationCurve LightIntensity = AnimationCurve.Linear(0f, 0f, 24f, 1f);
}
