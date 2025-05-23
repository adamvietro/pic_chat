defmodule PicChatWeb.MessageLive.FormComponent do
  use PicChatWeb, :live_component

  alias PicChat.Messages

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage message records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="message-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        phx-drop-target={@uploads.picture.ref}
        phx-value-user_id={@current_user.id}
      >
        <.input field={@form[:content]} type="text" label="Content" />
        <.live_file_input upload={@uploads.picture} />
        <%= for entry <- @uploads.picture.entries do %>
          <.live_img_preview entry={entry} width="75" />
        <% end %>
        <.input field={@form[:user_id]} type="hidden" value={@current_user.id} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Message</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{message: message} = assigns, socket) do
    changeset = Messages.change_message(message)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> allow_upload(:picture, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_event("save", %{"message" => message_params}, socket) do
    file_uploads =
      consume_uploaded_entries(socket, :picture, fn %{path: path}, entry ->
        ext = "." <> get_entry_extension(entry)
        dest = Path.join("priv/static/uploads", Path.basename(path <> ext))
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    message_params = Map.put(message_params, "picture", List.first(file_uploads))
    save_message(socket, socket.assigns.action, message_params)
  end

  @impl true
  def handle_event("validate", %{"message" => message_params}, socket) do
    changeset = Messages.change_message(socket.assigns.message, message_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  defp save_message(socket, :edit, message_params) do
    case Messages.update_message(socket.assigns.message, message_params) do
      {:ok, message} ->
        notify_parent({:edit, message})
        PicChatWeb.Endpoint.broadcast_from(self(), "messages", "edit", message)

        {:noreply,
         socket
         |> put_flash(:info, "Message updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_message(socket, :new, message_params) do
    IO.inspect(message_params)
    case Messages.create_message(message_params) do
      {:ok, message} ->
        notify_parent({:new, message})
        PicChatWeb.Endpoint.broadcast_from(self(), "messages", "new", message)

        {:noreply,
         socket
         |> put_flash(:info, "Message created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp get_entry_extension(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end
end
