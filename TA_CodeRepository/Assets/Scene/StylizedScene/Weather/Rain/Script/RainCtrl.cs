using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RainCtrl : MonoBehaviour
{
    public Shader RainShader;
    public Color RainColor = Color.white;
    public Texture2D RainShapeTexture;
    [Header("Layer One")]
    public Vector2 RainScale_One = Vector2.one;
    public float RotateSpeed_One = 1f;
    public float RotateAmount_One = 0.5f;
    public float DropSpeed_One = 1f;

    [Header("Layer Two")]
    public Vector2 RainScale_Two = Vector2.one * 1.5f;
    public float RotateSpeed_Two = 1f;
    public float RotateAmount_Two = 0.5f;
    public float DropSpeed_Two = 1f;

    [Header("Layer Three")]
    public Vector2 RainScale_Three = Vector2.one * 1.7f;
    public float RotateSpeed_Three = 1f;
    public float RotateAmount_Three = 0.5f;
    public float DropSpeed_Three = 1f;

    [Header("Layer Two")]
    public Vector2 RainScale_Four = Vector2.one * 2f;
    public float RotateSpeed_Four = 1f;
    public float RotateAmount_Four = 0.5f;
    public float DropSpeed_Four = 1f;

    Material mRainMat;
    public Material RainMaterial { get { return mRainMat; } }

    static readonly int id_RainColor = Shader.PropertyToID("_RainColor");
    static readonly int id_RainShapeTex = Shader.PropertyToID("_RainShapeTex");
    static readonly int id_RainScale_Layer12 = Shader.PropertyToID("_RainScale_Layer12");
    static readonly int id_RainScale_Layer34 = Shader.PropertyToID("_RainScale_Layer34");
    static readonly int id_RotateSpeed = Shader.PropertyToID("_RotateSpeed");
    static readonly int id_RotateAmount = Shader.PropertyToID("_RotateAmount");
    static readonly int id_DropSpeed = Shader.PropertyToID("_DropSpeed");

    private void Awake()
    {
        if(RainShader != null)
        {
            mRainMat = new Material(RainShader);
        }
    }

    private void OnEnable()
    {
        RainMgr.Instance.AddRain(this);
    }

    private void Update()
    {
        UpdateRainMat();
    }

    private void OnDisable()
    {
        RainMgr.Instance.RemoveRain(this); 
    }

    private void OnDestroy()
    {
        if(mRainMat != null)
        {
            SafeDestory(mRainMat);
        }
    }

    void UpdateRainMat()
    {
        if (mRainMat == null) return;
        mRainMat.SetColor(id_RainColor, RainColor);
        mRainMat.SetTexture(id_RainShapeTex, RainShapeTexture);
        mRainMat.SetVector(id_RainScale_Layer12, new Vector4(RainScale_One.x, RainScale_One.y, RainScale_Two.x, RainScale_Two.y));
        mRainMat.SetVector(id_RainScale_Layer34, new Vector4(RainScale_Three.x, RainScale_Three.y, RainScale_Four.x, RainScale_Four.y));
        mRainMat.SetVector(id_RotateSpeed, new Vector4(RotateSpeed_One, RotateSpeed_Two, RotateSpeed_Three, RotateSpeed_Four));
        mRainMat.SetVector(id_RotateAmount, new Vector4(RotateAmount_One, RotateAmount_Two, RotateAmount_Three, RotateAmount_Four));
        mRainMat.SetVector(id_DropSpeed, new Vector4(DropSpeed_One, DropSpeed_Two, DropSpeed_Three, DropSpeed_Four));
    }

    void SafeDestory(Object o)
    {
        if(o != null)
        {
            if(Application.isPlaying)
            {
                Destroy(o);
            }
            else
            {
                DestroyImmediate(o);
            }
        }
    }
}
