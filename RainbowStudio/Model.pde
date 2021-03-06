import java.util.List;

static public final int LEDS_PER_UNIVERSE = 170;

LXModel buildModel(int modelType) {
  // A three-dimensional grid model
  // return new GridModel3D();
  if (modelType == FULL_RAINBOW) {
    return new RainbowModel3D();
  } else if (modelType == SRIKANTH_PANEL) {
    return new SimplePanel();
  } else if (modelType == RAINBOW_PANEL) {
    return new RainbowModel3D(1);
  } else if (modelType == LARGE_PANEL) {
    return new SimplePanel(100, 50);
  } else {
    return null;
  }
}

public static class GridModel3D extends LXModel {
  
  public final static int SIZE = 20;
  
  public GridModel3D() {
    super(new Fixture());
  }
  
  public static class Fixture extends LXAbstractFixture {
    Fixture() {
      for (int z = 0; z < SIZE; ++z) {
        for (int y = 0; y < SIZE; ++y) {
          for (int x = 0; x < SIZE; ++x) {
            addPoint(new LXPoint(x, y, z));
          }
        }
      }
    }
  }
}

/*
 * Abstract class for tracking things common to our models.
 * These can be used by the Patterns so that a pattern can
 * work on either the full rainbow or some subset of LEDs
 * for test panels.  Also, knowing the radius and arc in
 * degrees is important for some patterns.
 *
 * TODO(tracy): Maybe it would be better to use the Metrics
 * class that the 2D GridModel uses.  But their standard
 * pixel coordinate system is 0,0 top left and max_x,max_y on
 * the bottom right. It might be better to migrate to that
 * coordinate system so some of the existing patterns in
 * the LX library work.  It requires rewriting our existing
 * patterns. Although, Processing uses this coordinate space so
 * probably less confusing to keep this.
 */
public static abstract class RainbowBaseModel extends LXModel {

  public RainbowBaseModel(LXFixture fixture) {
    super(fixture);
  }
  public int pointsWide;
  public int pointsHigh;
  public float thetaStart;
  public float thetaFinish;
  

  // From CAD drawings.  Note that these numbers are off the mechanical dimensions, so
  // there might still be some small adjustments.  Also, the variables below have the
  // theta start and theta finish slightly adjusted so that the model generates the
  // proper 12600 leds.
  // Starts at 9.3165082 degrees
  // arc is 161.3669836 degrees
  // end point at 170.6834918
  // radius is 36.9879  Based on a 73' chord of a circle with a perpendicular height to
  // the circle of 31'.

  static public float radiusInc = 2.75 / 12.0;
  static public float innerRadius = 36.9879;
  static public float outerRadius = 0.0;
  static public float rainbowThetaStart = 9.41; //9.4165082;
  static public float rainbowThetaFinish = 170.53; //170.5383491;
  static public float rainbowPointsPerRow = 420.0;
  static public float rainbowThetaInc = (rainbowThetaFinish-rainbowThetaStart) / rainbowPointsPerRow;
  static public float radialPixelDensity = 2.75; // 2.75 inches between pixels radially
  static public float innerRadiusPixelDensity = 2.5;
  static public float outerRadiusPixelDensity = 3.0;
  static public float pixelsPerFoot = 6.0;  // Based on 2" pixel density.
}

/*
 * A Generic 2D grid model.  Defaults to dimensions of Srikanth's test panel.  Also,
 * configureOutput is only implemented for Srikanth's specific wiring.  The Animated GIF
 * pattern currently uses a 100x50 animated gif of the game of life.  The Animated GIF
 * pattern will scale images to fit the points, but doesn't make sense for game of
 * life so it will run but not look right if not run on the LARGE_PANEL modelType in
 * buildModel (can be specified at the top of RainbowStudio.pde).
 */
public static class SimplePanel extends RainbowBaseModel {
  
  public static final int LED_WIDTH = 10;  // Defaults based on Srikanth's test panel
  public static final int LED_HEIGHT = 5;
  public static final int UNIVERSE = 0;
  
  public SimplePanel(int width, int height) {
      super(new Fixture(width, height));
      pointsWide = width;
      pointsHigh = height;
  }
  
  public SimplePanel() {
    super(new Fixture());
    pointsWide = LED_WIDTH;
    pointsHigh = LED_HEIGHT;
  }
  
