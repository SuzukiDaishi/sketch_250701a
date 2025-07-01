#version 150
// -------- uniforms ----------
uniform float thinFilmBase;   // base thickness in μm (≈0.2-2.0)
uniform float roughness;      // perceptual roughness 0-1
uniform float uTime;          // seconds

in  vec3 vNormal;
in  vec3 vViewDir;
out vec4 fragColor;

// -------- utilities ----------
float sat(float x){ return clamp(x,0.0,1.0); }
vec3  sat(vec3 v){ return clamp(v,0.0,1.0); }
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123); }

// -------- Fresnel (Schlick) ----------
vec3 fresnelSchlick(float cosT, vec3 F0){
    return F0 + (1.0-F0)*pow(1.0-cosT,5.0);
}

// -------- GGX / Smith ----------
float D_GGX(float cosNH,float a){
    float a2=a*a;
    float d=cosNH*cosNH*(a2-1.0)+1.0;
    return a2/(3.14159*d*d + 1e-4);
}
float G_Smith(float cosNV,float cosNL,float a){
    float k=(a+1.0); k=k*k/8.0;
    return cosNV/(cosNV*(1.0-k)+k) * cosNL/(cosNL*(1.0-k)+k);
}

// -------- Thin-film iridescence (glTF KHR_materials_iridescence inspired) ----------
vec3 iridescence(float iorFilm, float thickness, float cosTheta){
// wavelengths sampled at 3 points (R/G/B) as in KHR spec
    const vec3 lambda = vec3(0.681,0.532,0.450); // μm
    // phase delay φ = 4π * n * d * cosθ / λ
    vec3 phi = 4.0 * 3.141592 * iorFilm * thickness * cosTheta / lambda;
    // constructive interference term  (simple cosine)
    vec3 refl = 0.5 + 0.5*cos(phi);
    return refl*refl; // square to soften
}

// -------- hand-rolled sky gradient ----------
vec3 sampleEnv(vec3 dir){
    float t = sat(dir.y*0.5+0.5);
    vec3 skyTop = vec3(0.42,0.65,1.0);
    vec3 skyMid = vec3(0.80,0.88,1.0);
    vec3 ground = vec3(0.18,0.18,0.20);
    return mix(ground, mix(skyMid, skyTop, pow(t,1.6)), t);
}

// -------- main ----------
void main(){
    vec3 N = normalize(vNormal);
    vec3 V = normalize(vViewDir);
    vec3 I = -V;

    // --- animated micro-noise on thickness ---------------
    float n = hash(gl_FragCoord.xy + uTime*10.0);
    float thickness = thinFilmBase + 0.15*(n-0.5);  // μm

    // --- dispersion refraction ---------------------------
    vec3 eta = vec3(1.03,1.035,1.04);
    vec3 Rr = refract(I,N,1.0/eta.r);
    vec3 Rg = refract(I,N,1.0/eta.g);
    vec3 Rb = refract(I,N,1.0/eta.b);
    vec3 colRefract = vec3(sampleEnv(Rr).r, sampleEnv(Rg).g, sampleEnv(Rb).b);

    // --- GGX reflection ----------------------------------
    vec3  R = reflect(I,N);
    vec3  envRef = sampleEnv(R);
    float alpha  = max(0.003, roughness*roughness);
    vec3  H      = normalize(V+R);
    float cosNV  = sat(dot(N,V));
    float cosNL  = sat(dot(N,R));
    float cosNH  = sat(dot(N,H));
    vec3  F      = fresnelSchlick(sat(dot(H,V)), vec3(0.04));
    float  D = D_GGX(cosNH,alpha);
    float  G = G_Smith(cosNV,cosNL,alpha);
    vec3 spec = envRef * (D*G) / max(4.0*cosNV*cosNL,1e-4) * F;

    // --- iridescence -------------------------------------
    vec3 irid = iridescence(1.4, thickness, cosNV); // glass-like film

    // --- Beer-Lambert absorption -------------------------
    vec3 sigmaA = vec3(0.03,0.04,0.05); // tweak for tint
    vec3 trans  = exp(-sigmaA*2.0/max(cosNV,0.05));
    colRefract *= trans;

    // --- final combine + ACES-ish tonemap ----------------
    vec3 color = colRefract + irid + spec;
    color = color / (color+vec3(1.0));   // simple tonemap
    color = pow(color, vec3(1.0/2.2));   // gamma

    fragColor = vec4(sat(color),1.0);
}
