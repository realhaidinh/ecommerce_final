defmodule EcommerceFinalWeb.Public.ProductLive.Show do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Catalog
  alias EcommerceFinal.ShoppingCart
  alias EcommerceFinal.Utils.TimeUtil
  alias EcommerceFinal.Cache
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    socket =
      socket
      |> assign_product(id)
      |> assign(:review_page, 1)
      |> assign(:related_loading, %{reviews: true, products: true, rating_count: true})
      |> assign_reviews_async(id)
      |> assign_related_products_async(id)
      |> assign_rating_count_async(id)

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

  def handle_event("load_more_reviews", _, socket) do
    page = socket.assigns.review_page + 1
    product_id = socket.assigns.product.id

    socket =
      socket
      |> start_async(:get_reviews, fn ->
        Catalog.list_reviews_by_product(product_id, %{page: page})
      end)
      |> assign(:review_page, page)

    {:noreply, socket}
  end

  defp assign_product(socket, id) do
    product_key = "product:#{id}"

    {_, product} =
      Cache.get(product_key, fn ->
        Catalog.get_product!(id, [:rating, :categories, :images])
      end)

    product =
      Map.update!(product, :categories, fn categories ->
        Enum.map(categories, &%{id: &1.id, title: &1.title, url: "/categories/#{&1.id}"})
      end)
  
    socket
    |> assign(:page_title, product.title)
    |> assign(:product, product)  
  end

  defp assign_reviews_async(socket, product_id) do
    socket
    |> start_async(:get_reviews, fn -> Catalog.list_reviews_by_product(product_id) end)
    |> stream(:reviews, [], reset: true)
  end

  defp assign_rating_count_async(socket, product_id) do
    socket
    |> start_async(:get_rating_count, fn -> Catalog.list_rating_count_by_product(product_id) end)
    |> stream(:rating_count, [], reset: true)
  end

  defp assign_related_products_async(socket, product_id) do
    socket
    |> start_async(:get_related_products, fn ->
      get_related_product(product_id)
    end)
    |> stream(:related_products, [], reset: true)
  end

  @impl true
  def handle_async(:get_reviews, {:ok, result}, socket) do
    %{reviews: reviews, page: page, total_page: total_page} = result

    socket =
      socket
      |> stream(:reviews, reviews)
      |> update(:related_loading, &%{&1 | reviews: false})
      |> assign(:review_page, page)
      |> assign(:has_more_reviews, page < total_page)

    {:noreply, socket}
  end

  def handle_async(:get_rating_count, {:ok, result}, socket) do
    flatten =
      Enum.reduce(result, %{}, fn rating, acc ->
        Map.merge(acc, rating)
      end)

    rating_count =
      for index <- 1..5, reduce: [] do
        acc ->
          count = Map.get(flatten, index, 0)
          rate = %{id: index, rating: index, count: count}
          [rate | acc]
      end
      |> Enum.reverse()

    socket =
      socket
      |> stream(:rating_count, rating_count, reset: true)
      |> update(:related_loading, &%{&1 | rating_count: false})

    {:noreply, socket}
  end

  def handle_async(:get_related_products, {:ok, {_, related_products}}, socket) do
    socket =
      socket
      |> stream(:related_products, related_products, reset: true)
      |> update(:related_loading, &%{&1 | products: false})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:review_posted, review}, socket) do
    socket =
      socket
      |> stream_insert(:reviews, review)
      |> assign_product(review.product_id)

    {:noreply, socket}
  end

  defp get_related_product(product_id) do
    Cache.get("product-related:#{product_id}", fn ->
      Catalog.get_recommend_products(product_id)
    end)
  end
end
