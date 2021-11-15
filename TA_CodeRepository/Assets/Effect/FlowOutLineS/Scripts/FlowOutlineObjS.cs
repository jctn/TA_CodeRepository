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
        public bool CurOrFirstTwo = false;
        [Header("处理对象是Meshender还是SkinedMeshrender")]
        public bool IsSkinedRender = true;

        [Header("颜色")]
        [ColorUsage(true, false)]
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
        [Header("避免遮挡物体材质的描边")]
        public bool ShowOutline = false;

        [Header("模糊参数")]
        //剪影RT降采样
        [Range(0, 5)]
        public int SilhouetteDownSample = 3;
        [Range(0f, 5f)]
        public float BlurRadiusX = 1.6f;
        [Range(0f, 5f)]
        public float BlurRadiusY = 1.6f;
        [Header("y方向只向上方模糊")]
        public bool IsUPBlur = true;
        //迭代次数
        [Header("模糊迭代次数")]
        [Range(0f, 5f)]
        public int Iteration = 1;

        [Header("扭曲参数")]
        //模糊步长
        [Range(0, 5.0f)]
        public float DistortTimeFactor = 0.85f;
        [Range(-0.2f, 0.2f)]
        public float DistortRangeX = 0.0f;
        [Range(-0.2f, 0.2f)]
        public float DistortRangeY = 0.043f;
        [Range(0, 1.0f)]
        public float DistortStrengthX = 0.0079f;
        [Range(0, 1.0f)]
        public float DistortStrengthy = 1.0f;
        public Texture NoiseTex;
        public Vector4 NoiseTilingAndOffset = new Vector4(15.0f, 6.0f, 0.0f, 0.0f);

        [Header("Billboard参数")]
        public Vector2 BillboardSize = new Vector2(4f, 4f);
        public Vector3 BillboardOffset = new Vector3(0f, 1f, 0f);
        //public BlendMode BillboardSrcBlend = BlendMode.SrcAlpha;
        //public BlendMode BillboardDstBlend = BlendMode.OneMinusSrcAlpha;
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

        private Material mSilhouetteMat;
        public Material SilhouetteMat
        {
            get
            {
                return mSilhouetteMat;
            }
        }

        private Material mBlurMat;
        public Material BlurMat
        {
            get
            {
                return mBlurMat;
            }
        }

        private RenderTexture mSilhouetteTex;
        public RenderTexture SilhouetteTex
        {
            get
            {
                return mSilhouetteTex;
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
        private static int mID_SolidColorHDRFactor = Shader.PropertyToID("_SolidColorHDRFactor");
        private static int mID_DistortTimeFactor = Shader.PropertyToID("_DistortTimeFactor");
        private static int mID_DistortFactor = Shader.PropertyToID("_DistortFactor");
        private static int mID_DistortNoiseTilingAndOffset = Shader.PropertyToID("_NoiseTex_TO");
        private static int mID_SilhouetteTex = Shader.PropertyToID("_SilhouetteTex");
        private static int mID_NoiseTex = Shader.PropertyToID("_NoiseTex");
        private static int mID_MsakTexMask = Shader.PropertyToID("_MsakTexMask");
        private static int mID_BillboardSize = Shader.PropertyToID("_BillboardSize");
        //private static int mID_BillboardSrcBlend = Shader.PropertyToID("_BillboardSrcBlend");
        //private static int mID_BillboardDstBlend = Shader.PropertyToID("_BillboardDstBlend");
        private static int mID_BillboardZTest = Shader.PropertyToID("_BillboardZTest");
        private static int mID_AlphaFactor = Shader.PropertyToID("_AlphaFactor");

        private Transform p;
        //[HideInInspector]
        //public bool ForceUnRegistered;
        private int mIndex;
        private Shader mSolidShader;
        private Shader mBlurShader;
        private Shader mBillboardsShader;
        private Vector4 mMsakTexMask;
        private GameObject mBillboardGO;
        private float mActiveTime;

        private void OnEnable()
        {
            mActiveTime = Time.time;
        }

        private void Start()
        {
            if(!CurOrFirstTwo)
            {
                p = transform.parent;
                if (p == null || p.parent == null)
                {
                    Debug.LogWarning("FlowOutLineObj挂载节点不对");
                    return;
                }
                p = p.parent;
            }
            else
            {
                p = transform;
            }

            if(IsSkinedRender)
            {
                mRenderers = p.GetComponentsInChildren<SkinnedMeshRenderer>();
                if (mRenderers == null || mRenderers.Length <= 0)
                {
                    Debug.LogWarning("处理对象无SkinnedMeshRenderer");
                }
            }
            else
            {
                mRenderers = p.GetComponentsInChildren<MeshRenderer>();
                if (mRenderers == null || mRenderers.Length <= 0)
                {
                    Debug.LogWarning("处理对象无MeshRenderer");
                }
            }
        }

#if UNITY_EDITOR
        bool mCur_CurOrFirstTwo = false;
        bool mCur_IsSkinedRender = true;

        void EditorUpdate()
        {
            if(mCur_CurOrFirstTwo != CurOrFirstTwo || mCur_IsSkinedRender != IsSkinedRender)
            {
                mCur_CurOrFirstTwo = CurOrFirstTwo;
                mCur_IsSkinedRender = IsSkinedRender;

                if (!CurOrFirstTwo)
                {
                    p = transform.parent;
                    if (p == null || p.parent == null)
                    {
                        return;
                    }
                    p = p.parent;
                }
                else
                {
                    p = transform;
                }

                if (IsSkinedRender)
                {
                    mRenderers = p.GetComponentsInChildren<SkinnedMeshRenderer>();
                }
                else
                {
                    mRenderers = p.GetComponentsInChildren<MeshRenderer>();
                }
            }
        }
#endif

        private void Update()
        {
#if UNITY_EDITOR
            EditorUpdate();
#endif
            bool canRegistered;
            if (Camera.main != null)
            {
                canRegistered = mRenderers != null && mRenderers.Length > 0 && ((1 << mRenderers[0].gameObject.layer) & Camera.main.cullingMask) != 0;
            }
            else
            {
                canRegistered = mRenderers != null && mRenderers.Length > 0;
            }
            if (!mRegistered)
            {
                if (canRegistered)
                {
                    mRegistered = FlowOutlineMgrS.Instance.RegisterFlowOutlineObj(this, p);
                }
            }
            else
            {
                if (!canRegistered)
                {
                    mRegistered = false;
                    FlowOutlineMgrS.Instance.UnRegisterFlowOutlineObj(p);
                }
            }
        }

        private void LateUpdate()
        {
            if(mRegistered)
            {
                UpdateSilhouetteTex();
                UpdateMats();
                UpdateBillboard();
            }     
        }

        private void UpdateMats()
        {
            mIndex = FlowOutlineMgrS.Instance.GetFlowOutlineIndex(this);
            if (mIndex < 0) return;

            if (mSolidShader == null)
            {
                mSolidShader = Shader.Find("SaintSeiya2/Effect/FlowOutLineS/SolidColor");
            }

            if(mBlurShader == null)
            {
                mBlurShader = Shader.Find("SaintSeiya2/Effect/FlowOutLineS/Blur");
            }

            if(mBillboardsShader == null)
            {
                mBillboardsShader = Shader.Find("SaintSeiya2/Effect/FlowOutLineS/Billboard");
            }
            UpdateMaskMat();
            UpdateSilhouetteMat();
            UpdateBlurMat();
            UpdateBillboardsMat();
        }

        private void UpdateMaskMat()
        {         
            if(mMaskMat == null && mSolidShader != null)
            {
                mMaskMat = new Material(mSolidShader);
                mMaskMat.SetColor(mID_SolidColor, Color.white);
                mMaskMat.SetFloat(mID_SolidZTest, (float)CompareFunction.Disabled);//masktex没有深度缓冲区
                mMaskMat.SetFloat(mID_SolidZWrite, 0);
            }

            if(mMaskMat != null)
            {
                switch (mIndex)
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
        }

        private void UpdateSilhouetteMat()
        {
            if(mSilhouetteMat == null && mSolidShader != null)
            {
                mSilhouetteMat = new Material(mSolidShader);
                mSilhouetteMat.SetFloat("_ZTest", (float)CompareFunction.Disabled);
                mSilhouetteMat.SetFloat("_ZWrite", 0f);
                mSilhouetteMat.SetFloat("_ColorMask", (float)ColorWriteMask.All);
            }

            if(mSilhouetteMat != null)
            {
                Color tempColor = OutLineColor;
                if(OpenBreathing)
                {
                    float a = Mathf.Sin(2 * Mathf.PI * BreathingFrequency * (Time.time - mActiveTime));
                    a = a * 0.5f + 0.5f;
                    tempColor.a *= a;
                }
                mSilhouetteMat.SetColor(mID_SolidColor, tempColor);
                mSilhouetteMat.SetFloat(mID_SolidColorHDRFactor, OutLineColorHDRFactor);
            }
        }

        private void UpdateBlurMat()
        {
            if(mBlurMat == null && mBlurShader != null)
            {
                mBlurMat = new Material(mBlurShader);
            }
        }

        public void UpdateBillboardsMat()
        {
            if(mBillboardsMat == null && mBillboardsShader != null)
            {
                mBillboardsMat = new Material(mBillboardsShader);
            }
            
            if(mBillboardsMat != null)
            {
                mBillboardsMat.SetTexture(mID_SilhouetteTex, mSilhouetteTex);
                mBillboardsMat.SetVector(mID_MsakTexMask, mMsakTexMask);
                mBillboardsMat.SetFloat(mID_DistortTimeFactor, DistortTimeFactor);
                mBillboardsMat.SetVector(mID_DistortFactor, new Vector4(DistortRangeX, DistortRangeY, DistortStrengthX, DistortStrengthy));
                mBillboardsMat.SetVector(mID_DistortNoiseTilingAndOffset, NoiseTilingAndOffset);
                mBillboardsMat.SetTexture(mID_NoiseTex, NoiseTex);
                mBillboardsMat.SetVector(mID_BillboardSize, BillboardSize);
                //mBillboardsMat.SetFloat(mID_BillboardSrcBlend, (float)BillboardSrcBlend);
                //mBillboardsMat.SetFloat(mID_BillboardDstBlend, (float)BillboardDstBlend);
                mBillboardsMat.SetFloat(mID_BillboardZTest, (float)BillboardZTest);
                mBillboardsMat.SetFloat(mID_AlphaFactor, ColorIntensity);
                mBillboardsMat.renderQueue = BillboardRenderQueue;
            }
        }

        private void UpdateSilhouetteTex()
        {
            int w = Screen.width >> SilhouetteDownSample;
            int h = Screen.height >> SilhouetteDownSample;
            if (mSilhouetteTex == null || mSilhouetteTex.width != w || mSilhouetteTex.height != h)
            {
                if(mSilhouetteTex != null)
                {
                    RenderTexture.ReleaseTemporary(mSilhouetteTex);
                }
                mSilhouetteTex = RenderTexture.GetTemporary(w, h, 0, RenderTextureFormat.ARGBHalf);
            }
        }

        private void UpdateBillboard()
        {
            if(mBillboardGO == null)
            {
                mBillboardGO = GameObject.CreatePrimitive(PrimitiveType.Quad);
                DestroyObj(mBillboardGO.GetComponent<MeshCollider>());
                mBillboardGO.name = "Billboard";
                mBillboardGO.layer = transform.gameObject.layer;
                mBillboardGO.GetComponent<Renderer>().sharedMaterial = mBillboardsMat;
                mBillboardGO.transform.SetParent(transform, false);
            }
            if(mBillboardGO != null)
            {
                Vector3 pos = mBillboardGO.transform.localPosition;
                pos.x = BillboardOffset.x;
                pos.y = BillboardOffset.y;
                pos.z = BillboardOffset.z;
                mBillboardGO.transform.localPosition = pos;
                mBillboardGO.transform.localScale = new Vector3(BillboardSize.x, BillboardSize.y, 1f);
                if(Camera.main != null)
                {
                    mBillboardGO.transform.LookAt(Camera.main.transform, Vector3.up);
                }
            }
        }

        private void OnDisable()
        {
            mRegistered = false;
            FlowOutlineMgrS.Instance.UnRegisterFlowOutlineObj(p);
            DestroyObj(mBillboardGO);
            mBillboardGO = null;
            if(mSilhouetteTex != null)
            {
                RenderTexture.ReleaseTemporary(mSilhouetteTex);
                mSilhouetteTex = null;
            }
        }

        private void OnDestroy()
        {
            DestroyObj(mMaskMat);
            DestroyObj(mSilhouetteMat);
            DestroyObj(mBlurMat);
            DestroyObj(mBillboardsMat);

            mMaskMat = null;
            mSilhouetteMat = null;
            mBlurMat = null;
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
