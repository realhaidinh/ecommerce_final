defmodule EcommerceFinalWeb.Public.CheckoutLive.FormComponent do
  alias EcommerceFinal.Payos
  alias EcommerceFinal.Orders
  alias EcommerceFinal.Orders.Order
  alias EcommerceFinal.Utils.FormatUtil
  use EcommerceFinalWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.table id="order-products" rows={@cart.cart_items}>
        <:col :let={item} label="Sản phẩm">{item.product.title}</:col>

        <:col :let={item} label="Đơn giá">{FormatUtil.money_to_vnd(item.price_when_carted)}</:col>

        <:col :let={item} label="Số lượng">{item.quantity}</:col>

        <:col :let={item} label="Thành tiền">{FormatUtil.money_to_vnd(item.price_when_carted * item.quantity)}</:col>
      </.table>

      <.simple_form for={@changeset} id="order-form" phx-target={@myself} phx-submit="pay">
        <.input field={@changeset[:buyer_name]} type="text" label="Họ tên" />
        <.input field={@changeset[:buyer_address]} type="text" label="Địa chỉ" />
        <.input field={@changeset[:buyer_phone]} type="text" label="Số điện thoại" />
        <.input
          field={@changeset[:payment_type]}
          type="select"
          label="Phương thức thanh toán"
          options={payment_opts()}
        />
        <:actions>
          <.button phx-disable-with="..." data-confirm="Xác nhận đặt hàng">Đặt hàng</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:changeset, fn ->
       to_form(Ecto.Changeset.change(%Order{}))
     end)}
  end

  @impl true
  def handle_event("pay", %{"order" => order_params}, socket) do
    handle_payment(order_params, socket.assigns.cart, socket)
  end

  defp handle_payment(
         %{"payment_type" => "Thanh toán khi nhận hàng"} = order_params,
         cart,
         socket
       ) do
    {:ok, order} =
      Orders.make_order(cart, order_params)

    {:noreply, push_navigate(socket, to: ~p"/checkout/success/#{order.id}")}
  end

  defp handle_payment(%{"payment_type" => "Thanh toán online"} = order_params, cart, socket) do
    {:ok, order} =
      Orders.make_order(cart, order_params)

    payment_data =
      Payos.create_payment_data(%{
        amount: order.total_price,
        description: "TTDH-#{order.id}",
        return_url: url(~p"/checkout/success/#{order.id}")
      })

    {:ok, %{"data" => payment_link}} = Payos.create_payment_link(payment_data)
    Orders.update_order(order, %{transaction_id: payment_link["paymentLinkId"]})

    {:noreply, redirect(socket, external: payment_link["checkoutUrl"])}
  end

  defp payment_opts,
    do: [
      [key: "Thanh toán khi nhận hàng", value: "Thanh toán khi nhận hàng", selected: true],
      [key: "Thanh toán online", value: "Thanh toán online", selected: false]
    ]
end
