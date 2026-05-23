'------------------------------------------------------------------------------
' Boing Ball for PicoMite HDMI/USB
' A small homage to the Amiga and to the Boing Ball demo shown at CES 1984.
' Rebuilt in MMBasic for PicoMite HDMI/USB firmware (RP2350).
'
' Original Amiga demo programming: Dale Luck and Robert J. Mical (R.J.).
' PicoMite adaptation: Marcos LM 2026-04, with iterative help from an AI coding assistant.
' License: MIT
'------------------------------------------------------------------------------

OPTION DEFAULT NONE


'------------------------------------------------------------------------------
' File: core/10_state.bas
' Responsibility:
' - Declare shared scene, ball, palette, audio, and DRAW3D constants.
' - Own the global runtime state and shared arrays used by all modules.
'------------------------------------------------------------------------------

' Maintained display contract: the runtime now requires MODE 5.

' Scene geometry and grid layout.
CONST SCENE_MAX_X% = 319
CONST SCENE_MAX_Y% = 215
CONST SCENE_VERTICAL_MARGIN% = 20
CONST GRID_LINE_COUNT% = 50
CONST GRID_FLOOR_EDGE_LINE_COUNT% = 5
CONST GRID_WALL_MIN_X_SCENE% = 40
CONST GRID_WALL_MAX_X_SCENE% = 280
CONST GRID_CELL_STEP_SCENE% = 16
CONST GRID_FLOOR_TOP_Y_SCENE% = 192
CONST GRID_FLOOR_RAY_START_X_SCENE% = 10
CONST GRID_FLOOR_RAY_STEP_X_SCENE% = 20

' Ball motion, projection, and shadow tuning.
CONST BALL_RADIUS_SCENE% = 56
CONST BALL_START_X_SCENE% = 160
CONST BALL_START_Y_SCENE% = 108
CONST BALL_SIDE_BOUNCE_MARGIN_X_SCENE% = 50
CONST BALL_MIN_X_SCENE% = BALL_SIDE_BOUNCE_MARGIN_X_SCENE%
CONST BALL_MAX_X_SCENE% = SCENE_MAX_X% - BALL_SIDE_BOUNCE_MARGIN_X_SCENE%
CONST BALL_FLOOR_BOUNCE_Y_SCENE% = 156
CONST BALL_START_VX_SCENE% = 2
CONST BALL_START_VY_SCENE% = -10
CONST BALL_GRAVITY_SCENE% = 1
CONST BALL_FLOOR_BOUNCE_VY_SCENE% = -13
CONST BALL_VERTICAL_STEP_SCALE! = 0.50
CONST BALL_VERTICAL_ARC_GAIN! = 0.95

CONST BALL_MESH_LAT_LINES% = 9
CONST BALL_MESH_BANDS% = 8
CONST BALL_MESH_SEGMENTS% = 18
CONST BALL_MESH_LAT_START_DEG! = -80.0
CONST BALL_MESH_LAT_SWEEP_DEG! = 160.0
CONST BALL_MESH_YAW_DEG% = 37
CONST BALL_MESH_PITCH_DEG% = 0
CONST BALL_MESH_ROLL_DEG% = 20
CONST BALL_MESH_LON_OFFSET_DEG% = 13
CONST BALL_MESH_VIEW_Z_SIGN% = -1
CONST BALL_DRAW3D_OBJECT% = 1
CONST BALL_DRAW3D_CAMERA% = 1
CONST BALL_DRAW3D_VIEWPLANE% = 800
CONST BALL_DRAW3D_Z% = 800
CONST BALL_DEPTH_MAX_OFFSET% = 240
CONST BALL_DEPTH_STEP! = 6.0
CONST BALL_SIM_STEP_MS% = 20
CONST BALL_DRAW3D_SPIN_DEG! = 5.0
CONST BALL_MIN_RENDER_RADIUS% = 4
CONST BALL_DRAW3D_VERTEX_COUNT% = 162
CONST BALL_DRAW3D_FACE_COUNT% = 144
CONST BALL_DRAW3D_FACE_VERTICES% = 4
CONST BALL_DRAW3D_FACE_INDEX_COUNT% = 576
CONST BALL_DRAW3D_LIGHT_RAMP_COUNT% = 32
CONST BALL_DRAW3D_COLOUR_COUNT% = 2 + BALL_DRAW3D_LIGHT_RAMP_COUNT%
CONST BALL_RENDER_MODE_SOLID% = 0
CONST BALL_RENDER_MODE_WIREFRAME% = 1
CONST BALL_WALL_SHADOW_OFFSET_X_SCENE% = 20
CONST BALL_WALL_SHADOW_OFFSET_Y_SCENE% = 0
CONST BALL_LIGHT_X% = -220
CONST BALL_LIGHT_Y% = 120
CONST BALL_LIGHT_Z% = -50
CONST BALL_LIGHT_AMB% = 45
CONST BALL_FACE_LIT_FLAG% = 8

' Palette roles used by the active HDMI runtime.
CONST PAL_BACKGROUND_GREY% = 0
CONST PAL_SHADOW_GREY% = 1
CONST PAL_WIRE_SHADOW_GREY% = 3
CONST PAL_GRID_PURPLE% = 2
CONST PAL_BALL_RED% = 4
CONST PAL_BALL_WHITE% = 6
CONST PAL_BALL_WIRE_FILL% = 7
CONST PAL_BALL_WHITE_CLONE_FIRST% = 8
CONST PAL_BALL_WHITE_CLONE_LAST% = 11
CONST PAL_BALL_WIRE_EDGE% = 12
CONST PAL_BALL_RED_CLONE_FIRST% = 13
CONST PAL_BALL_RED_CLONE_LAST% = 15
CONST PAL_LIGHT_GREY_FIRST% = 32
CONST PAL_LIGHT_GREY_LAST% = PAL_LIGHT_GREY_FIRST% + BALL_DRAW3D_LIGHT_RAMP_COUNT% - 1

