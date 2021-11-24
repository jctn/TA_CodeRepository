using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class BlendModeGUI : ShaderGUI
{
    private Material mat;

    enum BlendModeChoose
    {
        正常_Normal,
        透明混合_Alphablend,
        变暗_Darken,
        正片叠底_Multiply,
        颜色加深_ColorBurn,
        线性加深_LinearBurn,
        深色_DarkerColor,
        变亮_Lighten,
        滤色_Screen,
        颜色减淡_ColorDodge,
        线性减淡_LinearDodge,
        浅色_LighterColor,
        叠加_Overlay,
        柔光_SoftLight,
        强光_HardLight,
        亮光_VividLight,
        线性光_LinearLight,
        点光_PinLight,
        实色混合_HardMix,
        差值_Difference,
        排除_Exclusion,
        减去_Subtract,
        划分_Divide,
        色相_Hue,
        饱和度_Saturation,
        颜色_Color,
        明度_Luminosity
    }

    private MaterialProperty ModeID;
    private MaterialProperty ModeChooseProps;
    string[] MateritalChoosenames = System.Enum.GetNames(typeof(BlendModeChoose));

    private MaterialProperty DstColorProps;
    private MaterialProperty DstTextureProps;
    private MaterialProperty SrcColorProps;
    private MaterialProperty SrcTextureProps;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);
        EditorGUILayout.BeginVertical(new GUIStyle("U2D.createRect"));
        EditorGUILayout.Space(10);
        ModeChooseProps = FindProperty("_IDChoose", properties);
        ModeID = FindProperty("_ModeID", properties);
        ModeChooseProps.floatValue = EditorGUILayout.Popup(
            "BlendModeChoose", (int) ModeChooseProps.floatValue,
            MateritalChoosenames);
        ModeID.floatValue = ModeChooseProps.floatValue;

        EditorGUILayout.Space(10);
        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(30);
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        EditorGUILayout.Space(10);
        DstColorProps = FindProperty("_Color1", properties);
        materialEditor.ColorProperty(DstColorProps, "DstColor");
        DstTextureProps = FindProperty("_MainTex1", properties);
        materialEditor.TextureProperty(DstTextureProps, "DstTexture");
        EditorGUILayout.Space(20);
        SrcColorProps = FindProperty("_Color2", properties);
        materialEditor.ColorProperty(SrcColorProps, "SrcColor");
        SrcTextureProps = FindProperty("_MainTex2", properties);
        materialEditor.TextureProperty(SrcTextureProps, "SrcTexture");
        EditorGUILayout.Space(10);
        EditorGUILayout.EndVertical();
    }
}