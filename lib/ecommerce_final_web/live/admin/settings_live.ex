defmodule EcommerceFinalWeb.Admin.SettingsLive do
  use EcommerceFinalWeb, :live_view

  alias EcommerceFinal.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Thông tin tài khoản
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input classes={["w-1/3"]} field={@email_form[:email]} type="email" label="Email" required />
          <.input
            classes={["w-1/3"]}
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Mật khẩu hiện tại"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="...">Đổi email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/admin/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_admin_email"
            value={@current_email}
            classs="w-1/3"
          />
          <.input
            classes={["w-1/3"]}
            field={@password_form[:password]}
            type="password"
            label="Mât khẩu mới"
            required
          />
          <.input
            classes={["w-1/3"]}
            field={@password_form[:password_confirmation]}
            type="password"
            label="Xác nhận mật khẩu mới"
          />
          <.input
            classes={["w-1/3"]}
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
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_admin_email(socket.assigns.current_admin, token) do
        :ok ->
          put_flash(socket, :info, "Đổi email thành công. Vui lòng đăng nhập lại với email mới của bạn.")

        :error ->
          put_flash(socket, :error, "Link đổi email không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.")
      end

    {:ok, push_navigate(socket, to: ~p"/admin/settings")}
  end

  def mount(_params, _session, socket) do
    admin = socket.assigns.current_admin
    email_changeset = Accounts.change_admin_email(admin)
    password_changeset = Accounts.change_admin_password(admin)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, admin.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:page_title, "Thông tin tài khoản")

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "admin" => admin_params} = params

    email_form =
      socket.assigns.current_admin
      |> Accounts.change_admin_email(admin_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "admin" => admin_params} = params
    admin = socket.assigns.current_admin

    case Accounts.apply_admin_email(admin, password, admin_params) do
      {:ok, applied_admin} ->
        Accounts.deliver_admin_update_email_instructions(
          applied_admin,
          admin.email,
          &url(~p"/admin/settings/confirm_email/#{&1}")
        )

        info = "Vui lòng kiểm tra email của bạn để xác nhận thay đổi email. Nếu không thấy email, hãy kiểm tra thư mục spam hoặc thử lại."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "admin" => admin_params} = params

    password_form =
      socket.assigns.current_admin
      |> Accounts.change_admin_password(admin_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "admin" => admin_params} = params
    admin = socket.assigns.current_admin

    case Accounts.update_admin_password(admin, password, admin_params) do
      {:ok, admin} ->
        password_form =
          admin
          |> Accounts.change_admin_password(admin_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