' Audio assets and persistent HUD labels.
CONST AUD_CUE_SIDE% = 0
CONST AUD_CUE_FLOOR% = 1
CONST AUDIO_SIDE_CUE_FILE$ = "boing_side.wav"
CONST AUDIO_FLOOR_CUE_FILE$ = "boing_floor.wav"
CONST HUD_PANEL_HEIGHT% = 20
CONST HUD_KEYCAP_WIDTH% = 16
CONST HUD_KEYCAP_HEIGHT% = 8
CONST HUD_KEYCAP_RADIUS% = 3
CONST HUD_KEYCAP_TOP_OFFSET% = 3
CONST HUD_LABEL_TOP_OFFSET% = 12
CONST HUD_DIVIDER_TOP_OFFSET% = 4
CONST HUD_DIVIDER_BOTTOM_OFFSET% = 3
CONST HUD_KEYCAP_TEXT_FONT% = 8
CONST HUD_TEXT_FONT% = 7
CONST HUD_TEXT_SCALE% = 1
CONST HUD_KEY_P_LABEL$ = "P"
CONST HUD_KEY_W_LABEL$ = "W"
CONST HUD_KEY_E_LABEL$ = "E"
CONST HUD_LABEL_RUN$ = "RUN/PAUSE"
CONST HUD_LABEL_WIRE$ = "WIRE/SOLID"
CONST HUD_LABEL_ENHANCED$ = "CLASSIC/ENH"

' Live motion state.
DIM BallPosX!
DIM BallPosY!
DIM BallVelX!
DIM BallVelY!
DIM BallDepthOffset!
DIM BallVelZ!
DIM BallGravityStep!
DIM BallFloorBounceVelY!

' Cached runtime palette and projection state.
DIM RuntimeBackgroundColor%
DIM RuntimeShadowColor%
DIM RuntimeWireShadowColor%
DIM RuntimeGridColor%
DIM RuntimeBallRedColor%
DIM RuntimeBallWhiteColor%
DIM RuntimeBallWireFillColor%
DIM RuntimeBallWireEdgeColor%
DIM RuntimeHudPanelColor%
DIM RuntimeHudTopLineColor%
DIM RuntimeHudAccentLineColor%
DIM RuntimeHudDividerColor%
DIM RuntimeHudLabelColor%
DIM RuntimeHudChipBorderColor%
DIM RuntimeHudKeyTextColor%
DIM RuntimeHudPauseFillColor%
DIM RuntimeHudWireFillColor%
DIM RuntimeHudEnhanceFillColor%
DIM SceneScaledBallRadius%
DIM SceneRenderClearHeight%
DIM SceneScreenCenterX%
DIM SceneScreenCenterY%
DIM BallShadowRadius%
DIM BallDrawDepthZ%
DIM BallDrawScreenX%
DIM BallDrawScreenY%
DIM BallShadowScreenX%
DIM BallShadowScreenY%

' Screen-space caches reused by the renderer.
DIM INTEGER SceneScreenX(SCENE_MAX_X% + 1)
DIM INTEGER SceneScreenY(SCENE_MAX_Y%)
DIM INTEGER SceneBallDrawX(SCENE_MAX_X% + 1)
DIM INTEGER SceneBallDrawY(SCENE_MAX_Y%)
DIM INTEGER GridLineX1(GRID_LINE_COUNT% - 1)
DIM INTEGER GridLineY1(GRID_LINE_COUNT% - 1)
DIM INTEGER GridLineX2(GRID_LINE_COUNT% - 1)
DIM INTEGER GridLineY2(GRID_LINE_COUNT% - 1)

' DRAW3D mesh, palette, and orientation state.
DIM FLOAT Ball3DVertices(2, BALL_DRAW3D_VERTEX_COUNT% - 1)
DIM INTEGER Ball3DFaceCounts(BALL_DRAW3D_FACE_COUNT% - 1)
DIM INTEGER Ball3DFaces(BALL_DRAW3D_FACE_INDEX_COUNT% - 1)
DIM INTEGER Ball3DColours(BALL_DRAW3D_COLOUR_COUNT% - 1)
DIM INTEGER Ball3DEdges(BALL_DRAW3D_FACE_COUNT% - 1)
DIM INTEGER Ball3DFills(BALL_DRAW3D_FACE_COUNT% - 1)
DIM FLOAT BallSpinAxisX!
DIM FLOAT BallSpinAxisY!
DIM FLOAT BallSpinAxisZ!
DIM FLOAT BallSpinQuatForward(4)
DIM FLOAT BallSpinQuatReverse(4)
DIM FLOAT BallSpinQuatCurrent(4)
DIM FLOAT BallSpinAngle!
DIM BallSpinDirection%

' Runtime control state.
DIM BallRenderMode%
DIM BallNextStepDueMs%
DIM AudioCuesEnabled%
DIM DemoPaused%
DIM EnhancedPresentationEnabled%

'------------------------------------------------------------------------------
' File: core/20_scene.bas
' Responsibility:
' - Set up scene-space to screen-space caches.
' - Configure the MODE 5 palette and framebuffer bring-up.
' - Build the persistent keyboard-shortcut HUD on framebuffer F.
' - Render the background, wall shadow, grid, and 3D ball each frame.
'
' Functions:
' - CacheGridLine(): store one scene-space grid segment in screen-space arrays.
' - CacheFloorEdgeLines(): store the accepted stepped floor-front contour lines.
' - InitGridLineCache(): precompute the perspective grid line endpoints.
' - InitRuntimePaletteRoleCache(): cache the runtime palette roles after `MAP SET`.
' - InitSceneRenderCache(): cache palette roles and coordinate transforms.
' - ClearSceneRenderArea(): refill only the active scene area on framebuffer `F`.
' - ApplyPaletteRange(): write one inclusive colour range into the MODE 5 palette.
' - ApplyInitialMode5Palette(): program the MODE 5 HDMI palette mapping.
' - DrawHudPanel(): draw the persistent footer band and separators on framebuffer `F`.
' - DrawHudKeycap(): draw one rounded coloured keycap in the footer band.
' - DrawHudModule(): draw one footer control module with keycap plus label.
' - InitHudOverlay(): draw the persistent structured control band once on framebuffer `F`.
' - InitVisualBringUp(): enter MODE 5 and prepare framebuffer F.
' - RenderFrame(): draw and present one complete frame.
'------------------------------------------------------------------------------

SUB CacheGridLine(lineIndex%, sceneX1%, sceneY1%, sceneX2%, sceneY2%)
  GridLineX1(lineIndex%) = SceneScreenX(sceneX1%)
  GridLineY1(lineIndex%) = SceneScreenY(sceneY1%)
  GridLineX2(lineIndex%) = SceneScreenX(sceneX2%)
  GridLineY2(lineIndex%) = SceneScreenY(sceneY2%)
END SUB

