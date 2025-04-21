defmodule EcommerceFinal.Repo do
  use Ecto.Repo,
    otp_app: :ecommerce_final,
    adapter: Ecto.Adapters.Postgres
end
