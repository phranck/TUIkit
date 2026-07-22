// Shared style for TUIkit DocC diagrams.
//
// Every diagram imports this file so that colors, fonts, and node shapes stay
// consistent across the documentation. The palette was sampled from the
// original diagram set (TUIkit green palette); output PNGs use a transparent
// background so one image serves both DocC light and dark mode.
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let colors = (
  green: rgb("#2e8b7a"),
  green-dark: rgb("#287a6b"),
  green-bright: rgb("#1a9e76"),
  teal: rgb("#1a7f8a"),
  slate: rgb("#5a6b7a"),
  edge: rgb("#64748b"),
  blue: rgb("#4285f4"),
  purple: rgb("#7c4dff"),
  orange: rgb("#e8851c"),
)

// Applies page and text defaults for a diagram document.
#let diagram-page(body) = {
  set page(width: auto, height: auto, margin: 6pt, fill: none)
  set text(font: ("SF Pro Text", "Helvetica Neue"), fill: white)
  body
}

// A rounded box body: bold title line plus smaller detail lines.
#let box-label(title, ..lines) = {
  set align(center)
  set par(leading: 0.5em)
  text(weight: 700, size: 10pt)[#title]
  for l in lines.pos() {
    linebreak()
    text(size: 8pt)[#l]
  }
}

// An orange decision diamond with a bold two-line label.
#let decision(pos, label, name: none) = node(
  pos,
  align(center, text(weight: 700, size: 9pt)[#label]),
  fill: colors.orange,
  shape: fletcher.shapes.diamond,
  inset: 6pt,
  name: name,
)

// A small italic edge annotation ("yes", "not consumed", ...).
#let elabel(content) = text(size: 8pt, fill: colors.edge, style: "italic")[#content]
