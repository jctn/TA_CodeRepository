using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
public class RainCtrl : MonoBehaviour
{
    [Header("Asset")]
    public int RainSceneDepthRenderIndex = -1;
    public Shader RainShader;
    public Texture2D RainHeightmap;
    public Texture2D RainShapeTexture;

    [Space]
    [Range(0f, 1f)]
    public float RainIntensity = 1;
    public Color RainColor = Color.white;
    [Header("Layer One")]
    public Vector2 RainScale_One = Vector2.one;
    public float RotateSpeed_One = 1f;
    public float RotateAmount_One = 0.5f;
    public float DropSpeed_One = 1f;
    public float RainDepthStart_One = 0f;
    public float RainDepthRange_One = 5f;
    public float RainOpacity_One = 1f;

    [Header("Layer Two")]
    public Vector2 RainScale_Two = Vector2.one * 1.5f;
    public float RotateSpeed_Two = 1f;
    public float RotateAmount_Two = 0.5f;
    public float DropSpeed_Two = 1f;
    public float RainDepthStart_Two = 5f;
    public float RainDepthRange_Two = 10f;
    public float RainOpacity_Two = 1f;

    [Header("Layer Three")]
    public Vector2 RainScale_Three = Vector2.one * 1.7f;
    public float RotateSpeed_Three = 1f;
    public float RotateAmount_Three = 0.5f;
    public float DropSpeed_Three = 1f;
    public float RainDepthStart_Three = 15f;
    public float RainDepthRange_Three = 20f;
    public float RainOpacity_Three = 1f;

    [Header("Layer Four")]
    public Vector2 RainScale_Four = Vector2.one * 2f;
    public float RotateSpeed_Four = 1f;
    public float RotateAmount_Four = 0.5f;
    public float DropSpeed_Four = 1f;
    public float RainDepthStart_Four = 35f;
    public float RainDepthRange_Four = 50f;
    public float RainOpacity_Four = 1f;

    const string rainSceneDepthRenderStr = "RainSceneDepthRender";
    Camera sceneDepthCam;
    RenderTexture sceneDepthTex;
    int sceneDepthTexSize = 512;
    float sceneDepthDistance = 100f;
    Material mRainMat;
    public Material RainMaterial { get { return mRainMat; } }

    static readonly int id_RainIntensity = Shader.PropertyToID("_RainIntensity");
    static readonly int id_RainColor = Shader.PropertyToID("_RainColor");
    static readonly int id_RainShapeTex = Shader.PropertyToID("_RainShapeTex");
    static readonly int id_RainScale_Layer12 = Shader.PropertyToID("_RainScale_Layer12");
    static readonly int id_RainScale_Layer34 = Shader.PropertyToID("_RainScale_Layer34");
    static readonly int id_RotateSpeed = Shader.PropertyToID("_RotateSpeed");
    static readonly int id_RotateAmount = Shader.PropertyToID("_RotateAmount");
    static readonly int id_DropSpeed = Shader.PropertyToID("_DropSpeed");
    static readonly int id_RainDepthStart = Shader.PropertyToID("_RainDepthStart");
    static readonly int id_RainDepthRange = Shader.PropertyToID("_RainDepthRange");
    static readonly int id_RainOpacities = Shader.PropertyToID("_RainOpacities");
    static readonly int id_RainHeightmap = Shader.PropertyToID("_RainHeightmap");
    static readonly int id_SceneDepthCamMatrixVP = Shader.PropertyToID("_SceneDepthCamMatrixVP");

    static RainCtrl instance;
    public static RainCtrl Instance
    {
        get { return instance; }
    }

    private void Awake()
    {
        instance = this;
        if(RainShader != null)
        {
            mRainMat = new Material(RainShader);
        }

#if UNITY_EDITOR
        RainSceneDepthRenderData rainSceneDepthRender = PipelineUtilities.GetRenderer<RainSceneDepthRenderData>(rainSceneDepthRenderStr, nameof(RainSceneDepthRenderData));
        PipelineUtilities.ValidatePipelineRenderers(rainSceneDepthRender, ref RainSceneDepthRenderIndex);
#endif

    }

