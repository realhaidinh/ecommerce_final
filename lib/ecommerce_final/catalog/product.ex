defmodule EcommerceFinal.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :title, :string
    field :price, :integer
    field :stock, :integer
    field :sold, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title, :description, :price, :stock, :sold])
    |> validate_required([:title, :description, :price, :stock, :sold])
  end
end
