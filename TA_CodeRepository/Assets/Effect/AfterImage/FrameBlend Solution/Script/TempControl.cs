using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TempControl : MonoBehaviour
{
    public float Speed = 10f;

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKey(KeyCode.W))
        {
            transform.Translate(transform.forward * Time.deltaTime * Speed);
        }

        if (Input.GetKey(KeyCode.S))
        {
            transform.Translate(-transform.forward * Time.deltaTime * Speed);
        }

        if(Input.GetKey(KeyCode.A))
        {
            transform.Translate(-transform.right * Time.deltaTime * Speed);
        }
        if(Input.GetKey(KeyCode.D))
        {
            transform.Translate(transform.right * Time.deltaTime * Speed);
        }
    }
}
