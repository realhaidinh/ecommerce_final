defmodule EcommerceFinalWeb.Public.HomeLive do
  alias EcommerceFinal.Catalog
  use EcommerceFinalWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex pt-6 justify-between">
      <div class="overflow-y-auto bg-slate-50 p-8 basis-1/5">
        <span
          class="font-semibold hover:underline hover:cursor-pointer"
          phx-click={JS.navigate(~p"/categories")}
        >
          DANH MỤC
        </span>
        <div class="flex flex-col flex-wrap mt-8" id="root-categories" phx-update="stream">
          <.link
            :for={{dom_id, category} <- @streams.categories}
            id={dom_id}
            navigate={~p"/categories/#{category.id}"}
            class="mb-2 hover:underline"
          >
            {category.title}
          </.link>
        </div>
      </div>
      <div class="flex p-4 bg-slate-50 basis-[75%] flex-col">
        <span class="font-semibold">Sản phẩm bạn có thể quan tâm</span>
        <div class="grid grid-cols-4 gap-8 mt-8" id="catalog-products" phx-update="stream">
          <.product_card
            click={JS.patch("/products/#{product.id}")}
            :for={{dom_id, product} <- @streams.landing_products}
            id={dom_id}
            product={product}
          />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    categories = Catalog.list_root_categories()

    socket =
      socket
      |> stream(:categories, categories)
      |> stream(:landing_products, [])
      |> assign(:page_title, "UIT EcommerceFinal")
      |> start_async(:fetch_landing_products, fn -> fetch_landing_products() end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:fetch_landing_products, {:ok, fetched_products}, socket) do
    {:noreply, stream(socket, :landing_products, fetched_products)}
  end

  def fetch_landing_products do
    Catalog.search_product(%{"limit" => 15})
    |> Map.get(:products)
  end
end
