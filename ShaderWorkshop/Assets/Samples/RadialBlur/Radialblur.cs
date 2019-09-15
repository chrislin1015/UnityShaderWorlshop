using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Radialblur : MonoBehaviour
{
    public Shader m_RadialBlurShader;
    public Vector2 m_Center = new Vector2(0.5f, 0.5f);
    public float m_Strength = 2.0f;
    public float m_Dist = 1.0f;

    protected Material m_RadialBlurMat;

    // Start is called before the first frame update
    void Start()
    {
        m_RadialBlurMat = new Material(m_RadialBlurShader);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (m_RadialBlurMat == null)
        {
            Graphics.Blit(source, destination);
        }
        else
        {
            m_RadialBlurMat.SetVector("_Center", new Vector4(m_Center.x, m_Center.y, 0.0f, 0.0f));
            m_RadialBlurMat.SetFloat("_Strength", m_Strength);
            m_RadialBlurMat.SetFloat("_Dist", m_Dist);
            Graphics.Blit(source, destination, m_RadialBlurMat);
        }
    }
}
