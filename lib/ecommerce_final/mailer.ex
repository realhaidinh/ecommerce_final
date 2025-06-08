defmodule EcommerceFinal.Mailer do
  use Swoosh.Mailer, otp_app: :ecommerce_final
  @email Application.get_env(:ecommerce_final, :smtp_username)
  def get_sender, do: {"UIT E-Commerce", @email}
end
