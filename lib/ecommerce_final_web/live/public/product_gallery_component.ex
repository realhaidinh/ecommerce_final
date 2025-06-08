defmodule EcommerceFinalWeb.Public.ProductGalleryComponent do
  alias EcommerceFinal.Catalog
  use EcommerceFinalWeb, :live_component
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        phx-target={@myself}
        for={@sort}
        id="sort"
        phx-change="sort_by"
        class="flex justify-end"
      >
        <.input
          type="select"
          label="Sắp xếp"
          field={@sort[:sort_by]}
          options={sort_opts(@sort_by)}
        />
      </.simple_form>

      <div class="grid grid-cols-4 gap-8 mt-8" id="catalog-products" phx-update="stream">
        <.product_card
          :for={{dom_id, product} <- @streams.products}
          id={dom_id}
          click={JS.navigate("/products/#{product.id}")}
          product={product}
        />
      </div>

      <div class="flex justify-center m-4">
        <button
          class="rounded-md bg-black disabled:bg-gray-700 text-white p-2 mx-2"
          phx-click="prev_page"
          phx-target={@myself}
          disabled={@page == 1}
          type="submit"
        >
          Trang trước
        </button>

        <button
          class="rounded-md bg-black disabled:bg-gray-700 text-white p-2 mx-2"
          phx-click="next_page"
          phx-target={@myself}
          disabled={@page == @total_page}
          type="submit"
        >
          Trang sau
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    %{products: products, total_page: total_page} = Catalog.search_product(assigns.params)
    page = Map.get(assigns.params, "page", "1") |> String.to_integer()
    sort_by = Map.get(assigns.params, "sort_by")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:page, page)
     |> assign(:sort_by, sort_by)
     |> assign_new(:sort, fn -> to_form(%{}) end)
     |> assign(:total_page, total_page)
     |> stream(:products, products, reset: true)}
  end

  @impl true
  def handle_event("prev_page", _params, socket) do
    {:noreply, push_patch(socket, to: self_path(socket, %{"page" => socket.assigns.page - 1}))}
  end

  def handle_event("next_page", _params, socket) do
    {:noreply, push_patch(socket, to: self_path(socket, %{"page" => socket.assigns.page + 1}))}
  end

  def handle_event("sort_by", %{"sort_by" => sort_by}, socket) do
    {:noreply, push_patch(socket, to: self_path(socket, %{"sort_by" => sort_by}))}
  end

  defp self_path(socket, extra) do
    socket.assigns.current_path <> ~p"/?#{Enum.into(extra, socket.assigns.params)}"
  end

  defp sort_opts(sort_by) do
    [
      [key: "Sắp xếp theo", value: "default", selected: sort_by == nil],
      [key: "Giá thấp đến cao", value: "price_asc", selected: sort_by == "price_asc"],
      [key: "Giá cao đến thấp", value: "price_desc", selected: sort_by == "price_desc"]
    ]
  end
end
