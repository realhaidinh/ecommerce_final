defmodule EcommerceFinalWeb.Public.CheckoutLive.Success do
  alias EcommerceFinal.Payos
  alias EcommerceFinal.Orders
  alias EcommerceFinal.Orders.Order
  use EcommerceFinalWeb, :live_view
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Đơn hàng {@order.id} {get_order_status(@status)}
      </.header>

      <.table
        id="order-products"
        rows={@order.line_items}
        row_click={fn item -> JS.navigate(~p"/products/#{item.product.id}") end}
      >
        <:col :let={item} label="Sản phẩm">{item.product.title}</:col>

        <:col :let={item} label="Đơn giá">{item.price}</:col>

        <:col :let={item} label="Số lượng">{item.quantity}</:col>

        <:col :let={item} label="Thành tiền">{item.price * item.quantity}</:col>
      </.table>

      <h1>Tổng tiền {@order.total_price}</h1>

      <p>Họ tên người nhận: {@order.buyer_name}</p>

      <p>Địa chỉ nhận hàng: {@order.buyer_address}</p>

      <p>Số điện thoại nhận hàng: {@order.buyer_phone}</p>
      <a
        :if={@status == :pending}
        href={"#{Payos.get_checkout_url(@order.transaction_id)}"}
        rel="noopener noreferrer"
        target="_blank"
      >
        Thanh toán đơn hàng ngay
      </a>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    %{current_user: %{id: user_id}} = socket.assigns
    order = Orders.get_user_order_by_id!(user_id, params["order_id"])

    if params["id"] == order.transaction_id do
      socket = assign(socket, :order, order)
      handle_order_status(order, socket)
    else
      {:noreply, push_navigate(socket, to: "/")}
    end
  end

  defp handle_order_status(%Order{payment_type: :"Thanh toán khi nhận hàng"} = _, socket) do
    {:noreply, {:noreply, assign(socket, :status, :cod)}}
  end

  defp handle_order_status(%Order{payment_type: :"Thanh toán online"} = order, socket) do
    with {:ok, %{"data" => payment_data}} <-
           Payos.get_payment_link_information(order.transaction_id) do
      case payment_data["status"] do
        "PAID" ->
          {:noreply, assign(socket, :status, :paid)}

        "PENDING" ->
          {:noreply, assign(socket, :status, :pending)}

        "PROCESSING" ->
          {:noreply, assign(socket, :status, :processing)}

        "CANCELLED" ->
          socket =
            if order.status == :"Đã hủy" do
              socket
            else
              {:ok, order} = Orders.update_order(order, %{status: :"Đã hủy"})
              assign(socket, :order, order)
            end

          {:noreply, assign(socket, :status, :cancelled)}
      end
    else
      _ -> {:noreply, push_navigate(socket, to: ~p"/")}
    end
  end

  defp get_order_status(:pending), do: "đang thanh toán"
  defp get_order_status(:paid), do: "đã thanh toán"
  defp get_order_status(:processing), do: "đang xử lý thanh toán"
  defp get_order_status(:cancelled), do: "đã hủy thanh toán"
  defp get_order_status(:cod), do: "đã đặt thành công, thanh toán khi nhận hàng"
end