    private void OnEnable()
    {
        RenderPipelineManager.beginCameraRendering += BeginCameraRendering;
    }

    private void Update()
    {
        UpdateRainMat();
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= BeginCameraRendering;
    }

    private void OnDestroy()
    {
        DisposeCreatedRes();
    }

    void UpdateRainMat()
    {
        if (mRainMat == null) return;
        mRainMat.SetFloat(id_RainIntensity, RainIntensity);
        mRainMat.SetColor(id_RainColor, RainColor);
        mRainMat.SetTexture(id_RainShapeTex, RainShapeTexture);
        mRainMat.SetVector(id_RainScale_Layer12, new Vector4(RainScale_One.x, RainScale_One.y, RainScale_Two.x, RainScale_Two.y));
        mRainMat.SetVector(id_RainScale_Layer34, new Vector4(RainScale_Three.x, RainScale_Three.y, RainScale_Four.x, RainScale_Four.y));
        mRainMat.SetVector(id_RotateSpeed, new Vector4(RotateSpeed_One, RotateSpeed_Two, RotateSpeed_Three, RotateSpeed_Four));
        mRainMat.SetVector(id_RotateAmount, new Vector4(RotateAmount_One, RotateAmount_Two, RotateAmount_Three, RotateAmount_Four));
        mRainMat.SetVector(id_DropSpeed, new Vector4(DropSpeed_One, DropSpeed_Two, DropSpeed_Three, DropSpeed_Four));
        mRainMat.SetVector(id_RainDepthStart, new Vector4(RainDepthStart_One, RainDepthStart_Two, RainDepthStart_Three, RainDepthStart_Four));
        mRainMat.SetVector(id_RainDepthRange, new Vector4(RainDepthRange_One, RainDepthRange_Two, RainDepthRange_Three, RainDepthRange_Four));
        mRainMat.SetVector(id_RainOpacities, new Vector4(RainOpacity_One, RainOpacity_Two, RainOpacity_Three, RainOpacity_Four));
        mRainMat.SetTexture(id_RainHeightmap, RainHeightmap);
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
        if (mRainMat != null)
        {
            SafeDestory(mRainMat);
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
                go.transform.SetParent(transform, false);
                go.hideFlags = HideFlags.HideAndDontSave;
                sceneDepthCam = go.AddComponent<Camera>();
                sceneDepthCam.enabled = false;
                sceneDepthCam.orthographic = true;
                UniversalAdditionalCameraData destAdditionalData = sceneDepthCam.GetUniversalAdditionalCameraData();
                if (destAdditionalData != null && RainSceneDepthRenderIndex >= 0)
                {
                    destAdditionalData.SetRenderer(RainSceneDepthRenderIndex);
                }
            }

            if (sceneDepthTex == null)
            {
                sceneDepthTex = new RenderTexture(CreateRenderTextureDescriptor(sceneDepthTexSize, sceneDepthTexSize))
                {
                    name = "_SceneDepthTex",
                    hideFlags = HideFlags.DontSave,
                    filterMode = FilterMode.Bilinear,
                    wrapMode = TextureWrapMode.Clamp
                };
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

        sceneDepthCam.transform.position = camera.transform.position + camera.transform.forward * sceneDepthCam.orthographicSize + camera.transform.up * (sceneDepthCam.farClipPlane - sceneDepthCam.nearClipPlane) * 0.5f;
        //sceneDepthCam.transform.rotation = Quaternion.LookRotation(-camera.transform.up);
        sceneDepthCam.transform.rotation = camera.transform.rotation;
        sceneDepthCam.transform.Rotate(camera.transform.right, 90f, Space.World);
        Shader.SetGlobalMatrix(id_SceneDepthCamMatrixVP, sceneDepthCam.projectionMatrix * sceneDepthCam.worldToCameraMatrix);//在Unity中，投影矩阵遵循OpenGL;
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
