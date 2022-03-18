using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace FlowOutline
{
    [DisallowMultipleComponent]
    public class FlowOutlineObjS : MonoBehaviour
    {
        [Header("从当前层级还是从上第2个层级开始查找处理对象")]
        public bool CurOrFirstTwo = true;
        [Header("处理对象是Meshender还是SkinedMeshrender")]
        public bool IsSkinedRender = true;

        [Header("颜色")]
        [ColorUsage(true, true)]
        public Color OutLineColor = Color.white;
        [Range(0f, 10f)]
        public float OutLineColorHDRFactor = 0f;
        [Header("边缘颜色强度")]
        [Range(0f, 5f)]
        public float ColorIntensity = 1f;
        [Header("颜色呼吸效果")]
        public bool OpenBreathing = false;
        [Range(0f, 5f)]
        public float BreathingFrequency = 1f;
        [Header("避免遮挡物体描边")]
        public bool ShowOutline = false;
        [Header("以对象自身为遮罩")]
        public bool OpenMask = true;

        [Header("模糊参数")]
        [Range(0f, 5f)]
        public float BlurRadiusX = 1.6f;
        [Range(0f, 5f)]
        public float BlurRadiusY = 1.6f;
        [Header("模糊方向受扭曲方向影响")]
        public bool BlurDirByDistortRange = true;

        [Header("扭曲参数")]
        [Range(-0.5f, 0.5f)]
        public float DistortRangeX = 0.0f;
        [Range(-0.5f, 0.5f)]
        public float DistortRangeY = 0.043f;
        [Range(0, 1.0f)]
        public float DistortStrengthX = 0.0079f;
        [Range(0, 1.0f)]
        public float DistortStrengthY = 1.0f;
        public Texture NoiseTex;
        public Vector4 NoiseTilingAndOffset = new Vector4(15.0f, 6.0f, 0.0f, 0.0f);
        public float NoiseTexRotation = 0f;
        public Vector2 NoiseTexFlowDir = new Vector2(0f, 1f);
        [Range(0, 5.0f)]
        public float NoiseTexFlowSpeed = 0.85f;
        public bool DebugNoiseTex = false;

        [Header("Billboard参数")]
        public Vector2 BillboardSize = new Vector2(4f, 4f);
        public Vector3 BillboardOffset = new Vector3(0f, 1f, 0f);
        public EZTest BillboardZTest = EZTest.on;
        [Min(3000)]
        public int BillboardRenderQueue = 3000;

        public enum EZTest
        {
            off = 8,
            on = 4
        }

        private Renderer[] mRenderers;
        public Renderer[] Renderers
        {
            get
            {
                return mRenderers;
            }
        }

        private Material mMaskMat;
        public Material MaskMat
        {
            get
            {
                return mMaskMat;
            }
        }

        private Material mBillboardsMat;
        public Material BillboardsMat
        {
            get
            {
                return mBillboardsMat;
            }
        }

        private bool mRegistered;
        public bool Registered
        {
            get
            {
                return mRegistered;
            }
            set
            {
                mRegistered = value;
            }
        }

        private static int mID_SolidColor = Shader.PropertyToID("_SolidColor");
        private static int mID_SolidZTest = Shader.PropertyToID("_ZTest");
        private static int mID_SolidZWrite = Shader.PropertyToID("_ZWrite");
        private static int mID_SolidColorMask = Shader.PropertyToID("_ColorMask");
        private static int mID_DistortFactor = Shader.PropertyToID("_DistortFactor");
        private static int mID_DistortNoiseTilingAndOffset = Shader.PropertyToID("_NoiseTex_TO");
        private static int mID_RotationAndFlow = Shader.PropertyToID("_RotationAndFlow");
        private static int mID_DebugNoise = Shader.PropertyToID("_DebugNoise");
        private static int mID_NoiseTex = Shader.PropertyToID("_NoiseTex");
        private static int mID_OpenMask = Shader.PropertyToID("_OpenMask");
        private static int mID_BillboardSize = Shader.PropertyToID("_BillboardSize");
        private static int mID_BillboardZTest = Shader.PropertyToID("_BillboardZTest");
        private static int mID_AlphaFactor = Shader.PropertyToID("_AlphaFactor");
        private static int mID_FlowOutLineColor = Shader.PropertyToID("_FlowOutLineColor");
        private static int mID_ColorHDRFactor = Shader.PropertyToID("_ColorHDRFactor");
        private static int mID_SceneIndex = Shader.PropertyToID("_SceneIndex");

        private Transform mTarget_Transform;
        private Shader mSolidShader;
        private Shader mBillboardsShader;
        private Vector4 mMsakTexMask;
        public Vector4 MsakTexMask
        {
            get
            {
                return mMsakTexMask;
            }
        }
        private GameObject mBillboardGO;
        private float mActiveTime;
        private Mesh mBillboardMesh;
        private int mSceneIndex;
        public int SceneIndex
        {
            get
            {
                return mSceneIndex;
            }
        }

        private void OnEnable()
        {
            mActiveTime = Time.time;
        }

        private void Start()
        {
            if (!CurOrFirstTwo)
            {
                mTarget_Transform = transform.parent;
                if (mTarget_Transform == null || mTarget_Transform.parent == null)
                {
                    Debug.LogWarning("FlowOutLineObj挂载节点不对");
                    return;
                }
                mTarget_Transform = mTarget_Transform.parent;
            }
            else
            {
                mTarget_Transform = transform;
            }

            if (IsSkinedRender)
            {
                mRenderers = mTarget_Transform.GetComponentsInChildren<SkinnedMeshRenderer>();
                if (mRenderers == null || mRenderers.Length <= 0)
                {
                    Debug.LogWarning("处理对象无SkinnedMeshRenderer");
                }
            }
            else
            {
                mRenderers = mTarget_Transform.GetComponentsInChildren<MeshRenderer>();
                if (mRenderers == null || mRenderers.Length <= 0)
                {
                    Debug.LogWarning("处理对象无MeshRenderer");
                }
            }

#if UNITY_EDITOR
            mCur_CurOrFirstTwo = CurOrFirstTwo;
            mCur_IsSkinedRender = IsSkinedRender;
#endif
        }

#if UNITY_EDITOR
        bool mCur_CurOrFirstTwo = false;
        bool mCur_IsSkinedRender = true;

        void EditorUpdate()
        {
            if (mCur_CurOrFirstTwo != CurOrFirstTwo || mCur_IsSkinedRender != IsSkinedRender)
            {
                mCur_CurOrFirstTwo = CurOrFirstTwo;
                mCur_IsSkinedRender = IsSkinedRender;

                mRegistered = false;
                FlowOutlineMgrS.Instance.UnRegisterFlowOutlineObj(this);

                if (!CurOrFirstTwo)
                {
                    mTarget_Transform = transform.parent;
                    if (mTarget_Transform == null || mTarget_Transform.parent == null)
                    {
                        mRenderers = null;
                        return;
                    }
                    mTarget_Transform = mTarget_Transform.parent;
                }
                else
                {
                    mTarget_Transform = transform;
                }

                if (IsSkinedRender)
                {
                    mRenderers = mTarget_Transform.GetComponentsInChildren<SkinnedMeshRenderer>();
                }
                else
                {
                    mRenderers = mTarget_Transform.GetComponentsInChildren<MeshRenderer>();
                }
            }
        }
#endif

        private void Update()
        {
#if UNITY_EDITOR
            EditorUpdate();
#endif
            bool canRegistered = mTarget_Transform != null && mRenderers != null && mRenderers.Length > 0;
            if (!mRegistered)
            {
                if (canRegistered)
                {
                    mRegistered = FlowOutlineMgrS.Instance.RegisterFlowOutlineObj(this, mTarget_Transform);
                }
            }
            else
            {
                if (!canRegistered)
                {
                    mRegistered = false;
                    FlowOutlineMgrS.Instance.UnRegisterFlowOutlineObj(this);
                }
            }
        }

        private void LateUpdate()
        {
            if (mRegistered)
            {
                UpdateMats();
                UpdateBillboard();
            }
        }

        private void UpdateMats()
        {
            if (mSolidShader == null)
            {
                mSolidShader = Shader.Find("Code Repository/Effect/FlowOutLineS/SolidColor");
            }

            if (mBillboardsShader == null)
            {
                mBillboardsShader = Shader.Find("Code Repository/Effect/FlowOutLineS/Billboard");
            }
            UpdateBillboardsMat();
        }

        public void UpdateMaskMat(int index)
        {
            if (mMaskMat == null && mSolidShader != null)
            {
                mMaskMat = new Material(mSolidShader);
                mMaskMat.SetColor(mID_SolidColor, Color.white);
                mMaskMat.SetFloat(mID_SolidZTest, (float)CompareFunction.Disabled);//masktex没有深度缓冲区
                mMaskMat.SetFloat(mID_SolidZWrite, 0);
            }

            switch (index)
            {
                case 0:
                    mMaskMat.SetFloat(mID_SolidColorMask, (float)ColorWriteMask.Red);
                    mMsakTexMask = new Vector4(1f, 0f, 0f, 0f);
                    break;
                case 1:
                    mMaskMat.SetFloat(mID_SolidColorMask, (float)ColorWriteMask.Green);
                    mMsakTexMask = new Vector4(0f, 1f, 0f, 0f);
                    break;
                case 2:
                    mMaskMat.SetFloat(mID_SolidColorMask, (float)ColorWriteMask.Blue);
                    mMsakTexMask = new Vector4(0f, 0f, 1f, 0f);
                    break;
                case 3:
                    mMaskMat.SetFloat(mID_SolidColorMask, (float)ColorWriteMask.Alpha);
                    mMsakTexMask = new Vector4(0f, 0f, 0f, 1f);
                    break;
            }
        }

        private void UpdateBillboardsMat()
        {
            if (mBillboardsMat == null && mBillboardsShader != null)
            {
                mBillboardsMat = new Material(mBillboardsShader);
            }

            if (mBillboardsMat != null)
            {
                Color tempColor = OutLineColor;
                if (OpenBreathing)
                {
                    float a = Mathf.Sin(2 * Mathf.PI * BreathingFrequency * (Time.time - mActiveTime));
                    a = a * 0.5f + 0.5f;
                    tempColor.a *= a;
                }
                mSceneIndex = FlowOutlineMgrS.Instance.GetSceneIndex(this);
                mBillboardsMat.SetInt(mID_SceneIndex, mSceneIndex);
                mBillboardsMat.SetInt(mID_OpenMask, OpenMask ? 1 : 0);
                mBillboardsMat.SetColor(mID_FlowOutLineColor, tempColor);
                mBillboardsMat.SetFloat(mID_ColorHDRFactor, OutLineColorHDRFactor);
                mBillboardsMat.SetVector(mID_DistortFactor, new Vector4(DistortRangeX, DistortRangeY, DistortStrengthX, DistortStrengthY));
                mBillboardsMat.SetVector(mID_DistortNoiseTilingAndOffset, NoiseTilingAndOffset);
                mBillboardsMat.SetVector(mID_RotationAndFlow, new Vector4(NoiseTexRotation, NoiseTexFlowDir.x, NoiseTexFlowDir.y, NoiseTexFlowSpeed));
#if UNITY_EDITOR
                mBillboardsMat.SetInt(mID_DebugNoise, DebugNoiseTex ? 1 : 0);
#endif
                mBillboardsMat.SetTexture(mID_NoiseTex, NoiseTex);
                mBillboardsMat.SetVector(mID_BillboardSize, BillboardSize * Mathf.Max(Mathf.Max(mTarget_Transform.lossyScale.x, mTarget_Transform.lossyScale.y), mTarget_Transform.lossyScale.z));
                mBillboardsMat.SetFloat(mID_BillboardZTest, (float)BillboardZTest);
                mBillboardsMat.SetFloat(mID_AlphaFactor, ColorIntensity);
                mBillboardsMat.renderQueue = BillboardRenderQueue;
            }
        }

        private void UpdateBillboard()
        {
            if (mBillboardGO == null)
            {
                mBillboardGO = GameObject.CreatePrimitive(PrimitiveType.Quad);
                DestroyObj(mBillboardGO.GetComponent<MeshCollider>());
                mBillboardMesh = mBillboardGO.GetComponent<MeshFilter>().mesh;
                Bounds b = mBillboardMesh.bounds;
                mBillboardMesh.bounds = new Bounds(Vector3.zero, Vector3.one * Mathf.Max(Mathf.Max(b.size.x, b.size.y), b.size.z) * 2f); //避免被视锥体剔除
                mBillboardGO.name = "Billboard";
                mBillboardGO.layer = transform.gameObject.layer;
                mBillboardGO.GetComponent<Renderer>().sharedMaterial = mBillboardsMat;
                mBillboardGO.transform.SetParent(transform, false);
            }
            if (mBillboardGO != null)
            {
                Vector3 pos;
                pos.x = BillboardOffset.x;
                pos.y = BillboardOffset.y;
                pos.z = BillboardOffset.z;
                mBillboardGO.transform.localPosition = pos;
                mBillboardGO.transform.localScale = new Vector3(BillboardSize.x, BillboardSize.y, 1f);
#if UNITY_EDITOR
                if (UnityEditor.SceneView.lastActiveSceneView != null)
                {
                    mBillboardGO.transform.LookAt(UnityEditor.SceneView.lastActiveSceneView.camera.transform, Vector3.up);
                }
#endif
            }
        }

        private void OnDisable()
        {
            mRegistered = false;
            FlowOutlineMgrS.Instance.UnRegisterFlowOutlineObj(this);
            DestroyObj(mBillboardMesh);
            DestroyObj(mBillboardGO);
            mBillboardGO = null;
        }

        private void OnDestroy()
        {
            DestroyObj(mMaskMat);
            DestroyObj(mBillboardsMat);
            mMaskMat = null;
            mBillboardsMat = null;
        }

        private void DestroyObj(UnityEngine.Object obj)
        {
            if (obj != null)
            {
#if UNITY_EDITOR
                DestroyImmediate(obj);
#else
                Destroy(obj);
#endif
            }
        }
    }
}

