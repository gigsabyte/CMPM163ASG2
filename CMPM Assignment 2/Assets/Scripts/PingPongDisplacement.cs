using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PingPongDisplacement : MonoBehaviour
{
    private Material mat;

    private float disp = 1.5f;
    private float maxDisp = 2.5f;
    private float minDisp = 1.0f;

    private bool increasing = true;

    private bool ping = false;

    // Start is called before the first frame update
    void Start()
    {
        mat = gameObject.GetComponent<Renderer>().material;

        //StartCoroutine(PingPong());
    }

    public void TogglePingPong()
    {
        if(ping)
        {
            StopAllCoroutines();
            ping = false;
        }
        else
        {
            StartCoroutine(PingPong());
            ping = true;
        }
        
    }

    private IEnumerator PingPong()
    {
        while (true)
        {
            yield return new WaitForSeconds(0.05f);
            if (increasing)
            {
                if (disp < maxDisp) disp += 0.05f;
                else increasing = false;
            }
            else
            {
                if (disp > minDisp) disp -= 0.05f;
                else increasing = true;
            }
            mat.SetFloat("_DisplacementAmt", disp);
        }
    }
}
