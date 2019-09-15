using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;
using System;

[Serializable]
[PostProcess(typeof(RadialBlurPPRenderer), PostProcessEvent.BeforeStack, "Chris/RadialBlur")]
public class RadialBlurPP : PostProcessEffectSettings
{
    public Vector2Parameter m_Center = new Vector2Parameter { value = new Vector2(0.5f, 0.5f) };

    [Range(0.0f, 2.0f), Tooltip("Sample Dist")]
    public FloatParameter m_Dist = new FloatParameter { value = 1.0f };

    [Range(0.0f, 10.0f), Tooltip("Sample Strength")]
    public FloatParameter m_Strength = new FloatParameter { value = 2.0f };
}

public sealed class RadialBlurPPRenderer : PostProcessEffectRenderer<RadialBlurPP>
{
    protected Shader m_MyShader = Shader.Find("Chris/RadialBlur");

    public override void Render(PostProcessRenderContext context)
    {
        var _Sheet = context.propertySheets.Get(m_MyShader);
        _Sheet.properties.SetVector("_Center", new Vector4(settings.m_Center.value.x, settings.m_Center.value.y, 0.0f, 0.0f));
        _Sheet.properties.SetFloat("_Dist", settings.m_Dist.value);
        _Sheet.properties.SetFloat("_Strength", settings.m_Strength.value);
        context.command.BlitFullscreenTriangle(context.source, context.destination, _Sheet, 0);
    }
}
