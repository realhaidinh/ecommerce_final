defmodule EcommerceFinal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application
  
  defp build_serving() do
    model_name = "AITeamVN/Vietnamese_Embedding"
    {:ok, model_info} = Bumblebee.load_model({:hf, model_name}, backend: Torchx.Backend)
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})
    
    Bumblebee.Text.text_embedding(model_info, tokenizer,
      output_attribute: :hidden_state,
      embedding_processor: :l2_norm
    )
  end
  
  @google_auth_json Application.compile_env!(:ecommerce_final, :google_auth_json)
  
  @impl true
  def start(_type, _args) do
    credentials = File.read!(@google_auth_json) |> JSON.decode!()
    source = {:service_account, credentials}
    topologies = Application.get_env(:libcluster, :topologies)
    children = [
      EcommerceFinalWeb.Telemetry,
      EcommerceFinal.Repo,
      {Goth, name: EcommerceFinal.Goth, source: source},
      {DNSCluster, query: Application.get_env(:ecommerce_final, :dns_cluster_query) || :ignore},
      {Cluster.Supervisor, [topologies, [name: EcommerceFinal.ClusterSupervisor]]},
      {Phoenix.PubSub, name: EcommerceFinal.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: EcommerceFinal.Finch},
      {Task.Supervisor, name: EcommerceFinal.TaskSupervisor},
      {Nx.Serving, name: TextEmbedding.Serving, serving: build_serving(), batch_timeout: 100, batch_size: 4},      
      # Start a worker by calling: EcommerceFinal.Worker.start_link(arg)
      # {EcommerceFinal.Worker, arg},
      # Start to serve requests, typically the last entry
      EcommerceFinalWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EcommerceFinal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EcommerceFinalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
