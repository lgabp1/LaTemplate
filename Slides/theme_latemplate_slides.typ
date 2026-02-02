// Theme file based on https://github.com/touying-typ/touying/blob/main/themes/metropolis.typ

// This theme is inspired by https://github.com/matze/mtheme
// The origin code was written by https://github.com/Enivex

#import "./touying/src/exports.typ": *

/// Default slide function for the presentation.
///
/// - title (string): The title of the slide. Default is `auto`.
///
/// - config (dictionary): The configuration of the slide. You can use `config-xxx` to set the configuration of the slide. For several configurations, you can use `utils.merge-dicts` to merge them.
///
/// - repeat (int, string): The number of subslides. Default is `auto`, which means touying will automatically calculate the number of subslides.
///
///   The `repeat` argument is necessary when you use `#slide(repeat: 3, self => [ .. ])` style code to create a slide. The callback-style `uncover` and `only` cannot be detected by touying automatically.
///
/// - setting (function): The setting of the slide. You can use it to add some set/show rules for the slide.
///
/// - composer (function, array): The composer of the slide. You can use it to set the layout of the slide.
///
///   For example, `#slide(composer: (1fr, 2fr, 1fr))[A][B][C]` to split the slide into three parts. The first and the last parts will take 1/4 of the slide, and the second part will take 1/2 of the slide.
///
///   If you pass a non-function value like `(1fr, 2fr, 1fr)`, it will be assumed to be the first argument of the `components.side-by-side` function.
///
///   The `components.side-by-side` function is a simple wrapper of the `grid` function. It means you can use the `grid.cell(colspan: 2, ..)` to make the cell take 2 columns.
///
///   For example, `#slide(composer: 2)[A][B][#grid.cell(colspan: 2)[Footer]]` will make the `Footer` cell take 2 columns.
///
///   If you want to customize the composer, you can pass a function to the `composer` argument. The function should receive the contents of the slide and return the content of the slide, like `#slide(composer: grid.with(columns: 2))[A][B]`.
///
/// - bodies (array): The contents of the slide. You can call the `slide` function with syntax like `#slide[A][B][C]` to create a slide.
#let slide(
  title: auto,
  align: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  if align != auto {
    self.store.align = align
  }
  let header(self) = {
    set std.align(top)
    show: components.cell.with(fill: self.colors.secondary, inset: 1em)
    set std.align(horizon)
    set text(fill: self.colors.neutral-lightest, weight: "medium", size: 1.2em)
    components.left-and-right(
      {
        if title != auto {
          utils.fit-to-width(grow: false, 100%, title)
        } else {
          utils.call-or-display(self, self.store.header)
        }
      },
      utils.call-or-display(self, self.store.header-right),
    )
  }
  let footer(self) = {
    set std.align(bottom)
    // Footer background
    show: components.cell.with(fill: self.colors.primary-light, inset: 0em)
    set std.align(horizon)
    set text(size: 1em)

    // Build a table with one column per section and a final page-counter column
    context {
      // Get the actual physical page number where this footer is being rendered
      let current_phys_page = here().page()
      let current_phys_page_visible = current_phys_page

      // Query level-1 headings (`.final()` not available on arrays in some runtimes)
      let all_sections = query(heading.where(level: 1))
      // Apply optional skipping of first/last sections as requested by theme params
      let skip_first = if self.store.skip_sections_n_first != none and self.store.skip_sections_n_first > 0 { self.store.skip_sections_n_first } else { 0 }
      let skip_last = if self.store.skip_sections_n_slides_last != none and self.store.skip_sections_n_slides_last > 0 { self.store.skip_sections_n_slides_last } else { 0 }

      // Bound indices to valid range
      let total_all_sections = all_sections.len()
      let start_idx = calc.min(skip_first, total_all_sections)
      let end_idx_raw = total_all_sections - skip_last
      let end_idx = if end_idx_raw < start_idx { start_idx } else { end_idx_raw }

      // Build the trimmed sections list used for the footer
      let sections = ()
      let i = start_idx
      while i < end_idx {
        sections.push(all_sections.at(i))
        i = i + 1
      }

      let all_slides = query(heading.where(level: 2))

      let footer_columns = ()
      let total_sections = sections.len()

      // Helper to build dot string for a section using the same logic everywhere
      // Accept section index to avoid calling a non-existent `index_of` method on arrays
      // Strategy: One dot per level-2 heading (slide), plus one dot for intro content if any
      let make_dot_str = (section, sec_idx) => {
        let section_start_page = section.location().page()
        let next_section_start_page = if sec_idx + 1 < total_sections {
          sections.at(sec_idx + 1).location().page()
        } else { 9999 }

        // Get all level-2 headings (slides) in this section
        let section_slides = all_slides.filter(sl => {
          let sl_page = sl.location().page()
          sl_page > section_start_page and sl_page < next_section_start_page
        })

        let s = ""

        // Check if there's an intro slide (content before first level-2 heading)
        let first_slide_page = if section_slides.len() > 0 {
          section_slides.at(0).location().page()
        } else { section_start_page + 1 }

        // Only add intro dot if there's a gap between section header and first slide
        if first_slide_page > section_start_page + 1 {
          let intro_page = section_start_page + 1
          let is_filled = intro_page <= current_phys_page_visible
          s = s + (if is_filled { "● " } else { "○ " })
        }

        // One dot per level-2 heading (slide)
        for sl in section_slides {
          let sl_page = sl.location().page()
          let is_filled = sl_page <= current_phys_page_visible
          s = s + (if is_filled { "● " } else { "○ " })
        }

        s.trim()
      }

      for (sec_idx, section) in sections.enumerate() {
        let dot_str = make_dot_str(section, sec_idx)
        footer_columns.push(
          stack(dir: ttb, spacing: 0pt)[
            #text(fill: self.colors.neutral-darkest, size: 0.7em, section.body)
            #v(-0.7em)
            #text(fill: self.colors.neutral-darkest, size: 0.7em, dot_str)
          ],
        )
      }

      // Page counter column using slide counter API (shows current slide / total slides)
      footer_columns.push(
        std.align(block()[
            #text(fill: self.colors.neutral-darkest, size: 0.9em, context str(utils.slide-counter.get().first()) + " / " + utils.last-slide-number)
          ],
          right
        )
      )

      // Column specification: flexible columns for sections and an auto column for the counter
      let col_spec = (footer_columns.len() - 1) * (1fr,) + (auto,)

      // Build final footer table
      let footer_table = table(
        columns: col_spec,
        stroke: none,
        inset: (top: 0.2em, bottom: 0pt, left: 0.6em, right: 0.6em),
        fill: self.colors.primary-light,
        align: center + bottom,
        ..footer_columns,
      )

      footer_table
    }

    if self.store.footer-progress {
      // Progress bar stays at the bottom
      place(bottom, components.progress-bar(
        height: 2pt,
        self.colors.primary,
        self.colors.primary-light,
      ))
    }
  }
  let self = utils.merge-dicts(
    self,
    config-page(
      fill: self.colors.neutral-lightest,
      header: header,
      footer: footer,
    ),
  )
  let new-setting = body => {
    show: std.align.with(self.store.align)
    set text(fill: self.colors.neutral-darkest)
    show: setting
    body
  }
  touying-slide(
    self: self,
    config: config,
    repeat: repeat,
    setting: new-setting,
    composer: composer,
    ..bodies,
  )
})


