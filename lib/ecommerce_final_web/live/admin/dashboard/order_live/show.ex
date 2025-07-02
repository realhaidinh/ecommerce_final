defmodule EcommerceFinalWeb.Admin.Dashboard.OrderLive.Show do
  alias EcommerceFinal.Orders.OrderNotifier
  alias EcommerceFinal.Orders
  use EcommerceFinalWeb, :live_view
  alias EcommerceFinal.Utils.{FormatUtil, TimeUtil}
  @impl true
  def mount(_, _session, socket) do
    {:ok, assign(socket, :page_title, "Quản lý đơn hàng")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign(socket, :order, Orders.get_order!(id))}
  end

  @impl true
  def handle_event("delivered-confirm", _unsigned_params, socket) do
    {:ok, order} = Orders.update_order(socket.assigns.order, %{status: :"Đã giao hàng"})
    OrderNotifier.deliver_order_shipped(order, order.user.email)

    {:noreply,
     socket
     |> assign(:order, order)
     |> put_flash(:info, "Đơn hàng #{order.id} đã giao thành công")}
  end

  def handle_event("delivering-confirm", _unsigned_params, socket) do
    {:ok, order} = Orders.update_order(socket.assigns.order, %{status: :"Đang giao hàng"})

    {:noreply,
     socket
     |> assign(:order, order)
     |> put_flash(:info, "Đơn hàng #{order.id} đang được giao")}
  end
end
