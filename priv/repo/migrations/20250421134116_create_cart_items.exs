defmodule EcommerceFinal.Repo.Migrations.CreateCartItems do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :price_when_carted, :integer
      add :quantity, :integer
      add :cart_id, references(:carts, on_delete: :delete_all)
      add :product_id, references(:products, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:cart_items, [:product_id])
    create index(:cart_items, [:cart_id, :product_id])
  end
end
