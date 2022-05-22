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
                matrix.SetTRS(curCam.transform.position, Quaternion.Euler(90f, 0f, 0f), Vector3.one * 2f);
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
        const string CMDSTR = "Rain";
        RenderTargetHandle mTemporaryColorTexture;
        RenderTargetIdentifier mSource;

        public RainMergePass()
        {
            mTemporaryColorTexture.Init("_RainTemporaryColorTexture");
        }

        public void Setup(RenderTargetIdentifier source)
        {
            mSource = source;
        }

        RenderTextureDescriptor GetDescriptor(RenderTextureDescriptor descriptor, int width, int height)
        {
            RenderTextureDescriptor desc = descriptor;
            desc.msaaSamples = 1;
            desc.depthBufferBits = 0;
            desc.width = width;
            desc.height = height;
            return desc;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                if (RainCtrl.Instance == null || RainCtrl.Instance.RainMaterial == null) return;
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                RenderTextureDescriptor camDesc = renderingData.cameraData.cameraTargetDescriptor;
                RenderTextureDescriptor desc = GetDescriptor(camDesc, camDesc.width, camDesc.height);
                cmd.GetTemporaryRT(mTemporaryColorTexture.id, desc, FilterMode.Bilinear);
                cmd.Blit(mSource, mTemporaryColorTexture.Identifier(), RainCtrl.Instance.RainMaterial, 0); //有load操作，后续优化
                cmd.Blit(mTemporaryColorTexture.Identifier(), mSource);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch(System.Exception e)
            {
                Debug.LogError("RainMerge feature is error" + e);
            }
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(mTemporaryColorTexture.id);
        }
    }

    public Mesh RainPostProcessingMesh;
    RainMaskPass rainMaskPass;
    RainMergePass mRainMergePass;
    const string rainSceneDepthRenderStr = "RainSceneDepthRender";

    public override void Create()
    {
        rainMaskPass = new RainMaskPass();
        rainMaskPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        mRainMergePass = new RainMergePass();
        mRainMergePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
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
            //mRainMergePass.Setup(renderer.cameraColorTarget);
            //renderer.EnqueuePass(mRainMergePass);
        }
    }
}
