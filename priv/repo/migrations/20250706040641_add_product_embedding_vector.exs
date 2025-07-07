defmodule EcommerceFinal.Repo.Migrations.AddProductEmbeddingVector do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    alter table("products") do
      add :embedding, :vector, size: 1024
    end
  end
end
