defmodule EcommerceFinal.Orders.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_line_items" do
    field :price, :integer
    field :quantity, :integer

    belongs_to :order, EcommerceFinal.Orders.Order
    belongs_to :product, EcommerceFinal.Catalog.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:price, :quantity])
    |> validate_required([:price, :quantity])
  end
end
