defmodule EcommerceFinalWeb.Public.CategoryLive.Index do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Catalog

  @impl true
  def mount(_params, _session, socket) do
    categories =
      Catalog.list_categories()
      |> Enum.reduce([], fn
        %{path: "0"} = category, acc ->
          [Map.put(category, :subcategories, []) | acc]

        %{path: path} = category, acc ->
          path_id = Enum.find_index(acc, fn cat ->
            String.starts_with?(path, "#{cat.path}.#{cat.id}")
          end)
          if path_id == nil do
            raise "Category with path #{path} not found in accumulator"
          end
          List.update_at(
            acc,
            path_id,
            &Map.update!(&1, :subcategories, fn sub -> [category | sub] end)
          )
      end)
      |> Enum.sort_by(& &1.title)

    {:ok,
     socket
     |> assign(:page_title, "Tất cả danh mục")
     |> stream(:categories, categories, reset: true)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
