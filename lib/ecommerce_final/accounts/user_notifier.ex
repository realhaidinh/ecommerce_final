defmodule EcommerceFinal.Accounts.UserNotifier do
  import Swoosh.Email

  alias EcommerceFinal.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from(Mailer.get_sender())
      |> subject(subject)
      |> text_body(body)

    Task.Supervisor.start_child(EcommerceFinal.TaskSupervisor, fn ->
      with {:ok, metadata} <- Mailer.deliver(email) do
        IO.inspect(metadata)
        {:ok, email}
      end
    end)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Xin chào #{user.email},

    Để kích hoạt tài khoản vui lòng truy cập vào đường link sau:

    #{url}


    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Xin chào #{user.email},

    Để thay đổi mật khẩu vui lòng truy cập đường link sau

    #{url}

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Xin chào #{user.email},

    Để thay đổi email vui lòng truy cập đường link sau

    #{url}


    ==============================
    """)
  end
end
