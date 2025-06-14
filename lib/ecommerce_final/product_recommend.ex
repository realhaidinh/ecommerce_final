defmodule EcommerceFinal.ProductRecommend do
  alias EcommerceFinal.Catalog.Product

  @api_url Application.compile_env(:ecommerce_final, :recommend_api_url)
  @access_token Application.compile_env(:ecommerce_final, :recommend_api_access_token)
  @finch_client EcommerceFinal.Finch

  def get_product_recommend(id) do
    url = get_recommend_url(id)
    request = Finch.build(:get, url)

    case Finch.request(request, @finch_client) do
      {:ok, %Finch.Response{body: body, status: 200}} ->
        {:ok, format_response(body)}

      _ ->
        :error
    end
  end

  def reload_system() do
    EcommerceFinal.Cache.reset()
    url = @api_url <> "/refresh"

    headers = [
      {"authorization", "Bearer #{@access_token}"}
    ]

    request = Finch.build(:post, url, headers)

    Task.Supervisor.start_child(EcommerceFinal.TaskSupervisor, fn ->
      Finch.request(request, @finch_client)
    end)
  end

  defp format_response(response) do
    response
    |> JSON.decode!()
    |> Enum.map(
      &%Product{
        id: &1["id"],
        title: &1["title"],
        price: &1["price"],
        rating: &1["rating"],
        sold: &1["sold"],
        cover: &1["cover"]
      }
    )
  end

  defp get_recommend_url(id) do
    @api_url <> "/#{id}?top_k=8"
  end
end
