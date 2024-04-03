import gleam/iterator
import gleam/string
import konbini.{type Message, type Parser, expect, succeed}
import konbini/parsers.{drop}

pub fn parse(
  string: String,
  parser: Parser(_, value),
) -> Result(value, Message(_)) {
  let input = {
    use state <- iterator.unfold(string)

    case string.pop_grapheme(state) {
      Error(Nil) -> iterator.Done
      Ok(#(grapheme, state)) -> iterator.Next(grapheme, state)
    }
  }

  konbini.parse(input, parser)
}

pub fn grapheme(wanted: String) -> Parser(String, String) {
  use grapheme <- expect
  grapheme == wanted
}

pub fn string(wanted: String) -> Parser(String, String) {
  case string.to_graphemes(wanted) {
    [] -> succeed("")

    [first, ..rest] -> {
      use <- drop(grapheme(first))
      use <- drop(string(string.join(rest, "")))
      succeed(wanted)
    }
  }
}
