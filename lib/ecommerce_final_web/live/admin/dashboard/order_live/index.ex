defmodule EcommerceFinalWeb.Admin.Dashboard.OrderLive.Index do
  alias EcommerceFinal.Orders
  use EcommerceFinalWeb, :live_view

  @impl true
  def mount(_, _session, socket) do
    if connected?(socket), do: Orders.subscribe("orders")
    socket =
      socket
      |> assign(:page_title, "Quản lý đơn hàng")
      |> stream(:orders, Orders.list_orders())
    {:ok, socket}
  end


  @impl true
  def handle_info({:new_order, order}, socket) do
    {:noreply, stream_insert(socket, :orders, order, at: 0)}
  end

  def handle_info({:update_order, order}, socket) do
    {:noreply, stream_insert(socket, :orders, order)}
  end
end
