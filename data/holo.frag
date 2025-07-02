#version 150
uniform float thinFilmBase, roughness, alpha, lensDepth, farPlane, warpScale, noiseAmp, dispersion, time;
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
  vec3 eta=vec3(1.333,
                 1.333 + 0.007*dispersion,
                 1.333 + 0.015*dispersion);
  vec3 P=vPosV;
  float r=lensDepth;

  /* refract into the bubble */
  vec3 I0r=refract(I,N,1.0/eta.r);
  vec3 I0g=refract(I,N,1.0/eta.g);
  vec3 I0b=refract(I,N,1.0/eta.b);

  /* intersect inner surface and refract back to air */
  float tr=-dot(P,I0r)+sqrt(max(dot(P,I0r)*dot(P,I0r)-(dot(P,P)-r*r),0.0));
  float tg=-dot(P,I0g)+sqrt(max(dot(P,I0g)*dot(P,I0g)-(dot(P,P)-r*r),0.0));
  float tb=-dot(P,I0b)+sqrt(max(dot(P,I0b)*dot(P,I0b)-(dot(P,P)-r*r),0.0));
  vec3 Pr=P+I0r*tr, Pg=P+I0g*tg, Pb=P+I0b*tb;

  vec3 Nr=normalize(Pr), Ng=normalize(Pg), Nb=normalize(Pb);
  vec3 Rr=refract(I0r,Nr,eta.r);
  vec3 Rg=refract(I0g,Ng,eta.g);
  vec3 Rb=refract(I0b,Nb,eta.b);

  /* projection to far plane */
  float tBase=(-farPlane - P.z)/I.z;
  vec3 basePos=P+I*tBase;
  vec2 base=gl_FragCoord.xy/resolution;

  float tR=(-farPlane - Pr.z)/Rr.z;
  float tG=(-farPlane - Pg.z)/Rg.z;
  float tB=(-farPlane - Pb.z)/Rb.z;
  vec3 Qr=Pr+Rr*tR, Qg=Pg+Rg*tG, Qb=Pb+Rb*tB;

  vec2 diffR=(Qr.xy-basePos.xy)/(-farPlane);
  vec2 diffG=(Qg.xy-basePos.xy)/(-farPlane);
  vec2 diffB=(Qb.xy-basePos.xy)/(-farPlane);
  float w = warpScale*(farPlane-lensDepth)/farPlane;
  vec2 uvR=clamp(base + diffR*w,0.002,0.998);
  vec2 uvG=clamp(base + diffG*w,0.002,0.998);
  vec2 uvB=clamp(base + diffB*w,0.002,0.998);

  vec3 refr=vec3(texture(bgTex,uvR).r, texture(bgTex,uvG).g, texture(bgTex,uvB).b);
  vec3 film=irid(1.33,thinFilmBase,cv)*0.85;
  float width=mix(4.0,1.0,roughness*2.5);
  vec3 spec=F(cv,vec3(0.04))*pow(1.0-cv,width)*0.5;

  vec3 col=pow((refr+film+spec)/(refr+film+spec+1.0), vec3(1.0/2.2));
  fragColor=vec4(sat(col), alpha);
}
