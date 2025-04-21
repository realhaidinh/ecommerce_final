defmodule EcommerceFinal.Catalog.ProductImage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_images" do
    field :url, :string
    belongs_to :product, EcommerceFinal.Catalog.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product_image, attrs) do
    product_image
    |> cast(attrs, [:url])
    |> validate_required([:url])
  end
end
