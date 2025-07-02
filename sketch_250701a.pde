import processing.opengl.*;

PShape geom;
PShader holo;
PImage  bg;

/* parameters */
float thin = 1.0f, rough = 0.12f, alpha = 0.35f;
float depth = 2.0f, farP = 20.0f, warpScale = 1.5f, noiseAmp = 0.10f;
float dispersion = 1.0f;
boolean useBox = true, useIco = false;

void settings(){ size(900,650,P3D); }

void setup(){
  surface.setTitle("Warp Bubble  –  SPACE I  A/Z T/G D/F W/S Y/H U/J R/E");
  noStroke(); updateGeom();
  bg = loadImage("windows.jpg"); bg.resize(width,height);

  holo = loadShader("holo.frag","holo.vert");
  holo.set("bgTex",bg); holo.set("resolution",(float)width,(float)height);
}

void draw(){
  background(0); hint(DISABLE_DEPTH_TEST); image(bg,0,0); hint(ENABLE_DEPTH_TEST);

  holo.set("thinFilmBase",thin);
  holo.set("roughness",rough);
  holo.set("alpha",alpha);
  holo.set("lensDepth",depth);
  holo.set("farPlane",farP);
  holo.set("warpScale",warpScale);
  holo.set("noiseAmp",noiseAmp);
  holo.set("dispersion",dispersion);
  holo.set("time",millis()*0.001f);

  beginBlend(); shader(holo);
  pushMatrix();
    translate(width*0.5f, height*0.55f);
    rotateY(frameCount*0.006f); rotateX(frameCount*0.004f);
    shape(geom);
  popMatrix(); resetShader(); endBlend();

  hud();
}

void beginBlend(){ PGL g=beginPGL(); g.enable(PGL.BLEND);
  g.blendFunc(PGL.SRC_ALPHA,PGL.ONE_MINUS_SRC_ALPHA); endPGL(); }
void endBlend(){ PGL g=beginPGL(); g.disable(PGL.BLEND); endPGL(); }

void hud(){
  hint(DISABLE_DEPTH_TEST);
  fill(255); textSize(12);
  String sh=useBox?"BOX":useIco?"ICO":"SPHERE";
  text(String.format(
    "%s  α=%.2f thin=%.2fµm depth=%.2f far=%.0f scale=%.1f noise=%.2f rough=%.2f disp=%.1f",
    sh,alpha,thin,depth,farP,warpScale,noiseAmp,rough,dispersion),10,height-10);
  hint(ENABLE_DEPTH_TEST);
}

void keyPressed(){
  switch(key){
    case ' ': useBox=!useBox; useIco=false; updateGeom(); break;
    case 'i': case 'I': useIco=!useIco; useBox=false; updateGeom(); break;
    case 'a': case 'A': alpha = constrain(alpha+0.05f,0f,1f); break;
    case 'z': case 'Z': alpha = constrain(alpha-0.05f,0f,1f); break;
    case 't': case 'T': thin  = constrain(thin +0.05f,0.3f,1.5f); break;
    case 'g': case 'G': thin  = constrain(thin -0.05f,0.3f,1.5f); break;
    case 'd': case 'D': depth = constrain(depth+0.15f,1f,4f); break;
    case 'f': case 'F': depth = constrain(depth-0.15f,1f,4f); break;
    case 'w': case 'W': farP  = constrain(farP +2f,8f,40f); break;
    case 's': case 'S': farP  = constrain(farP -2f,8f,40f); break;
    case 'y': case 'Y': warpScale=constrain(warpScale+0.2f,0.5f,4f); break;
    case 'h': case 'H': warpScale=constrain(warpScale-0.2f,0.5f,4f); break;
    case 'u': case 'U': noiseAmp = constrain(noiseAmp+0.02f,0f,0.3f); break;
    case 'j': case 'J': noiseAmp = constrain(noiseAmp-0.02f,0f,0.3f); break;
    case 'k': case 'K': dispersion = constrain(dispersion+0.1f,0f,2f); break;
    case 'l': case 'L': dispersion = constrain(dispersion-0.1f,0f,2f); break;
    case 'r':           rough = constrain(rough+0.02f,0f,0.4f); break;
    case 'e':           rough = constrain(rough-0.02f,0f,0.4f); break;
    case 'p': case 'P': saveFrame("frame-####.png"); break;
  }
}

void updateGeom(){
  if(useBox)      geom=createShape(BOX,250);
  else if(useIco) geom=createIcosahedron(220);
  else            geom=createShape(SPHERE,250);
}

PShape createIcosahedron(float r){
  float t=(1+sqrt(5))/2, s=r/sqrt(1+t*t);
  float[][] v={{-s,t*s,0},{s,t*s,0},{-s,-t*s,0},{s,-t*s,0},
               {0,-s,t*s},{0,s,t*s},{0,-s,-t*s},{0,s,-t*s},
               {t*s,0,-s},{t*s,0,s},{-t*s,0,-s},{-t*s,0,s}};
  int[][] f={{0,11,5},{0,5,1},{0,1,7},{0,7,10},{0,10,11},
             {1,5,9},{5,11,4},{11,10,2},{10,7,6},{7,1,8},
             {3,9,4},{3,4,2},{3,2,6},{3,6,8},{3,8,9},
             {4,9,5},{2,4,11},{6,2,10},{8,6,7},{9,8,1}};
  PShape ico=createShape(); ico.beginShape(TRIANGLES);
  ico.noStroke();
  for(int[] T:f){
    PVector a=new PVector(v[T[0]][0],v[T[0]][1],v[T[0]][2]);
    PVector b=new PVector(v[T[1]][0],v[T[1]][1],v[T[1]][2]);
    PVector c=new PVector(v[T[2]][0],v[T[2]][1],v[T[2]][2]);
    PVector n=PVector.cross(PVector.sub(b,a),PVector.sub(c,a),null).normalize();
    ico.normal(n.x,n.y,n.z); ico.vertex(a.x,a.y,a.z);
    ico.normal(n.x,n.y,n.z); ico.vertex(b.x,b.y,b.z);
    ico.normal(n.x,n.y,n.z); ico.vertex(c.x,c.y,c.z);
  }
  ico.endShape(); return ico;
}
