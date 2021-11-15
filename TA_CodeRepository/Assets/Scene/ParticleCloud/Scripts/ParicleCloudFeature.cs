using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ParicleCloudFeature : ScriptableRendererFeature
{
    class ParicleCloudLightMatCapPass : ScriptableRenderPass
    {
        Setting mSetting;
        Camera mCamera;
        RenderTargetHandle mRenderTargetHandle;
        Matrix4x4 mMatrixM;
        Matrix4x4 mMatrixP;
        Matrix4x4 mMatrixMVP;

        int mID_MVPMatrix = Shader.PropertyToID("_MVPMatrix");
        int mID_MMatrix = Shader.PropertyToID("_MMatrix");

        public ParicleCloudLightMatCapPass()
        {
            mRenderTargetHandle.Init("_LightMatCap");
            mMatrixM = Matrix4x4.identity;
            mMatrixP = GL.GetGPUProjectionMatrix(Matrix4x4.Ortho(-0.495f, 0.495f, -0.495f, 0.495f, -1f, 0f), true);
        }

        public void Setup(Setting setting, Camera cam)
        {
            mSetting = setting;
            mCamera = cam;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            cmd.GetTemporaryRT(mRenderTargetHandle.id, 128, 128, 16, FilterMode.Bilinear);
            ConfigureTarget(mRenderTargetHandle.Identifier(), mRenderTargetHandle.Identifier());
            ConfigureClear(ClearFlag.All, Color.clear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if(mSetting != null)
            {
                UpdateMatrix();
                CommandBuffer cmd = CommandBufferPool.Get("RenderParticleCloudLightMatCap");
                cmd.SetGlobalMatrix(mID_MVPMatrix, mMatrixMVP);
                cmd.SetGlobalMatrix(mID_MMatrix, mMatrixM);
                cmd.DrawMesh(mSetting.MatCapSphereMesh, Matrix4x4.identity, mSetting.LightMat);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(mRenderTargetHandle.id);
        }

        void UpdateMatrix()
        {
            Matrix4x4 inverse = Matrix4x4.identity;
            inverse.m22 = -1f;
            Matrix4x4 view = inverse * Matrix4x4.Rotate(Quaternion.Inverse(mCamera.transform.rotation));
            mMatrixMVP = mMatrixP * view * mMatrixM;
        }
    }

    class ParicleCloudFogTexPass : ScriptableRenderPass
    {
        Setting mSetting;
        Camera mCamera;
        RenderTargetHandle mRenderTargetHandle;
        Matrix4x4 mMatrixM;
        Matrix4x4 mMatrixP;
        Matrix4x4 mMatrixMVP;

        int mID_MVPMatrix = Shader.PropertyToID("_MVPMatrix");
        int mID_MMatrix = Shader.PropertyToID("_MMatrix");

        public ParicleCloudFogTexPass()
        {
            mRenderTargetHandle.Init("_CloudFogTex");
            mMatrixM = Matrix4x4.identity;
            mMatrixP = GL.GetGPUProjectionMatrix(Matrix4x4.Perspective(60f, 2f, 0.01f, 1f), true);
        }

        public void Setup(Setting setting, Camera cam)
        {
            mSetting = setting;
            mCamera = cam;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            cmd.GetTemporaryRT(mRenderTargetHandle.id, 256, 128, 16, FilterMode.Bilinear);
            ConfigureTarget(mRenderTargetHandle.Identifier(), mRenderTargetHandle.Identifier());
            ConfigureClear(ClearFlag.All, Color.clear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (mSetting != null)
            {
                UpdateMatrix();
                CommandBuffer cmd = CommandBufferPool.Get("RenderParticleCloudFogTex");
                cmd.SetGlobalMatrix(mID_MVPMatrix, mMatrixMVP);
                cmd.SetGlobalMatrix(mID_MMatrix, mMatrixM);
                cmd.DrawMesh(mSetting.MatCapSphereMesh, Matrix4x4.identity, mSetting.LightMat);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(mRenderTargetHandle.id);
        }

        void UpdateMatrix()
        {
            Matrix4x4 inverse = Matrix4x4.identity;
            inverse.m22 = -1f;
            Matrix4x4 view = inverse * Matrix4x4.Rotate(Quaternion.Inverse(mCamera.transform.rotation));
            mMatrixMVP = mMatrixP * view * mMatrixM;
        }
    }

    class ParicleCloudEdgeTexPass : ScriptableRenderPass
    {
        Setting mSetting;
        Camera mCamera;
        RenderTargetHandle mRenderTargetHandle;
        Matrix4x4 mMatrixM;
        Matrix4x4 mMatrixP;
        Matrix4x4 mMatrixMVP;

        int mID_MVPMatrix = Shader.PropertyToID("_MVPMatrix");
        int mID_MMatrix = Shader.PropertyToID("_MMatrix");

        public ParicleCloudEdgeTexPass()
        {
            mRenderTargetHandle.Init("_EdgeTex");
            mMatrixM = Matrix4x4.identity;
            mMatrixP = GL.GetGPUProjectionMatrix(Matrix4x4.Perspective(60f, 1f, 0.01f, 1f), true);
        }

        public void Setup(Setting setting, Camera cam)
        {
            mSetting = setting;
            mCamera = cam;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            cmd.GetTemporaryRT(mRenderTargetHandle.id, 128, 128, 16, FilterMode.Bilinear);
            ConfigureTarget(mRenderTargetHandle.Identifier(), mRenderTargetHandle.Identifier());
            ConfigureClear(ClearFlag.All, Color.clear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (mSetting != null)
            {
                UpdateMatrix();
                CommandBuffer cmd = CommandBufferPool.Get("RenderParticleCloudEdgeTex");
                cmd.SetGlobalMatrix(mID_MVPMatrix, mMatrixMVP);
                cmd.SetGlobalMatrix(mID_MMatrix, mMatrixM);
                cmd.DrawMesh(mSetting.MatCapSphereMesh, Matrix4x4.identity, mSetting.EdgeMat);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(mRenderTargetHandle.id);
        }

        void UpdateMatrix()
        {
            Matrix4x4 inverse = Matrix4x4.identity;
            inverse.m22 = -1f;
            Matrix4x4 view = inverse * Matrix4x4.Rotate(Quaternion.Inverse(mCamera.transform.rotation));
            mMatrixMVP = mMatrixP * view * mMatrixM;
        }
    }

    [System.Serializable]
    public class Setting
    {
        public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingTransparents;
        public string CullCameraTag = "MainCamera";
        [Header("Unity内置SphereMesh")]
        public Mesh MatCapSphereMesh;
        public Material LightMat;
        public Material EdgeMat;
    }

    ParicleCloudLightMatCapPass mParicleCloudLightMatCapPass;
    ParicleCloudFogTexPass mParicleCloudFogTexPass;
    ParicleCloudEdgeTexPass mParicleCloudEdgeTexPass;
    public Setting MSetting = new Setting();

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if(ParticleCloudMgr.Instance.ParicleClouds.Count > 0 && CheckSetting())
        {
            Camera cam = renderingData.cameraData.camera;
            if (cam.cameraType == CameraType.SceneView || (cam.cameraType == CameraType.Game && cam.CompareTag(MSetting.CullCameraTag)))
            {
                mParicleCloudLightMatCapPass.Setup(MSetting, cam);
                mParicleCloudFogTexPass.Setup(MSetting, cam);
                mParicleCloudEdgeTexPass.Setup(MSetting, cam);

                renderer.EnqueuePass(mParicleCloudLightMatCapPass);
                renderer.EnqueuePass(mParicleCloudFogTexPass);
                renderer.EnqueuePass(mParicleCloudEdgeTexPass);
            }
        }
    }

    public override void Create()
    {
        mParicleCloudLightMatCapPass = new ParicleCloudLightMatCapPass();
        mParicleCloudFogTexPass = new ParicleCloudFogTexPass();
        mParicleCloudEdgeTexPass = new ParicleCloudEdgeTexPass();
    }

    private bool CheckSetting()
    {
        return MSetting != null && !string.IsNullOrEmpty(MSetting.CullCameraTag) && MSetting.MatCapSphereMesh != null && MSetting.LightMat != null && MSetting.EdgeMat != null;
    }
}
