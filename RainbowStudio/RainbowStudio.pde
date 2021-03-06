/** 
 * By using LX Studio, you agree to the terms of the LX Studio Software
 * License and Distribution Agreement, available at: http://lx.studio/license
 *
 * Please note that the LX license is not open-source. The license
 * allows for free, non-commercial use.
 *
 * HERON ARTS MAKES NO WARRANTY, EXPRESS, IMPLIED, STATUTORY, OR
 * OTHERWISE, AND SPECIFICALLY DISCLAIMS ANY WARRANTY OF
 * MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR A PARTICULAR
 * PURPOSE, WITH RESPECT TO THE SOFTWARE.
 */

// ---------------------------------------------------------------------------
//
// Welcome to LX Studio! Getting started is easy...
// 
// (1) Quickly scan this file
// (2) Look at "Model" to define your model
// (3) Move on to "Patterns" to write your animations
// 
// ---------------------------------------------------------------------------

// Reference to top-level LX instance
heronarts.lx.studio.LXStudio lx;

static public final boolean enableArtNet = false;
static public final int ARTNET_PORT = 6454;
static public final String LED_CONTROLLER_IP = "192.168.1.63";

static public final int FULL_RAINBOW = 0;
static public final int SRIKANTH_PANEL = 1;
static public final int RAINBOW_PANEL = 2;
static public final int LARGE_PANEL = 3;

static public PApplet pApplet;

void setup() {
  // Processing setup, constructs the window and the LX instance
  size(800, 720, P3D);
  pApplet = this;
  
  int modelType = RAINBOW_PANEL; // RAINBOW_PANEL or FULL_RAINBOW
  
  LXModel model = buildModel(modelType);
  lx = new heronarts.lx.studio.LXStudio(this, model, MULTITHREADED);
  lx.ui.setResizable(RESIZABLE);
  
  if (modelType == RAINBOW_PANEL) {
    // Manually force the camera settings for a single panel.  A single panel is
    // way at the top of the world space and it is difficult to zoom in on it.
    float cameraY = RainbowBaseModel.innerRadius + 
        (RainbowBaseModel.outerRadius - RainbowBaseModel.innerRadius)/2.0;
    lx.ui.preview.setCenter(0.0, cameraY, 0.0);
    lx.ui.preview.setRadius(8.0);
  }
  
  // Output the model bounding box for reference.
  System.out.println("minx, miny: " + model.xMin + "," + model.yMin);
  System.out.println("maxx, maxy: " + model.xMax + "," + model.yMax);
  System.out.println("bounds size: " + (model.xMax - model.xMin) + "," +
    (model.yMax - model.yMin));
 
  // FULL_RAINBOW is
  // rectangle bounds size: 86.52052, 37.74478
  // Roughly, 87, 38 feet with led's per 2 inch (highest density) = 87*6, 38*6 = 522x228
  // 86.52052 * 6 = 519.12312
  // 37.74478 * 6 = 226.46868
  // NOTE(tracy): Using images at larger sizes reduces aliasing artifacts
  // when not resorting to averaging neighbors in the pattern code.

  if (enableArtNet) {
    if (modelType == FULL_RAINBOW) {
      RainbowModel3D.configureOutput(lx);
    } else if (modelType == SRIKANTH_PANEL) {
      SimplePanel.configureOutputSrikanthPanel(lx);
    } else if (modelType == RAINBOW_PANEL) {
      SimplePanel.configureOutputRainbowPanel(lx);
    }
  }

  // Dump our MIDI device names for reference.
  heronarts.lx.midi.LXMidiEngine midi = lx.engine.midi;
  for (heronarts.lx.midi.LXMidiOutput output : midi.outputs) {
    System.out.println(output.getName() + ": " + output.getDescription());
  }
}

void initialize(final heronarts.lx.studio.LXStudio lx, heronarts.lx.studio.LXStudio.UI ui) {
  // Add custom components or output drivers here
}

void onUIReady(heronarts.lx.studio.LXStudio lx, heronarts.lx.studio.LXStudio.UI ui) {
  // Add custom UI components here
}

void draw() {
  // All is handled by LX Studio
}

// Configuration flags
final static boolean MULTITHREADED = true;
final static boolean RESIZABLE = true;

// Helpful global constants
final static float INCHES = 1.0/12.0;
final static float IN = INCHES;
final static float FEET = 1.0;
final static float FT = FEET;
final static float CM = IN / 2.54;
final static float MM = CM * .1;
final static float M = CM * 100;
final static float METER = M;
