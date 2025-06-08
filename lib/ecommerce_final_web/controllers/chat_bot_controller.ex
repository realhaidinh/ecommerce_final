defmodule EcommerceFinalWeb.ChatBotController do
  use EcommerceFinalWeb, :controller

  def webhook(conn, params) do
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
        error = "Đã xảy ra lỗi trong quá trình xử lý yêu cầu của bạn."
        json(conn, %{fulfillmentText: error})
    end
  end

  def handle_intent("get_product_detail", %{"product_id" => _id}) do
    product = %{name: "Sample Product", price: 100, description: "This is a sample product."}

    detail =
      """
        Tên: #{product.name}
        Giá: #{product.price}
        Mô tả: #{product.description}
      """

    {:ok, detail}
  end

  def handle_intent(_, _params) do
    :error
  end
end
