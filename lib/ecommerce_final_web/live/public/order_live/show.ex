defmodule EcommerceFinalWeb.Public.OrderLive.Show do
  use EcommerceFinalWeb, :live_view
  alias EcommerceFinal.Orders
  alias EcommerceFinal.Payos
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {EcommerceFinalWeb.Layouts, :public_profile}}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    order = Orders.get_user_order_by_id!(socket.assigns.current_user.id, id)

    {:noreply,
     socket
     |> assign(:page_title, "Đơn hàng #{order.id}")
     |> assign(:order, order)}
  end

  @impl true
  def handle_event("cancel-order", _unsigned_params, socket) do
    order = socket.assigns.order

    with {:ok, _} <- Payos.cancel_payment_link(order.transaction_id),
         {:ok, order} <-
           Orders.update_order(order, %{status: :"Đã hủy"}) do
      {:noreply,
       socket
       |> assign(:order, order)
       |> put_flash(:info, "Đã hủy đơn hàng #{order.id}")}
    else
      error -> {:noreply, put_flash(socket, :error, "Xảy ra lỗi #{inspect(error)}")}
    end
  end
end
