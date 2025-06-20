defmodule EcommerceFinalWeb.Public.ProductGalleryComponent do
  alias EcommerceFinal.Catalog
  use EcommerceFinalWeb, :live_component
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between">
        <div>
          <form
            class="self-end"
            id="price_range_filter"
            phx-target={@myself}
            phx-submit="price_range_filter"
          >
            <input
              name="min_price"
              maxlength="13"
              class="w-1/4"
              type="text"
              value={@min_price}
              oninput="this.value = this.value.replace(/[^0-9]/g, '')"
              placeholder="₫ TỪ"
            /> -
            <input
              name="max_price"
              maxlength="13"
              class="w-1/4"
              type="text"
              value={@max_price}
              oninput="this.value = this.value.replace(/[^0-9]/g, '')"
              placeholder="₫ ĐẾN"
            />
            <button
              class="rounded-md bg-black disabled:bg-gray-700 text-white p-2 mx-2"
              phx-target={@myself}
              type="submit"
            >
              ÁP DỤNG
            </button>
            <button
              class="rounded-md bg-black disabled:bg-gray-700 text-white p-2 mx-2"
              phx-click="reset_filter"
              phx-target={@myself}
              type="button"
            >
              XÓA BỘ LỌC
            </button>
          </form>
          <p :if={assigns[:valid_price?] != nil && assigns[:valid_price?] != true}>
            Vui lòng điền giá phù hợp
          </p>
        </div>
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
      </div>

      <div
        class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8 mt-8"
        id="catalog-products"
        phx-update="stream"
      >
        <.product_card :for={{dom_id, product} <- @streams.products} id={dom_id} product={product} />
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
    min_price = Map.get(assigns.params, "min_price") |> get_price()
    max_price = Map.get(assigns.params, "max_price") |> get_price()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:page, page)
     |> assign(:sort_by, sort_by)
     |> assign(:min_price, min_price)
     |> assign(:max_price, max_price)
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

  def handle_event("reset_filter", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.current_path)}
  end

  def handle_event(
        "price_range_filter",
        %{"min_price" => min_price, "max_price" => max_price},
        socket
      ) do
    min_price = get_price(min_price)
    max_price = get_price(max_price)

    socket =
      if valid_price_range?(min_price, max_price) do
        price_range = %{
          "min_price" => min_price,
          "max_price" => max_price
        }

        socket
        |> assign(:valid_price?, true)
        |> push_patch(to: self_path(socket, price_range))
      else
        assign(socket, :valid_price?, false)
      end

    {:noreply, socket}
  end

  defp get_price(price) when is_nil(price) or price === "", do: nil
  defp get_price(price) when is_binary(price), do: String.to_integer(price)

  defp valid_price_range?(nil, nil), do: true
  defp valid_price_range?(_, nil), do: true
  defp valid_price_range?(nil, _), do: true
  defp valid_price_range?(min_price, max_price), do: min_price < max_price

  defp self_path(socket, extra) do
    socket.assigns.current_path <> ~p"/?#{Enum.into(extra, socket.assigns.params)}"
  end

  defp sort_opts(sort_by) do
    [
      [key: "Sắp xếp theo", value: "default", selected: sort_by == nil],
      [key: "Giá thấp đến cao", value: "price_asc", selected: sort_by == "price_asc"],
      [key: "Giá cao đến thấp", value: "price_desc", selected: sort_by == "price_desc"],
      [key: "Bán chạy", value: "sales", selected: sort_by == "sales"],
      [key: "Mới nhất", value: "recent", selected: sort_by == "recent"]
    ]
  end
end
