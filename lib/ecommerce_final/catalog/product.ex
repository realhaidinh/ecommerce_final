defmodule EcommerceFinal.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset
  alias EcommerceFinal.Catalog.{Category, Review, ProductImage}

  schema "products" do
    field :description, :string
    field :title, :string
    field :price, :integer
    field :stock, :integer
    field :sold, :integer, default: 0
    field :rating, :decimal, virtual: true
    field :rating_count, :integer, virtual: true

    many_to_many :categories, Category,
      join_through: "product_categories",
      on_replace: :delete,
      preload_order: [asc: :level]

    has_many :reviews, Review, preload_order: [desc: :inserted_at]
    has_many :images, ProductImage, on_replace: :delete
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
