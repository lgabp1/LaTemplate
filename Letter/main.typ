#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/subpar:0.2.2"
#show: codly-init.with()

#import "latemplate.typ": latemplate
#import "lalib.typ": place_at, emphasis_text, insert_toc, insert_annex_page, hidden_heading

#set par(
  first-line-indent: 1em,
  spacing: 1.2em,
  justify: true,
)

#set text(size: 12pt)

// Enable equation numbering for subfigure references
#set math.equation(numbering: "1.")

// ==== Body ====

#latemplate(
  title: [_LaTemplate_: Letter template],
  title_size: 21pt,
  header_content: (
    left: [
      *Name SURNAME*

      #grid(
        columns: (1.6em, 8em, 1.6em, 1.6em, 8em),
        align: (left, left, left, left, left),
        stroke: none,
        [#image("assets/mail.svg", height: 1em)],
        [#link("mailto:some@mail.com")[some\@mail.com]],
        [|],
        [#image("assets/phone.svg", height: 1em)],
        [+12 3456 7890],
      )
      ],
    right: [
      DESTINATION
    ],
  ),
  page_numbering: none,
  heading_numbering: "I.A.1",
  column_count: 1,
)[

Dear Sir or Madam,

#lorem(40)

#lorem(60)

#set par(first-line-indent: 0em) // No indent for closing line
Yours Sincerely,

Name

]


