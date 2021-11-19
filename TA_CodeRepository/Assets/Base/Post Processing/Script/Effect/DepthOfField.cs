using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class DepthOfField : PostFXBase
{
    public float FocusDistance = 5f;
    public float Dof = 4f;
    public float SmoothRange = 0.5f;

    [Min(0)]
    public float BlurRange = 3f;
    [Min(0)]
    public int Iteration = 2;
    [Min(1)]
    public int DownSample = 2;

    RenderTargetHandle RT1;
    RenderTargetHandle RT2;
    Material mDofMat;

    int mID_BlurRange = Shader.PropertyToID("_BlurRange");

    private void Start()
    {
        RT1.Init("_DofRt1");
        RT2.Init("_DofRt2");
        Shader dofShader = Shader.Find("Code Repository/Post Processing/DepthOfField");
        if(dofShader != null)
        {
            mDofMat = new Material(dofShader);
        }
    }

    public override void Render(ScriptableRenderContext context, CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetHandle dest, ref RenderingData renderingData)
    {
        if(mDofMat != null)
        {
            mDofMat.SetFloat(mID_BlurRange, BlurRange);

            cmd.BeginSample("Dof");
            int w = Mathf.Max(1, renderingData.cameraData.cameraTargetDescriptor.width / DownSample);
            int h = Mathf.Max(1, renderingData.cameraData.cameraTargetDescriptor.height / DownSample);
            RenderTextureDescriptor desc = GetDescriptor(renderingData.cameraData.cameraTargetDescriptor, w, h);
            cmd.GetTemporaryRT(RT1.id, desc, FilterMode.Bilinear);
            cmd.Blit(source, RT1.id);

            cmd.BeginSample("Blur");
            //模糊降分辨率
            for (int i = 0; i < Iteration; i++)
            {
                desc.width = Mathf.Max(1, desc.width / 2);
                desc.height = Mathf.Max(1, desc.height / 2);
                cmd.GetTemporaryRT(RT2.id, desc, FilterMode.Bilinear);
                cmd.Blit(RT1.id, RT2.id, mDofMat, 0);

                cmd.ReleaseTemporaryRT(RT1.id);
                desc.width = Mathf.Max(1, desc.width / 2);
                desc.height = Mathf.Max(1, desc.height / 2);
                cmd.GetTemporaryRT(RT1.id, desc, FilterMode.Bilinear);
                cmd.Blit(RT2.id, RT1.id, mDofMat, 0);
                cmd.ReleaseTemporaryRT(RT2.id);
            }
            //模糊升分辨率
            for (int i = 0; i < Iteration; i++)
            {
                desc.width *= 2;
                desc.height *= 2;
                cmd.GetTemporaryRT(RT2.id, desc, FilterMode.Bilinear);
                cmd.Blit(RT1.id, RT2.id, mDofMat, 0);

                cmd.ReleaseTemporaryRT(RT1.id);
                desc.width *= 2;
                desc.height *= 2;
                cmd.GetTemporaryRT(RT1.id, desc, FilterMode.Bilinear);
                cmd.Blit(RT2.id, RT1.id, mDofMat, 0);
                cmd.ReleaseTemporaryRT(RT2.id);
            }
            cmd.EndSample("Blur");

            cmd.BeginSample("Merge");
            cmd.Blit(source, dest.id);
            cmd.ReleaseTemporaryRT(RT1.id);
            cmd.EndSample("Merge");

            cmd.EndSample("Dof");
        }
        else
        {
            cmd.Blit(source, dest.id);
        }
    }
}
