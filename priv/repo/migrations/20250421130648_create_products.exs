defmodule EcommerceFinal.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :title, :string
      add :description, :string
      add :price, :integer
      add :stock, :integer
      add :sold, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
