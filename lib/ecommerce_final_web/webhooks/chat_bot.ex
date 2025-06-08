defmodule EcommerceFinalWeb.Webhooks.ChatBot do
  use EcommerceFinalWeb, :controller
  alias EcommerceFinal.Utils.FormatUtil
  alias EcommerceFinal.Catalog

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
        error = "Yêu cầu của bạn không hợp lệ."
        json(conn, %{fulfillmentText: error})

      {:error, error} ->
        json(conn, %{fulfillmentText: error})
    end
  end

  def handle_intent("get_product_detail", %{"product_id" => id}) do
    id = trunc(id)
    product = Catalog.get_product(id)

    if product.id do
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

  def handle_intent(_, _params) do
    :error
  end
end
