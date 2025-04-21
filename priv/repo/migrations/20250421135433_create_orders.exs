defmodule EcommerceFinal.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :total_price, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :buyer_address, :string
      add :buyer_name, :string
      add :buyer_phone, :string
      add :status, :string
      add :transaction_id, :string
      add :payment_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:user_id])
  end
end
