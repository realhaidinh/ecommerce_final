defmodule EcommerceFinalWeb.Admin.Dashboard.ProductLive.Index do
  alias EcommerceFinal.Catalog.Product
  alias EcommerceFinal.Catalog
  alias EcommerceFinal.Utils.FormatUtil
  use EcommerceFinalWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Quản lý sản phẩm")
     |> stream(:products, Catalog.list_products())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, params, socket.assigns.live_action)}
  end

  def apply_action(socket, %{"id" => id}, :edit) do
    assign(socket, :product, Catalog.get_product!(id, [:images, :categories]))
  end

  def apply_action(socket, _, :new) do
    assign(socket, :product, %Product{})
  end

  def apply_action(socket, _, _), do: assign(socket, :product, nil)

  @impl true
  def handle_info({:saved, product}, socket) do
    {:noreply, stream_insert(socket, :products, product)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product)
    {:noreply, stream_delete(socket, :products, product)}
  end
end
