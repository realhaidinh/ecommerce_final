defmodule EcommerceFinalWeb.Public.ChatBotComponent do
  use EcommerceFinalWeb, :live_component
  alias EcommerceFinalWeb.Bot.DialogFlow
  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="chat-box"
      class="fixed bottom-4 right-4 rounded-full shadow-lg w-16 h-16 bg-white flex flex-col overflow-hidden transition-all duration-0 data-[open=true]:h-[75vh] data-[open=true]:w-1/3 data-[open=true]:rounded-lg"
    >
      <div
        class="p-3 bg-gray-200 border-b border-gray-200 flex justify-center cursor-pointer"
        phx-click={
          JS.toggle_attribute({"data-open", "true", "false"}, to: "#chat-box")
          |> JS.toggle_attribute({"data-open", "true", "false"}, to: ".hero-chat-bubble-oval-left")
          |> JS.toggle_class("hidden", to: ".hero-chat-bubble-oval-left")
          |> JS.transition(
            {"ease-out duration-300", "opacity-0", "opacity-100"},
            to: "message-collapse")
        }
        }
      >
        <.icon
        name="hero-chat-bubble-oval-left"
        class="w-12 h-12 data-[open=true]:h-6 data-[open=true]:w-6"
        />
      </div>

      <div
        class="flex-1 overflow-y-auto p-4 bg-gray-50 message-collapse"
        id="chatbox-message-container"
        phx-hook="ScrollToBottom"
      >
        <div phx-update="stream" id="box-messages" class="space-y-3">
          <div
            :for={{_id, message} <- @streams.messages}
            id={"message-box-#{message.id}"}
            class={[
              "flex flex-col",
              if(message.sender == :user, do: "items-end", else: "items-start")
            ]}
          >
            <div class={[
              "p-3 rounded-2xl shadow-sm break-words",
              if(message.sender == :user,
                do: "bg-blue-500 text-white",
                else: "bg-white text-gray-800"
              )
            ]}>
              <span class={[
                "block leading-relaxed",
                if(message.sender == :bot, do: "whitespace-pre", else: nil)
              ]}>{message.content}</span>
            </div>
          </div>
        </div>
      </div>

      <form
        phx-submit="send_message"
        phx-target={@myself}
        class="p-3 bg-white border-t border-gray-200 flex items-center gap-3 message-collapse"
      >
        <input
          type="text"
          name="message"
          placeholder="Type your message..."
          autocomplete="off"
          class="flex-1 p-2 border border-gray-300 rounded-full text-sm focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
        />
        <button type="submit" class="text-blue-500 hover:text-blue-600" title="Send message">
          <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
          </svg>
        </button>
      </form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream(:messages, [], reset: true)

    {:ok, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message} = _params, socket) do
    message = String.trim(message)

    socket =
      if message != "" do
        new_message = create_message(message, :user)
        user_id = if socket.assigns.current_user, do: socket.assigns.current_user.id, else: nil
        socket
        |> stream_insert(:messages, new_message)
        |> start_async(:ask_bot, fn -> DialogFlow.ask(message, user_id) end)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :current_msg, message)}
  end

  @impl true
  def handle_async(:ask_bot, {:ok, response}, socket) do
    bot_response = create_message(response, :bot)
    {:noreply, stream_insert(socket, :messages, bot_response)}
  end

  def handle_async(:ask_bot, {:exit, _reason}, socket) do
    bot_response = create_message("Xin lỗi quý khách, đã có lỗi xảy ra.", :bot)
    {:noreply, stream_insert(socket, :messages, bot_response)}
  end

  defp create_message(content, sender) do
    %{id: System.unique_integer([:positive]), content: content, sender: sender}
  end
end
