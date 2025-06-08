defmodule EcommerceFinal.Utils.FormatUtil do
  def slugify(nil), do: ""

  def slugify(input) do
    input
    |> Unidecode.decode()
    |> String.downcase()
    |> String.trim()
    |> String.normalize(:nfkd)
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/[\s-]+/, "-", global: true)
  end

  def money_to_vnd(money) do
    money =
      money
      |> Integer.to_charlist()
      |> Enum.reverse()
      |> Enum.chunk_every(3, 3, [])
      |> Enum.join(".")
      |> String.reverse()

    money <> " đ"
  end
end
