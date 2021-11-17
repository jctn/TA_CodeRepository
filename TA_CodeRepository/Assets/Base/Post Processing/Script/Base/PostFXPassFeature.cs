using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostFXPassFeature : ScriptableRendererFeature
{
    class PostFXPass : ScriptableRenderPass
    {
        const string CMDSTR = "PostFX";
        RenderTargetHandle mTemporaryColorTexture;
        RenderTargetIdentifier mSource;

        public PostFXPass()
        {
            mTemporaryColorTexture.Init("_TemporaryColorTexture");
        }

        public void Setup(RenderTargetIdentifier source)
        {
            mSource = source;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //if(PostFXManager.Instance.PostFXCount > 0)
            //{
            //    CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
            //    cmd.BeginSample(CMDSTR);
            //    cmd.GetTemporaryRT(mTemporaryColorTexture.id, renderingData.cameraData.cameraTargetDescriptor, FilterMode.Bilinear);
            //    context.ExecuteCommandBuffer(cmd);
            //    cmd.Clear();

            //    PostFXManager.Instance.RenderPostFX(context, cmd, mSource, mTemporaryColorTexture, ref renderingData);

            //    cmd.Blit(mTemporaryColorTexture.Identifier(), mSource);
            //    cmd.EndSample(CMDSTR);
            //    context.ExecuteCommandBuffer(cmd);
            //    cmd.Clear();
            //    CommandBufferPool.Release(cmd);
            //}
            if (PostFXManager.Instance.PostFXCount > 0)
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                cmd.GetTemporaryRT(mTemporaryColorTexture.id, renderingData.cameraData.cameraTargetDescriptor, FilterMode.Bilinear);
                PostFXManager.Instance.RenderPostFX(context, cmd, mSource, mTemporaryColorTexture, ref renderingData);
                cmd.Blit(mTemporaryColorTexture.Identifier(), mSource);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(mTemporaryColorTexture.id);
        }
    }

    PostFXPass mPostFXPass;

    public override void Create()
    {
        mPostFXPass = new PostFXPass();
        mPostFXPass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        mPostFXPass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(mPostFXPass);
    }
}