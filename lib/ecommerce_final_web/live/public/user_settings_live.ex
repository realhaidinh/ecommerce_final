defmodule EcommerceFinalWeb.Public.UserSettingsLive do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Cài đặt tài khoản
      <:subtitle>Thay đổi email hoặc mật khẩu</:subtitle>
    </.header>

    <div>
      <div class="divide-y flex justify-stretch">
        <div class="p-4 grow">
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input
              class={["w-full"]}
              field={@email_form[:email]}
              type="email"
              label="Email"
              required
            />
            <.input
              class={["w-1/3"]}
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label="Mật khẩu hiện tại"
              value={@email_form_current_password}
              required
            />
            <:actions>
              <.button phx-disable-with="...">Đổi Email</.button>
            </:actions>
          </.simple_form>
        </div>
        <div class="p-4 grow">
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              class="w-full"
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.input
              class={["w-full"]}
              field={@password_form[:password]}
              type="password"
              label="Mật khẩu mới"
              required
            />
            <.input
              class={["w-full"]}
              field={@password_form[:password_confirmation]}
              type="password"
              label="Xác nhận mật khẩu"
            />
            <.input
              class={["w-full"]}
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Mật khẩu hiện tại"
              id="current_password_for_password"
              value={@current_password}
              required
            />
            <:actions>
              <.button phx-disable-with="...">Đổi mật khẩu</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
      <div>
        <div :if={@current_user.confirmed_at == nil} class="text-center mt-4">
          <p class="text-red-500">
            Email của bạn chưa được xác nhận. Vui lòng kiểm tra email của bạn để xác nhận.
          </p>
          <p>
            <.button phx-click="resend_confirmation">Gửi lại email xác nhận</.button>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Đổi Email thành công.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    socket = assign_page_title(socket)
    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign_page_title()
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket, layout: {EcommerceFinalWeb.Layouts, :public_profile}}
  end

  defp assign_page_title(socket), do: assign(socket, :page_title, "Tài khoản")

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "Đường link xác nhận email đã được gửi đến địa chỉ email của bạn."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("resend_confirmation", _, socket) do
    Accounts.deliver_user_confirmation_instructions(
      socket.assigns.current_user,
      &url(~p"/users/confirm/#{&1}")
    )

    info = "Đường link xác nhận email đã được gửi đến địa chỉ email của bạn."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
