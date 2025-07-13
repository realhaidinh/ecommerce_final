defmodule EcommerceFinalWeb.Webhooks.Payment do
  use EcommerceFinalWeb, :controller
  import EcommerceFinal.Payos
  alias EcommerceFinal.Orders.OrderNotifier
  alias EcommerceFinal.Orders

  def payment_confirm(conn, params) do
    success =
      with {:ok, data} <- verify_payment_webhook_data(params),
           "success" <- data["desc"] do
        if order = Orders.get_order_by_transaction_id(data["paymentLinkId"]) do
          if(order.status != :"Đã thanh toán") do
            {:ok, order} = Orders.update_order(order, %{status: :"Đã thanh toán"})
            OrderNotifier.deliver_order_paid(order, order.user.email)
          end
          true
        else
          false
        end
      else
        _ ->
          false
      end

    json(conn, %{success: success})
  end
end