/// Title slide for the presentation. You should update the information in the `config-info` function. You can also pass the information directly to the `title-slide` function.
///
/// Example:
///
/// ```typst
/// #show: latemplate_slides-theme.with(
///   config-info(
///     title: [Title],
///     logo: emoji.city,
///   ),
/// )
///
/// #title-slide(subtitle: [Subtitle], extra: [Extra information])
/// ```
///
/// - config (dictionary): The configuration of the slide. You can use `config-xxx` to set the configuration of the slide. For several configurations, you can use `utils.merge-dicts` to merge them.
///
/// - extra (string, none): The extra information you want to display on the title slide.
#let title-slide(
  config: (:),
  extra: none,
  ..args,
) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config,
    config-common(freeze-slide-counter: true),
    config-page(fill: self.colors.neutral-lightest),
  )
  let info = self.info + args.named()
  let body = {
    set text(fill: self.colors.neutral-darkest)
    // Top half - colored background, absolutely positioned to ignore margins
    place(top + left, dx: -2em, dy: -3em, block(
      width: 115%,
      height: 60%,
      fill: self.colors.secondary,
      {
        set text(fill: rgb(self.colors.neutral-lightest))
        set std.align(bottom)
        pad(
          x: 2em,
          y: 1em,
          components.left-and-right(
            {
              text(size: 2em, text(weight: "medium", info.title))
            },
            [
              #text(2em, utils.call-or-display(self, info.logo))
              #h(1em)
            ]
          )
        )
      }
    ))
    // Bottom half: 4 sections
    place(bottom, {
      set text(fill: self.colors.neutral-dark, size: 1em)
      pad(top:45%)[
        #grid(
          columns: (1fr, 1fr),
          rows: (1fr, auto),
          inset: 0.2em,
          grid.cell(colspan: 2)[ // Top
            #align(top)[
              #if info.subtitle != none {
                text(info.subtitle, size: 1.5em)
              }
            ]
          ],
          { // Bottom left
            let fields = ()
            if info.date != none {fields.push(utils.display-info-date(self))}
            if info.author != none {fields.push(info.author)}
            stack(dir: ttb, spacing: 0.4em, ..fields)
          },
          { // Bottom right
            let fields = ()
            if info.institution != none {fields.push(info.institution)}
            if extra != none {fields.push(extra)}

            align(stack(dir: ttb, spacing: 0.4em, ..fields), right)
          },
        )
      ]
    })
  }
  touying-slide(self: self, body)
})


