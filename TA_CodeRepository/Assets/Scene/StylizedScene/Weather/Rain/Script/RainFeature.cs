using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RainFeature : ScriptableRendererFeature
{
    class RainMaskPass : ScriptableRenderPass
    {
        const string CMDSTR = "RainMask";
        RenderTargetHandle rainMaskTexture;
        Mesh postProcessingMesh;

        public RainMaskPass()
        {
            rainMaskTexture.Init("_RainMaskTexture");
        }

        public void Setup(Mesh ppMesh)
        {
            postProcessingMesh = ppMesh;
        }

        RenderTextureDescriptor GetDescriptor(int width, int height)
        {
            RenderTextureDescriptor desc = new RenderTextureDescriptor(width, height);
            desc.msaaSamples = 1;
            desc.depthBufferBits = 0;
            desc.colorFormat = RenderTextureFormat.ARGB32;
            desc.useMipMap = false;
            desc.sRGB = false;
            return desc;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            RenderTextureDescriptor desc = GetDescriptor(256, 256);
            cmd.GetTemporaryRT(rainMaskTexture.id, desc, FilterMode.Bilinear);
            ConfigureClear(ClearFlag.All, Color.clear);
            ConfigureTarget(rainMaskTexture.id);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                if (postProcessingMesh == null || RainCtrl.Instance == null || RainCtrl.Instance.RainMaterial == null) return;
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                Matrix4x4 matrix = Matrix4x4.identity;
                Camera curCam = renderingData.cameraData.camera;
                matrix.SetTRS(curCam.transform.position, Quaternion.Euler(90f, 0f, 0f), Vector3.one * 100f);
                cmd.DrawMesh(postProcessingMesh, matrix, RainCtrl.Instance.RainMaterial, 0, 0);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch (System.Exception e)
            {
                Debug.LogError("RainMask feature is error" + e);
            }
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(rainMaskTexture.id);
        }
    }

    class RainMergePass : ScriptableRenderPass
    {
        const string CMDSTR = "Rain Merge";
        Mesh postProcessingMesh;

        public void Setup(Mesh ppMesh)
        {
            postProcessingMesh = ppMesh;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                if (postProcessingMesh == null || RainCtrl.Instance == null || RainCtrl.Instance.RainMaterial == null) return;
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                Matrix4x4 matrix = Matrix4x4.identity;
                Camera curCam = renderingData.cameraData.camera;
                matrix.SetTRS(curCam.transform.position, Quaternion.Euler(90f, 0f, 0f), Vector3.one * 100f);
                cmd.DrawMesh(postProcessingMesh, matrix, RainCtrl.Instance.RainMaterial, 0, 1);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch(System.Exception e)
            {
                Debug.LogError("RainMerge feature is error" + e);
            }
        }
    }

    public Mesh RainPostProcessingMesh;
    RainMaskPass rainMaskPass;
    RainMergePass mRainMergePass;
    const string rainSceneDepthRenderStr = "RainSceneDepthRender";

    public override void Create()
    {
        rainMaskPass = new RainMaskPass
        {
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents
        };
        mRainMergePass = new RainMergePass
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
        };
#if UNITY_EDITOR
        RainSceneDepthRenderData rainSceneDepthRender = PipelineUtilities.GetRenderer<RainSceneDepthRenderData>(rainSceneDepthRenderStr, nameof(RainSceneDepthRenderData));
        PipelineUtilities.ValidatePipelineRenderers(rainSceneDepthRender);
#endif
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (RainPostProcessingMesh == null || RainCtrl.Instance == null || !RainCtrl.Instance.enabled) return;
        bool mainGameCam = renderingData.cameraData.camera.cameraType == CameraType.Game && renderingData.cameraData.camera == Camera.main;
        if (mainGameCam || renderingData.cameraData.camera.cameraType == CameraType.SceneView)
        {
            rainMaskPass.Setup(RainPostProcessingMesh);
            renderer.EnqueuePass(rainMaskPass);
            mRainMergePass.Setup(RainPostProcessingMesh);
            renderer.EnqueuePass(mRainMergePass);
        }
    }
}
