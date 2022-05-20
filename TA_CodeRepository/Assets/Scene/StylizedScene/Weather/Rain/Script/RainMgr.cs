using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

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

    bool mRegisterRenderEvent = false;
    Camera sceneDepthCam;
    RenderTexture sceneDepthTex;
    int sceneDepthTexSize = 512;
    float sceneDepthDistance = 100f;

    public void AddRain(RainCtrl rainCtrl)
    {
        if(!rainCtrls.Contains(rainCtrl))
        {
            rainCtrls.Add(rainCtrl);
            RegisterRenderEvent();
        }
    }

    public void RemoveRain(RainCtrl rainCtrl)
    {
        rainCtrls.Remove(rainCtrl);
        UnRegisterRenderEvent();
    }

    void RegisterRenderEvent()
    {
        if (rainCtrls.Count > 0)
        {
            if (!mRegisterRenderEvent)
            {
                RenderPipelineManager.beginCameraRendering += BeginCameraRendering;
                mRegisterRenderEvent = true;
            }
        }
    }

    void UnRegisterRenderEvent()
    {
        if (rainCtrls.Count <= 0)
        {
            if (mRegisterRenderEvent)
            {
                RenderPipelineManager.beginCameraRendering -= BeginCameraRendering;
                mRegisterRenderEvent = false;
                DisposeCreatedRes();
            }
        }
    }

    void DisposeCreatedRes()
    {
        if (sceneDepthTex != null)
        {
            if (sceneDepthCam != null) sceneDepthCam.targetTexture = null;
            SafeDestory(sceneDepthTex);
            sceneDepthTex = null;
        }
        if (sceneDepthCam != null)
        {
            SafeDestory(sceneDepthCam.gameObject);
            sceneDepthCam = null;
        }
    }

    void SafeDestory(Object obj)
    {
#if UNITY_EDITOR
        Object.DestroyImmediate(obj);
#else
        Object.Destroy(obj);
#endif
    }

    private RenderTextureDescriptor CreateRenderTextureDescriptor(int w, int h)
    {
        RenderTextureDescriptor desc = new RenderTextureDescriptor(w, h, RenderTextureFormat.Depth, 16, 0)
        {
            msaaSamples = 1
        };
        return desc;
    }

    void BeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        if (camera == Camera.main || camera.cameraType == CameraType.SceneView)
        //if (camera == Camera.main)
        {
            if (sceneDepthCam == null)
            {
                GameObject go = new GameObject("SceneDepth Cam");
                go.transform.SetParent(rainCtrls[0].transform, false);
                go.hideFlags = HideFlags.HideAndDontSave;
                sceneDepthCam = go.AddComponent<Camera>();
                sceneDepthCam.enabled = false;
                sceneDepthCam.cameraType = CameraType.Game;
                sceneDepthCam.orthographic = true;
            }

            if (sceneDepthTex == null)
            {
                sceneDepthTex = RenderTexture.GetTemporary(CreateRenderTextureDescriptor(sceneDepthTexSize, sceneDepthTexSize));
                sceneDepthTex.name = "_SceneDepthTex";
                sceneDepthTex.hideFlags = HideFlags.DontSave;
                sceneDepthCam.targetTexture = sceneDepthTex;
                Shader.SetGlobalTexture("_SceneDepthTex", sceneDepthTex);
            }

            UpdateDepthCamera(camera);
            UniversalRenderPipeline.RenderSingleCamera(context, sceneDepthCam);
        }
    }

    void UpdateDepthCamera(Camera camera)
    {
        if (camera == null || sceneDepthCam == null) return;
        sceneDepthCam.cullingMask = camera.cullingMask;
        GetViewFrustumBox(camera, sceneDepthDistance, out Vector3 min, out Vector3 max);
        sceneDepthCam.nearClipPlane = 1f;
        sceneDepthCam.farClipPlane = Mathf.Max(max.y - min.y, 0.1f) + sceneDepthCam.nearClipPlane;
        sceneDepthCam.orthographicSize = 0.5f * Mathf.Max(max.x - min.x, 0.1f) / sceneDepthCam.aspect;

        sceneDepthCam.transform.position = camera.transform.position + camera.transform.forward * sceneDepthCam.orthographicSize +  camera.transform.up * (sceneDepthCam.farClipPlane - sceneDepthCam.nearClipPlane) * 0.5f;
        //sceneDepthCam.transform.rotation = Quaternion.LookRotation(-camera.transform.up);
        sceneDepthCam.transform.rotation = camera.transform.rotation;
        sceneDepthCam.transform.Rotate(camera.transform.right, 90f, Space.World);
    }

    void GetViewFrustumBox(Camera camera, float distance, out Vector3 min, out Vector3 max)
    {
        if (camera == null)
        {
            min = Vector3.one;
            max = Vector3.one;
            return;
        }
        float near = camera.nearClipPlane;
        float fov = Mathf.Deg2Rad * camera.fieldOfView;
        float aspect = camera.aspect;
        Vector3 forward = camera.transform.forward;
        Vector3 right = camera.transform.right;
        Vector3 up = camera.transform.up;

        float halfHeight = near * Mathf.Tan(fov / 2f); //近裁剪面
        float halfWidth = halfHeight * aspect;
        Vector3 toTop = up * halfHeight;
        Vector3 toRight = right * halfWidth;

        Vector3 toTopLeft = forward + toTop - toRight; //近裁剪面
        Vector3 toBottomLeft = forward - toTop - toRight;
        Vector3 toTopRight = forward + toTop + toRight;
        Vector3 toBottomRight = forward - toTop + toRight;

        float f = distance / near;
        Vector3 toTopLeftFar = f * toTopLeft; //相似三角形
        Vector3 toBottomLeftFar = f * toBottomLeft;
        Vector3 toTopRightFar = f * toTopRight;
        Vector3 toBottomRightFar = f * toBottomRight;

        min = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
        max = new Vector3(float.MinValue, float.MinValue, float.MinValue);

        min = Vector3.Min(min, toTopLeftFar);
        min = Vector3.Min(min, toBottomLeftFar);
        min = Vector3.Min(min, toTopRightFar);
        min = Vector3.Min(min, toBottomRightFar);

        max = Vector3.Max(max, toTopLeftFar);
        max = Vector3.Max(max, toBottomLeftFar);
        max = Vector3.Max(max, toTopRightFar);
        max = Vector3.Max(max, toBottomRightFar);
    }
}
