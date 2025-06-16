defmodule EcommerceFinal.Catalog.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :path, :string, default: "0"
    field :level, :integer
    field :title, :string
    field :product_count, :integer, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:title, :path])
    |> validate_required([:title, :path])
  end
end
