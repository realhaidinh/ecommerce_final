defmodule EcommerceFinal.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias EcommerceFinal.Repo

  alias EcommerceFinal.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def list_user() do
    Repo.all(User)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  alias EcommerceFinal.Accounts.{Admin, AdminToken, AdminNotifier}

  ## Database getters

  @doc """
  Gets a admin by email.

  ## Examples

      iex> get_admin_by_email("foo@example.com")
      %Admin{}

      iex> get_admin_by_email("unknown@example.com")
      nil

  """
  def get_admin_by_email(email) when is_binary(email) do
    Repo.get_by(Admin, email: email)
  end

  @doc """
  Gets a admin by email and password.

  ## Examples

      iex> get_admin_by_email_and_password("foo@example.com", "correct_password")
      %Admin{}

      iex> get_admin_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_admin_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    admin = Repo.get_by(Admin, email: email)
    if Admin.valid_password?(admin, password), do: admin
  end

  @doc """
  Gets a single admin.

  Raises `Ecto.NoResultsError` if the Admin does not exist.

  ## Examples

      iex> get_admin!(123)
      %Admin{}

      iex> get_admin!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admin!(id), do: Repo.get!(Admin, id)

  ## Admin registration

  @doc """
  Registers a admin.

  ## Examples

      iex> register_admin(%{field: value})
      {:ok, %Admin{}}

      iex> register_admin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_admin(attrs) do
    %Admin{}
    |> Admin.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking admin changes.

  ## Examples

      iex> change_admin_registration(admin)
      %Ecto.Changeset{data: %Admin{}}

  """
  def change_admin_registration(%Admin{} = admin, attrs \\ %{}) do
    Admin.registration_changeset(admin, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the admin email.

  ## Examples

      iex> change_admin_email(admin)
      %Ecto.Changeset{data: %Admin{}}

  """
  def change_admin_email(admin, attrs \\ %{}) do
    Admin.email_changeset(admin, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_admin_email(admin, "valid password", %{email: ...})
      {:ok, %Admin{}}

      iex> apply_admin_email(admin, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_admin_email(admin, password, attrs) do
    admin
    |> Admin.email_changeset(attrs)
    |> Admin.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the admin email using the given token.

  If the token matches, the admin email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_admin_email(admin, token) do
    context = "change:#{admin.email}"

    with {:ok, query} <- AdminToken.verify_change_email_token_query(token, context),
         %AdminToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(admin_email_multi(admin, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp admin_email_multi(admin, email, context) do
    changeset =
      admin
      |> Admin.email_changeset(%{email: email})
      |> Admin.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given admin.

  ## Examples

      iex> deliver_admin_update_email_instructions(admin, current_email, &url(~p"/admins/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_admin_update_email_instructions(
        %Admin{} = admin,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, admin_token} = AdminToken.build_email_token(admin, "change:#{current_email}")

    Repo.insert!(admin_token)
    AdminNotifier.deliver_update_email_instructions(admin, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the admin password.

  ## Examples

      iex> change_admin_password(admin)
      %Ecto.Changeset{data: %Admin{}}

  """
  def change_admin_password(admin, attrs \\ %{}) do
    Admin.password_changeset(admin, attrs, hash_password: false)
  end

  @doc """
  Updates the admin password.

  ## Examples

      iex> update_admin_password(admin, "valid password", %{password: ...})
      {:ok, %Admin{}}

      iex> update_admin_password(admin, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_admin_password(admin, password, attrs) do
    changeset =
      admin
      |> Admin.password_changeset(attrs)
      |> Admin.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin: admin}} -> {:ok, admin}
      {:error, :admin, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_admin_session_token(admin) do
    {token, admin_token} = AdminToken.build_session_token(admin)
    Repo.insert!(admin_token)
    token
  end

  @doc """
  Gets the admin with the given signed token.
  """
  def get_admin_by_session_token(token) do
    {:ok, query} = AdminToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_admin_session_token(token) do
    Repo.delete_all(AdminToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given admin.

  ## Examples

      iex> deliver_admin_confirmation_instructions(admin, &url(~p"/admins/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_admin_confirmation_instructions(confirmed_admin, &url(~p"/admins/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_admin_confirmation_instructions(%Admin{} = admin, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if admin.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, admin_token} = AdminToken.build_email_token(admin, "confirm")
      Repo.insert!(admin_token)
      AdminNotifier.deliver_confirmation_instructions(admin, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a admin by the given token.

  If the token matches, the admin account is marked as confirmed
  and the token is deleted.
  """
  def confirm_admin(token) do
    with {:ok, query} <- AdminToken.verify_email_token_query(token, "confirm"),
         %Admin{} = admin <- Repo.one(query),
         {:ok, %{admin: admin}} <- Repo.transaction(confirm_admin_multi(admin)) do
      {:ok, admin}
    else
      _ -> :error
    end
  end

  defp confirm_admin_multi(admin) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, Admin.confirm_changeset(admin))
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given admin.

  ## Examples

      iex> deliver_admin_reset_password_instructions(admin, &url(~p"/admins/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_admin_reset_password_instructions(%Admin{} = admin, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, admin_token} = AdminToken.build_email_token(admin, "reset_password")
    Repo.insert!(admin_token)

    AdminNotifier.deliver_reset_password_instructions(
      admin,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the admin by reset password token.

  ## Examples

      iex> get_admin_by_reset_password_token("validtoken")
      %Admin{}

      iex> get_admin_by_reset_password_token("invalidtoken")
      nil

  """
  def get_admin_by_reset_password_token(token) do
    with {:ok, query} <- AdminToken.verify_email_token_query(token, "reset_password"),
         %Admin{} = admin <- Repo.one(query) do
      admin
    else
      _ -> nil
    end
  end

  @doc """
  Resets the admin password.

  ## Examples

      iex> reset_admin_password(admin, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Admin{}}

      iex> reset_admin_password(admin, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_admin_password(admin, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, Admin.password_changeset(admin, attrs))
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin: admin}} -> {:ok, admin}
      {:error, :admin, changeset, _} -> {:error, changeset}
    end
  end
end
