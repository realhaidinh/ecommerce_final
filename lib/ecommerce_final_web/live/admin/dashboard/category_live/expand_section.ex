defmodule EcommerceFinalWeb.Admin.Dashboard.CategoryLive.ExpandSection do
  use EcommerceFinalWeb, :live_component
  alias EcommerceFinal.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"sub_categories_#{@category.id}"} class="col-span-3 w-full hidden" phx-update="stream">
      <span id={"blank-#{@category.id}"} class="self-center hidden only:block">
        Danh mục con trống
      </span>

      <span
        :for={{dom_id, cat} <- Map.get(@streams, @category.title, [])}
        id={dom_id}
        class="grid grid-cols-3 border border-b-0 border-gray-200 bg-white hover:bg-gray-200"
      >
        <span class="pl-20 py-2 ">{cat.title}</span>
        <span class="px-4 py-2">{cat.product_count}</span>
        <div class="flex flex-row justify-center">
          <.link
            navigate={~p"/admin/dashboard/catalog/categories/#{cat}"}
            class="justify-self-center px-4 py-2 text-blue-500"
          >
            Chi tiết
          </.link>

          <.link
            class="px-4 py-2 text-blue-500"
            phx-target={@myself}
            phx-click={JS.push("delete", value: %{id: cat.id, parent_title: @category.title})}
            data-confirm="Xác nhận xóa danh mục?"
          >
            Xóa
          </.link>
        </div>
      </span>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, stream(socket, "", [])}
  end

  @impl true
  def handle_event("show-subcategories", %{"id" => id}, socket) do
    category = Catalog.get_category(id)

    socket =
      if Map.get(socket.assigns.streams, category.title) do
        socket
      else
        subcategory = Catalog.get_subcategories(category)
        stream(socket, category.title, subcategory)
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id, "parent_title" => parent_title}, socket) do
    category = Catalog.get_category!(id)
    Catalog.delete_category(category)
    {:noreply, stream_delete(socket, parent_title, category)}
  end
end
