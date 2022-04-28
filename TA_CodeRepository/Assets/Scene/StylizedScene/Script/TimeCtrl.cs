using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class TimeCtrl : MonoBehaviour
{
    [Range(0f, 24f)]
    public float TimeLine = 6f;
    public float DayCycleInMinutes = 30f;
    public bool SetTimeByCurve = false;
    public AnimationCurve TimeofDayCurve = AnimationCurve.Linear(0.0f, 0.0f, 24.0f, 24.0f);
    
    float mTimeProgression;
    float mCurveTime;
    float mGradientTime;
    float mTimeofDay = 6f;

    public float GetCurveTime
    {
        get { return mCurveTime; }
    }

    public float GetGradientTime
    {
        get { return mGradientTime; }
    }

    public float GetTimeOfDay
    {
        get { return mTimeofDay; }
    }

    private void Start()
    {
        if(DayCycleInMinutes > 0)
        {
            mTimeProgression = 24f / 60f / DayCycleInMinutes;
        }
        else
        {
            mTimeProgression = 0;
        }
    }

    private void Update()
    {
        if(Application.isPlaying)
        {
            TimeLine += Time.deltaTime * mTimeProgression;
            if(TimeLine >= 24f)
            {
                TimeLine %= 24f;
            }
        }
        
        if(SetTimeByCurve)
        {
            mTimeofDay = TimeofDayCurve.Evaluate(TimeLine);
        }
        else
        {
            mTimeofDay = TimeLine;
        }
        mCurveTime = mTimeofDay;
        mGradientTime = mTimeofDay / 24f;
    }
}
