defmodule EcommerceFinalWeb.Public.ProductLive.ReviewFormComponent do
  alias EcommerceFinal.Catalog.Review
  alias EcommerceFinal.Catalog
  use EcommerceFinalWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Đăng đánh giá sản phẩm
      </.header>
      <.simple_form
        for={@review_form}
        id="review-form"
        phx-target={@myself}
        phx-submit="submit_review"
      >
        <.input field={@review_form[:rating]} type="number" label="Điểm" min="1" max="5" value="1" />
        <.input field={@review_form[:content]} classes="w-full" type="textarea" label="Nội dung" />
        <:actions>
          <.button phx-disable-with="...">Đánh giá</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:review_form, fn ->
       to_form(Catalog.change_review(%Review{}, %{}))
     end)}
  end

  @impl true
  def handle_event("submit_review", %{"review" => review_params}, socket) do
    submit_review(socket, review_params)
  end

  def submit_review(socket, review_params) do
    %{current_user: user, product: product} = socket.assigns

    case Catalog.create_review(user.id, product.id, review_params) do
      {:ok, review} ->
        review = Map.put(review, :user, user)
        send(self(), {:review_posted, review})

        socket =
          socket
          |> put_flash(:info, "Đánh giá đã được đăng")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
