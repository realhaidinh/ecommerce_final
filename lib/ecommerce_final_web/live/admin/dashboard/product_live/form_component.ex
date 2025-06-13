defmodule EcommerceFinalWeb.Admin.Dashboard.ProductLive.FormComponent do
  alias EcommerceFinal.Catalog.Category
  alias EcommerceFinal.Catalog
  alias EcommerceFinal.Catalog.Product
  use EcommerceFinalWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <section class="bg-white">
        <.simple_form
          for={@form}
          id="product-form"
          phx-target={@myself}
          phx-submit="save"
          phx-change="change"
        >
          <.input field={@form[:title]} type="text" label="Tên sản phẩm" />
          <.input field={@form[:description]} type="text" label="Mô tả sản phẩm" />
          <.input field={@form[:price]} type="text" label="Giá bán" />
          <.input field={@form[:stock]} type="number" label="Kho" min="0" />
          <.input
            field={@form[:category_id]}
            type="select"
            list="categories"
            label="Danh mục"
            options={category_opts(@changeset)}
          />
          <div phx-drop-target={@uploads.uploaded_files.ref}>
            <label for={@uploads.uploaded_files.ref}>Ảnh sản phẩm</label>
            <.live_file_input upload={@uploads.uploaded_files} />
          </div>

          <%= for entry <- @uploads.uploaded_files.entries do %>
            <.live_img_preview entry={entry} width="75" />
            <div class="py-5">{entry.progress}%</div>

            <button
              type="button"
              phx-click="cancel-upload"
              phx-target={@myself}
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
          <% end %>

          <:actions>
            <.button phx-disable-with="...">Lưu</.button>
          </:actions>
        </.simple_form>
      </section>
    </div>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    attrs = %{"category_id" => get_product_main_category_id(product)}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:uploaded_files, accept: ~w(.jpg .jpeg .png .webp), max_entries: 10)
     |> assign_new(:changeset, fn ->
       Catalog.change_product(product, attrs)
     end)
     |> assign_new(:form, fn %{changeset: changeset} ->
       to_form(changeset)
     end)}
  end

  defp category_opts(changeset) do
    existing_id =
      changeset
      |> Ecto.Changeset.get_change(:categories, [])
      |> Enum.max_by(& &1.data.level, fn -> -1 end)

    for cat <- Catalog.list_categories(),
        do: [key: cat.title, value: cat.id, selected: cat.id == existing_id]
  end

  defp get_product_main_category_id(%Product{categories: %Ecto.Association.NotLoaded{}}), do: -1

  defp get_product_main_category_id(%Product{categories: categories}) do
    case Enum.max_by(categories, & &1.level, fn -> -1 end) do
      %Category{id: id} -> id
      _ -> -1
    end
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :uploaded_files, fn %{path: path}, entry ->
        dest = get_dest_path(entry.client_name)
        File.cp!(path, dest)
        {:ok, "/uploads/products/#{Path.basename(dest)}"}
      end)

    product_params = Map.put(product_params, "uploaded_files", uploaded_files)

    save_product(socket, socket.assigns.action, product_params)
  end

  def handle_event("change", %{"product" => product_params}, socket) do
    changeset = Catalog.change_product(socket.assigns.product, product_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :uploaded_files, ref)}
  end

  def save_product(socket, :edit, product_params) do
    case Catalog.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def save_product(socket, :new, product_params) do
    case Catalog.create_product(product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), msg)

  @product_images_dir Application.app_dir(:ecommerce_final, "priv/static/uploads/products")

  defp get_dest_path(path) do
    Path.join(@product_images_dir, Path.basename(path))
  end
end
