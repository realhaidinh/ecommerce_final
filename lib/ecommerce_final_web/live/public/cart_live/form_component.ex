defmodule EcommerceFinalWeb.Public.CartLive.FormComponent do
  alias EcommerceFinal.ShoppingCart
  use EcommerceFinalWeb, :live_component

  alias EcommerceFinal.ShoppingCart
  alias EcommerceFinal.Utils.FormatUtil
  @impl true
  def render(assigns) do
    ~H"""
    <div class="mt-8 p-2">
      <div class="grid grid-cols-5 border-b-2 py-2">
        <span class="justify-self-center">Sản phẩm</span>
        <span class="justify-self-center">Đơn giá</span>
        <span class="justify-self-center">Số lượng</span>
        <span class="justify-self-center">Số tiền</span>
        <span class="justify-self-center">Thao tác</span>
      </div>
      <.simple_form
        :let={f}
        for={ShoppingCart.change_cart(@cart)}
        classes={["grid grid-cols-5 justify-items-center gap-y-8"]}
        phx-target={@myself}
        phx-change="update"
        phx-throttle="200"
        autocomplete="off"
      >
        <.inputs_for :let={%{data: item} = item_form} field={f[:cart_items]}>
          <label for={item_form[:quantity].id} class="hover:cursor-pointer self-center p-2">
            <.link href={~p"/products/#{item.product.id}"} class="">
              {item.product.title}
            </.link>
          </label>
          <span class="col-start-2 self-center">
            {FormatUtil.money_to_vnd(item.product.price)}
          </span>
          <input
            type="number"
            name={item_form[:quantity].name}
            id={item_form[:quantity].id}
            value={Phoenix.HTML.Form.normalize_value("number", item_form[:quantity].value)}
            min="0"
            max={item.product.stock}
            autocomplete="off"
            class="block self-center rounded-lg w-1/3 text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6"
          />
          <span class="col-start-4 self-center">
            {ShoppingCart.total_item_price(item) |> FormatUtil.money_to_vnd()}
          </span>
          <.link
            class="rounded-lg p-2 col-start-5 w-10 bg-zinc-900 h-fit self-center text-sm font-semibold leading-6 text-white"
            phx-click="remove"
            phx-value-product_id={item.product.id}
            data-confirm="Bạn có chắc chắn bỏ sản phẩm này"
          >
            Xóa
          </.link>
        </.inputs_for>
      </.simple_form>
      <div class="mt-8 flex justify-between">
        <div class="flex self-center">
          <span>Tổng thanh toán ({length(@cart.cart_items)} sản phẩm ):&nbsp;</span>
          <span>
            {ShoppingCart.total_cart_price(@cart) |> FormatUtil.money_to_vnd()}
          </span>
        </div>
        <button
          class="rounded-md bg-black text-white p-2"
          id="checkout-button"
          phx-click={JS.navigate(~p"/checkout")}
        >
          Mua hàng
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("update", %{"cart" => cart_params}, socket) do
    update_cart(socket, cart_params)
  end

  defp update_cart(socket, cart_params) do
    case ShoppingCart.update_cart(socket.assigns.cart, cart_params) do
      {:ok, _cart} ->
        {:noreply, put_flash(socket, :info, "Cập nhật giỏ hàng thành công")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
