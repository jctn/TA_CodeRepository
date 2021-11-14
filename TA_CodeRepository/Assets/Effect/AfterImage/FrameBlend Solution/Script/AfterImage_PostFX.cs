using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class AfterImage_PostFX : PostFXBase
{
    [Range(0.0f, 0.5f)]
    [Header("残影消散速度")]
    public float AfterImageRemoveSpeed = 0.1f;
    [Range(0, 2)]
    [Header("残影亮度")]
    public float AfterImageIntensity = 1f;
    [Range(1, 30)]
    [Header("残影帧间隔")]
    public int AfterImageInterval = 2;
    [Range(0, 10)]
    [Header("模糊半径")]
    public float BlurRadius = 0.5f;
    public GameObject Player;

    private int mMaskDownSample = 1;
    private Renderer[] meshRenderers;
    private RenderTexture mAfterImageRt;
    private RenderTexture mMaskRt;
    private Material mAfterImageMat;
    private int mFrameCount;

    private int mID_IsWriteAfterImage;
    private int mID_MaskTex;
    private int mID_AfterImageRemoveSpeed;
    private int mID_AfterImageRT;
    private int mID_AfterImageIntensity;
    private int mID_BlurRadius;

    private void Start()
    {
        Init();
    }

    private void OnDestroy()
    {
        if(mAfterImageRt != null)
        {
            RenderTexture.ReleaseTemporary(mAfterImageRt);
            mAfterImageRt = null;
        }

        if(mMaskRt != null)
        {
            RenderTexture.ReleaseTemporary(mMaskRt);
            mMaskRt = null;
        }

        if(mAfterImageMat != null)
        {
            DestroyImmediate(mAfterImageMat);
            mAfterImageMat = null;
        }
    }

    private void Init()
    {
        if (meshRenderers == null && Player != null)
        {
            meshRenderers = Player.GetComponentsInChildren<Renderer>();
        }

        if (mAfterImageRt == null)
        {
            mAfterImageRt = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBHalf);
        }

        if (mMaskRt == null)
        {
            mMaskRt = RenderTexture.GetTemporary(Screen.width >> mMaskDownSample, Screen.height >> mMaskDownSample, 0, RenderTextureFormat.R8);
        }

        if (mAfterImageMat == null)
        {
            Shader afterImageShader = Shader.Find("Hidden/AfterImage");
            if (afterImageShader != null)
            {
                mAfterImageMat = new Material(afterImageShader);
                mID_IsWriteAfterImage = Shader.PropertyToID("_IsWriteAfterImage");
                mID_MaskTex = Shader.PropertyToID("_MaskTex");
                mID_AfterImageRemoveSpeed = Shader.PropertyToID("_AfterImageRemoveSpeed");
                mID_AfterImageRT = Shader.PropertyToID("_AfterImageRT");
                mID_AfterImageIntensity = Shader.PropertyToID("_AfterImageIntensity");
                mID_BlurRadius = Shader.PropertyToID("_BlurRadius");
            }
        }
    }

    public override void Render(ScriptableRenderContext context, CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetHandle dest, ref RenderingData renderingData)
    {
        cmd = CommandBufferPool.Get("AfterImage");
        if (renderingData.cameraData.camera.cameraType == CameraType.Game && mAfterImageMat != null && mAfterImageRt != null)
        {
            //当前帧人物遮罩
            cmd.SetRenderTarget(mMaskRt, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            cmd.ClearRenderTarget(true, true, Color.clear);
            if (meshRenderers != null && mAfterImageMat != null)
            {
                for (int i = 0; i < meshRenderers.Length; i++)
                {
                    cmd.DrawRenderer(meshRenderers[i], mAfterImageMat, 0, 0);
                }
            }

            mFrameCount++;
            if (mFrameCount >= AfterImageInterval)
            {
                mFrameCount -= AfterImageInterval;
                mAfterImageMat.SetFloat(mID_IsWriteAfterImage, 1f);
            }
            else
            {
                mAfterImageMat.SetFloat(mID_IsWriteAfterImage, 0f);
            }

            //扣取当前帧人物
            mAfterImageMat.SetTexture(mID_MaskTex, mMaskRt);
            mAfterImageMat.SetFloat(mID_AfterImageRemoveSpeed, AfterImageRemoveSpeed);
            cmd.Blit(source, mAfterImageRt, mAfterImageMat, 1);

            //当前帧和残影叠加
            mAfterImageMat.SetTexture(mID_AfterImageRT, mAfterImageRt);
            mAfterImageMat.SetFloat(mID_AfterImageIntensity, AfterImageIntensity);
            mAfterImageMat.SetFloat(mID_BlurRadius, BlurRadius);
            cmd.Blit(source, dest.Identifier(), mAfterImageMat, 2);
        }
        else
        {
            cmd.Blit(source, dest.Identifier());
        }
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}