/// New section slide for the presentation. You can update it by updating the `new-section-slide-fn` argument for `config-common` function.
///
/// Example: `config-common(new-section-slide-fn: new-section-slide.with(numbered: false))`
///
/// - config (dictionary): The configuration of the slide. You can use `config-xxx` to set the configuration of the slide. For several configurations, you can use `utils.merge-dicts` to merge them.
///
/// - level (int): The level of the heading.
///
/// - numbered (boolean): Indicates whether the heading is numbered.
///
/// - body (auto): The body of the section. It will be passed by touying automatically.
#let new-section-slide(
  config: (:),
  level: 1,
  numbered: true,
  body,
) = touying-slide-wrapper(self => {
  let slide-body = {
    set std.align(horizon)
    show: pad.with(20%)
    set text(size: 1.5em)
    stack(
      dir: ttb,
      spacing: 1em,
      text(self.colors.neutral-darkest, utils.display-current-heading(
        level: level,
        numbered: numbered,
        style: auto,
      )),
      block(
        height: 2pt,
        width: 100%,
        spacing: 0pt,
        fill: self.colors.secondary, // No progress bar
      ),
    )
    text(self.colors.neutral-dark, body)
  }
  self = utils.merge-dicts(
    self,
    config-page(fill: self.colors.neutral-lightest),
  )
  touying-slide(self: self, config: config, slide-body)
})


/// Focus on some content.
///
/// Example: `#focus-slide[Wake up!]`
///
/// - config (dictionary): The configuration of the slide. You can use `config-xxx` to set the configuration of the slide. For several configurations, you can use `utils.merge-dicts` to merge them.
///
/// - align (alignment): The alignment of the content. Default is `horizon + center`.
#let focus-slide(
  config: (:),
  align: horizon + center,
  body,
) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-common(),
    config-page(fill: self.colors.neutral-dark, margin: 2em),
  )
  set text(fill: self.colors.neutral-lightest, size: 1.5em)
  touying-slide(self: self, config: config, std.align(align, hide[#heading(level: 2, outlined: false, bookmarked: false)[]] + body))
})


/// Touying latemplate_slides theme.
///
/// Example:
///
/// ```typst
/// #show: latemplate_slides-theme.with(aspect-ratio: "16-9", config-colors(primary: blue))`
/// ```
///
/// Consider using:
///
/// ```typst
/// #set text(font: "Fira Sans", weight: "light", size: 20pt)`
/// #show math.equation: set text(font: "Fira Math")
/// #set strong(delta: 100)
/// #set par(justify: true)
/// ```
///
/// The default colors:
///
/// ```typ
/// config-colors(
///   primary: rgb("#eb811b"),
///   primary-light: rgb("#d6c6b7"),
///   secondary: rgb("#23373b"),
///   neutral-lightest: rgb("#fafafa"),
///   neutral-dark: rgb("#23373b"),
///   neutral-darkest: rgb("#23373b"),
/// )
/// ```
///
/// - aspect-ratio (string): The aspect ratio of the slides. Default is `16-9`.
///
/// - align (alignment): The alignment of the content. Default is `horizon`.
///
/// - header (content, function): The header of the slide. Default is `self => utils.display-current-heading(setting: utils.fit-to-width.with(grow: false, 100%), depth: self.slide-level)`.
///
/// - header-right (content, function): The right part of the header. Default is `self => self.info.logo`.
///
/// - footer (content, function): The footer of the slide. Default is `none`.
///
/// - footer-right (content, function): The right part of the footer. Default is `context utils.slide-counter.display() + " / " + utils.last-slide-number`.
///
/// - footer-progress (boolean): Whether to show the progress bar in the footer. Default is `true`.
#let latemplate_slides-theme(
  aspect-ratio: "16-9",
  align: horizon,
  header: self => utils.display-current-heading(
    setting: utils.fit-to-width.with(grow: false, 100%),
    depth: self.slide-level,
  ),
  header-right: self => self.info.logo,
  footer: none,
  footer-right: context utils.slide-counter.display()
    + " / "
    + utils.last-slide-number,
  footer-progress: false,
  skip_sections_n_first: none,
  skip_sections_n_slides_last: none,
  ..args,
  body,
) = {
  set text(size: 20pt)

  show: touying-slides.with(
    config-page(
      paper: "presentation-" + aspect-ratio,
      header-ascent: 30%,
      footer-descent: -30%,
      margin: (top: 3em, bottom: 1.5em, x: 2em),
    ),
    config-common(
      slide-fn: slide,
      new-section-slide-fn: new-section-slide,
    ),
    config-methods(
      alert: utils.alert-with-primary-color,
    ),
    config-colors(
      primary: rgb("#eb811b"),
      primary-light: rgb("#d6c6b7"),
      secondary: rgb("#23373b"),
      neutral-lightest: rgb("#fafafa"),
      neutral-dark: rgb("#23373b"),
      neutral-darkest: rgb("#23373b"),
    ),
    // save the variables for later use
    config-store(
      align: align,
      header: header,
      header-right: header-right,
      footer: footer,
      footer-right: footer-right,
      footer-progress: footer-progress,
      skip_sections_n_first: skip_sections_n_first,
      skip_sections_n_slides_last: skip_sections_n_slides_last,
    ),
    ..args,
  )

  body
}

