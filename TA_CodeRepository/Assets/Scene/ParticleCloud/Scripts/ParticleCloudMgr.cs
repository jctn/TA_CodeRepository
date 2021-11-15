using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleCloudMgr 
{
    static ParticleCloudMgr _instance;
    public static ParticleCloudMgr Instance
    {
        get
        {
            if(_instance == null)
            {
                _instance = new ParticleCloudMgr();
            }
            return _instance;
        }
    }

    List<ParticleCloud> mParicleClouds = new List<ParticleCloud>();

    public List<ParticleCloud> ParicleClouds
    {
        get
        {
            return mParicleClouds;
        }
    }

    public void AddParticleCloud(ParticleCloud paricleCloud)
    {
        if(!mParicleClouds.Contains(paricleCloud))
        {
            mParicleClouds.Add(paricleCloud);
        }
    }

    public void RemoveParticleCloud(ParticleCloud paricleCloud)
    {
        mParicleClouds.Remove(paricleCloud);
    }
}