SUB CacheFloorEdgeLines(startIndex%)
  ' Preserve the accepted stepped floor-front contour under the wall grid.
  CacheGridLine startIndex%, 37, 194, 283, 194
  CacheGridLine startIndex% + 1, 33, 197, 287, 197
  CacheGridLine startIndex% + 2, 28, 201, 291, 201
  CacheGridLine startIndex% + 3, 21, 207, 299, 207
  CacheGridLine startIndex% + 4, 10, 215, 309, 215
END SUB

SUB InitGridLineCache()
  LOCAL sceneX%
  LOCAL sceneY%
  LOCAL floorBottomX%
  LOCAL lineIndex%

  lineIndex% = 0
  FOR sceneX% = GRID_WALL_MIN_X_SCENE% TO GRID_WALL_MAX_X_SCENE% STEP GRID_CELL_STEP_SCENE%
    CacheGridLine lineIndex%, sceneX%, 0, sceneX%, GRID_FLOOR_TOP_Y_SCENE%
    lineIndex% = lineIndex% + 1
  NEXT sceneX%

  FOR sceneY% = 0 TO GRID_FLOOR_TOP_Y_SCENE% STEP GRID_CELL_STEP_SCENE%
    CacheGridLine lineIndex%, GRID_WALL_MIN_X_SCENE%, sceneY%, GRID_WALL_MAX_X_SCENE%, sceneY%
    lineIndex% = lineIndex% + 1
  NEXT sceneY%

  floorBottomX% = GRID_FLOOR_RAY_START_X_SCENE%
  FOR sceneX% = GRID_WALL_MIN_X_SCENE% TO GRID_WALL_MAX_X_SCENE% STEP GRID_CELL_STEP_SCENE%
    CacheGridLine lineIndex%, sceneX%, GRID_FLOOR_TOP_Y_SCENE%, floorBottomX%, SCENE_MAX_Y%
    lineIndex% = lineIndex% + 1
    floorBottomX% = floorBottomX% + GRID_FLOOR_RAY_STEP_X_SCENE%
  NEXT sceneX%

  CacheFloorEdgeLines lineIndex%
  lineIndex% = lineIndex% + GRID_FLOOR_EDGE_LINE_COUNT%

  IF lineIndex% <> GRID_LINE_COUNT% THEN ERROR "Grid line cache mismatch"
END SUB

SUB InitRuntimePaletteRoleCache()
  RuntimeBackgroundColor% = MAP(PAL_BACKGROUND_GREY%)
  RuntimeShadowColor% = MAP(PAL_SHADOW_GREY%)
  RuntimeWireShadowColor% = MAP(PAL_WIRE_SHADOW_GREY%)
  RuntimeGridColor% = MAP(PAL_GRID_PURPLE%)
  RuntimeBallRedColor% = RGB(255, 0, 0)
  RuntimeBallWhiteColor% = RGB(255, 255, 255)
  RuntimeBallWireFillColor% = MAP(PAL_BALL_WIRE_FILL%)
  RuntimeBallWireEdgeColor% = MAP(PAL_BALL_WIRE_EDGE%)
  RuntimeHudPanelColor% = RGB(118, 118, 126)
  RuntimeHudTopLineColor% = RGB(232, 232, 236)
  RuntimeHudAccentLineColor% = RGB(146, 112, 172)
  RuntimeHudDividerColor% = RGB(86, 82, 96)
  RuntimeHudLabelColor% = RGB(248, 248, 250)
  RuntimeHudChipBorderColor% = RGB(246, 246, 248)
  RuntimeHudKeyTextColor% = RGB(255, 255, 255)
  RuntimeHudPauseFillColor% = RGB(196, 52, 52)
  RuntimeHudWireFillColor% = RGB(0, 132, 48)
  RuntimeHudEnhanceFillColor% = RGB(116, 78, 156)
END SUB

SUB InitSceneRenderCache()
  LOCAL sceneX%
  LOCAL sceneY%
  LOCAL activeTop%
  LOCAL activeBottom%
  LOCAL scaledHeightRange%

  InitRuntimePaletteRoleCache()

  activeTop% = SCENE_VERTICAL_MARGIN%
  activeBottom% = MM.VRES - HUD_PANEL_HEIGHT% - 1
  SceneScreenCenterX% = MM.HRES / 2
  SceneScreenCenterY% = MM.VRES / 2
  scaledHeightRange% = activeBottom% - activeTop%

  FOR sceneX% = 0 TO SCENE_MAX_X% + 1
    SceneScreenX(sceneX%) = sceneX% * (MM.HRES - 1) / SCENE_MAX_X%
    SceneBallDrawX(sceneX%) = SceneScreenX(sceneX%) - SceneScreenCenterX%
  NEXT sceneX%

  FOR sceneY% = 0 TO SCENE_MAX_Y%
    SceneScreenY(sceneY%) = activeTop% + sceneY% * scaledHeightRange% / SCENE_MAX_Y%
    SceneBallDrawY(sceneY%) = SceneScreenCenterY% - SceneScreenY(sceneY%)
  NEXT sceneY%

  SceneRenderClearHeight% = SceneScreenY(SCENE_MAX_Y%) + 1

  InitGridLineCache()
END SUB

SUB ClearSceneRenderArea()
  BOX 0, 0, MM.HRES, SceneRenderClearHeight%, 0, RuntimeBackgroundColor%, RuntimeBackgroundColor%
END SUB

SUB ApplyPaletteRange(firstIndex%, lastIndex%, colour%)
  LOCAL paletteIndex%

  FOR paletteIndex% = firstIndex% TO lastIndex%
    MAP(paletteIndex%) = colour%
  NEXT paletteIndex%
END SUB

SUB ApplyMode5LightRampPalette()
  LOCAL paletteIndex%
  LOCAL rampIndex%
  LOCAL grey%

  rampIndex% = 0
  FOR paletteIndex% = PAL_LIGHT_GREY_FIRST% TO PAL_LIGHT_GREY_LAST%
    grey% = (rampIndex% * 255) / (BALL_DRAW3D_LIGHT_RAMP_COUNT% - 1)
    MAP(paletteIndex%) = RGB(grey%, grey%, grey%)
    rampIndex% = rampIndex% + 1
  NEXT paletteIndex%
END SUB

