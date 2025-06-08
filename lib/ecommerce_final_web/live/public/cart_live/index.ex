defmodule EcommerceFinalWeb.Public.CartLive.Index do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.ShoppingCart

  @impl true
  def mount(_params, _session, socket) do
    cart = socket.assigns.cart
    if connected?(socket), do: ShoppingCart.subscribe(cart.id)
    {:ok, assign(socket, :page_title, "Giỏ hàng")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove", %{"product_id" => product_id}, socket) do
    {:ok, _cart} = ShoppingCart.remove_item_from_cart(socket.assigns.cart, product_id)
    {:noreply, put_flash(socket, :info, "Sản phẩm đã bị xóa khỏi giỏ hàng")}
  end
end
