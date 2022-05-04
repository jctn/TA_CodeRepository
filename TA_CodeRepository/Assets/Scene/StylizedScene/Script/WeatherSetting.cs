using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Weather Setting", menuName = "Code Repository/Scene/WeatherSetting")]
public class WeatherSetting : ScriptableObject
{
    [Header("Sky")]
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient BottomColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient MiddleColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient TopColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunGlowColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient MoonColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient MoonGlowColor;

    [Header("Light")]
    public Gradient LightColor;
    public AnimationCurve LightIntensity = AnimationCurve.Linear(0f, 0f, 24f, 1f);
}
