defmodule EcommerceFinal.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :total_price, :integer
    field :buyer_address, :string
    field :buyer_phone, :string
    field :buyer_name, :string

    field :status, Ecto.Enum,
      values: [:"Chờ thanh toán", :"Đã thanh toán", :"Đang giao hàng", :"Đã giao hàng", :"Đã hủy"],
      default: :"Chờ thanh toán"

    field :payment_type, Ecto.Enum,
      values: [:"Thanh toán khi nhận hàng", :"Thanh toán online"],
      default: :"Thanh toán khi nhận hàng"

    field :transaction_id, :string

    has_many :line_items, EcommerceFinal.Orders.LineItem
    has_many :products, through: [:line_items, :product]
    belongs_to :user, EcommerceFinal.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :total_price,
      :user_id,
      :buyer_address,
      :buyer_phone,
      :buyer_name,
      :status,
      :payment_type,
      :transaction_id
    ])
    |> validate_required([:total_price, :buyer_address, :buyer_phone, :buyer_name, :payment_type])
  end
end
