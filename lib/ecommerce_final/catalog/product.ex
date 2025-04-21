defmodule EcommerceFinal.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :title, :string
    field :price, :integer
    field :stock, :integer
    field :sold, :integer, default: 0

    many_to_many :categories, EcommerceFinal.Catalog.Category,
      join_through: "product_categories",
      on_replace: :delete,
      preload_order: [asc: :level]

    has_many :images, EcommerceFinal.Catalog.ProductImage, on_replace: :delete
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title, :description, :price, :stock])
    |> validate_required([:title, :description, :price, :stock])
    |> validate_number(:price, greater_than: 0)
  end
end
