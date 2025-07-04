#version 150
uniform float thinFilmBase, roughness, alpha, lensDepth, farPlane, warpScale, noiseAmp, time;
uniform sampler2D bgTex;
uniform vec2 resolution;

in  vec3 vN, vV, vPosV;
out vec4 fragColor;

/* helpers */
float sat(float x){return clamp(x,0.0,1.0);} vec3 sat(vec3 v){return clamp(v,0.0,1.0);}
vec3  F(float c,vec3 f0){return f0+(1.0-f0)*pow(1.0-c,5.0);}
vec3  irid(float n,float d,float c){
  const vec3 L=vec3(0.681,0.532,0.450);
  return 0.5+0.5*cos(4.0*3.141592*n*d*c/L);
}
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
vec2 curl(vec2 p){float e=.001;
  return vec2(h(p+vec2(0,e))-h(p-vec2(0,e)),
              h(p+vec2(e,0))-h(p-vec2(e,0)));}

void main(){
  vec3 N = normalize(vN + vec3(curl(gl_FragCoord.xy*0.006+time*0.3)*noiseAmp,0));
  vec3 V = normalize(vV); vec3 I=-V; float cv=sat(dot(N,V));

  /* dispersion directions */
  vec3 eta=vec3(1.333,1.340,1.348);
  vec3 Rr=refract(I,N,1.0/eta.r);
  vec3 Rg=refract(I,N,1.0/eta.g);
  vec3 Rb=refract(I,N,1.0/eta.b);

  vec3 P=vPosV; float r=lensDepth;
  float tr=-dot(P,Rr)+sqrt(max(dot(P,Rr)*dot(P,Rr)-(dot(P,P)-r*r),0));
  float tg=-dot(P,Rg)+sqrt(max(dot(P,Rg)*dot(P,Rg)-(dot(P,P)-r*r),0));
  float tb=-dot(P,Rb)+sqrt(max(dot(P,Rb)*dot(P,Rb)-(dot(P,P)-r*r),0));
  vec3 Qr=P+Rr*tr, Qg=P+Rg*tg, Qb=P+Rb*tb;

  /* screen projection */
  vec2 base=(I.xy/I.z)*(-farPlane); base=base*0.5/resolution.y+0.5;
  vec2 uvR=clamp(base + (Qr.xy/Qr.z - I.xy/I.z)*warpScale*0.5,0.002,0.998);
  vec2 uvG=clamp(base + (Qg.xy/Qg.z - I.xy/I.z)*warpScale*0.5,0.002,0.998);
  vec2 uvB=clamp(base + (Qb.xy/Qb.z - I.xy/I.z)*warpScale*0.5,0.002,0.998);

  vec3 refr=vec3(texture(bgTex,uvR).r, texture(bgTex,uvG).g, texture(bgTex,uvB).b);
  vec3 film=irid(1.33,thinFilmBase,cv)*0.85;
  vec3 spec=F(cv,vec3(0.04))*0.15;

  vec3 col=pow((refr+film+spec)/(refr+film+spec+1.0), vec3(1.0/2.2));
  fragColor=vec4(sat(col), alpha);
}
