// The dual rendering dispatch (RenderCycle.md, "The Dispatch Function").
//
// renderToBuffer() checks Renderable conformance first, then recurses into
// body (binding dynamic properties on the way), and falls back to an empty
// buffer for Never-body views without Renderable.
//
// Layout: both decision diamonds share one row, the three outcome boxes share
// the next row, and the example boxes sit in a clearly separated bottom row.
#import "style.typ": *

#show: diagram-page

#diagram(
  spacing: (34pt, 26pt),
  ..diagram-defaults,

  node((1, 0), box-label(
    [renderToBuffer(view, context)],
    [Free function – single entry point],
  ), fill: colors.blue, name: <entry>),

  decision((1, 1), [view is \ Renderable?], name: <d1>),

  decision((2, 1), [Body ≠ \ Never?], name: <d2>),

  node((0, 2), box-label(
    [Renderable.renderToBuffer(context:)],
    [Direct rendering to FrameBuffer],
    [body is never called],
  ), fill: colors.green, name: <direct>),

  node((1, 2), box-label(
    [renderToBuffer(view.body, context)],
    [Bind dynamic properties, then recurse],
    [until a Renderable leaf is reached],
  ), fill: colors.green, name: <body>),

  node((3, 2), box-label(
    [FrameBuffer()],
    [Empty buffer – silent no-op],
  ), fill: colors.green, name: <empty>),

  node((0, 3), box-label(
    [FrameBuffer],
    [Cell surface of styled graphemes],
  ), fill: colors.purple, name: <buffer>),

  node((1, 3), box-label(
    [],
    [Text · VStack · HStack],
    [Button · Panel · Card],
    [ModifiedView · ContainerView],
  ), fill: colors.slate, name: <ex-direct>),

  node((2, 3), box-label(
    [],
    [Box · User-defined views],
    [Any view composing],
    [other views in body],
  ), fill: colors.slate, name: <ex-body>),

  node((3, 3), box-label(
    [],
    [Never-body views],
    [without Renderable],
  ), fill: colors.slate, name: <ex-empty>),

  edge(<entry>, <d1>, "-|>"),
  edge(<d1>, <d2>, "-|>", label: elabel[no], label-side: left),
  edge(<d1>, <direct>, "-|>", label: elabel[yes], label-side: left),
  edge(<d2>, <body>, "-|>", label: elabel[yes], label-side: left),
  edge(<d2>, <empty>, "-|>", label: elabel[no], label-side: right),

  edge(<direct>, <buffer>, "-|>"),
  edge(<body>, (0.45, 1), <entry>, "--|>", label: elabel[recurse], label-pos: 0.3, label-side: left),

  edge(<direct>, <ex-direct>, "..", stroke: 0.7pt + colors.edge.transparentize(45%)),
  edge(<body>, <ex-body>, "..", stroke: 0.7pt + colors.edge.transparentize(45%)),
  edge(<empty>, <ex-empty>, "..", stroke: 0.7pt + colors.edge.transparentize(45%)),
)
