defmodule EcommerceFinalWeb.Public.ProductLive.Index do
  use EcommerceFinalWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page_title = "Tìm sản phẩm: " <> Map.get(params, "keyword", "")
    {:noreply,
     socket
     |> assign(:page_title, page_title)
     |> assign(:params, params)
     |> assign(:current_path, "/products")}
  end
end
