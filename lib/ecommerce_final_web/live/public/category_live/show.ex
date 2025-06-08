defmodule EcommerceFinalWeb.Public.CategoryLive.Show do
  alias EcommerceFinal.Catalog.Category
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"category_id" => id} = params, _uri, socket) do
    category = Catalog.get_category!(id)
    params = Map.put(params, "category_ids", [id])

    {:noreply,
     socket
     |> assign(:page_title, category.title)
     |> assign(:category, category)
     |> assign(:current_path, "/categories/#{id}")
     |> assign_parents_category(category)
     |> assign(:subcategories, Catalog.get_subcategories(category))
     |> assign(:params, params)}
  end

  defp assign_parents_category(socket, %Category{} = category) do
    parent_ids = String.split(category.path, ".", trim: true)

    parents =
      Catalog.list_categories_by_ids(parent_ids)
      |> Enum.map(fn cat -> Map.put(cat, :url, "/categories/#{cat.id}") end)

    assign(socket, :parents, parents)
  end
end
