defmodule EcommerceFinalWeb.Admin.Dashboard.CategoryLive.FormComponent do
  alias EcommerceFinal.Catalog
  use EcommerceFinalWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <section class="bg-white ">
      <.simple_form for={@form} id="category-form" phx-target={@myself} phx-submit="save">
        <.input field={@form[:title]} type="text" label="Tên danh mục" />
        <:actions>
          <.button phx-disable-with="...">Lưu</.button>
        </:actions>
      </.simple_form>
    </section>
    """
  end

  @impl true
  def update(%{category: category} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Catalog.change_category(category))
     end)}
  end

  @impl true
  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.action, category_params)
  end

  defp save_category(%{assigns: %{category: category}} = socket, :edit, category_params) do
    case Catalog.update_category(category, category_params) do
      {:ok, category} ->
        notify_parent({:updated, category})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_category(%{assigns: %{category: category}} = socket, :new, category_params) do
    chset = Catalog.change_category(category, category_params)

    case Catalog.insert_category(chset) do
      {:ok, category} ->
        notify_parent({:created, category})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), msg)
end
