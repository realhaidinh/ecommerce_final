defmodule EcommerceFinal.Serving do
  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def get_embed(nil), do: Nx.tensor([0])

  def get_embed(input) do
    GenServer.call(__MODULE__, {:embed, input}, :infinity)
  end

  @impl true
  def init(init_arg) do
    {:ok, nil, {:continue, init_arg}}
  end

  @impl true
  def handle_continue(continue_arg, _) do
    model_name = Keyword.get(continue_arg, :model_name)
    {:ok, model_info} = Bumblebee.load_model({:hf, model_name})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})

    serving =
      Bumblebee.Text.text_embedding(model_info, tokenizer,
        output_attribute: :hidden_state,
        output_pool: :cls_token_pooling,
        embedding_processor: :l2_norm
      )

    {:noreply, serving}
  end

  @impl true
  def handle_call({:embed, text}, from, serving) do
    Task.async(fn ->
      embed =
        case Nx.Serving.run(serving, text) do
          %{embedding: embed} ->
            embed

          outputs ->
            for out <- outputs, do: out.embedding
        end

      {from, embed}
    end)

    {:noreply, serving}
  end

  @impl true
  def handle_info({_, {from, embed}}, serving) do
    GenServer.reply(from, embed)
    {:noreply, serving}
  end

  def handle_info(_, serving) do
    {:noreply, serving}
  end
end
