defmodule FnChess.Pgn.Parser.Util do
  use Combine

  defmacro defparser(name, do: body) do
    quote do
      def unquote(name)(parser \\ nil) do
        label(parser |> unquote(body), unquote(Atom.to_string(name)))
      end
    end
  end

  def quoted_string(previous \\ nil) do
    previous
    |> between(char("\""), word_of(~r/[^"]+/), char("\""))
  end

  def words(previous \\ nil) do
    previous
    |> many(either(word(), whitespace()))
  end

  def map_keys(map, func) do
    map
    |> Enum.map(fn {k, v} -> {func.(k), v} end)
    |> Enum.into(%{})
  end

  def whitespace do
    [space(), tab(), newline()] |> choice()
  end

  def choice_from_map(previous, mapping) do
    choice(
      previous,
      Enum.map(mapping, fn {pgn, parsed} ->
        string(pgn) |> map(fn _ -> parsed end)
      end)
    )
  end

  def has_string(s) do
    option(string(s)) |> map(fn value -> value == s end)
  end
end
