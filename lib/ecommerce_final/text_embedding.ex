defmodule EcommerceFinal.TextEmbedding do
  def get_embed(nil), do: Nx.tensor([0])

  def get_embed(input) do
    %{embedding: embed} = Nx.Serving.batched_run(TextEmbedding.Serving, input)
    embed[0]
  end

end
