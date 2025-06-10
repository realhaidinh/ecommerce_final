defmodule EcommerceFinal.Repo.Migrations.AddCartItemsUniqueIndex do
  use Ecto.Migration

  def change do
    drop_if_exists index(:cart_items, [:cart_id, :product_id])
    create unique_index(:cart_items, [:cart_id, :product_id], name: :unique_cart_item)
  end
end
