using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[Serializable]
public class HitStatusShowData : StatusShowBaseData
{
    [Header("总的持续时间")]
    public float Duration = 2f;
    [Header("间隔，只取横轴0-1范围")]
    public AnimationCurve HitInterval = new AnimationCurve(new Keyframe(0f, 0.15f), new Keyframe(1f, 0.15f));
    [Header("单次持续时间，只取横轴0-1范围")]
    public AnimationCurve OnceDuration = new AnimationCurve(new Keyframe(0f, 0.05f), new Keyframe(1f, 0.05f));
    [GradientUsage(true)]
    public Gradient HitBaseCol = new Gradient();
    [GradientUsage(true)]
    public Gradient HitRimCol = new Gradient();
    [Range(0f, 1f)]
    public float HitRimThreshod = 0.5f;
    [Range(0f, 1f)]
    public float HitRimSmooth = 0f;

    public override BaseStatusShow CreateInstance()
    {
        BaseStatusShow mBaseStatusShow = new HitStatusShow
        {
            MStatusShowBaseData = this
        };
        return mBaseStatusShow;
    }
}
