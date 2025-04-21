defmodule EcommerceFinal.Repo.Migrations.ChangeCategoryLevelToGeneratedColumn do
  use Ecto.Migration

  def change do
    alter table("categories") do
      remove_if_exists :level
      add :level, :integer, generated: "ALWAYS AS (nlevel(path)) STORED"
    end
  end
end
