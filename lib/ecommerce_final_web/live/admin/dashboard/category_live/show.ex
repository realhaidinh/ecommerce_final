defmodule EcommerceFinalWeb.Admin.Dashboard.CategoryLive.Show do
  alias EcommerceFinal.Catalog
  alias EcommerceFinal.Catalog.Category

  use EcommerceFinalWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Quản lý danh mục")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    category = Catalog.get_category_with_product_count(id)

    socket =
      socket
      |> assign(:category, category)
      |> stream(:categories, Catalog.get_subcategories(category), reset: true)

    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  def apply_action(socket, :new) do
    %{category: category} = socket.assigns

    subcategory = %Category{
      path: Catalog.get_subcategory_path(category)
    }

    assign(socket, :subcategory, subcategory)
  end

  def apply_action(socket, _), do: socket
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Catalog.get_category!(id)
    Catalog.delete_category(category)
    {:noreply, stream_delete(socket, :categories, category)}
  end

  @impl true
  def handle_info({:updated, category}, socket) do
    {:noreply, assign(socket, :category, category)}
  end

  def handle_info({:created, category}, socket) do
    {:noreply, stream_insert(socket, :categories, category)}
  end
end
