using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class ParticleCloud_Tex : MonoBehaviour
{
    [Header("把场景相机拖入(可选)")]
    public Camera SceneCam;
    [Header("拖入Unity内置sphere")]
    public Mesh MatCapSphereMesh;
    [Header("光照MatCap纹理")]
    public Texture LightTex;
    [Header("边缘光纹理")]
    public Texture EdgeLightTex;
    [Header("在子节点生成光照预览球")]
    public bool ShowTipSphere;
    [Header("天空球")]
    public Transform SkySphere;

    //LightMatCap
    public Vector3 LightMatCapAngle = new Vector3(0f, -90f, 0f);
    Matrix4x4 mLightMatCapP;
    Matrix4x4 mLightMatCapMVP;
    GameObject mLightMatCapTipSphere;
    Material mMatCapSphereMat;

    //FogTex,云层穿透效果
    Matrix4x4 mFogP;
    Matrix4x4 mFogMVP;

    //EdgeLightTex
    public Vector3 EdgeLightAngle = new Vector3(0f, -90f, 0f);
    Matrix4x4 mEdgeLightMVP;
    Matrix4x4 mEdgeLightP;
    GameObject mEdgeLightTipSphere;

    //common
    Matrix4x4 mview;

    static int mID_MatCapMainTex = Shader.PropertyToID("_MatCapMainTex");
    static int mID_MVPMatrix = Shader.PropertyToID("_MVPMatrix");

    static int mID_LightMatCap = Shader.PropertyToID("_LightMatCap");
    static int mID_CloudFogTex = Shader.PropertyToID("_CloudFogTex");
    static int mID_EdgeTex = Shader.PropertyToID("_EdgeTex");

    private void OnEnable()
    {
        if(mMatCapSphereMat == null)
        {
            mMatCapSphereMat = new Material(Shader.Find("ParticleCloud/MatCapSpher_Tex"));
        }
        IniteMatrix();
        RenderPipelineManager.beginFrameRendering += RenderMatCaps;
        RenderPipelineManager.endFrameRendering += ReleaseRT;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginFrameRendering -= RenderMatCaps;
        RenderPipelineManager.endFrameRendering -= ReleaseRT;
        CoreUtils.Destroy(mMatCapSphereMat);
        CoreUtils.Destroy(mLightMatCapTipSphere);
        CoreUtils.Destroy(mEdgeLightTipSphere);
    }

    private void Update()
    {
#if UNITY_EDITOR
        if (Application.isPlaying && ShowTipSphere && MatCapSphereMesh != null && LightTex != null && EdgeLightTex)
        {
            UpdateTipSphere(ref mLightMatCapTipSphere, LightTex, "LightMatCapTipSphere", LightMatCapAngle, new Vector3(0f, 10f, 0f));
            UpdateTipSphere(ref mEdgeLightTipSphere, EdgeLightTex, "EdgeLightMatCapTipSphere", EdgeLightAngle, new Vector3(0f, 12f, 0f));
        }
#endif
    }

    void UpdateTipSphere(ref GameObject go, Texture tex, string name, Vector3 r, Vector3 p)
    {
        if(go == null)
        {
            go = new GameObject(name);
            go.AddComponent<MeshFilter>().sharedMesh = MatCapSphereMesh;
            Material mat = new Material(Shader.Find("Unlit/Texture"));
            mat.SetTexture("_MainTex", tex);
            go.AddComponent<MeshRenderer>().material = mat;
            go.transform.SetParent(transform, false);
            go.transform.localPosition = p;
        }
        if(SkySphere != null)
        {
            go.transform.rotation = Quaternion.Euler(r) * SkySphere.rotation;
        }
        else
        {
            go.transform.rotation = Quaternion.Euler(r);
        }      
    }

    void IniteMatrix()
    {
        mLightMatCapP = GL.GetGPUProjectionMatrix(Matrix4x4.Ortho(-0.495f, 0.495f, -0.495f, 0.495f, -1f, 0f), true);
        mEdgeLightP = GL.GetGPUProjectionMatrix(Matrix4x4.Perspective(60f, 1f, 0.01f, 1f), true);
        mFogP = GL.GetGPUProjectionMatrix(Matrix4x4.Perspective(60f, 2f, 0.01f, 1f), true);
    }

    void UpdateMatrix(ref Matrix4x4 mvp, Vector3 modelR, bool updateView, in Matrix4x4 p, Quaternion camR)
    {
        if (updateView)
        {
            Matrix4x4 inverse = Matrix4x4.identity;
            inverse.m22 = -1f;
            mview = inverse * Matrix4x4.Rotate(Quaternion.Inverse(camR));
        }

        Matrix4x4 model;
        if (SkySphere != null)
        {
            model = Matrix4x4.Rotate(SkySphere.rotation) * Matrix4x4.Rotate(Quaternion.Euler(modelR));
        }
        else
        {
            model = Matrix4x4.Rotate(Quaternion.Euler(modelR));
        }
        mvp = p * mview * model;
    }

    void RenderLightMatCap(ScriptableRenderContext context)
    {
        if(LightTex != null)
        {
            CommandBuffer cmd = CommandBufferPool.Get("RenderLightMatCap");
            cmd.GetTemporaryRT(mID_LightMatCap, 128, 128, 16, FilterMode.Bilinear);
            cmd.SetRenderTarget(mID_LightMatCap);
            cmd.ClearRenderTarget(true, true, Color.clear);
            cmd.SetGlobalTexture(mID_MatCapMainTex, LightTex);
            cmd.SetGlobalMatrix(mID_MVPMatrix, mLightMatCapMVP);
            cmd.DrawMesh(MatCapSphereMesh, Matrix4x4.identity, mMatCapSphereMat);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
    
    void RenderFogTex(ScriptableRenderContext context)
    {
        if (LightTex != null)
        {
            CommandBuffer cmd = CommandBufferPool.Get("RenderFogTex");
            cmd.GetTemporaryRT(mID_CloudFogTex, 256, 128, 16, FilterMode.Bilinear);
            cmd.SetRenderTarget(mID_CloudFogTex);
            cmd.ClearRenderTarget(true, true, Color.clear);
            cmd.SetGlobalTexture(mID_MatCapMainTex, LightTex);
            cmd.SetGlobalMatrix(mID_MVPMatrix, mFogMVP);
            cmd.DrawMesh(MatCapSphereMesh, Matrix4x4.identity, mMatCapSphereMat);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    void RenderEdgeTex(ScriptableRenderContext context)
    {
        if(EdgeLightTex != null)
        {
            CommandBuffer cmd = CommandBufferPool.Get("RenderEdgeMatCap");
            cmd.GetTemporaryRT(mID_EdgeTex, 128, 128, 16, FilterMode.Bilinear);
            cmd.SetRenderTarget(mID_EdgeTex);
            cmd.ClearRenderTarget(true, true, Color.clear);
            cmd.SetGlobalTexture(mID_MatCapMainTex, EdgeLightTex);
            cmd.SetGlobalMatrix(mID_MVPMatrix, mEdgeLightMVP);
            cmd.DrawMesh(MatCapSphereMesh, Matrix4x4.identity, mMatCapSphereMat);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    void RenderMatCaps(ScriptableRenderContext context, Camera[] cams)
    {
        if (MatCapSphereMesh == null)
        {
            Debug.LogError("MatCapSphereMesh为空！");
            return;
        }

        Camera cam;
        if(cams.Length > 0 && cams[0].cameraType == CameraType.SceneView)
        {
            cam = cams[0];
        }
        else
        {
            Camera editorCam = SceneCam != null ? SceneCam : FindObjectOfType<Camera>();
            cam = Camera.main != null ? Camera.main : editorCam;
        }
        if (cam != null)
        {
            UpdateMatrix(ref mLightMatCapMVP, LightMatCapAngle, true, in mLightMatCapP, cam.transform.rotation);
            UpdateMatrix(ref mFogMVP, LightMatCapAngle, false, in mFogP, cam.transform.rotation);
            UpdateMatrix(ref mEdgeLightMVP, EdgeLightAngle, false, in mEdgeLightP, cam.transform.rotation);

            RenderLightMatCap(context);
            RenderFogTex(context);
            RenderEdgeTex(context);
        }
    }

    void ReleaseRT(ScriptableRenderContext context, Camera[] cams)
    {
        CommandBuffer cmd = CommandBufferPool.Get();
        cmd.ReleaseTemporaryRT(mID_LightMatCap);
        cmd.ReleaseTemporaryRT(mID_EdgeTex);
        cmd.ReleaseTemporaryRT(mID_CloudFogTex);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}