SUB ApplyInitialMode5Palette()
  LOCAL ballRed%
  LOCAL ballWhite%

  ballRed% = RGB(255, 0, 0)
  ballWhite% = RGB(255, 255, 255)

  MAP(PAL_BACKGROUND_GREY%) = RGB(173, 170, 173)
  MAP(PAL_SHADOW_GREY%) = RGB(136, 136, 136)
  MAP(PAL_WIRE_SHADOW_GREY%) = RGB(165, 165, 165)
  MAP(PAL_GRID_PURPLE%) = RGB(173, 0, 173)
  MAP(PAL_BALL_RED%) = ballRed%
  MAP(PAL_BALL_WHITE%) = ballWhite%
  MAP(PAL_BALL_WIRE_FILL%) = RGB(0, 80, 0)
  ApplyPaletteRange PAL_BALL_WHITE_CLONE_FIRST%, PAL_BALL_WHITE_CLONE_LAST%, ballWhite%
  MAP(PAL_BALL_WIRE_EDGE%) = RGB(0, 150, 0)
  ApplyPaletteRange PAL_BALL_RED_CLONE_FIRST%, PAL_BALL_RED_CLONE_LAST%, ballRed%
  ApplyMode5LightRampPalette()
  MAP SET
END SUB

SUB DrawHudPanel()
  LOCAL panelTop%
  LOCAL divider1X%
  LOCAL divider2X%
  LOCAL dividerTop%
  LOCAL dividerBottom%

  panelTop% = MM.VRES - HUD_PANEL_HEIGHT%
  BOX 0, panelTop%, MM.HRES, HUD_PANEL_HEIGHT%, 0, RuntimeHudPanelColor%, RuntimeHudPanelColor%
  LINE 0, panelTop%, MM.HRES - 1, panelTop%, 1, RuntimeHudTopLineColor%
  LINE 0, panelTop% + 1, MM.HRES - 1, panelTop% + 1, 1, RuntimeHudAccentLineColor%
  divider1X% = MM.HRES / 3
  divider2X% = divider1X% * 2
  dividerTop% = panelTop% + HUD_DIVIDER_TOP_OFFSET%
  dividerBottom% = MM.VRES - HUD_DIVIDER_BOTTOM_OFFSET%
  LINE divider1X%, dividerTop%, divider1X%, dividerBottom%, 1, RuntimeHudDividerColor%
  LINE divider2X%, dividerTop%, divider2X%, dividerBottom%, 1, RuntimeHudDividerColor%
END SUB

SUB DrawHudKeycap(centerX%, topY%, fillColor%, label$)
  LOCAL chipLeft%
  LOCAL chipMidY%

  chipLeft% = centerX% - (HUD_KEYCAP_WIDTH% / 2)
  chipMidY% = topY% + (HUD_KEYCAP_HEIGHT% / 2)
  RBOX chipLeft%, topY%, HUD_KEYCAP_WIDTH%, HUD_KEYCAP_HEIGHT%, HUD_KEYCAP_RADIUS%, RuntimeHudChipBorderColor%, fillColor%
  TEXT centerX%, chipMidY%, label$, "CM", HUD_KEYCAP_TEXT_FONT%, HUD_TEXT_SCALE%, RuntimeHudKeyTextColor%, -1
END SUB

SUB DrawHudModule(columnIndex%, fillColor%, keyLabel$, textLabel$)
  LOCAL columnWidth%
  LOCAL centerX%
  LOCAL panelTop%
  LOCAL keyTop%
  LOCAL labelY%

  panelTop% = MM.VRES - HUD_PANEL_HEIGHT%
  columnWidth% = MM.HRES / 3
  centerX% = (columnWidth% * columnIndex%) + (columnWidth% / 2)
  keyTop% = panelTop% + HUD_KEYCAP_TOP_OFFSET%
  labelY% = panelTop% + HUD_LABEL_TOP_OFFSET%
  DrawHudKeycap centerX%, keyTop%, fillColor%, keyLabel$
  TEXT centerX%, labelY%, textLabel$, "CT", HUD_TEXT_FONT%, HUD_TEXT_SCALE%, RuntimeHudLabelColor%, -1
END SUB

SUB InitHudOverlay()
  DrawHudPanel()
  DrawHudModule 0, RuntimeHudPauseFillColor%, HUD_KEY_P_LABEL$, HUD_LABEL_RUN$
  DrawHudModule 1, RuntimeHudWireFillColor%, HUD_KEY_W_LABEL$, HUD_LABEL_WIRE$
  DrawHudModule 2, RuntimeHudEnhanceFillColor%, HUD_KEY_E_LABEL$, HUD_LABEL_ENHANCED$
END SUB

SUB InitVisualBringUp()
  MODE 5
  ApplyInitialMode5Palette()
  InitSceneRenderCache()
  FRAMEBUFFER CREATE
  FRAMEBUFFER WRITE F
  CLS RuntimeBackgroundColor%
  InitHudOverlay()
END SUB

SUB RenderFrame()
  FRAMEBUFFER WRITE F
  ClearSceneRenderArea()
  IF BallRenderMode% = BALL_RENDER_MODE_WIREFRAME% THEN
    CIRCLE BallShadowScreenX%, BallShadowScreenY%, BallShadowRadius%, 1, 1.0, RuntimeWireShadowColor%, RuntimeWireShadowColor%
  ELSE
    CIRCLE BallShadowScreenX%, BallShadowScreenY%, BallShadowRadius%, 1, 1.0, RuntimeShadowColor%, RuntimeShadowColor%
  END IF
  LINE GridLineX1(), GridLineY1(), GridLineX2(), GridLineY2(), 1, RuntimeGridColor%
  IF BallRenderMode% = BALL_RENDER_MODE_WIREFRAME% THEN
    DRAW3D WRITE BALL_DRAW3D_OBJECT%, BallDrawScreenX%, BallDrawScreenY%, BallDrawDepthZ%, 1, 1
  ELSE
    DRAW3D WRITE BALL_DRAW3D_OBJECT%, BallDrawScreenX%, BallDrawScreenY%, BallDrawDepthZ%
  END IF
  FRAMEBUFFER COPY F, N, B
END SUB

'------------------------------------------------------------------------------
' File: core/30_audio.bas
' Responsibility:
' - Detect whether the rebound cue files are available on target storage.
' - Play the side-wall and floor-impact WAV cues safely.
' - Keep rebound audio active whenever the cue files are available.
'
' Functions:
' - DisableAudioCues(): collapse to silent mode after a cue or stop failure.
' - InitAudioState(): enable cues only when both WAV assets are present.
' - StopAudioCuePlayback(): stop any active cue cleanly.
' - PlayAudioCueFile(): play one WAV file and fail back to silence on error.
' - PlayAudioCue(): play the requested rebound cue and fail back to silence on error.
'------------------------------------------------------------------------------

SUB DisableAudioCues()
  AudioCuesEnabled% = 0
END SUB

