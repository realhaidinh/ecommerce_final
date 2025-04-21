defmodule EcommerceFinal.ShoppingCartFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EcommerceFinal.ShoppingCart` context.
  """

  @doc """
  Generate a cart.
  """
  def cart_fixture(attrs \\ %{}) do
    {:ok, cart} =
      attrs
      |> Enum.into(%{

      })
      |> EcommerceFinal.ShoppingCart.create_cart()

    cart
  end

  @doc """
  Generate a cart_item.
  """
  def cart_item_fixture(attrs \\ %{}) do
    {:ok, cart_item} =
      attrs
      |> Enum.into(%{
        price_when_carted: 42,
        quantity: 42
      })
      |> EcommerceFinal.ShoppingCart.create_cart_item()

    cart_item
  end
end
