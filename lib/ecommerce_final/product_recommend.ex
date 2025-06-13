defmodule EcommerceFinal.ProductRecommend do
  alias EcommerceFinal.Catalog.Product

  @api_url Application.compile_env(:ecommerce_final, :recommend_api_url)
  @access_token Application.compile_env(:ecommerce_final, :recommend_api_access_token)

  def get_product_recommend(id) do
    url = get_recommend_url(id)
    request = Finch.build(:get, url)

    case Finch.request(request, EcommerceFinal.Finch) do
      {:ok, %Finch.Response{body: body, status: 200}} ->
        format_response(body)

      _ ->
        []
    end
  end

  def reload_system() do
    EcommerceFinal.Cache.prune()
    url = @api_url <> "/refresh"

    headers = [
      {"authorization", "Bearer #{access_token()}"}
    ]

    request = Finch.build(:post, url, headers)

    Finch.request(request, EcommerceFinal.Finch)
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
        images: [%{url: &1["cover"]}]
      }
    )
  end

  defp get_recommend_url(id) do
    api_url() <> "/#{id}?top_k=8"
  end

  defp access_token(), do: @access_token
  defp api_url(), do: @api_url
end
