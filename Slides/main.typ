#import "./touying/lib.typ": *
#import "./theme_latemplate_slides.typ": *

#import "@preview/numbly:0.1.0": numbly

// Utility to create multi-colum slides easily
#let even_columns(
  inset: 0.5em,    // Space between cells
  cell_align: top, // Alignment inside each cell
  ..contents       // Columns
) = table(
  columns: (1fr,)*contents.pos().len(),
  inset: inset,
  ..(contents.pos().map(content =>
      [#set std.align(cell_align)  // Set alignment inside each cell
       #content]
  ))
)

#show: latemplate_slides-theme.with(
  aspect-ratio: "16-9",
  footer: self => [self.info.institution ],
  config-info(
    title: [Title],
    subtitle: [Subtitle],
    author: [Authors],
    date: datetime.today(),
    institution: [Institution],
    logo: [Test],
  ),
  skip_sections_n_first: 1,
  skip_sections_n_slides_last: 1,
)

// Outline and heading numbering setup
#show heading.where(level: 1): set heading(numbering: "I")
#set heading(numbering: (first, ..other) => // Show heading number for level 1 only
  if other.pos().len() == 0 { return first }
)

#title-slide(
  extra: [#image("../Letter/assets/mail.svg", height: 1cm)]
)

= Outline <touying:hidden>
#outline(title: none, indent: 1em, depth: 2)

= First Section

#focus-slide[
  Focus !
]

== A long long long long long long long long long long long long long long long long long long long long long long Title

#even_columns(
  [
    === Subsection 1
    A slide with equation:
    #pause
    $ x_(n+1) = (x_n + a / x_n) / 2 $
  ],
  [
    === Subsection 2
    #lorem(2)
    #pause
    #lorem(4)
  ]
)

= Conclusion

--- 

Empty sections cause issues with slide counting...

#show: appendix
= Appendix

---