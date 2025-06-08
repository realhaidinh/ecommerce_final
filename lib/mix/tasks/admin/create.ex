defmodule Mix.Tasks.Admin.Create do
  use Mix.Task
  alias EcommerceFinal.Accounts
  @impl Mix.Task
  @shortdoc "Creates an admin user with the specified email and password"
  def run(args) do
    Mix.Task.run("app.start")

    case parse_args(args) do
      {email, password} when is_binary(email) and is_binary(password) ->
        IO.puts("Creating admin user with email: #{email}")
        create_admin(email, password)

      _ ->
        IO.puts("Usage: mix admin.create --email EMAIL --password PASSWORD")
    end
  end

  defp create_admin(email, password) do
    case Accounts.register_admin(%{
           email: email,
           password: password
         }) do
      {:ok, admin} ->
        IO.puts("Admin user created successfully: #{admin.email}")

      {:error, changeset} ->
        IO.puts("Failed to create admin user")

        for {field, errors} <- errors_on(changeset) do
          IO.puts("#{field}: #{Enum.join(errors, ", ")}")
        end
    end
  end

  defp parse_args(args) do
    args
    |> OptionParser.parse!(strict: [email: :string, password: :string])
    |> case do
      {opts, _} ->
        email = Keyword.get(opts, :email)
        password = Keyword.get(opts, :password)

        if email && password do
          {email, password}
        else
          :error
        end
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts[key] |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
