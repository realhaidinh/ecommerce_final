defmodule EcommerceFinalWeb.Webhooks.ChatBot do
  use EcommerceFinalWeb, :controller
  alias EcommerceFinal.ShoppingCart
  alias EcommerceFinal.Utils.FormatUtil
  alias EcommerceFinal.Catalog
  alias EcommerceFinalWeb.Bot.DialogFlow
  @secret_key Application.compile_env!(:ecommerce_final, :chat_bot_secret_key)

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
         "projects/" <> ^project_id <> "/agent/sessions/" <> session = Map.get(params, "session"),
         {:ok, parameters} <- Map.fetch(query_result, "parameters"),
         {:ok, response} <- handle_intent(name, parameters, session) do
      fulfillment_text = fulfillment_text <> response
      json(conn, %{fulfillmentText: fulfillment_text})
    else
      :error ->
        error = "Yêu cầu của bạn không hợp lệ."
        json(conn, %{fulfillmentText: error})

      {:error, error} ->
        json(conn, %{fulfillmentText: error})
    end
  end

  defp handle_intent("get_product_detail", %{"product_id" => id}, _session) do
    id = trunc(id)
    product = Catalog.get_product(id)

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

      {:ok, detail}
    else
      {:error, "Không tìm thấy sản phẩm có mã #{id}."}
    end
  end

  defp handle_intent("add_to_cart", _parameters, "guest_session") do
    {:error, "Vui lòng đăng nhập để thực hiện chức năng này"}
  end

  defp handle_intent("add_to_cart", %{"url" => url, "product_id" => product_id}, "user-" <> id) do
    host = EcommerceFinalWeb.Endpoint.host()

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
      {:ok, response}
    else
      _ ->
        {:error, "Không thể thêm sản phẩm vào giỏ hàng"}
    end
  end

  defp handle_intent(_, _params, _) do
    :error
  end
end