SUB InitAudioState()
  DisableAudioCues()
  IF MM.INFO(EXISTS FILE AUDIO_SIDE_CUE_FILE$) <> 1 THEN EXIT SUB
  IF MM.INFO(EXISTS FILE AUDIO_FLOOR_CUE_FILE$) <> 1 THEN EXIT SUB
  AudioCuesEnabled% = 1
END SUB

SUB StopAudioCuePlayback()
  IF MM.INFO(SOUND) = "OFF" THEN EXIT SUB

  ON ERROR SKIP
  PLAY STOP
  IF MM.ERRNO THEN DisableAudioCues()
END SUB

SUB PlayAudioCueFile(cueFile$)
  ON ERROR SKIP
  PLAY WAV cueFile$
  IF MM.ERRNO THEN DisableAudioCues()
END SUB

SUB PlayAudioCue(cue%)
  LOCAL cueFile$

  IF AudioCuesEnabled% = 0 THEN EXIT SUB

  IF MM.INFO(SOUND) <> "OFF" THEN
    StopAudioCuePlayback()
    IF AudioCuesEnabled% = 0 THEN EXIT SUB
  END IF

  cueFile$ = AUDIO_FLOOR_CUE_FILE$
  IF cue% = AUD_CUE_SIDE% THEN cueFile$ = AUDIO_SIDE_CUE_FILE$
  PlayAudioCueFile cueFile$
END SUB

'------------------------------------------------------------------------------
' File: core/40_ball.bas
' Responsibility:
' - Own the live ball motion state.
' - Apply rebounds, spin-direction changes, and rebound-triggered audio cues.
' - Refresh the screen-space cache used by the renderer.
'
' Functions:
' - InitBallState(): initialize motion state, spin direction, 3D object, and render cache.
' - InitBallMotionState(): derive runtime motion values from scene constants.
' - UpdateBallRenderCache(): cache current screen-space ball and shadow positions.
' - AdvanceBallSpin(): rotate the DRAW3D ball using the active spin direction.
' - UpdateBallState(): advance one simulation step and refresh render state.
' - AdvanceBallPosition(): integrate horizontal, vertical, and depth motion for one step.
' - HandleBallHorizontalBounds(): apply side-wall rebound checks.
' - ApplyBallHorizontalBounce(): share the clamp/spin/audio work for side rebounds.
' - ApplyBallLeftBounce(): clamp, reverse spin, and play the side cue on left rebound.
' - ApplyBallRightBounce(): clamp, reverse spin, and play the side cue on right rebound.
' - HandleBallFloorBounce(): clamp vertical motion and play the floor cue on impact.
' - ApplyBallDepthBounce(): share the clamp/audio work for front/back rebounds.
' - HandleBallDepthBounds(): clamp the optional pseudo-depth rebound range.
'------------------------------------------------------------------------------

SUB InitBallState()
  InitBallMotionState()
  BallSpinDirection% = 1
  BallSpinAngle! = 0.0
  InitDraw3DBall()
  UpdateBallRenderCache()
END SUB

SUB InitBallMotionState()
  LOCAL verticalStepScale!
  LOCAL scaledHeightRange%

  verticalStepScale! = BALL_VERTICAL_STEP_SCALE!
  scaledHeightRange% = MM.VRES - SCENE_VERTICAL_MARGIN% - HUD_PANEL_HEIGHT% - 1
  SceneScaledBallRadius% = BALL_RADIUS_SCENE% * scaledHeightRange% / SCENE_MAX_Y%
  IF SceneScaledBallRadius% < BALL_MIN_RENDER_RADIUS% THEN SceneScaledBallRadius% = BALL_MIN_RENDER_RADIUS%
  BallGravityStep! = BALL_GRAVITY_SCENE% * verticalStepScale! * verticalStepScale!
  BallFloorBounceVelY! = BALL_FLOOR_BOUNCE_VY_SCENE% * verticalStepScale! * BALL_VERTICAL_ARC_GAIN!
  BallPosX! = BALL_START_X_SCENE%
  BallPosY! = BALL_START_Y_SCENE%
  BallVelX! = BALL_START_VX_SCENE%
  BallVelY! = BALL_START_VY_SCENE% * verticalStepScale! * BALL_VERTICAL_ARC_GAIN!
  BallDepthOffset! = 0.0
  BallVelZ! = BALL_DEPTH_STEP!
END SUB

SUB UpdateBallRenderCache()
  LOCAL ballSceneX%
  LOCAL ballSceneY%
  LOCAL ballSceneShadowX%
  LOCAL ballSceneShadowY%
  LOCAL ballDrawPerspective!
  LOCAL shadowOffsetX%
  LOCAL shadowOffsetY%
  LOCAL shadowOffsetRatio!
  LOCAL shadowOffsetScreenX%
  LOCAL shadowOffsetScreenY%
  LOCAL projectedBallCenterX!
  LOCAL projectedBallCenterY!

  ballSceneX% = INT(BallPosX! + 0.5)
  ballSceneY% = INT(BallPosY! + 0.5)
  BallDrawDepthZ% = BALL_DRAW3D_Z% + INT(BallDepthOffset! + 0.5)
  BallShadowRadius% = (SceneScaledBallRadius% * BALL_DRAW3D_Z% + (BallDrawDepthZ% / 2)) / BallDrawDepthZ%
  IF BallShadowRadius% < BALL_MIN_RENDER_RADIUS% THEN BallShadowRadius% = BALL_MIN_RENDER_RADIUS%
  shadowOffsetRatio! = 1.0
  IF BALL_DEPTH_MAX_OFFSET% > 0 THEN
    shadowOffsetRatio! = (BALL_DEPTH_MAX_OFFSET% - BallDepthOffset!) / BALL_DEPTH_MAX_OFFSET%
    IF shadowOffsetRatio! < 0.0 THEN shadowOffsetRatio! = 0.0
  END IF
  ' Keep the shadow anchored to the projected center while depth only changes its wall offset.
  shadowOffsetX% = INT((BALL_WALL_SHADOW_OFFSET_X_SCENE% * shadowOffsetRatio!) + 0.5)
  shadowOffsetY% = (BALL_WALL_SHADOW_OFFSET_Y_SCENE% * BALL_DRAW3D_Z% + (BallDrawDepthZ% / 2)) / BallDrawDepthZ%
  BallDrawScreenX% = SceneBallDrawX(ballSceneX%)
  BallDrawScreenY% = SceneBallDrawY(ballSceneY%)
  ballDrawPerspective! = BALL_DRAW3D_VIEWPLANE% / BallDrawDepthZ%
  projectedBallCenterX! = SceneScreenCenterX% + (BallDrawScreenX% * ballDrawPerspective!)
  projectedBallCenterY! = SceneScreenCenterY% - (BallDrawScreenY% * ballDrawPerspective!)
  ballSceneShadowX% = ballSceneX% + shadowOffsetX%
  ballSceneShadowY% = ballSceneY% + shadowOffsetY%
  shadowOffsetScreenX% = SceneScreenX(ballSceneShadowX%) - SceneScreenX(ballSceneX%)
  shadowOffsetScreenY% = SceneScreenY(ballSceneShadowY%) - SceneScreenY(ballSceneY%)
  BallShadowScreenX% = INT(projectedBallCenterX! + shadowOffsetScreenX% + 0.5)
  BallShadowScreenY% = INT(projectedBallCenterY! + shadowOffsetScreenY% + 0.5)