  public static class Fixture extends LXAbstractFixture {
    Fixture() {
      this(LED_WIDTH, LED_HEIGHT);
    }
    
    Fixture(int width, int height) {
      // Determine the size in 3D space with this factor.  1.0 looks a bit
      // cramped, especially on the larger panel.  This should eventually account
      // for the physical led spacing on a given panel.
      float worldScaleFactor = 1.5;
      float worldWidth = width/worldScaleFactor;
      float worldHeight = height/worldScaleFactor;
      int numRows = height;
      int numCols = width;
      float widthPerColumn = worldWidth / numCols;
      float heightPerRow = worldHeight / numRows;
      for (int rowNum = 0; rowNum < numRows; rowNum++) {
        for (int colNum = 0; colNum < numCols; colNum++) {
          // Centered around x=0.0 in 3D space just like the rainbow.
          float x = colNum * widthPerColumn - worldWidth/2.0;
          float y = rowNum * heightPerRow;
          float z = 0.0;
          addPoint(new LXPoint(x, y, z));
        }
      }
    }
  }
  
  public static void configureOutputRainbowPanel(LX lx) {
    int pointsWide = ((RainbowBaseModel)lx.model).pointsWide;
    int pointsHigh = ((RainbowBaseModel)lx.model).pointsHigh;
    int maxColNum = pointsWide - 1;

    int currentUniverse = 0;
    List<ArtNetDatagram> datagrams = new ArrayList<ArtNetDatagram>();
    int[] dmxChannelsForUniverse = new int[LEDS_PER_UNIVERSE];
    for (int globalLedPos = 0; globalLedPos < pointsWide*pointsHigh; globalLedPos++) {
      int colNumFromRight = globalLedPos / pointsHigh;
      int colNumFromLeft = maxColNum - colNumFromRight;
      int rowNumFromBottom;
      if (colNumFromRight % 2 == 0)
        rowNumFromBottom = globalLedPos % pointsHigh;
      else
        rowNumFromBottom = pointsHigh - globalLedPos % pointsHigh - 1;

      // Chunk by 170 for each universe.
      int universeLedPos = globalLedPos % LEDS_PER_UNIVERSE;
      int pointIndex = rowNumFromBottom * pointsWide + colNumFromLeft;
      // System.out.println(globalLedPos + " colNum:" +colNumFromLeft + " rowNum:" + rowNumFromBottom + " pointIndex: " + pointIndex);
      dmxChannelsForUniverse[universeLedPos] = pointIndex;
      // Either we are on DMX channel 170, or we are at the end of the panel.
      if (universeLedPos == LEDS_PER_UNIVERSE - 1 || globalLedPos == pointsWide * pointsHigh - 1) {
        ArtNetDatagram datagram = new ArtNetDatagram(dmxChannelsForUniverse, currentUniverse);
        try {
          datagram.setAddress(LED_CONTROLLER_IP).setPort(ARTNET_PORT);
        } catch (java.net.UnknownHostException uhex) {
          System.out.println("ERROR! UnknownHostException while configuring ArtNet: " + LED_CONTROLLER_IP);
        }
        datagrams.add(datagram);
        currentUniverse++;
        dmxChannelsForUniverse = new int[LEDS_PER_UNIVERSE];
      }
    }
    // Now we have datagrams bound to all of our LEDs.  Create a LXDatagramOutput and register
    // all datagrams with it.
    try {
      LXDatagramOutput datagramOutput = new LXDatagramOutput(lx);
      for (ArtNetDatagram datagram : datagrams) {
        datagramOutput.addDatagram(datagram);
      }
      // Finally, register our LXDatagramOutput with the engine.
      lx.engine.output.addChild(datagramOutput);
    } catch (java.net.SocketException sex) {
      // This can happen for example if we run out of file handles because some code is opening
      // files without closing them.
      System.out.println("ERROR! SocketException when initializing DatagramOutput: " + sex.getMessage());
    }
  }

