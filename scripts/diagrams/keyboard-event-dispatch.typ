// Keyboard event dispatch (KeyboardShortcuts.md, "Overview").
//
// The five-layer, first-consumer-wins model. Layer 0 (text input) and
// Layer 3 (focus system) are mutually exclusive: both hasTextInputFocus
// gates route around the layer that must not run.
#import "style.typ": *

#show: diagram-page

#diagram(
  spacing: (32pt, 18pt),
  ..diagram-defaults,

  node((0, 0), box-label(
    [Terminal raw bytes],
  ), fill: colors.slate),

  node((0, 1), box-label(
    [KeyEvent.parse()],
  ), fill: colors.green-bright),

  decision((0, 2), [hasText \ InputFocus?], name: <gate0>),

  node((0, 3), box-label(
    [Layer 0 · Text Input],
    [focusManager.dispatchKeyEvent()],
    [TextField / SecureField priority],
  ), fill: colors.teal, name: <layer0>),

  node((0, 4), box-label(
    [Layer 1 · Status Bar Items],
    [statusBar.handleKeyEvent()],
    [Shortcut-triggered actions],
  ), fill: colors.green, name: <layer1>),

  node((0, 5), box-label(
    [Layer 2 · View Handlers],
    [keyEventDispatcher.dispatch()],
    [.onKeyPress modifiers (deepest first)],
  ), fill: colors.green, name: <layer2>),

  decision((0, 6), [hasText \ InputFocus?], name: <gate3>),

  node((0, 7), box-label(
    [Layer 3 · Focus System],
    [focusManager.dispatchKeyEvent()],
    [Focused element → Tab/Shift+Tab],
    [→ Arrow key fallback],
  ), fill: colors.green, name: <layer3>),

  node((0, 8), box-label(
    [Layer 4 · Default Bindings],
    [q quit · t theme · a appearance],
  ), fill: colors.teal, name: <layer4>),

  node((0, 9), text(size: 8.5pt, style: "italic")[Event dropped], fill: colors.slate),

  node((1.7, 4.5), box-label(
    [Event consumed],
  ), fill: colors.green-bright, name: <consumed>),

  edge((0, 0), (0, 1), "-|>"),
  edge((0, 1), (0, 2), "-|>"),

  edge(<gate0>, <layer0>, "-|>", label: elabel[yes], label-side: left),
  edge(<gate0>, (0.58, 2), (0.58, 3.5), <layer1>, "-|>", label: elabel[no], label-pos: 0.06, label-side: right),

  edge(<layer0>, <layer1>, "-|>", label: elabel[not consumed], label-side: left),
  edge(<layer1>, <layer2>, "-|>", label: elabel[not consumed], label-side: left),
  edge(<layer2>, <gate3>, "-|>", label: elabel[not consumed], label-side: left),

  edge(<gate3>, <layer3>, "-|>", label: elabel[no], label-side: left),
  edge(<gate3>, (0.58, 6), (0.58, 7.5), <layer4>, "-|>", label: elabel[yes], label-pos: 0.06, label-side: right),

  edge(<layer3>, <layer4>, "-|>", label: elabel[not consumed], label-side: left),
  edge(<layer4>, (0, 9), "-|>", label: elabel[not consumed], label-side: left),

  edge(<layer0>, (1.7, 3), <consumed>, "-|>", label: elabel[consumed], label-pos: 0.28, label-side: left),
  edge(<layer1>, (1.7, 4), <consumed>, "-|>", label: elabel[consumed], label-pos: 0.3, label-side: left),
  edge(<layer2>, (1.7, 5), <consumed>, "-|>", label: elabel[consumed], label-pos: 0.3, label-side: left),
  edge(<layer3>, (1.7, 7), <consumed>, "-|>", label: elabel[consumed], label-pos: 0.28, label-side: left),
)
