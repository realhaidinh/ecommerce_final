defmodule EcommerceFinalWeb.Public.ProductLive.Show do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Catalog
  alias EcommerceFinal.Catalog.Product
  alias EcommerceFinal.ShoppingCart
  alias EcommerceFinal.Utils.TimeUtil
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    product = Catalog.get_product!(id, [:rating, :categories, :images])

    product =
      Map.update!(product, :categories, fn categories ->
        Enum.map(categories, &%{title: &1.title, url: "/categories/#{&1.id}"})
      end)

    product_id = product.id

    socket =
      socket
      |> assign(:page_title, product.title)
      |> assign(:product, product)
      |> start_async(:fetch_reviews, fn -> Catalog.list_reviews_by_product(id) end)
      |> start_async(:fetch_related_products, fn ->
        fetch_related_product(product_id)
      end)
      |> stream(:reviews, [])
      |> stream(:related_products, [])
      |> stream(:review_freq, [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("add", _, socket) do
    socket =
      if socket.assigns.current_user do
        case ShoppingCart.add_item_to_cart(socket.assigns.cart, socket.assigns.product.id) do
          {:ok, _cart} ->
            put_flash(socket, :info, "Sản phẩm đã được thêm vào giỏ hàng")

          {:error, _changeset} ->
            put_flash(socket, :error, "There was an error adding the item to your cart")
        end
      else
        redirect(socket, to: ~p"/users/log_in")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_async(:fetch_reviews, {:ok, fetched_reviews}, socket) do
    review_freq =
      Enum.frequencies_by(fetched_reviews, & &1.rating)

    review_freq =
      for rating <- 1..5 do
        %{id: rating, rating: rating, count: Map.get(review_freq, rating, 0)}
      end

    socket =
      socket
      |> stream(:reviews, fetched_reviews, reset: true)
      |> stream(:review_freq, review_freq, reset: true)

    {:noreply, socket}
  end

  def handle_async(:fetch_related_products, {:ok, related_products}, socket) do
    {:noreply, stream(socket, :related_products, related_products, reset: true)}
  end

  defp fetch_related_product(product_id) do
    url = get_recommend_url(product_id)
    request = Finch.build(:get, url)

    case Finch.request(request, EcommerceFinal.Finch) do
      {:ok, %Finch.Response{body: body, status: 200}} ->
        body
        |> JSON.decode!()
        |> Enum.map(fn product ->
          %Product{
            id: product["id"],
            title: product["title"],
            price: product["price"],
            rating: get_rating(product["rating"]),
            sold: product["sold"],
            images: [%{url: product["cover"]}]
          }
        end)

      _ ->
        []
    end
  end

  defp get_recommend_url(id) do
    Application.get_env(:ecommerce_final, :recommend_api_url) <> "/#{id}?top_k=8"
  end

  defp get_rating(nil), do: 0
  defp get_rating(rating), do: rating
end
