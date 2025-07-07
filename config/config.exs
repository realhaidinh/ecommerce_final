# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ecommerce_final,
  ecto_repos: [EcommerceFinal.Repo],
  generators: [timestamp_type: :utc_datetime],
  payos_client_id: System.fetch_env!("PAYOS_CLIENT_ID"),
  payos_api_key: System.fetch_env!("PAYOS_API_KEY"),
  payos_checksum_key: System.fetch_env!("PAYOS_CHECKSUM_KEY"),
  host_email: System.fetch_env!("HOST_EMAIL"),
  google_auth_json: System.fetch_env!("GOOGLE_AUTH_JSON"),
  chat_bot_secret_key: System.fetch_env!("CHAT_BOT_SECRET_KEY"),
  dialogflow_project_id: System.fetch_env!("DIALOGFLOW_PROJECT_ID")

config :ecommerce_final, EcommerceFinal.Repo, types: EcommerceFinal.PostgrexTypes

config :nx, default_backend: {EXLA.Backend, client: :host}

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Configures the endpoint
config :ecommerce_final, EcommerceFinalWeb.Endpoint,
  url: [host: "eshopuit.id.vn", scheme: "https", port: 443],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: EcommerceFinalWeb.ErrorHTML, json: EcommerceFinalWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EcommerceFinal.PubSub,
  live_view: [signing_salt: "KNlIa9BO"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.

config :ecommerce_final, EcommerceFinal.Mailer,
  adapter: Resend.Swoosh.Adapter,
  api_key: System.fetch_env!("RESEND_API_KEY")

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ecommerce_final: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  ecommerce_final: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, JSON
config :swoosh, :json_library, JSON

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
