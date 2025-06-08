defmodule EcommerceFinal.Utils.SignatureUtil do
  def create_signature_from_obj(obj, checksum) do
    data = to_query_str(obj)
    generate_hmac_sha256(checksum, data)
  end

  def create_signature_of_payment_request(data, checksum) do
    data =
      "amount=#{data.amount}&cancelUrl=#{data.cancelUrl}&description=#{data.description}&orderCode=#{data.orderCode}&returnUrl=#{data.returnUrl}"

    generate_hmac_sha256(checksum, data)
  end

  defp to_query_str(obj) do
    obj
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map(fn {key, value} ->
      "#{key}=#{value}"
    end)
    |> Enum.join("&")
  end

  defp generate_hmac_sha256(checksum, data) do
    :crypto.mac(:hmac, :sha256, checksum, data)
    |> Base.encode16(case: :lower)
  end
end
