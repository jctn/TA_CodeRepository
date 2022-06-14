using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Weather Setting", menuName = "Code Repository/Scene/WeatherSetting")]
public class WeatherSetting : ScriptableObject
{
    [Header("Sky Color Setting")]
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient TopColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient MiddleColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient BottomColor;

    [Header("Sun&Moon Setting")]
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunGlowColor;

    public AnimationCurve SunGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    public AnimationCurve MoonGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    public AnimationCurve StarIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    [Header("Light Setting")]
    public Gradient LightColor;
    public AnimationCurve LightIntensity = AnimationCurve.Linear(0f, 0f, 24f, 1f);

    [Header("Rain Setting")]
    public Texture2D RainHeightmap;
    public Texture2D RainShapeTexture;
    public Texture2D RainSplashTex;

    [Space]
    [Range(0f, 1f)]
    public float RainIntensity = 1f;
    [Range(0f, 1f)]
    public float RainOpacityInAll = 1f;
    public Color RainColor = Color.white;
    [Header("Raindrop Layer One")]
    public Vector2 RainScale_One = Vector2.one;
    public float RotateSpeed_One = 1f;
    public float RotateAmount_One = 0.5f;
    public float DropSpeed_One = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_One = 1f;

    [Header("Raindrop Layer Two")]
    public Vector2 RainScale_Two = Vector2.one * 1.5f;
    public float RotateSpeed_Two = 1f;
    public float RotateAmount_Two = 0.5f;
    public float DropSpeed_Two = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_Two = 1f;

    [Header("Raindrop Layer Three")]
    public Vector2 RainScale_Three = Vector2.one * 1.7f;
    public float RotateSpeed_Three = 1f;
    public float RotateAmount_Three = 0.5f;
    public float DropSpeed_Three = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_Three = 1f;

    [Header("Raindrop Layer Four")]
    public Vector2 RainScale_Four = Vector2.one * 2f;
    public float RotateSpeed_Four = 1f;
    public float RotateAmount_Four = 0.5f;
    public float DropSpeed_Four = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_Four = 1f;

    [Header("RainSplash")]
    public bool EnableRainSplash = true;
    public int SplashCount = 50;
    public float SplashPlayTime = 0.2f;
    public float SplashIntervalMin = 0.3f;
    public float SplashIntervalMax = 0.5f;
    public float SplashScaleMin = 0.5f;
    public float SplashScaleMax = 1f;
    public float SplashOpacityMin = 0.5f;
    public float SplashOpacityMax = 1f;
}
