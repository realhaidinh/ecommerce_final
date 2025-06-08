defmodule EcommerceFinalWeb.Admin.Dashboard.ProductLive.Show do
  alias EcommerceFinal.Catalog
  use EcommerceFinalWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Quản lý sản phẩm")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    product = Catalog.get_product!(id, [:categories, :rating, :images])
    {:noreply, assign(socket, :product, product)}
  end

  @impl true
  def handle_info({:saved, product}, socket) do
    product = Map.put(product, :categories, Enum.sort_by(product.categories, & &1.level))
    {:noreply, assign(socket, :product, product)}
  end
end
