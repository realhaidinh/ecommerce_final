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
    params = Map.put(params, "category_ids", [String.to_integer(id)])

    {:noreply,
     socket
     |> assign(:page_title, category.title)
     |> assign(:category, category)
     |> assign(:current_path, "/categories/#{id}")
     |> assign_categories(category)
     |> assign(:subcategories, Catalog.get_subcategories(category))
     |> assign(:params, params)}
  end

  defp assign_categories(socket, %Category{} = category) do
    parent_ids = String.split(category.path, ".", trim: true)

    categories =
      Catalog.list_categories_by_ids(parent_ids) ++ [category]
      |> Enum.map(&(%{title: &1.title, url: "/categories/#{&1.id}"}))

    assign(socket, :categories, categories)
  end
end
