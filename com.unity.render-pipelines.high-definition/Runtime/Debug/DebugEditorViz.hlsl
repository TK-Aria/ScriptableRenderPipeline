#ifndef UNITY_DEBUG_EDITOR_VIZ_INCLUDED
#define UNITY_DEBUG_EDITOR_VIZ_INCLUDED

// Define bounds value in linear RGB for fresnel0 values
static const float dieletricMin = 0.02;
static const float dieletricMax = 0.07;
static const float gemsMin      = 0.07;
static const float gemsMax      = 0.22;
static const float conductorMin = 0.45;
static const float conductorMax = 1.00;
static const float albedoMin    = 0.012;
static const float albedoMax    = 0.9;

// Pass 0 - Albedo
half4 pbrAlbedoValidate(BSDFData bsdfData, bool isMetal, bool metallicWorkflow)
{
    half3 SpecularColor = bsdfData.fresnel0;
    half3 baseColor = bsdfData.diffuseColor;

    half3 unTouched = Luminance(bsdfData.diffuseColor).xxx; // if no errors, leave color as it was in render

    if (!metallicWorkflow)
    {
        isMetal = dot(SpecularColor, float3(0.3333,0.3333,0.3333)) >= conductorMin;
    }

    // When checking full range we do not take the luminance but the mean because often in game blue color are highlight as too low whereas this is what we are looking for.
    half value = dot(baseColor, half3(0.3333, 0.3333, 0.3333));

     // Check if we are pure metal with black albedo
     if (_DebugLightingMaterialValidatePureMetalColor.x > 0.0 && isMetal && value != 0.0)
     {
        return half4(_DebugLightingMaterialValidatePureMetalColor.yzw, 0);
     }

    // If we have a metallic object, don't complain about low albedo
    if (!isMetal && value < albedoMin)
    {
       return _DebugLightingMaterialValidateLowColor;
    }
    else if (value > albedoMax)
    {
        return _DebugLightingMaterialValidateHighColor;
    }
    else
    {
       return half4(unTouched, 0);
    }

    return half4(unTouched, 0);
}

//Metal Specular
half4 pbrMetalValidate(BSDFData bsdfData, bool isMetal, bool metallicWorkflow)
{
    half3 SpecularColor = bsdfData.fresnel0;
    half3 baseColor = bsdfData.diffuseColor;

    half value = dot(SpecularColor, float3(0.3333,0.3333,0.3333));

    if (!metallicWorkflow)
    {
        isMetal = value >= conductorMin;
    }

    half4 outColor = half4(Luminance(baseColor.xyz).xxx, 1.0f);

    if (value < conductorMin && isMetal)
    {
         outColor = _DebugLightingMaterialValidateLowColor;
    }
    else if (value > conductorMax)
    {
        outColor = _DebugLightingMaterialValidateHighColor;
    }
    else if (isMetal)
    {
         // If we are here we supposed the users want to have a metal, so check if we have a pure metal (black albedo) or not
        // if it is not a pure metal, highlight it
       if (_DebugLightingMaterialValidatePureMetalColor.x > 0.0)
       {
            outColor = dot(baseColor.xyz, half3(1,1,1)) == 0 ? outColor : half4(_DebugLightingMaterialValidatePureMetalColor.yzw, 0);
       }
    }

    return outColor;
}

#endif
