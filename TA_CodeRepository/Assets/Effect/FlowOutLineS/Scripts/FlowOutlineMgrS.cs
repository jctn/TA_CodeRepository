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

        public const int MAX_FLOWITEM_COUNT = 8;
        public const int MAX_CHANNEL_COUNT = 4;

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
            }
            else
            {
                if (mFlowOutlineObjsDic.Count >= MAX_FLOWITEM_COUNT) return false;
                mFlowOutlineObjsDic.Add(p, outlineObj);
            }
            return true;
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

        public void GetRenderFlowOutlineObjs(List<FlowOutlineObjS> flowOutlineObjS, Camera cam)
        {
            if (flowOutlineObjS == null || cam == null) return;
            flowOutlineObjS.Clear();

            int count = 0;
            if (cam.cameraType == CameraType.Game)
            {
                foreach (var pair in mFlowOutlineObjsDic)
                {
                    if (count >= MAX_CHANNEL_COUNT) break;
                    if (((1 << pair.Key.gameObject.layer) & cam.cullingMask) != 0)
                    {
                        flowOutlineObjS.Add(pair.Value);
                        count++;
                    }
                }
            }
            else if (cam.cameraType == CameraType.SceneView)
            {
                foreach (var pair in mFlowOutlineObjsDic)
                {
                    if (count >= MAX_CHANNEL_COUNT) break;
                    flowOutlineObjS.Add(pair.Value);
                    count++;
                }
            }
        }

        public int GetSceneIndex(FlowOutlineObjS flowOutlineObj)
        {
            int sceneIndex = 0;
            foreach (var pair in mFlowOutlineObjsDic)
            {
                if (pair.Value == flowOutlineObj)
                {
                    return sceneIndex;
                }
                sceneIndex++;
            }
            if (sceneIndex < mFlowOutlineObjsDic.Count)
            {
                return sceneIndex;
            }
            else
            {
                return 0;
            }
        }
    }
}
