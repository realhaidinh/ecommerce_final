defmodule EcommerceFinal.Catalog.Review do
  use Ecto.Schema
  import Ecto.Changeset
  alias EcommerceFinal.Accounts.User
  alias EcommerceFinal.Catalog.Product

  schema "reviews" do
    field :rating, :integer
    field :content, :string
    belongs_to :user, User
    belongs_to :product, Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:rating, :content])
    |> validate_required([:rating, :content])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
  end
end
