#version 150
/* holographic shader
 * mode 0 = MIRROR (opaque glassy)
 * mode 1 = BUBBLE (transparent, refracts background)
 */

uniform float thinFilmBase;
uniform float roughness;
uniform int   mode;        /* 0 / 1 */
uniform float alpha;       /* final alpha (1.0 or 0.35) */

uniform sampler2D bgTex;   /* background texture */
uniform vec2  resolution;  /* viewport size */

in  vec3 vN;
in  vec3 vV;
out vec4 fragColor;

/* util */
float sat(float x){ return clamp(x,0.0,1.0); }
vec3  sat(vec3 v){ return clamp(v,0.0,1.0); }

/* Fresnel */
vec3 F_Schlick(float cosT, vec3 F0){
  return F0 + (1.0 - F0) * pow(1.0 - cosT, 5.0);
}

/* GGX */
float D_GGX(float c, float a){
  float a2 = a*a;
  float d  = c*c*(a2-1.0)+1.0;
  return a2 / (3.14159 * d * d + 1e-4);
}
float G_Smith(float cv, float cl, float a){
  float k=(a+1.0); k=k*k/8.0;
  return cv/(cv*(1.0-k)+k) * cl/(cl*(1.0-k)+k);
}

/* thin-film interference */
vec3 irid(float nFilm, float d, float cosT){
  const vec3 lam = vec3(0.681, 0.532, 0.450); /* µm */
  vec3 phi = 4.0 * 3.141592 * nFilm * d * cosT / lam;
  return 0.5 + 0.5 * cos(phi);
}

/* simple gradient env */
vec3 env(vec3 d){
  float t = sat(d.y*0.5 + 0.5);
  vec3 sky = mix(vec3(0.80,0.88,1.0), vec3(0.42,0.65,1.0), pow(t,1.6));
  return mix(vec3(0.18,0.18,0.20), sky, t);
}

void main(){
  vec3 N = normalize(vN);
  vec3 V = normalize(vV);
  vec3 I = -V;
  float cv = sat(dot(N,V));

  if(mode == 0){ /* MIRROR ------------------------------------------------ */
    vec3 eta = vec3(1.03,1.035,1.04);
    vec3 Rr = refract(I,N,1.0/eta.r);
    vec3 Rg = refract(I,N,1.0/eta.g);
    vec3 Rb = refract(I,N,1.0/eta.b);
    vec3 refr = vec3(env(Rr).r, env(Rg).g, env(Rb).b);

    float a = max(0.003, roughness*roughness);
    vec3  R = reflect(I,N);
    vec3  H = normalize(V+R);
    float cl = sat(dot(N,R));
    float ch = sat(dot(N,H));
    vec3  F = F_Schlick(sat(dot(H,V)), vec3(0.04));
    vec3  spec = env(R) * (D_GGX(ch,a) * G_Smith(cv,cl,a))
                 / max(4.0*cv*cl,1e-4) * F;

    vec3 col = refr + irid(1.4, thinFilmBase, cv) + spec;
    col = col / (col + 1.0);
    col = pow(col, vec3(1.0/2.2));
    fragColor = vec4(sat(col), 1.0);
    return;
  }

  /* BUBBLE -------------------------------------------------------------- */
  vec2 uv0 = gl_FragCoord.xy / resolution;
  vec2 ofs = N.xy * 0.03;               /* simple spherical lens */
  vec3 refrCol = vec3(texture(bgTex, uv0 + ofs*0.95).r,
                      texture(bgTex, uv0 + ofs*1.00).g,
                      texture(bgTex, uv0 + ofs*1.05).b);

  vec3 col = refrCol +
             irid(1.4, thinFilmBase, cv) * 0.8 +
             F_Schlick(cv, vec3(0.04))   * 0.2;

  col = col / (col + 1.0);
  col = pow(col, vec3(1.0/2.2));
  fragColor = vec4(sat(col), alpha);
}
