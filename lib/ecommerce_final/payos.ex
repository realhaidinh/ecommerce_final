defmodule EcommerceFinal.Payos do
  require Logger
  alias EcommerceFinal.Utils.TimeUtil
  alias EcommerceFinal.Utils.SignatureUtil

  @api_key Application.compile_env!(:ecommerce_final, :payos_api_key)
  @client_id Application.compile_env!(:ecommerce_final, :payos_client_id)
  @checksum_key Application.compile_env!(:ecommerce_final, :payos_checksum_key)
  @payos_api_url "https://api-merchant.payos.vn"

  def create_payment_data(%{return_url: return_url, amount: amount, description: description}) do
    %{
      orderCode:
        TimeUtil.get_current_time() |> to_string() |> String.slice(-6..-1) |> String.to_integer(),
      returnUrl: return_url,
      cancelUrl: return_url,
      amount: amount,
      description: description
    }
  end

  def create_payment_link(payment_data) when is_map(payment_data) do
    try do
      body =
        payment_data
        |> Map.put(
          :signature,
          SignatureUtil.create_signature_of_payment_request(payment_data, @checksum_key)
        )
        |> JSON.encode_to_iodata!()

      url = @payos_api_url <> "/v2/payment-requests"

      headers = [
        {"Accept", "application/json"},
        {"Content-type", "application/json"},
        {"Charset", "UTF-8"}
      ]

      fetch(:post, url, headers, body)
    rescue
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        {:error, e}
    end
  end

  def get_payment_link_information(id) do
    url = @payos_api_url <> "/v2/payment-requests/#{id}"
    fetch(:get, url)
  end

  def cancel_payment_link(id) do
    url = @payos_api_url <> "/v2/payment-requests/#{id}/cancel"

    headers = [
      {"Accept", "application/json"},
      {"Content-type", "application/json"},
      {"Charset", "UTF-8"}
    ]

    fetch(:post, url, headers)
  end

  def verify_payment_webhook_data(%{"data" => data, "signature" => signature}) do
    data_signature = SignatureUtil.create_signature_from_obj(data, @checksum_key)

    if data_signature == signature do
      {:ok, data}
    else
      {:error, "Invalid signature"}
    end
  end

  def verify_payment_webhook_data(_), do: {:error, "Missing data or signature"}

  defp fetch(method, url, headers \\ [], body \\ nil) do
    headers = [{"x-client-id", @client_id}, {"x-api-key", @api_key} | headers]
    request = Finch.build(method, url, headers, body)

    case Finch.request(request, EcommerceFinal.Finch) do
      {:ok, %Finch.Response{body: resp_body}} ->
        JSON.decode(resp_body)

      error ->
        error
    end
  end

  def get_checkout_url(id) do
    "https://pay.payos.vn/web/#{id}"
  end
end
