defmodule EcommerceFinalWeb.Admin.LoginLive do
  use EcommerceFinalWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Đăng nhập trang quản lý
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/admin/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required classes="w-full" />
        <.input field={@form[:password]} type="password" label="Password" classes="w-full" required />
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">
            Đăng nhập <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "admin")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
