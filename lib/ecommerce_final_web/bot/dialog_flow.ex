defmodule EcommerceFinalWeb.Bot.DialogFlow do
  @project_id Application.compile_env!(:ecommerce_final, :dialogflow_project_id)
  @language_code "vi"
  @base_url "https://dialogflow.googleapis.com/v2/projects"

  def ask(message, session_id \\ 123_456_789) do
    url = "#{@base_url}/#{@project_id}/agent/sessions/#{session_id}:detectIntent"
    token = Goth.fetch!(EcommerceFinal.Goth).token

    request_body = %{
      query_input: %{
        text: %{
          text: message,
          language_code: @language_code
        }
      }
    }

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    body = JSON.encode_to_iodata!(request_body)
    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, EcommerceFinal.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        body
        |> JSON.decode!()
        |> Map.get("queryResult")
        |> Map.get("fulfillmentText")

      _ ->
        raise "Dialogflow request failed"
    end
  end
end