END SUB

SUB AdvanceBallSpin()
  IF BallSpinDirection% > 0 THEN
    BallSpinAngle! = BallSpinAngle! + BALL_DRAW3D_SPIN_DEG!
    DRAW3D ROTATE BallSpinQuatForward(), BALL_DRAW3D_OBJECT%
  ELSE
    BallSpinAngle! = BallSpinAngle! - BALL_DRAW3D_SPIN_DEG!
    DRAW3D ROTATE BallSpinQuatReverse(), BALL_DRAW3D_OBJECT%
  END IF
  IF BallSpinAngle! >= 360.0 THEN BallSpinAngle! = BallSpinAngle! - 360.0
  IF BallSpinAngle! <= -360.0 THEN BallSpinAngle! = BallSpinAngle! + 360.0
  DRAW3D RESET BALL_DRAW3D_OBJECT%
END SUB

SUB UpdateBallState()
  AdvanceBallPosition()
  HandleBallHorizontalBounds()
  HandleBallFloorBounce()
  IF EnhancedPresentationEnabled% <> 0 THEN
    HandleBallDepthBounds()
  END IF
  AdvanceBallSpin()
  UpdateBallRenderCache()
END SUB

SUB AdvanceBallPosition()
  BallPosX! = BallPosX! + BallVelX!
  BallPosY! = BallPosY! + BallVelY!
  IF EnhancedPresentationEnabled% <> 0 THEN
    BallDepthOffset! = BallDepthOffset! + BallVelZ!
  END IF
  BallVelY! = BallVelY! + BallGravityStep!
END SUB

SUB HandleBallHorizontalBounds()
  IF BallPosX! < BALL_MIN_X_SCENE% THEN
    ApplyBallLeftBounce()
  END IF

  IF BallPosX! > BALL_MAX_X_SCENE% THEN
    ApplyBallRightBounce()
  END IF
END SUB

SUB ApplyBallHorizontalBounce(clampedX!, newVelX!)
  BallPosX! = clampedX!
  BallVelX! = newVelX!
  BallSpinDirection% = -BallSpinDirection%
  PlayAudioCue AUD_CUE_SIDE%
END SUB

SUB ApplyBallLeftBounce()
  ApplyBallHorizontalBounce BALL_MIN_X_SCENE%, ABS(BallVelX!)
END SUB

SUB ApplyBallRightBounce()
  ApplyBallHorizontalBounce BALL_MAX_X_SCENE%, -ABS(BallVelX!)
END SUB

SUB HandleBallFloorBounce()
  IF BallPosY! > BALL_FLOOR_BOUNCE_Y_SCENE% THEN
    BallPosY! = BALL_FLOOR_BOUNCE_Y_SCENE%
    BallVelY! = BallFloorBounceVelY!
    PlayAudioCue AUD_CUE_FLOOR%
  END IF
END SUB

SUB ApplyBallDepthBounce(clampedDepth!, newVelZ!)
  BallDepthOffset! = clampedDepth!
  BallVelZ! = newVelZ!
  PlayAudioCue AUD_CUE_SIDE%
END SUB

SUB HandleBallDepthBounds()
  IF BallDepthOffset! < 0.0 THEN
    ApplyBallDepthBounce 0.0, ABS(BallVelZ!)
  END IF

  IF BallDepthOffset! > BALL_DEPTH_MAX_OFFSET% THEN
    ApplyBallDepthBounce BALL_DEPTH_MAX_OFFSET%, -ABS(BallVelZ!)
  END IF
END SUB


'------------------------------------------------------------------------------
' File: core/50_ball_draw3d.bas
' Responsibility:
' - Build the Boing Ball DRAW3D mesh from the accepted scene constants.
' - Configure face colours, create the DRAW3D object, and cache spin quaternions.
'
' Functions:
' - InitDraw3DBall(): coordinate full DRAW3D object setup.
' - BuildBallDraw3DVertices(): generate the rotated globe vertices.
' - BuildBallDraw3DFaces(): generate face topology for the maintained globe mesh.
' - ApplyBallDraw3DRenderMode(): map the current solid or contour style into edge/fill arrays.
' - RebuildBallDraw3DObject(): recreate the single DRAW3D object after style changes.
' - CreateBallDraw3DObject(): create the PicoMite DRAW3D object and camera.
' - RestoreBallDraw3DOrientation(): reapply the current spin angle after a rebuild.
' - InitBallSpinAxis(): cache the single spin axis shared by runtime rotation calls.
' - InitBallSpinQuaternions(): build the forward and reverse spin quaternions.
' - StoreDraw3DVertex(): compute and store one rotated mesh vertex.
'------------------------------------------------------------------------------

SUB InitDraw3DBall()
  LOCAL yawSin!
  LOCAL yawCos!
  LOCAL pitchSin!
  LOCAL pitchCos!
  LOCAL rollSin!
  LOCAL rollCos!
  LOCAL modelRadius!

  modelRadius! = SceneScaledBallRadius%
  yawSin! = SIN(RAD(BALL_MESH_YAW_DEG%))
  yawCos! = COS(RAD(BALL_MESH_YAW_DEG%))
  pitchSin! = SIN(RAD(BALL_MESH_PITCH_DEG%))
  pitchCos! = COS(RAD(BALL_MESH_PITCH_DEG%))
  rollSin! = SIN(RAD(BALL_MESH_ROLL_DEG%))
  rollCos! = COS(RAD(BALL_MESH_ROLL_DEG%))

  BuildBallDraw3DVertices(modelRadius!, yawSin!, yawCos!, pitchSin!, pitchCos!, rollSin!, rollCos!)
  BuildBallDraw3DFaces()
  InitBallSpinAxis()
  InitBallSpinQuaternions()
  RebuildBallDraw3DObject()
