using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

//TODO：rt格式，斜截视锥体，非运行模式相机正确创建，模糊
//[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{
    public int ReflectionTextureDown = 1;

    private Camera mReflectionCamera = null;
    private RenderTexture mReflectionRT = null;
    private Renderer mPlaneRender;
    private int mID_ReflectionTex = Shader.PropertyToID("_ReflectionTex");

    private void OnEnable()
    {
        RenderPipelineManager.beginCameraRendering += RenderPipelineManager_beginCameraRendering;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= RenderPipelineManager_beginCameraRendering;
    }

    private void OnDestroy()
    {
        if (mReflectionRT != null)
        {
            RenderTexture.ReleaseTemporary(mReflectionRT);
            mReflectionRT = null;
        }

        if (mReflectionCamera != null)
        {
            Destroy(mReflectionCamera);
            mReflectionCamera = null;
        }
    }


    private void RenderPipelineManager_beginCameraRendering(ScriptableRenderContext arg1, Camera arg2)
    {
        if (arg2 == Camera.main)
        {
            RenderReflection(arg1, arg2);
        }
    }

    private void RenderReflection(ScriptableRenderContext context, Camera cam)
    {
        if (mReflectionCamera == null)
        {
            GameObject go = new GameObject("Reflection Camera");
            go.transform.SetParent(transform);
            mReflectionCamera = go.AddComponent<Camera>();
            mReflectionCamera.CopyFrom(cam);
            mReflectionCamera.enabled = false;
        }

        int w = Screen.width / ReflectionTextureDown;
        int h = Screen.height / ReflectionTextureDown;
        if (mReflectionRT == null || mReflectionRT.width != w || mReflectionRT.height != h)
        {
            if(mReflectionRT != null)
            {
                RenderTexture.ReleaseTemporary(mReflectionRT);
            }
            mReflectionRT = RenderTexture.GetTemporary(w, h, 24);
            mReflectionRT.name = "ReflectionTexture" + transform.name;
            mReflectionCamera.targetTexture = mReflectionRT;

            if (mPlaneRender == null) mPlaneRender = GetComponent<Renderer>();
            if (mPlaneRender != null)
            {
                MaterialPropertyBlock mpb = new MaterialPropertyBlock();
                mPlaneRender.GetPropertyBlock(mpb);
                mpb.SetTexture(mID_ReflectionTex, mReflectionRT);
                mPlaneRender.SetPropertyBlock(mpb);
            }
        }
        UpdateCamearaParams(cam, mReflectionCamera);
        var reflectM = CaculateReflectMatrix(transform.up, transform.position);
        mReflectionCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflectM;
        mReflectionCamera.transform.position = reflectM.MultiplyPoint(cam.transform.position);
        //绕序反向，故裁剪反向
        GL.invertCulling = true;
        UniversalRenderPipeline.RenderSingleCamera(context, mReflectionCamera);
        GL.invertCulling = false;
    }

    //https://zhuanlan.zhihu.com/p/92633614
    Matrix4x4 CaculateReflectMatrix(Vector3 normal, Vector3 positionOnPlane)
    {
        var d = -Vector3.Dot(normal, positionOnPlane);
        var reflectM = Matrix4x4.identity;

        var x2 = 2 * normal.x * normal.x;
        var y2 = 2 * normal.y * normal.y;
        var z2 = 2 * normal.z * normal.z;
        var xy2 = -2 * normal.x * normal.y;
        var xz2 = -2 * normal.x * normal.z;
        var yz2 = -2 * normal.y * normal.z;

        reflectM.m00 = 1 - x2;
        reflectM.m11 = 1 - y2;
        reflectM.m22 = 1 - z2;

        reflectM.m01 = xy2;
        reflectM.m02 = xz2;
        reflectM.m10 = xy2;
        reflectM.m12 = yz2;
        reflectM.m20 = xz2;
        reflectM.m21 = yz2;

        reflectM.m03 = -2 * d * normal.x;
        reflectM.m13 = -2 * d * normal.y;
        reflectM.m23 = -2 * d * normal.z;
        return reflectM;
    }

    private void UpdateCamearaParams(Camera srcCamera, Camera destCamera)
    {
        if (destCamera == null || srcCamera == null)
            return;

        destCamera.clearFlags = srcCamera.clearFlags;
        destCamera.backgroundColor = srcCamera.backgroundColor;
        destCamera.farClipPlane = srcCamera.farClipPlane;
        destCamera.nearClipPlane = srcCamera.nearClipPlane;
        destCamera.fieldOfView = srcCamera.fieldOfView;
        destCamera.aspect = srcCamera.aspect;
        destCamera.orthographic = srcCamera.orthographic;
        destCamera.orthographicSize = srcCamera.orthographicSize;

        UniversalAdditionalCameraData destAdditionalData = destCamera.GetUniversalAdditionalCameraData();
        if(destAdditionalData != null)
        {
            destAdditionalData.requiresColorOption = CameraOverrideOption.Off;
            destAdditionalData.requiresDepthOption = CameraOverrideOption.Off;
        }
    }
}
