defmodule EcommerceFinalWeb.Admin.Dashboard.OrderLive.Index do
  alias EcommerceFinal.Orders
  use EcommerceFinalWeb, :live_view

  @impl true
  def mount(_, _session, socket) do
    {:ok, assign(socket, :page_title, "Quản lý đơn hàng")}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, stream(socket, :orders, Orders.list_orders())}
  end
end
