defmodule EcommerceFinalWeb.Public.Cart do
  alias EcommerceFinal.ShoppingCart
  import Phoenix.LiveView
  use Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    cart = fetch_current_cart(socket.assigns.current_user)
    if connected?(socket), do: cart && ShoppingCart.subscribe(cart.id)

    {:cont,
     socket
     |> assign(:cart, cart)
     |> attach_hook(:cart_hook, :handle_info, &handle_info/2)}
  end

  defp handle_info({:cart_updated, updated_cart}, socket) do
    {:halt, assign(socket, :cart, updated_cart)}
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp fetch_current_cart(nil), do: nil

  defp fetch_current_cart(current_user) do
    if cart = ShoppingCart.get_cart_by_user_id(current_user.id) do
      cart
    else
      {:ok, new_cart} = ShoppingCart.create_cart(current_user.id)
      new_cart
    end
  end
end
