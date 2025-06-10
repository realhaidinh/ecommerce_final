defmodule EcommerceFinalWeb.Bot.DialogFlow do
  @project_id Application.compile_env!(:ecommerce_final, :dialogflow_project_id)
  @language_code "vi"
  @base_url "https://dialogflow.googleapis.com/v2/projects"

  def ask(message, user_id) do
    session_id = get_session_id(user_id)

    with {:ok, response} <- make_request(message, session_id),
         query_result = Map.get(response, "queryResult"),
         fulfillment_text = Map.get(query_result, "fulfillmentText") do
      fulfillment_text
    else
      {:error, _} -> raise "Dialogflow request failed"
    end
  end

  defp make_request(message, session_id) do
    url = get_url(session_id)
    token = Goth.fetch!(EcommerceFinal.Goth).token

    request_body =
      JSON.encode_to_iodata!(%{
        query_input: %{
          text: %{
            text: message,
            language_code: @language_code
          }
        }
      })

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    request = Finch.build(:post, url, headers, request_body)

    case Finch.request(request, EcommerceFinal.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, JSON.decode!(body)}

      {:ok, %Finch.Response{status: status}} ->
        {:error, "Request failed with status #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_session_id(nil), do: "guest_session"

  defp get_session_id(user_id) when is_integer(user_id) do
    "user-#{user_id}"
  end

  defp get_url(session_id) do
    "#{@base_url}/#{@project_id}/agent/sessions/#{session_id}:detectIntent"
  end
end
