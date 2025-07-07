defmodule EcommerceFinalWeb.Webhooks.ChatBot do
  use EcommerceFinalWeb, :controller
  alias EcommerceFinal.Orders
  alias EcommerceFinal.ShoppingCart
  alias EcommerceFinal.Utils.FormatUtil
  alias EcommerceFinal.Catalog
  alias EcommerceFinal.Catalog.Product
  alias EcommerceFinalWeb.Bot.DialogFlow

  @secret_key Application.compile_env!(:ecommerce_final, :chat_bot_secret_key)

  defp get_host(), do: EcommerceFinalWeb.Endpoint.host()

  def authenticate?(conn) do
    conn.req_headers
    |> Enum.any?(fn {header, value} ->
      header == "secret-key" and value == @secret_key
    end)
  end

  def webhook(conn, params) do
    if authenticate?(conn) do
      process_request(conn, params)
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    end
  end

  defp process_request(conn, params) do
    project_id = DialogFlow.get_project_id()

    with {:ok, query_result} <- Map.fetch(params, "queryResult"),
         {:ok, intent} <- Map.fetch(query_result, "intent"),
         {:ok, name} <- Map.fetch(intent, "displayName"),
         fulfillment_text = Map.get(query_result, "fulfillmentText", ""),
         "projects/" <> ^project_id <> "/agent/sessions/" <> session <-
           Map.get(params, "session"),
         {:ok, parameters} <- Map.fetch(query_result, "parameters"),
         {:ok, response} <-
           handle_intent(name, parameters, session, fulfillment_text, query_result) do
      json(conn, response)
    else
      :error ->
        error = "Yêu cầu của bạn không hợp lệ."
        json(conn, %{fulfillmentText: error})

      {:error, error} ->
        json(conn, %{fulfillmentText: error})
    end
  end

  defp handle_intent("get_product_detail", %{"product_id" => id}, session, fulfillment_text, _) do
    id = trunc(id)
    product = Catalog.get_product!(id)
    project_id = DialogFlow.get_project_id()

    if product do
      detail =
        """
        \nTên: #{product.title}
        Giá: #{FormatUtil.money_to_vnd(product.price)}
        Mô tả: #{product.description}
        Đánh giá: #{product.rating}
        Đã bán: #{product.sold}
        Tồn kho: #{product.stock}
        """

      response = %{
        fulfillmentText: fulfillment_text <> detail,
        outputContexts: [
          %{
            name:
              "projects/#{project_id}/agent/sessions/#{session}/contexts/get_product_detail-followup",
            lifespanCount: 1,
            parameters: %{
              "product_id" => product.id
            }
          }
        ]
      }

      {:ok, response}
    else
      {:error, "Không tìm thấy sản phẩm có mã #{id}."}
    end
  end

  defp handle_intent("add_to_cart", _parameters, "guest_session", _, _) do
    {:error, "Vui lòng đăng nhập để thực hiện chức năng này"}
  end

  defp handle_intent(
         "add_to_cart",
         %{"url" => url, "product_id" => product_id},
         "user-" <> id,
         _,
         _
       ) do
    host = get_host()

    product_id =
      with {:ok, %URI{host: ^host, path: path}} <- URI.new(url),
           ["products", product_id | _rest] <- String.split(path, "/", trim: true) do
        product_id
      else
        _ ->
          if(product_id != "") do
            trunc(product_id)
          else
            nil
          end
      end

    with cart <- ShoppingCart.get_cart_by_user_id(id),
         {:ok, _} <- ShoppingCart.add_item_to_cart(cart, product_id) do
      response = "Đã thêm sản phẩm vào giỏ hàng"

      response = %{
        fulfillmentText: response
      }

      {:ok, response}
    else
      _ ->
        {:error, "Không thể thêm sản phẩm vào giỏ hàng"}
    end
  end

  defp handle_intent("order_tracking", _, "guest_session", _, _) do
    {:error, "Vui lòng đăng nhập để thực hiện chức năng này"}
  end

  defp handle_intent("order_tracking", %{"order_id" => order_id}, "user-" <> id, _, _) do
    order_id = trunc(order_id)
    order = Orders.get_user_order_by_id(id, order_id)

    if order do
      {items, item_count} =
        Enum.map_reduce(
          order.line_items,
          0,
          &{"\nTên sản phẩm: #{&1.product.title}\nĐơn giá: #{FormatUtil.money_to_vnd(&1.price)}\nSố lượng: #{&1.quantity}",
           &2 + 1}
        )

      response =
        """
        Đơn hàng ##{order.id}
        Tình trạng: #{order.status}
        Hình thức thanh toán: #{order.payment_type}
        Số lượng sản phẩm: #{item_count}
        Tổng tiền: #{FormatUtil.money_to_vnd(order.total_price)}
        Sản phẩm: #{items}
        """

      response = %{
        fulfillmentText: response
      }

      {:ok, response}
    else
      {:error, "Không tìm thấy đơn hàng"}
    end
  end

  defp handle_intent("search_product", %{"keyword" => keyword}, _, _, _) do
    host = get_host()

    products = Catalog.fts_product(keyword)

    response =
      if products == [] do
        "Không tìm thấy sản phẩm bạn muốn tìm."
      else
        product_list =
          products
          |> Enum.map(fn %Product{id: id, title: title, price: price} ->
            "Tên sản phẩm: #{title}\nMã sản phẩm: #{id}\nGiá:#{price}\nLiên kết đến sản phẩm: #{host}/products/#{id}"
          end)
          |> Enum.join("\n------\n")

        """
        Shop xin gửi danh sách sản phẩm bạn muốn tìm:
        #{product_list}
        """
      end

    response = %{
      fulfillmentText: response
    }

    {:ok, response}
  end

  defp handle_intent("get_product_detail_related", _params, _, _, query) do
    %{"outputContexts" => context} = query

    [
      %{
        "parameters" => %{
          "product_id" => id
        }
      }
      | _
    ] = context

    products = Catalog.get_recommend_products(trunc(id))
    host = get_host()

    product_list =
      products
      |> Enum.map(fn %Product{id: id, title: title, price: price} ->
        "Tên sản phẩm: #{title}\nMã sản phẩm: #{id}\nGiá:#{price}\nLiên kết đến sản phẩm: #{host}/products/#{id}"
      end)
      |> Enum.join("\n------\n")

    fulfillment_text =
      """
      Shop xin gửi danh sách sản phẩm liên quan:
      #{product_list}
      """

    response = %{
      fulfillmentText: fulfillment_text
    }

    {:ok, response}
  end

  defp handle_intent(_, _, _, _, _) do
    :error
  end
end
