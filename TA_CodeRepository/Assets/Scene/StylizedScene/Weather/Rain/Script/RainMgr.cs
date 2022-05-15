using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RainMgr
{
    static RainMgr mInstance;
    public static RainMgr Instance
    {
        get 
        { 
            if(mInstance == null)
            {
                mInstance = new RainMgr();
            }
            return mInstance; 
        }
    }

    List<RainCtrl> rainCtrls = new List<RainCtrl>();

    public List<RainCtrl> RainCtrls
    {
        get { return rainCtrls; }
    }

    public void AddRain(RainCtrl rainCtrl)
    {
        if(!rainCtrls.Contains(rainCtrl))
        {
            rainCtrls.Add(rainCtrl);
        }
    }

    public void RemoveRain(RainCtrl rainCtrl)
    {
        rainCtrls.Remove(rainCtrl);
    }
}