END SUB

SUB BuildBallDraw3DVertices(modelRadius!, yawSin!, yawCos!, pitchSin!, pitchCos!, rollSin!, rollCos!)
  LOCAL latStep!
  LOCAL lonStep!
  LOCAL latDeg!
  LOCAL lonDeg!
  LOCAL latLine%
  LOCAL seg%
  LOCAL vertexIndex%

  latStep! = BALL_MESH_LAT_SWEEP_DEG! / (BALL_MESH_LAT_LINES% - 1)
  lonStep! = 360.0 / BALL_MESH_SEGMENTS%
  vertexIndex% = 0

  FOR latLine% = 0 TO BALL_MESH_LAT_LINES% - 1
    latDeg! = BALL_MESH_LAT_START_DEG! + latLine% * latStep!
    FOR seg% = 0 TO BALL_MESH_SEGMENTS% - 1
      lonDeg! = BALL_MESH_LON_OFFSET_DEG% + seg% * lonStep!
      StoreDraw3DVertex(vertexIndex%, latDeg!, lonDeg!, modelRadius!, yawSin!, yawCos!, pitchSin!, pitchCos!, rollSin!, rollCos!)
      vertexIndex% = vertexIndex% + 1
    NEXT seg%
  NEXT latLine%
END SUB

SUB BuildBallDraw3DFaces()
  LOCAL band%
  LOCAL bandStart%
  LOCAL nextBandStart%
  LOCAL seg%
  LOCAL nextSeg%
  LOCAL faceIndex%
  LOCAL faceOffset%

  faceIndex% = 0
  faceOffset% = 0

  FOR band% = 0 TO BALL_MESH_BANDS% - 1
    bandStart% = band% * BALL_MESH_SEGMENTS%
    nextBandStart% = bandStart% + BALL_MESH_SEGMENTS%

    FOR seg% = 0 TO BALL_MESH_SEGMENTS% - 1
      nextSeg% = seg% + 1
      IF nextSeg% = BALL_MESH_SEGMENTS% THEN nextSeg% = 0

      Ball3DFaceCounts(faceIndex%) = BALL_DRAW3D_FACE_VERTICES%
      Ball3DFaces(faceOffset%) = bandStart% + seg%
      Ball3DFaces(faceOffset% + 1) = nextBandStart% + seg%
      Ball3DFaces(faceOffset% + 2) = nextBandStart% + nextSeg%
      Ball3DFaces(faceOffset% + 3) = bandStart% + nextSeg%

      faceIndex% = faceIndex% + 1
      faceOffset% = faceOffset% + BALL_DRAW3D_FACE_VERTICES%
    NEXT seg%
  NEXT band%
END SUB

SUB ApplyBallDraw3DRenderMode()
  LOCAL band%
  LOCAL seg%
  LOCAL faceIndex%
  LOCAL fillIndex%
  LOCAL wireframeMode%

  wireframeMode% = 0
  IF BallRenderMode% = BALL_RENDER_MODE_WIREFRAME% THEN
    wireframeMode% = 1
    Ball3DColours(0) = RuntimeBallWireEdgeColor%
    Ball3DColours(1) = RuntimeBallWireFillColor%
  ELSE
    Ball3DColours(0) = RuntimeBallRedColor%
    Ball3DColours(1) = RuntimeBallWhiteColor%
  END IF

  LoadBallDraw3DLightRamp()

  faceIndex% = 0
  FOR band% = 0 TO BALL_MESH_BANDS% - 1
    FOR seg% = 0 TO BALL_MESH_SEGMENTS% - 1
      IF wireframeMode% <> 0 THEN
        Ball3DEdges(faceIndex%) = 0
        Ball3DFills(faceIndex%) = 1
      ELSE
        fillIndex% = 0
        IF (band% + seg%) MOD 2 = 0 THEN fillIndex% = 1
        Ball3DEdges(faceIndex%) = fillIndex%
        Ball3DFills(faceIndex%) = fillIndex%
      END IF

      faceIndex% = faceIndex% + 1
    NEXT seg%
  NEXT band%
END SUB

SUB LoadBallDraw3DLightRamp()
  LOCAL rampIndex%
  LOCAL grey%

  FOR rampIndex% = 0 TO BALL_DRAW3D_LIGHT_RAMP_COUNT% - 1
    grey% = (rampIndex% * 255) / (BALL_DRAW3D_LIGHT_RAMP_COUNT% - 1)
    Ball3DColours(2 + rampIndex%) = RGB(grey%, grey%, grey%)
  NEXT rampIndex%
END SUB

SUB RebuildBallDraw3DObject()
  ApplyBallDraw3DRenderMode()
  CreateBallDraw3DObject()
  RestoreBallDraw3DOrientation()
END SUB

SUB CreateBallDraw3DObject()
  LOCAL wire%

  wire% = 0
  IF BallRenderMode% = BALL_RENDER_MODE_WIREFRAME% THEN wire% = 1

  DRAW3D CLOSE ALL
  DRAW3D CAMERA BALL_DRAW3D_CAMERA%, BALL_DRAW3D_VIEWPLANE%, 0, 0
  IF wire% <> 0 THEN
    DRAW3D CREATE BALL_DRAW3D_OBJECT%, BALL_DRAW3D_VERTEX_COUNT%, BALL_DRAW3D_FACE_COUNT%, BALL_DRAW3D_CAMERA%, Ball3DVertices(), Ball3DFaceCounts(), Ball3DFaces(), Ball3DColours(), Ball3DEdges()
  ELSE
    DRAW3D CREATE BALL_DRAW3D_OBJECT%, BALL_DRAW3D_VERTEX_COUNT%, BALL_DRAW3D_FACE_COUNT%, BALL_DRAW3D_CAMERA%, Ball3DVertices(), Ball3DFaceCounts(), Ball3DFaces(), Ball3DColours(), Ball3DEdges(), Ball3DFills()
  END IF
  ConfigBallLight wire%
END SUB

SUB ConfigBallLight(wire%)
  IF EnhancedPresentationEnabled% = 0 THEN EXIT SUB

  DRAW3D LIGHT BALL_DRAW3D_OBJECT%, BALL_LIGHT_X%, BALL_LIGHT_Y%, BALL_LIGHT_Z%, BALL_LIGHT_AMB%
  IF wire% <> 0 THEN EXIT SUB

  DRAW3D SET FLAGS BALL_DRAW3D_OBJECT%, BALL_FACE_LIT_FLAG%, 0, BALL_DRAW3D_FACE_COUNT%
