import processing.opengl.*;

PShape geom;
PShader holo;
PImage  bgImg;

float thin  = 1.0f;
float rough = 0.15f;
boolean useBox = true;
boolean useIco = false;

void settings(){ size(900, 650, P3D); }

void setup(){
  surface.setTitle("Holographic Iridescence Demo  –  <space>/<I>");
  noStroke();
  updateGeometry();

  holo = loadShader("holo.frag", "holo.vert");
  holo.set("thinFilmBase", thin);
  holo.set("roughness",   rough);

  bgImg = loadImage("windows.jpg");
  bgImg.resize(width, height);
}

void draw(){
  /* ---------- 0) 画面クリア（色＋デプス） ---------- */
  background(0);                 // ← ここで depth buffer もリセット

  /* ---------- 1) 背景画像（深度 OFF） ---------- */
  hint(DISABLE_DEPTH_TEST);      // ← 深度書き込み無効
  image(bgImg, 0, 0, width, height);
  hint(ENABLE_DEPTH_TEST);       // ← 以降 3D は通常深度

  /* ---------- 2) 3D オブジェクト ---------- */
  shader(holo);
  pushMatrix();
    translate(width*0.5f, height*0.55f);
    rotateY(frameCount*0.006f);
    rotateX(frameCount*0.004f);
    shape(geom);
  popMatrix();
  resetShader();

  /* ---------- 3) テキスト（最前面） ---------- */
  hint(DISABLE_DEPTH_TEST);
  fill(255); textSize(12);
  text("shape: "+(useBox?"BOX":useIco?"ICOSAHEDRON":"SPHERE")+
       "   |  <space>/<I>", 10, height-10);
  hint(ENABLE_DEPTH_TEST);
}

void keyPressed(){
  if(key==' '){ useBox=!useBox; useIco=false; updateGeometry(); }
  else if(key=='i'||key=='I'){ useIco=!useIco; useBox=false; updateGeometry(); }
}

void updateGeometry(){
  if(useBox)      geom=createShape(BOX,250);
  else if(useIco) geom=createIcosahedron(220);
  else            geom=createShape(SPHERE,220);
}

PShape createIcosahedron(float r){
  float t=(1+sqrt(5))/2, s=r/sqrt(1+t*t);
  float[][] v={
    {-s,t*s,0},{s,t*s,0},{-s,-t*s,0},{s,-t*s,0},
    {0,-s,t*s},{0,s,t*s},{0,-s,-t*s},{0,s,-t*s},
    {t*s,0,-s},{t*s,0,s},{-t*s,0,-s},{-t*s,0,s}
  };
  int[][] f={{0,11,5},{0,5,1},{0,1,7},{0,7,10},{0,10,11},
             {1,5,9},{5,11,4},{11,10,2},{10,7,6},{7,1,8},
             {3,9,4},{3,4,2},{3,2,6},{3,6,8},{3,8,9},
             {4,9,5},{2,4,11},{6,2,10},{8,6,7},{9,8,1}};
  PShape ico=createShape(); ico.beginShape(TRIANGLES); ico.noStroke();
  for(int[] tri:f){
    PVector a=new PVector(v[tri[0]][0],v[tri[0]][1],v[tri[0]][2]);
    PVector b=new PVector(v[tri[1]][0],v[tri[1]][1],v[tri[1]][2]);
    PVector c=new PVector(v[tri[2]][0],v[tri[2]][1],v[tri[2]][2]);
    PVector n=PVector.cross(PVector.sub(b,a),PVector.sub(c,a),null).normalize();
    ico.normal(n.x,n.y,n.z); ico.vertex(a.x,a.y,a.z);
    ico.normal(n.x,n.y,n.z); ico.vertex(b.x,b.y,b.z);
    ico.normal(n.x,n.y,n.z); ico.vertex(c.x,c.y,c.z);
  }
  ico.endShape(); return ico;
}
