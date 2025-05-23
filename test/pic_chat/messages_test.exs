defmodule PicChat.MessagesTest do
  use PicChat.DataCase

  alias PicChat.Messages

  import PicChat.MessagesFixtures
  import PicChat.AccountsFixtures

  describe "messages" do
    alias PicChat.Messages.Message

    import PicChat.MessagesFixtures

    @invalid_attrs %{content: nil}

    test "list_messages/0 returns all messages" do
      user = user_fixture()
      message = message_fixture(user_id: user.id)
      assert Messages.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      user = user_fixture()
      message = message_fixture(user_id: user.id)
      assert Messages.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      user = user_fixture()
      valid_attrs = %{content: "some content", user_id: user.id}

      assert {:ok, %Message{} = message} = Messages.create_message(valid_attrs)
      assert message.content == "some content"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      user = user_fixture()
      message = message_fixture(user_id: user.id)
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Message{} = message} = Messages.update_message(message, update_attrs)
      assert message.content == "some updated content"
    end

    test "update_message/2 with invalid data returns error changeset" do
      user = user_fixture()
      message = message_fixture(user_id: user.id)
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)
      assert message == Messages.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      user = user_fixture()
      message = message_fixture(user_id: user.id)
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      user = user_fixture()
      message = message_fixture(user_id: user.id)
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end

    test "create_message/1 with valid data creates a message with picture" do
      user = user_fixture()
      valid_attrs = %{content: "some content", user_id: user.id, picture: "images/picture.png"}

      assert {:ok, %Message{} = message} = Messages.create_message(valid_attrs)
      assert message.content == "some content"
      assert message.user_id == user.id
      assert message.picture == "images/picture.png"
    end

    test "list_messages/1 returns paginated messages" do
      user = user_fixture()
      message1 = message_fixture(user_id: user.id)
      _message2 = message_fixture(user_id: user.id)
      assert Messages.list_messages(limit: 1, offset: 1) == [message1]
    end

    test "todays_messages/0" do
      user = user_fixture()
      today_message = message_fixture(user_id: user.id)

      yesterday =
        DateTime.add(DateTime.utc_now(), -1, :day) |> DateTime.truncate(:second)

      _yesterday_message =
        PicChat.Repo.insert!(%Message{
          content: "some content",
          user_id: user.id,
          inserted_at: yesterday
        })

      assert Messages.todays_messages() == [today_message]
    end
  end
end
