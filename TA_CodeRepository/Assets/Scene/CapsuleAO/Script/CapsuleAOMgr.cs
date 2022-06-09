using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class CapsuleAOMgr : MonoBehaviour
{
    static CapsuleAOMgr instance;
    public static CapsuleAOMgr Instance
    {
        get { return instance; }
    }

    List<SphereAO> sphereAOs = new List<SphereAO>();

    static int id_Spheres = Shader.PropertyToID("Spheres");
    static int id_SphereCount = Shader.PropertyToID("SphereCount");

    const int MAXSPHERECOUNT = 24;
    Vector4[] sphere = new Vector4[MAXSPHERECOUNT];

    private void Awake()
    {
        instance = this;
    }

    private void Update()
    {
        int count = Mathf.Min(MAXSPHERECOUNT, sphereAOs.Count);
        for(int i = 0; i < count; i++)
        {
            Vector3 pos = sphereAOs[i].transform.position;
            sphere[i].x = pos.x;
            sphere[i].y = pos.y;
            sphere[i].z = pos.z;
            sphere[i].w = sphereAOs[i].SphereRadius;
        }
        Shader.SetGlobalVectorArray(id_Spheres, sphere);
        Shader.SetGlobalInt(id_SphereCount, count);
    }

    public void AddSphere(SphereAO sphereAO)
    {
        sphereAOs.Add(sphereAO);
    }

    public void RemoveSphere(SphereAO sphereAO)
    {
        sphereAOs.Remove(sphereAO);
    }
}
