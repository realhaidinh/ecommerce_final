defmodule EcommerceFinalWeb.Public.ProductLive.Show do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Catalog
  alias EcommerceFinal.ShoppingCart
  alias EcommerceFinal.Utils.TimeUtil
  alias EcommerceFinal.ProductRecommend
  alias EcommerceFinal.Cache
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    product_key = "product:#{id}"

    {_, product} =
      Cache.get(product_key, fn ->
        Catalog.get_product!(id, [:rating, :categories, :images])
      end)

    product =
      Map.update!(product, :categories, fn categories ->
        Enum.map(categories, &%{id: &1.id, title: &1.title, url: "/categories/#{&1.id}"})
      end)

    category_ids = Enum.map(product.categories, & &1.id)

    socket =
      socket
      |> assign(:page_title, product.title)
      |> assign(:product, product)
      |> assign(:related_loading, %{reviews: true, products: true})
      |> assign_reviews_async(id)
      |> assign_related_products_async(id, category_ids)

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
    {:noreply, socket}
  end
  defp assign_reviews_async(socket, product_id) do
    socket
    |> start_async(:fetch_reviews, fn -> Catalog.list_reviews_by_product(product_id) end)
    |> stream(:reviews, [], reset: true)
    |> stream(:review_freq, [], reset: true)
  end

  defp assign_related_products_async(socket, product_id, category_ids) do
    socket
    |> start_async(:get_related_products, fn ->
      get_related_product(product_id, category_ids)
    end)
    |> stream(:related_products, [], reset: true)
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
      |> update(:related_loading, &%{&1 | reviews: false})

    {:noreply, socket}
  end

  def handle_async(:get_related_products, {:ok, result}, socket) do
    {_, related_products} = result

    socket =
      socket
      |> stream(:related_products, related_products, reset: true)
      |> update(:related_loading, &%{&1 | products: false})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:review_posted, review}, socket) do
    {:noreply, stream_insert(socket, :reviews, review)}
  end

  defp get_related_product(product_id, category_ids) do
    Cache.get("product-related:#{product_id}", fn ->
      case ProductRecommend.get_product_recommend(product_id) do
        {:ok, products} ->
          products

        :error ->
          Catalog.search_product(%{"category_ids" => category_ids, "limit" => 8})
          |> Map.get(:products)
          |> Enum.reject(&(&1.id == product_id))
      end
    end)
  end
end