  /*
   * Based on photo from Srikanth. 0 led on his board is bottom right. 149 led is
   * on top left.  The wiring starts from right to left and then alternates to
   * left to right moving up the rows.  The points in 3D space start with
   * 0 at the bottom left. y=1, x=0 also starts from the left side (direction does not
   * alternate like the wiring)
   * TODO(tracy): This only works for Srikanth's specific wiring.
   */
  public static void configureOutputSrikanthPanel(LX lx) {
    int pointsWide = ((RainbowBaseModel)lx.model).pointsWide;
    int pointsHigh = ((RainbowBaseModel)lx.model).pointsHigh;
    int[] ledWiring = new int[LEDS_PER_UNIVERSE];
    int currentUniverse = 0;
    List<ArtNetDatagram> datagrams = new ArrayList<ArtNetDatagram>();
    
    // For each Point, we want to figure out which LED on the physical strip
    // corresponds to the 3D point.  We are technically mapping to DMX channels
    // here, but this is simple wiring on one universe.
    for (int rowNum = 0; rowNum < pointsWide; rowNum++) {
      for (int colNum = 0; colNum < pointsHigh; colNum++) {
        // Points are stored in a 1D array.
        int pointIndex = rowNum * pointsWide + colNum;
        // NOTE(tracy): For Srikanth's home wiring diagram;
        // The end of the leds is at (rowNum-1, 0)
        // First row, third row, etc. goes from right to left.
        // Second row, fourth row goes from left to right.
        // (i.e. the wiring snakes back and forth).
        // Point(row0, col0) (bottom left in 3d space) should be 
        //     led position 9 in first row (0-based index). i.e. LED_WIDTH - colNum
        // Point(row1, col0) LEDs start going left to right so it is LED 10
        // Point(row1, col1) is LED 11 i.e. LED_WIDTH * rowNum + colNum (generic solution)
        // Point(row2, col0) is LED 29 i.e. LED_WIDTH * (rowNum + 1) - 1
        // Point(row2, col1) is LED 28 i.e. LED_WIDTH * (rowNum + 1) - 2
        //     generic solution for 0,2,4 is LED_WIDTH * (rowNum + 1) - 1 - colNum
        int ledPos = 0;
        if (rowNum % 2 == 0) {
          ledPos = pointsWide * (rowNum + 1) - 1 - colNum;
        } else {
          ledPos = pointsWide * rowNum + colNum;
        }
        // ledWiring should only by chunks of 170 LEDs.  ledPos above is the global led
        // position. Here we mod by 170 to produce a universe-local led number.  When
        // we see the last LED in a universe chunk we will build a datagram and increase
        // the current universe number.  If it is the last point of the grid, we also
        // build the final datagram (after which the for loop ends).
        ledPos = ledPos % LEDS_PER_UNIVERSE;
        //System.out.println("pointIndex: " + pointIndex + " rowNum " + rowNum + " colNum " + colNum + " ledChannel: " + ledPos +  " univ: " + currentUniverse);
        ledWiring[ledPos] = pointIndex;
        // Either we are on DMX channel 170, or we are at the end of the panel.
        if (ledPos == LEDS_PER_UNIVERSE - 1 || pointIndex == pointsWide * pointsHigh - 1) {
          ArtNetDatagram datagram = new ArtNetDatagram(ledWiring, currentUniverse);
          try {
             datagram.setAddress(LED_CONTROLLER_IP).setPort(ARTNET_PORT);
          } catch (java.net.UnknownHostException uhex) {
             System.out.println("ERROR! UnknownHostException while configuring ArtNet: " + LED_CONTROLLER_IP);
          }
          datagrams.add(datagram);
          currentUniverse++;
          ledWiring = new int[LEDS_PER_UNIVERSE];
        }
      }
    }   
    
    // Now we have datagrams bound to all of our LEDs.  Create a LXDatagramOutput and register
    // all datagrams with it.  
    try {
      LXDatagramOutput datagramOutput = new LXDatagramOutput(lx);
      for (ArtNetDatagram datagram : datagrams) {
        datagramOutput.addDatagram(datagram);
      }
      // Finally, register our LXDatagramOutput with the engine.
      lx.engine.output.addChild(datagramOutput);
    } catch (java.net.SocketException sex) {
      // This can happen for example if we run out of file handles because some code is opening
      // files without closing them.
      System.out.println("ERROR! SocketException when initializing DatagramOutput: " + sex.getMessage());
    }
    
  }
}

