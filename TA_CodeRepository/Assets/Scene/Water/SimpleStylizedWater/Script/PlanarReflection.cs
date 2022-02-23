using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{
    public LayerMask LayersToReflect = -1;
    [Min(1)]
    public int ReflectionTextureDown = 1;
    public bool BlurReflectionTex = true;
    [Range(0f, 15f)]
    public float BlurRadius = 5f;
    [Range(1, 4)]
    public int Iteration = 4;
    [Range(1f, 10f)]
    public float RTDownScaling = 2f;

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
#if UNITY_EDITOR
            DestroyImmediate(mReflectionCamera.gameObject);
#else
            Destroy(mReflectionCamera.gameObject);
#endif
            mReflectionCamera = null;
        }

        if (mDualKawaseBlurMat != null)
        {
#if UNITY_EDITOR
            DestroyImmediate(mDualKawaseBlurMat);
#else
            Destroy(mDualKawaseBlurMat);
#endif
            mDualKawaseBlurMat = null;
        }

    }


    private void RenderPipelineManager_beginCameraRendering(ScriptableRenderContext arg1, Camera arg2)
    {
        if (arg2 == Camera.main)
        {
            RenderReflection(arg1, arg2);
        }
    }

    private RenderTextureDescriptor CreateRenderTextureDescriptor(Camera camera, int w, int h, bool needsAlpha)
    {
        RenderTextureDescriptor desc = new RenderTextureDescriptor(w, h);
        RenderTextureFormat renderTextureFormatDefault = RenderTextureFormat.Default;
        bool use32BitHDR = !needsAlpha && RenderingUtils.SupportsRenderTextureFormat(RenderTextureFormat.RGB111110Float);
        RenderTextureFormat hdrFormat = (use32BitHDR) ? RenderTextureFormat.RGB111110Float : RenderTextureFormat.DefaultHDR;
        desc.colorFormat = camera.allowHDR && UniversalRenderPipeline.asset.supportsHDR ? hdrFormat : renderTextureFormatDefault;
        desc.depthBufferBits = 24;
        int msaaSamples = 1;
        if (camera.allowMSAA && UniversalRenderPipeline.asset.msaaSampleCount > 1)
            msaaSamples = (camera.targetTexture != null) ? camera.targetTexture.antiAliasing : UniversalRenderPipeline.asset.msaaSampleCount;
        desc.msaaSamples = msaaSamples;
        desc.sRGB = (QualitySettings.activeColorSpace == ColorSpace.Linear);

        desc.enableRandomWrite = false;
        desc.bindMS = false;
        desc.useDynamicScale = camera.allowDynamicResolution;
        return desc;
    }

    private RenderTextureDescriptor CreateBlurRenderTextureDescriptor(Camera camera, int w, int h, bool needsAlpha)
    {
        RenderTextureDescriptor desc = new RenderTextureDescriptor(w, h);
        RenderTextureFormat renderTextureFormatDefault = RenderTextureFormat.Default;
        bool use32BitHDR = !needsAlpha && RenderingUtils.SupportsRenderTextureFormat(RenderTextureFormat.RGB111110Float);
        RenderTextureFormat hdrFormat = (use32BitHDR) ? RenderTextureFormat.RGB111110Float : RenderTextureFormat.DefaultHDR;
        desc.colorFormat = camera.allowHDR && UniversalRenderPipeline.asset.supportsHDR ? hdrFormat : renderTextureFormatDefault;
        desc.depthBufferBits = 0;
        desc.msaaSamples = 1;
        desc.sRGB = (QualitySettings.activeColorSpace == ColorSpace.Linear);
        return desc;
    }

    private void RenderReflection(ScriptableRenderContext context, Camera sourceCam)
    {
        if (mReflectionCamera == null)
        {
            GameObject go = new GameObject("Reflection Camera");
            go.transform.SetParent(transform);
            go.hideFlags = HideFlags.DontSave;
            mReflectionCamera = go.AddComponent<Camera>();
            mReflectionCamera.enabled = false;
            mReflectionCamera.cullingMask = ~(1 << 4) & LayersToReflect.value;
            mReflectionCamera.cameraType = CameraType.Reflection;

            UniversalAdditionalCameraData destAdditionalData = mReflectionCamera.GetUniversalAdditionalCameraData();
            if (destAdditionalData != null)
            {
                destAdditionalData.requiresColorOption = CameraOverrideOption.Off;
                destAdditionalData.requiresDepthOption = CameraOverrideOption.Off;
            }
        }

        int w = Mathf.Max(Screen.width / ReflectionTextureDown, 1);
        int h = Mathf.Max(Screen.height / ReflectionTextureDown, 1);
        if (mReflectionRT == null || mReflectionRT.width != w || mReflectionRT.height != h)
        {
            if(mReflectionRT != null)
            {
                RenderTexture.ReleaseTemporary(mReflectionRT);
            }
            mReflectionRT = RenderTexture.GetTemporary(CreateRenderTextureDescriptor(sourceCam, w, h, false));
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
        UpdateCamearaParams(sourceCam, mReflectionCamera);
        var reflectM = CaculateReflectMatrix(transform.up, transform.position);
        mReflectionCamera.worldToCameraMatrix = sourceCam.worldToCameraMatrix * reflectM;
        mReflectionCamera.transform.position = reflectM.MultiplyPoint(sourceCam.transform.position);

        //近裁剪面的斜切.
        //https://blog.csdn.net/puppet_master/article/details/80808486
        //https://zhuanlan.zhihu.com/p/74529106
        float d = Vector3.Dot(transform.up, transform.position);
        Vector4 planeWS = new Vector4(transform.up.x, transform.up.y, transform.up.z, d);//平面
        Vector4 planeVS = mReflectionCamera.worldToCameraMatrix.inverse.transpose * planeWS;
        mReflectionCamera.projectionMatrix = mReflectionCamera.CalculateObliqueMatrix(planeVS);

        //绕序反向，故裁剪反向
        GL.invertCulling = true;
        UniversalRenderPipeline.RenderSingleCamera(context, mReflectionCamera);
        GL.invertCulling = false;
        if(BlurReflectionTex)
        {
            DualKawaseBlur(context, sourceCam);
        }
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
    }

    struct Level
    {
        public int down;
        public int up;
    }

    private const string PROFILER_TAG = "Reflection_DualKawaseBlur";
    private Shader mDualKawaseBlurShader;
    private Material mDualKawaseBlurMat;
    private const int MaxPyramidSize = 16;
    Level[] mPyramid;
    int mID_Offset = Shader.PropertyToID("_Offset");

    //https://github.com/QianMo/X-PostProcessing-Library/blob/master/Assets/X-PostProcessing/Effects/DualKawaseBlur/DualKawaseBlur.cs
    private void DualKawaseBlur(ScriptableRenderContext context, Camera sourceCam)
    {
        DualKawaseBlur_Init();
        DualKawaseBlur_Render(context, sourceCam);
    }

    void DualKawaseBlur_Init()
    {
        if(mDualKawaseBlurShader == null)
        {
            mDualKawaseBlurShader = Shader.Find("Code Repository/Scene/SimpleStylizedWater/Reflection_DualKawaseBlur");
        }
        if (mDualKawaseBlurMat == null && mDualKawaseBlurShader != null)
        {
            mDualKawaseBlurMat = new Material(mDualKawaseBlurShader);
        }

        if(mPyramid == null)
        {
            mPyramid = new Level[MaxPyramidSize];
            for (int i = 0; i < MaxPyramidSize; i++)
            {
                mPyramid[i] = new Level
                {
                    down = Shader.PropertyToID("_Reflection_BlurMipDown" + i),
                    up = Shader.PropertyToID("_Reflection_BlurMipUp" + i)
                };
            }
        }
    }

    void DualKawaseBlur_Render(ScriptableRenderContext context, Camera sourceCam)
    {
        mDualKawaseBlurMat.SetFloat(mID_Offset, BlurRadius);

        CommandBuffer cmd = CommandBufferPool.Get(PROFILER_TAG);
        int w = (int)(mReflectionRT.width / RTDownScaling);
        int h = (int)(mReflectionRT.height / RTDownScaling);

        //downsample
        int lastDown = 0;
        for(int i = 0; i < Iteration; i++)
        {
            RenderTextureDescriptor descriptor = CreateBlurRenderTextureDescriptor(sourceCam, w, h, false);
            int down = mPyramid[i].down;
            int up = mPyramid[i].up;
            cmd.GetTemporaryRT(down, descriptor, FilterMode.Bilinear);
            cmd.GetTemporaryRT(up, descriptor, FilterMode.Bilinear);

            if(i == 0)
            {
                cmd.Blit(mReflectionRT, down, mDualKawaseBlurMat, 0);
            }
            else
            {
                cmd.Blit(lastDown, down, mDualKawaseBlurMat, 0);
            }
            lastDown = down;
            w = Mathf.Max(1, w / 2);
            h = Mathf.Max(1, h / 2);
        }

        //upsample
        int lastup = mPyramid[Iteration - 1].down;
        for (int i = Iteration - 2; i >= 0; i--)
        {
            int up = mPyramid[i].up;
            cmd.Blit(lastup, up, mDualKawaseBlurMat, 1);
            lastup = up;
        }
        cmd.Blit(lastup, mReflectionRT, mDualKawaseBlurMat, 1);

        //CleanUp
        for(int i = 0; i < Iteration; i++)
        {
            cmd.ReleaseTemporaryRT(mPyramid[i].down);
            cmd.ReleaseTemporaryRT(mPyramid[i].up);
        }
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}
