using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace FlowOutline
{
    public class FlowOutlineMgrS
    {
        static FlowOutlineMgrS instance;
        public static FlowOutlineMgrS Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new FlowOutlineMgrS();
                }
                return instance;
            }
        }

        private Dictionary<Transform, FlowOutlineObjS> mFlowOutlineObjsDic = new Dictionary<Transform, FlowOutlineObjS>();
        public Dictionary<Transform, FlowOutlineObjS>.ValueCollection FlowOutlineObjs
        {
            get
            {
                return mFlowOutlineObjsDic.Values;
            }
        }

        public bool NeedPassRender
        {
            get
            {
                return FlowOutlineObjs != null && FlowOutlineObjs.Count > 0;
            }
        }
        public int BlurDownSample = 3;

        private const int MAX_ROLE_COUNT = 4;

        public bool RegisterFlowOutlineObj(FlowOutlineObjS outlineObj, Transform p)
        {
            if (outlineObj == null || p == null) return false;
            if (mFlowOutlineObjsDic.TryGetValue(p, out FlowOutlineObjS obj))
            {
                if (obj != outlineObj) //重复
                {
                    CoreUtils.Destroy(obj);
                    mFlowOutlineObjsDic.Add(p, outlineObj);
                }
                return true;
            }
            else if (mFlowOutlineObjsDic.Count < MAX_ROLE_COUNT)
            {
                mFlowOutlineObjsDic.Add(p, outlineObj);
                return true;
            }
            return false;
        }

        public void UnRegisterFlowOutlineObj(FlowOutlineObjS outlineObj)
        {
            foreach (var pair in mFlowOutlineObjsDic)
            {
                if (pair.Value == outlineObj)
                {
                    mFlowOutlineObjsDic.Remove(pair.Key);
                    break;
                }
            }
        }

        public int GetFlowOutlineIndex(FlowOutlineObjS flowOutline)
        {
            int i = 0;
            foreach(var f in FlowOutlineObjs)
            {
                if(flowOutline == f)
                {
                    break;
                }
                i++;
            }
            if (i < FlowOutlineObjs.Count)
            {
                return i;
            }
            else
            {
                return -1;
            }
        }
    }
}
