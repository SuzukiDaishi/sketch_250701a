#version 150
/* Holographic thin-film shader (ASCII-only, noise-free) */

uniform float thinFilmBase;   // micrometers
uniform float roughness;      // 0-1 perceptual roughness

in  vec3 vN;
in  vec3 vV;
out vec4 fragColor;

/* util */
float sat(float x){ return clamp(x,0.0,1.0); }
vec3  sat(vec3 v){ return clamp(v,0.0,1.0); }

/* Fresnel */
vec3 fresnelSchlick(float cosT, vec3 F0){
  return F0 + (1.0-F0)*pow(1.0-cosT,5.0);
}

/* GGX / Smith */
float D_GGX(float cosNH,float a){
  float a2=a*a;
  float d=cosNH*cosNH*(a2-1.0)+1.0;
  return a2/(3.14159*d*d+1e-4);
}
float G_Smith(float cosNV,float cosNL,float a){
  float k=(a+1.0); k=k*k/8.0;
  return cosNV/(cosNV*(1.0-k)+k)*cosNL/(cosNL*(1.0-k)+k);
}

/* thin-film interference (3-wavelength) */
vec3 iridescence(float nFilm,float d,float cosT){
  const vec3 lambda = vec3(0.681,0.532,0.450); // micrometers
  vec3 phi = 4.0*3.141592*nFilm*d*cosT / lambda;
  return 0.5 + 0.5*cos(phi);
}

/* simple sky/ground environment */
vec3 envCol(vec3 d){
  float t=sat(d.y*0.5+0.5);
  vec3 skyTop=vec3(0.42,0.65,1.0);
  vec3 skyMid=vec3(0.80,0.88,1.0);
  vec3 ground=vec3(0.18,0.18,0.20);
  return mix(ground, mix(skyMid,skyTop,pow(t,1.6)), t);
}

void main(){
  vec3 N = normalize(vN);
  vec3 V = normalize(vV);
  vec3 I = -V;

  /* dispersion refraction */
  vec3 eta = vec3(1.03,1.035,1.04);
  vec3 Rr = refract(I,N,1.0/eta.r);
  vec3 Rg = refract(I,N,1.0/eta.g);
  vec3 Rb = refract(I,N,1.0/eta.b);
  vec3 refr = vec3(envCol(Rr).r, envCol(Rg).g, envCol(Rb).b);

  /* GGX reflection */
  float a=max(0.003, roughness*roughness);
  vec3  R = reflect(I,N);
  vec3  H = normalize(V+R);
  float cv=sat(dot(N,V));
  float cl=sat(dot(N,R));
  float ch=sat(dot(N,H));
  vec3  F = fresnelSchlick(sat(dot(H,V)), vec3(0.04));
  vec3  spec = envCol(R)*(D_GGX(ch,a)*G_Smith(cv,cl,a)) /
               max(4.0*cv*cl,1e-4) * F;

  /* thin-film */
  vec3 irid = iridescence(1.4, thinFilmBase, cv);

  /* Beer absorption */
  vec3 trans = exp(-vec3(0.03,0.04,0.05)*2.0/max(cv,0.05));
  refr *= trans;

  /* combine + tone-map */
  vec3 col = refr + irid + spec;
  col = col/(col+1.0);
  col = pow(col,vec3(1.0/2.2));

  fragColor = vec4(sat(col),1.0);
}
