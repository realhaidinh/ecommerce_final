defmodule EcommerceFinal.Mailer do
  use Swoosh.Mailer, otp_app: :ecommerce_final
  @email Application.compile_env!(:ecommerce_final, :host_email)
  def get_sender, do: {"UIT E-Commerce", @email}
end
