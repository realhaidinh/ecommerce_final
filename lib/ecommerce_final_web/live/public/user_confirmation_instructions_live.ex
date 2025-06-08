defmodule EcommerceFinalWeb.Public.UserConfirmationInstructionsLive do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Chưa nhận được email xác nhận?
        <:subtitle>Chúng tôi sẽ gửi email xác nhận lại cho bạn ngay</:subtitle>
      </.header>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input class={["w-full"]} field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="..." class="w-full">
            Gửi lại email xác nhận
          </.button>
        </:actions>
      </.simple_form>

      <p :if={@current_user == nil} class="text-center mt-4">
        <.link href={~p"/users/register"}>Đăng ký</.link>
        | <.link href={~p"/users/log_in"}>Đăng nhập</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "Nếu email của bạn có trong hệ thống và chưa được xác nhận, bạn sẽ nhận được email hướng dẫn trong giây lát."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
