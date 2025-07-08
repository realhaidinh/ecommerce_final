defmodule EcommerceFinal.Repo.Migrations.CreateProductEmbededdingIndex do
  use Ecto.Migration

  def change do
    create index(:products, ["embedding vector_cosine_ops"], using: :hnsw)
  end
end
