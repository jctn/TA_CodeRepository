using System.Collections;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[AddComponentMenu("Noise/Compute Texture 3D_SingleChannel")]
public class ComputeTexture3D_SingleChannel : ComputeTexture {
    public ComputeShader texture3DSlicer;
    public GraphicsFormat Format = GraphicsFormat.R8_UNorm;

    //-------------------------------------------------------------------------------------------------------------------
    // Generator Functions
    //-------------------------------------------------------------------------------------------------------------------
    public override void GenerateTexture(){
        int kernel = computeShader.FindKernel(kernelName);
        computeShader.Dispatch(kernel, 
            squareResolution/computeThreads.x, 
            squareResolution/computeThreads.y, 
            squareResolution/computeThreads.z);
    }

    public override void CreateRenderTexture(){
        //24 is the bits of the depth buffer not the resolution of the z-direction
        RenderTexture rt = new RenderTexture(squareResolution, squareResolution, 0, Format, 0);
        rt.enableRandomWrite = true;
        rt.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        rt.volumeDepth = squareResolution;
        rt.filterMode = FilterMode.Bilinear;
        rt.wrapMode = TextureWrapMode.Clamp;
        rt.Create();
        rwTexture.rt = rt;
    }

    //-------------------------------------------------------------------------------------------------------------------
	// Save/Utility Functions
	//-------------------------------------------------------------------------------------------------------------------
    RenderTexture Copy3DSliceToRenderTexture(int layer){
        RenderTexture render = new RenderTexture(squareResolution, squareResolution, 0, Format, 0);
		render.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
		render.enableRandomWrite = true;
        render.filterMode = FilterMode.Bilinear;
        render.wrapMode = TextureWrapMode.Clamp;
		render.Create();

        int kernelIndex = texture3DSlicer.FindKernel("CSMain_S");
        texture3DSlicer.SetTexture(kernelIndex, "noise_s", rwTexture.rt);
        texture3DSlicer.SetInt("layer", layer);
        texture3DSlicer.SetTexture(kernelIndex, "Result_s", render);
        //texture3DSlicer.Dispatch(kernelIndex, squareResolution, squareResolution, 1);
        texture3DSlicer.Dispatch(kernelIndex, squareResolution / 32, squareResolution / 32, 1);
        return render;
    }

    protected Texture2D NewConvertFromRenderTexture(RenderTexture rt)
    {
        Texture2D output = new Texture2D(squareResolution, squareResolution, Format, 0, TextureCreationFlags.None);
        RenderTexture.active = rt;
        output.ReadPixels(new Rect(0, 0, squareResolution, squareResolution), 0, 0);
        output.Apply();
        return output;
    }

    public override void SaveAsset(){
        //for readability
        int dim = squareResolution;
        //Slice 3D Render Texture to individual layers
        RenderTexture[] layers = new RenderTexture[squareResolution];
        for(int i = 0; i < squareResolution; i++)
            layers[i] = Copy3DSliceToRenderTexture(i);
        //Write RenderTexture slices to static textures
        Texture2D[] finalSlices = new Texture2D[squareResolution];
        for(int i = 0; i < squareResolution; i++)
            finalSlices[i] = NewConvertFromRenderTexture(layers[i]);
        //Build 3D Texture from 2D slices
        Texture3D output = new Texture3D(dim, dim, dim, Format, TextureCreationFlags.None, 0);
        output.filterMode = FilterMode.Bilinear;
        output.wrapMode = TextureWrapMode.Repeat;
        Color[] outputPixels = output.GetPixels();
        for(int k = 0; k < dim; k++){
            Color[] layerPixels = finalSlices[k].GetPixels();
            for(int i = 0; i < dim; i++){
                for(int j = 0; j < dim; j++){
                    outputPixels[i + j * dim + k * dim * dim] = layerPixels[i+j*dim];
                }
            }
        }

        output.SetPixels(outputPixels);
        output.Apply();

        AssetDatabase.CreateAsset(output, "Assets/Base/NoiseGenerator/" + assetName + ".asset");
    }
}
