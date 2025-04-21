defmodule EcommerceFinal.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION ltree"

    create table(:categories) do
      add :title, :string
      add :path, :ltree
      add :level, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:categories, [:path], using: "GIST")
  end
end
