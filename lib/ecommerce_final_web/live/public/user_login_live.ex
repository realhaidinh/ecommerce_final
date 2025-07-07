defmodule EcommerceFinalWeb.Public.UserLoginLive do
  use EcommerceFinalWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Đăng nhập
        <:subtitle>
          Chưa có tài khoản?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            đăng ký tài khoản mới
          </.link>
          ngay.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required classes="w-full" />
        <.input field={@form[:password]} type="password" label="Password" required classes="w-full" />

        <div class="mt-2 flex items-center justify-between gap-6">
          <.input field={@form[:remember_me]} type="checkbox" label="Lưu phiên" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Quên mật khẩu
          </.link>
        </div>
        <:actions>
          <.button phx-disable-with="..." class="w-full">
            Đăng nhập <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
