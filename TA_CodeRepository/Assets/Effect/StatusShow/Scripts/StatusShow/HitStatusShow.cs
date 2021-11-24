using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HitStatusShow : BaseStatusShow
{
    static int mID_HitOn = Shader.PropertyToID("_HitOn");
    static int mID_HitBaseCol = Shader.PropertyToID("_HitBaseCol");
    static int mID_HitRimCol = Shader.PropertyToID("_HitRimCol");
    static int mID_HitRimThreshod = Shader.PropertyToID("_HitRimThreshod");
    static int mID_HitRimSmooth = Shader.PropertyToID("_HitRimSmooth");

    MaterialPropertyBlock mMPB;
    HitStatusShowData data;
    float activeTime;

    public override void StatusEnter()
    {
        data = MStatusShowBaseData as HitStatusShowData;
        if (data == null) return;

        if(mMPB == null)
        {
            mMPB = new MaterialPropertyBlock();
        }
        mMPB.SetFloat(mID_HitOn, 1f);
        mMPB.SetColor(mID_HitBaseCol, data.HitBaseCol.Evaluate(0f));
        mMPB.SetColor(mID_HitRimCol, data.HitRimCol.Evaluate(0f));
        mMPB.SetFloat(mID_HitRimSmooth, data.HitRimSmooth);
        mMPB.SetFloat(mID_HitRimThreshod, data.HitRimThreshod);
        SetMPB(mMPB);

        activeTime = Time.time;
    }

    public override void StatusUpdate()
    {
        if(mMPB != null && data != null)
        {
            float duration = data.Duration;
            float curDuration = Time.time - activeTime;
            if (curDuration > duration)
            {
                mMPB.SetFloat(mID_HitOn, 0f);
                SetMPB(mMPB);
                return;
            }

            float rate = curDuration / duration;
            float interval = data.HitInterval.Evaluate(rate);
            float onceDuartion = data.OnceDuration.Evaluate(rate);
            float onceTime = curDuration % (interval + onceDuartion);
            if(onceTime <= onceDuartion)
            {
                mMPB.SetFloat(mID_HitOn, 1f);
                mMPB.SetColor(mID_HitBaseCol, data.HitBaseCol.Evaluate(onceTime % onceDuartion));
                mMPB.SetColor(mID_HitRimCol, data.HitRimCol.Evaluate(onceTime % onceDuartion));
            }
            else
            {
                mMPB.SetFloat(mID_HitOn, 0f);
            }
            SetMPB(mMPB);
        }
    }
}