END SUB

SUB RestoreBallDraw3DOrientation()
  IF BallSpinAngle! = 0.0 THEN EXIT SUB

  MATH Q_CREATE RAD(BallSpinAngle!), BallSpinAxisX!, BallSpinAxisY!, BallSpinAxisZ!, BallSpinQuatCurrent()
  DRAW3D ROTATE BallSpinQuatCurrent(), BALL_DRAW3D_OBJECT%
  DRAW3D RESET BALL_DRAW3D_OBJECT%
END SUB

SUB InitBallSpinAxis()
  BallSpinAxisX! = -SIN(RAD(BALL_MESH_ROLL_DEG%))
  BallSpinAxisY! = -COS(RAD(BALL_MESH_ROLL_DEG%))
  BallSpinAxisZ! = 0.0
END SUB

SUB InitBallSpinQuaternions()
  MATH Q_CREATE RAD(BALL_DRAW3D_SPIN_DEG!), BallSpinAxisX!, BallSpinAxisY!, BallSpinAxisZ!, BallSpinQuatForward()
  MATH Q_CREATE RAD(-BALL_DRAW3D_SPIN_DEG!), BallSpinAxisX!, BallSpinAxisY!, BallSpinAxisZ!, BallSpinQuatReverse()
END SUB

SUB StoreDraw3DVertex(vertexIndex%, latDeg!, lonDeg!, modelRadius!, yawSin!, yawCos!, pitchSin!, pitchCos!, rollSin!, rollCos!)
  LOCAL sx!
  LOCAL sy!
  LOCAL sz!
  LOCAL xYaw!
  LOCAL zYaw!
  LOCAL yPitch!
  LOCAL zPitch!
  LOCAL xRoll!
  LOCAL yRoll!

  sx! = COS(RAD(latDeg!)) * COS(RAD(lonDeg!))
  sy! = SIN(RAD(latDeg!))
  sz! = COS(RAD(latDeg!)) * SIN(RAD(lonDeg!))

  xYaw! = sx! * yawCos! + sz! * yawSin!
  zYaw! = sz! * yawCos! - sx! * yawSin!
  yPitch! = sy! * pitchCos! - zYaw! * pitchSin!
  zPitch! = zYaw! * pitchCos! + sy! * pitchSin!
  xRoll! = xYaw! * rollCos! - yPitch! * rollSin!
  yRoll! = yPitch! * rollCos! + xYaw! * rollSin!

  Ball3DVertices(0, vertexIndex%) = xRoll! * modelRadius!
  Ball3DVertices(1, vertexIndex%) = -yRoll! * modelRadius!
  Ball3DVertices(2, vertexIndex%) = BALL_MESH_VIEW_Z_SIGN% * zPitch! * modelRadius!
END SUB

'------------------------------------------------------------------------------
' File: core/90_main.bas
' Responsibility:
' - Own runtime startup order.
' - Poll simple keyboard controls for pause, wireframe mode, and enhanced presentation.
' - Run the maintained main loop directly in the final assembled source.
'
' Functions:
' - InitBoingRuntime(): bring up the accepted runtime in the documented order.
' - InitRuntimeControlState(): initialize pause, render-mode, and presentation state.
' - AdvanceBallStateIfDue(): limit ball-state updates to the fixed slow-step cadence.
' - HandleRuntimeControlKey(): dispatch one recognized keyboard shortcut.
' - PollRuntimeControls(): drain pending console keys and apply recognized toggles.
' - TogglePauseState(): flip the demo pause state.
' - ToggleBallRenderMode(): flip the ball between solid and wireframe DRAW3D modes.
' - ToggleEnhancedPresentationMode(): flip native lighting and pseudo-depth together.
' - RunBoingMain(): initialize audio, video, ball state, draw the first frame,
'   and then stay in the combined update-plus-render loop.
'------------------------------------------------------------------------------

SUB InitBoingRuntime()
  InitRuntimeControlState()
  InitAudioState()
  InitVisualBringUp()
  InitBallState()
  RenderFrame()
END SUB

SUB InitRuntimeControlState()
  DemoPaused% = 1
  BallRenderMode% = BALL_RENDER_MODE_SOLID%
  EnhancedPresentationEnabled% = 0
  BallNextStepDueMs% = TIMER
END SUB

SUB AdvanceBallStateIfDue()
  IF DemoPaused% <> 0 THEN
    BallNextStepDueMs% = TIMER
    EXIT SUB
  END IF

  IF TIMER < BallNextStepDueMs% THEN EXIT SUB

  UpdateBallState()
  BallNextStepDueMs% = TIMER + BALL_SIM_STEP_MS%
END SUB

SUB TogglePauseState()
  IF DemoPaused% = 0 THEN
    DemoPaused% = 1
  ELSE
    DemoPaused% = 0
  END IF
END SUB

SUB ToggleBallRenderMode()
  IF BallRenderMode% = BALL_RENDER_MODE_SOLID% THEN
    BallRenderMode% = BALL_RENDER_MODE_WIREFRAME%
  ELSE
    BallRenderMode% = BALL_RENDER_MODE_SOLID%
  END IF
  RebuildBallDraw3DObject()
END SUB

SUB ToggleEnhancedPresentationMode()
  IF EnhancedPresentationEnabled% = 0 THEN
    EnhancedPresentationEnabled% = 1
  ELSE
    EnhancedPresentationEnabled% = 0
  END IF

  BallDepthOffset! = 0.0
  BallVelZ! = ABS(BALL_DEPTH_STEP!)
  RebuildBallDraw3DObject()
  UpdateBallRenderCache()
END SUB

SUB HandleRuntimeControlKey(key$)
  IF key$ = "P" OR key$ = "p" THEN
    TogglePauseState()
  ELSEIF key$ = "W" OR key$ = "w" THEN
    ToggleBallRenderMode()
  ELSEIF key$ = "E" OR key$ = "e" THEN
    ToggleEnhancedPresentationMode()
  END IF
END SUB

SUB PollRuntimeControls()
  LOCAL key$

  DO
    key$ = INKEY$
    IF key$ = "" THEN EXIT DO
    HandleRuntimeControlKey key$
  LOOP
END SUB

SUB RunBoingMain()
  InitBoingRuntime()

  DO
    PollRuntimeControls()
    AdvanceBallStateIfDue()
    RenderFrame()
  LOOP
END SUB

RunBoingMain
END
