defmodule EcommerceFinalWeb.Public.OrderLive.Index do
  use EcommerceFinalWeb, :live_view
  alias EcommerceFinal.Orders
  alias EcommerceFinal.Utils.{FormatUtil, TimeUtil}
  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_user_orders(socket), layout: {EcommerceFinalWeb.Layouts, :public_profile}}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :page_title, "Đơn hàng của tôi")}
  end

  def load_user_orders(socket) do
    user_id = socket.assigns.current_user.id
    orders = Orders.list_user_orders(user_id)
    if connected?(socket), do: Orders.subscribe("user_orders:#{user_id}")
    stream(socket, :orders, orders)
  end

  @impl true
  def handle_info({_, order}, socket) do
    {:noreply, stream_insert(socket, :orders, order)}
  end

end
