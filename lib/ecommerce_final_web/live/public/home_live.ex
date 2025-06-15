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
        <%= if @loading do %>
          <div class="grid grid-cols-4 gap-8 mt-8">
            <div :for={_ <- 1..4} class="animate-pulse space-y-4 rounded-xl bg-white p-4 shadow">
              <div class="h-40 w-full rounded-lg bg-gray-200"></div>
              <div class="space-y-2">
                <div class="h-4 w-3/4 rounded bg-gray-200"></div>
                <div class="h-4 w-1/2 rounded bg-gray-200"></div>
              </div>
              <div class="h-8 w-24 rounded-md bg-gray-300"></div>
            </div>
          </div>
        <% else %>
          <div class="grid grid-cols-4 gap-8 mt-8" id="catalog-products" phx-update="stream">
            <.product_card
              :for={{dom_id, product} <- @streams.landing_products}
              id={dom_id}
              product={product}
            />
          </div>
        <% end %>
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
      |> assign(:loading, true)
      |> start_async(:fetch_landing_products, fn -> fetch_landing_products() end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:fetch_landing_products, {:ok, fetched_products}, socket) do
    socket =
      socket
      |> stream(:landing_products, fetched_products)
      |> assign(:loading, false)

    {:noreply, socket}
  end

  def fetch_landing_products do
    Catalog.search_product(%{"limit" => 16})
    |> Map.get(:products)
  end
end