public static class RainbowModel3D extends RainbowBaseModel {
  static public final int LED_WIDTH = 420;
  static public final int LED_HEIGHT = 30;
  
  public RainbowModel3D() {
    this(28);
  }
    
  public RainbowModel3D(int numPanels) {
    super(new Fixture(numPanels));
    float arc = numPanels * RainbowBaseModel.rainbowThetaInc * 15.0;
    this.thetaStart = 90.0 - arc/2.0;
    this.thetaFinish = 90.0 + arc/2.0;
    pointsWide = numPanels * 15;
    pointsHigh = 30;
  }
  
  public static class Fixture extends LXAbstractFixture {
    Fixture(int numPanels) {
      float arc = numPanels * RainbowBaseModel.rainbowThetaInc * 15.0;
      float thetaStart = 90.0 - arc/2.0;
      float thetaFinish = 90.0 + arc/2.0;
      int ledsHigh = 30;
      float z = 0;
      float r = innerRadius;  // Feet
      int ledCount = 0;
      for (int rowNum = 0; rowNum < ledsHigh; rowNum++) {
        for (float angle = thetaFinish; angle > thetaStart; angle -= RainbowBaseModel.rainbowThetaInc) {
          double x = r * cos(radians(angle));
          double y = r * sin(radians(angle));
          addPoint(new LXPoint(x, y, z));
          ledCount++;
        }
        r += radiusInc;  // Each strip is separated by 2.75 inches.  r is in units of feet.
      }
      outerRadius = r;
      System.out.println("thetaStart: " + thetaStart);
      System.out.println("thetaFinish: " + thetaFinish);
      System.out.println("ledCount: " + ledCount);
      System.out.println("outerRadius: " + outerRadius);
    }
  }
  
  /*
   * Determine point to LED mapping.  This code is placed inside the model class because
   * it is very tightly coupled to the model generation.  For now, we will just put 170 pixel
   * chunks into each ArtNetDatagram, increasing the universe number each time.
   * TODO(tracy): Fix this for final wiring.  Maybe it will be similar to RainbowPanel?
   * TODO(tracy): It would be nice to be able to configure this in the UI.  We would need to
   * call disable on the LXDatagramOutput, remove it, and then rebuild with the new IP/Port.
   */
  public static void configureOutput(LX lx) {
    List<ArtNetDatagram> datagrams = new ArrayList<ArtNetDatagram>();
    int pointsPerUniverse = 170;
    int numPoints = lx.model.points.length;
    int numUniverses = numPoints / pointsPerUniverse;
    
    for (int currentUniverse = 0; currentUniverse < numUniverses; currentUniverse++) {
      int pointOffset = currentUniverse * pointsPerUniverse;
      // This will be an array 170 point indices (aka LED id's)
      int[] pIndicesForUniverse = new int[pointsPerUniverse];
      // Here 'i' will take on the range of values of the global point index values.  For example,
      // we want to put point indices (aka LED id's) 170-339 into an array, which lets
      // the Datagram know which points (aka LED's) it is responsible for sending
      for (int i = pointOffset; i < pointOffset + pointsPerUniverse; i++) {
        pIndicesForUniverse[i - pointOffset] = i;
      }
      ArtNetDatagram datagram = new ArtNetDatagram(pIndicesForUniverse, currentUniverse);
      try {
        datagram.setAddress(LED_CONTROLLER_IP).setPort(ARTNET_PORT);
      } catch (java.net.UnknownHostException uhex) {
        System.out.println("ERROR! UnknownHostException while configuring ArtNet: " + 
        LED_CONTROLLER_IP);
      }
      datagrams.add(datagram);
    }
    
    // Now we have datagrams bound to all of our LEDs.  Create a LXDatagramOutput and register
    // all datagrams with it.  
    try {
      LXDatagramOutput datagramOutput = new LXDatagramOutput(lx);
      for (ArtNetDatagram datagram : datagrams) {
        datagramOutput.addDatagram(datagram);
      }
      // Finally, register our LXDatagramOutput with the engine.
      lx.engine.output.addChild(datagramOutput);
    } catch (java.net.SocketException sex) {
      // This can happen for example if we run out of file handles because some code is opening
      // files without closing them.
      System.out.println("ERROR! SocketException when initializing DatagramOutput: " + sex.getMessage());
    }
  }
}
