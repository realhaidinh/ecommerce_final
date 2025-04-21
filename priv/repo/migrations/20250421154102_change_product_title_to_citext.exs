defmodule EcommerceFinal.Repo.Migrations.ChangeProductTitleToCitext do
  use Ecto.Migration

  def change do
    alter table("products") do
      modify :title, :citext
    end
  end
end
