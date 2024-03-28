import gleam/string
import showtime/tests/should

import konbini.{
  Message, Position, any, choice, drop, end, keep, label, many, not_followed_by,
  parse, some, succeed,
}

import konbini/internal/parsers.{
  ascii_alphanumeric, ascii_lowercase, grapheme, spaces, string, surrounded_by,
}

pub type Part {
  Placeholder
  Reference(String)
  Static(String)
}

pub fn template_test() {
  let open = {
    use <- drop(label(string("{{"), "opening braces"))
    use <- drop(spaces())
    succeed(Nil)
  }

  let close = {
    use <- drop(spaces())
    use <- drop(label(string("}}"), "closing braces"))
    succeed(Nil)
  }

  let static = {
    use parts <- keep(
      some({
        use <- drop(not_followed_by(open))
        use grapheme <- keep(any())
        succeed(grapheme)
      }),
    )

    succeed(Static(string.join(parts, "")))
  }

  let reference = {
    let placeholder = {
      use <- drop(grapheme("_"))
      succeed(Placeholder)
    }

    let id = {
      let initial = ascii_lowercase()
      let symbol = choice(grapheme("-"), grapheme("_"))
      let subsequent = choice(symbol, ascii_alphanumeric())
      use first <- keep(initial)
      use rest <- keep(many(subsequent))
      succeed(Reference(string.join([first, ..rest], "")))
    }

    choice(label(placeholder, "placeholder"), label(id, "id"))
    |> surrounded_by(open, close)
  }

  let template = {
    use parts <- keep(many(choice(reference, static)))
    use <- drop(end())
    succeed(parts)
  }

  parse("one {{ two }} three {{_}} four", template)
  |> should.equal(
    Ok([
      Static("one "),
      Reference("two"),
      Static(" three "),
      Placeholder,
      Static(" four"),
    ]),
  )

  parse("one {{ / }} three {{_}} four", template)
  |> should.equal(Error(Message(Position(8), "/", ["placeholder", "id"])))

  parse("one {{ two }} three {{_x}} four", template)
  |> should.equal(Error(Message(Position(24), "x", ["closing braces"])))
}