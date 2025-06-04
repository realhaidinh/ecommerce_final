defmodule EcommerceFinal.Repo.Migrations.AddProductTitleUnaccented do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS unaccent;"

    execute "CREATE OR REPLACE FUNCTION f_unaccent(text) RETURNS text
    AS $$
    SELECT public.unaccent('public.unaccent', $1);
    $$ LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT;
    "

    alter table("products") do
      add :title_unaccented, :citext, generated: "ALWAYS AS (f_unaccent(title)::citext) STORED"
    end

    create index(:products, :title_unaccented)
  end
end
