defmodule EcommerceFinalWeb.Admin.Dashboard.CategoryLive.Table do
  use EcommerceFinalWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-6 bg-gray-300 p-4">
        <span class="col-span-2">Tên danh mục</span> <span>Sản phẩm</span>
        <span class="col-start-5 col-span-2 justify-self-center">Thao tác</span>
      </div>

      <div id="categories" phx-update="stream">
        <div
          :for={{id, category} <- @categories}
          id={id}
          class="grid grid-cols-3 border border-b-0 border-gray-200 hover:bg-gray-200"
        >
          <div class="flex">
            <.link
              class="px-4 py-2 text-blue-500"
              phx-target={"#sub_categories_#{category.id}"}
              phx-click={
                JS.push("show-subcategories", value: %{id: category.id})
                |> JS.toggle_class(
                  "hidden flex flex-col",
                  transition: {"transform ease-in duration-200", "opacity-0", "opacity-100"},
                  to: "#sub_categories_#{category.id}"
                )
                |> JS.toggle_class(
                  "-rotate-90",
                  to: "#chevron-#{category.id}"
                )
              }
            >
              <span class="hero-chevron-down size-6 -rotate-90" id={"chevron-#{category.id}"}></span>
            </.link>
            <span class="px-4 py-2">{category.title}</span>
          </div>
          <span class="px-4 py-2">{category.product_count}</span>
          <div class="flex flex-row justify-center">
            <.link
              class="px-4 py-2 text-blue-500"
              patch={~p"/admin/dashboard/catalog/categories/#{category}"}
            >
              Chi tiết
            </.link>

            <.link
              class="px-4 py-2 text-blue-500"
              phx-click={JS.push("delete", value: %{id: category.id})}
              data-confirm="Xác nhận xóa danh mục?"
            >
              Xóa
            </.link>
          </div>

          <.live_component
            module={EcommerceFinalWeb.Admin.Dashboard.CategoryLive.ExpandSection}
            id={"subcat-#{category.id}"}
            category={category}
          />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns) |> stream("", [])}
  end
end
