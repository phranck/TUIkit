// The 12-step render pipeline (RenderCycle.md, "The Render Pipeline").
//
// Left column: steps 1-6 flow downward. Right column: steps 7-12 flow upward,
// mirroring the frame's path back out to the terminal. Step 12 is the frame
// commit introduced with the render-phase model: lifetime effects replay and
// the runtime managers finalize only after terminal output.
#import "style.typ": *

#show: diagram-page

#diagram(
  spacing: (28pt, 14pt),
  node-corner-radius: 7pt,
  node-inset: 9pt,
  edge-stroke: 1.1pt + colors.edge,

  node((0, 0), box-label(
    [1 · Clear Per-Frame State],
    [Key handlers · Preferences],
    [Focus staging · Status bar · App header],
  ), fill: colors.green),

  node((0, 1), box-label(
    [2 · Begin Tracking],
    [Lifecycle · StateStorage],
    [Observation · RenderCache pass],
  ), fill: colors.green),

  node((0, 2), box-label(
    [3 · Build Environment],
    [EnvironmentValues with palette,],
    [appearance, focus, status bar,],
    [services, localization],
  ), fill: colors.green),

  node((0, 3), box-label(
    [4 · Create RenderContext],
    [Width + height + environment],
    [identity + render phase],
  ), fill: colors.green),

  node((0, 4), box-label(
    [5 · Evaluate Scene],
    [app.body → WindowGroup],
  ), fill: colors.green),

  node((0, 5), box-label(
    [6 · Render View Tree],
    [renderToBuffer() recursion → FrameBuffer],
    [up to 3 passes · effects recorded],
    [into per-pass collectors],
  ), fill: colors.green),

  node((1, 5), box-label(
    [7 · Build Output Lines],
    [Clip cell surface → encode SGR],
    [pad rows · fill empty lines],
  ), fill: colors.green),

  node((1, 4), box-label(
    [8 · Begin Buffered Frame],
    [Terminal.beginFrame()],
  ), fill: colors.green),

  node((1, 3), box-label(
    [9 · App Header + Content Diff],
    [Render header at top ·],
    [diff changed content lines],
  ), fill: colors.green),

  node((1, 2), box-label(
    [10 · Render Status Bar],
    [Separate RenderContext ·],
    [diff into same frame buffer],
  ), fill: colors.green),

  node((1, 1), box-label(
    [11 · Flush Frame],
    [Terminal.endFrame()],
    [→ single write() syscall],
  ), fill: colors.green-bright),

  node((1, 0), box-label(
    [12 · Frame Commit + Finalize],
    [Replay lifetime effects: onAppear ·],
    [.task · onChange · adopt final collectors],
    [Lifecycle diff · state GC ·],
    [observation + cache cleanup],
  ), fill: colors.green-dark),

  edge((0, 0), (0, 1), "-|>"),
  edge((0, 1), (0, 2), "-|>"),
  edge((0, 2), (0, 3), "-|>"),
  edge((0, 3), (0, 4), "-|>"),
  edge((0, 4), (0, 5), "-|>"),
  edge((0, 5), (1, 5), "-|>"),
  edge((1, 5), (1, 4), "-|>"),
  edge((1, 4), (1, 3), "-|>"),
  edge((1, 3), (1, 2), "-|>"),
  edge((1, 2), (1, 1), "-|>"),
  edge((1, 1), (1, 0), "-|>"),
)
