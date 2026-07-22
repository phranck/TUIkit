// The dual rendering dispatch (RenderCycle.md, "The Dispatch Function").
//
// renderToBuffer() checks Renderable conformance first, then recurses into
// body (binding dynamic properties on the way), and falls back to an empty
// buffer for Never-body views without Renderable.
#import "style.typ": *

#show: diagram-page

#diagram(
  spacing: (34pt, 20pt),
  node-corner-radius: 7pt,
  node-inset: 9pt,
  edge-stroke: 1.1pt + colors.edge,

  node((1, 0), box-label(
    [renderToBuffer(view, context)],
    [Free function – single entry point],
  ), fill: colors.blue, name: <entry>),

  decision((1, 1), [view is \ Renderable?], name: <d1>),

  decision((1.7, 1.6), [Body ≠ \ Never?], name: <d2>),

  node((0, 2.4), box-label(
    [Renderable.renderToBuffer(context:)],
    [Direct rendering to FrameBuffer],
    [body is never called],
  ), fill: colors.green, name: <direct>),

  node((1.15, 2.4), box-label(
    [renderToBuffer(view.body, context)],
    [Bind dynamic properties, then recurse],
    [until a Renderable leaf is reached],
  ), fill: colors.green, name: <body>),

  node((2.3, 2.4), box-label(
    [FrameBuffer()],
    [Empty buffer – silent no-op],
  ), fill: colors.green, name: <empty>),

  node((0, 3.5), box-label(
    [FrameBuffer],
    [Cell surface of styled graphemes],
  ), fill: colors.purple, name: <buffer>),

  node((0.62, 3.5), box-label(
    [],
    [Text · VStack · HStack],
    [Button · Panel · Card],
    [ModifiedView · ContainerView],
  ), fill: colors.slate, name: <ex-direct>),

  node((1.5, 3.5), box-label(
    [],
    [Box · User-defined views],
    [Any view composing],
    [other views in body],
  ), fill: colors.slate, name: <ex-body>),

  node((2.3, 3.5), box-label(
    [],
    [Never-body views],
    [without Renderable],
  ), fill: colors.slate, name: <ex-empty>),

  edge(<entry>, <d1>, "-|>"),
  edge(<d1>, <direct>, "-|>", label: elabel[yes], label-side: left),
  edge(<d1>, <d2>, "-|>", label: elabel[no], label-side: right),
  edge(<d2>, <body>, "-|>", label: elabel[yes], label-side: left),
  edge(<d2>, <empty>, "-|>", label: elabel[no], label-side: right),

  edge(<direct>, <buffer>, "-|>"),
  edge(<body>, <entry>, "--|>", bend: 40deg, label: elabel[recurse], label-side: right),

  edge(<direct>, <ex-direct>, "..", stroke: 0.9pt + colors.edge),
  edge(<body>, <ex-body>, "..", stroke: 0.9pt + colors.edge),
  edge(<empty>, <ex-empty>, "..", stroke: 0.9pt + colors.edge),
)
