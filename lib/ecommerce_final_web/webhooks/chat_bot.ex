defmodule EcommerceFinalWeb.Webhooks.ChatBot do
  use EcommerceFinalWeb, :controller
  alias EcommerceFinal.Utils.FormatUtil
  alias EcommerceFinal.Catalog

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
    with {:ok, query_result} <- Map.fetch(params, "queryResult"),
         {:ok, intent} <- Map.fetch(query_result, "intent"),
         {:ok, name} <- Map.fetch(intent, "displayName"),
         {:ok, fulfillment_text} <- Map.fetch(query_result, "fulfillmentText"),
         {:ok, params} <- Map.fetch(query_result, "parameters"),
         {:ok, response} <- handle_intent(name, params) do
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
  defp handle_intent("get_product_detail", %{"product_id" => id}) do
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

  defp handle_intent(_, _params) do
    :error

    # %{
    #   "originalDetectIntentRequest" => %{"payload" => %{}},
    #   "queryResult" => %{
    #     "allRequiredParamsPresent" => true,
    #     "fulfillmentMessages" => [
    #       %{"text" => %{"text" => ["Mời quý khách xem thông tin sản phẩm"]}}
    #     ],
    #     "fulfillmentText" => "Mời quý khách xem thông tin sản phẩm",
    #     "intent" => %{
    #       "displayName" => "get_product_detail",
    #       "name" =>
    #         "projects/shop-assistant-dwpb/agent/intents/40d36503-574d-4ea3-93b9-dd8016f60f00"
    #     },
    #     "intentDetectionConfidence" => 0.6419782,
    #     "languageCode" => "vi",
    #     "outputContexts" => [
    #       %{
    #         "name" =>
    #           "projects/shop-assistant-dwpb/agent/sessions/guest_session/contexts/__system_counters__",
    #         "parameters" => %{
    #           "no-input" => 0.0,
    #           "no-match" => 0.0,
    #           "product_id" => 13.0,
    #           "product_id.original" => "13"
    #         }
    #       }
    #     ],
    #     "parameters" => %{"product_id" => 13.0},
    #     "queryText" => "sản phẩm mã 13"
    #   },
    #   "responseId" => "aa06af82-cc15-4db6-ad6e-0d3015c77645-996f169b",
    #   "session" => "projects/shop-assistant-dwpb/agent/sessions/guest_session"
    # }
  end
end
