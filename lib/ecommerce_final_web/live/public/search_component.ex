defmodule EcommerceFinalWeb.Public.SearchComponent do
  alias EcommerceFinal.Catalog
  use EcommerceFinalWeb, :live_component
  @impl true
  def render(assigns) do
    ~H"""
    <div class="col-start-2 col-end-6 md:order-2 mr-2.5 relative">
      <form phx-change="update" phx-target={@myself} phx-throttle="500" phx-submit="search_product">
        <div class="flex border-2 w-5/6 rounded-md bg-white">
          <input
            id="search-input"
            class="focus:ring-0 border-0 bg-transparent flex-auto w-3/4"
            name="keyword"
            type="text"
            placeholder="Tìm kiếm sản phẩm"
            autocomplete="off"
            phx-hook="SearchInput"
            phx-target={@myself}
            phx-focus={JS.show(to: "#search-popover", transition: "fade-out")}
            phx-blur={JS.hide(to: "#search-popover", transition: "fade-out")}
          />
          <button class="hover:bg-blue-300 p-2 flex text-blue-700 before:[block]" type="submit">
            Tìm kiếm
          </button>
        </div>
      </form>

      <div
        id="search-popover"
        role="tooltip"
        title="search-popover"
        class="hidden absolute top-[calc(100%-1px)] left-0 bg-white w-[calc(73.5%-0.5rem)] ml-1"
      >
        <div id="product_preview" class="px-3 py-2 flex flex-col">
          <.link
            :for={{dom_id, product} <- @streams.products}
            id={"search-#{dom_id}"}
            navigate={~p"/products/#{product}"}
            class="hover:bg-gray-200"
            data-selected={@selected_index == product.index}
          >
            <span class="pl-1">{product.title}</span>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_index, 0)
     |> assign(:keyword, "")
     |> stream(:products, [])}
  end

  @impl true
  def handle_event("update", %{"keyword" => keyword}, socket) do
    {products, _total} =
      if keyword == "",
        do: {[], 0},
        else:
          Catalog.search_product(keyword)
          |> Enum.map_reduce(1, fn product, idx ->
            product = Map.put(product, :index, idx)
            idx = idx + 1
            {product, idx}
          end)

    {:noreply,
     socket
     |> assign(:keyword, keyword)
     |> stream(:products, products, reset: true)}
  end

  def handle_event("search_product", _unsigned_params, socket) do
    keyword = socket.assigns.keyword

    socket =
      if keyword == "" do
        socket
      else
        push_navigate(socket, to: ~p"/products?keyword=#{keyword}")
      end

    {:noreply, socket}
  end

end
