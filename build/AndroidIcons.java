// Run with: java build/AndroidIcons.java android/app/src/main/res
// Standalone original Cloud Files launcher graphics; no binary files in Git.
import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import java.io.File;

public class AndroidIcons {
  static void make(File out, int px, boolean foreground, boolean round) throws Exception {
    BufferedImage img = new BufferedImage(px,px,BufferedImage.TYPE_INT_ARGB);
    Graphics2D g = img.createGraphics();
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);
    g.setRenderingHint(RenderingHints.KEY_RENDERING,RenderingHints.VALUE_RENDER_QUALITY);
    g.scale(px/256.0, px/256.0);
    Color blue = new Color(23,105,224);
    Color white = Color.WHITE;
    if (!foreground) {
      g.setColor(blue);
      if(round) g.fill(new Ellipse2D.Double(0,0,256,256));
      else g.fill(new RoundRectangle2D.Double(0,0,256,256,60,60));
    }
    // Logo sits within Android adaptive icon's safe zone.
    double ox=0,oy=0;
    g.setColor(white);
    g.fill(new Ellipse2D.Double(74+ox,87+oy,76,76));
    g.fill(new Ellipse2D.Double(114+ox,70+oy,76,85));
    g.fill(new Ellipse2D.Double(151+ox,96+oy,47,57));
    g.fill(new RoundRectangle2D.Double(66+ox,118+oy,132,49,22,22));
    // A contrasting folder mark emphasizes local file access.
    g.setColor(new Color(14,68,163));
    g.fill(new RoundRectangle2D.Double(83,132,104,54,10,10));
    g.fill(new RoundRectangle2D.Double(83,125,48,19,8,8));
    g.setColor(new Color(216,235,255));
    g.fill(new RoundRectangle2D.Double(94,148,82,29,6,6));
    g.dispose();
    out.getParentFile().mkdirs();
    ImageIO.write(img,"png",out);
  }
  public static void main(String[] args) throws Exception {
    if(args.length != 1) throw new IllegalArgumentException("Expected Android resources path");
    File res=new File(args[0]);
    String[] folders={"mipmap-mdpi","mipmap-hdpi","mipmap-xhdpi","mipmap-xxhdpi","mipmap-xxxhdpi"};
    int[] sizes={48,72,96,144,192};
    for(int i=0;i<folders.length;i++){
      File dir=new File(res,folders[i]);
      make(new File(dir,"ic_launcher.png"),sizes[i],false,false);
      make(new File(dir,"ic_launcher_round.png"),sizes[i],false,true);
      // Foreground uses standard 108dp adaptive viewport.
      make(new File(dir,"ic_launcher_foreground.png"),(int)(sizes[i]*108.0/48),true,false);
    }
    File adaptive=new File(res,"mipmap-anydpi-v26");
    adaptive.mkdirs();
    String xml="<?xml version=\"1.0\" encoding=\"utf-8\"?><adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\"><background android:drawable=\"@color/cloud_files_icon_background\"/><foreground android:drawable=\"@mipmap/ic_launcher_foreground\"/></adaptive-icon>";
    java.nio.file.Files.writeString(new File(adaptive,"ic_launcher.xml").toPath(),xml);
    java.nio.file.Files.writeString(new File(adaptive,"ic_launcher_round.xml").toPath(),xml);
    File values=new File(res,"values");
    values.mkdirs();
    java.nio.file.Files.writeString(new File(values,"cloud_files_colors.xml").toPath(),
      "<?xml version=\"1.0\" encoding=\"utf-8\"?><resources><color name=\"cloud_files_icon_background\">#1769E0</color></resources>");
    System.out.println("Cloud Files adaptive, round, and fixed launcher icons generated.");
  }
}
