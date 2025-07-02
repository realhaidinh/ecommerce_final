defmodule EcommerceFinal.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias EcommerceFinal.Accounts.User
  alias EcommerceFinal.Cache
  alias EcommerceFinal.Orders.LineItem
  alias EcommerceFinal.ShoppingCart
  alias EcommerceFinal.Repo
  alias EcommerceFinal.Catalog.Product
  alias EcommerceFinal.Orders.Order

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(
      from o in Order,
        left_join: u in assoc(o, :user),
        order_by: [asc: o.id],
        select: %Order{
          id: o.id,
          inserted_at: o.inserted_at,
          status: o.status,
          total_price: o.total_price,
          user: %User{
            id: u.id,
            email: u.email
          }
        }
    )
  end

  def list_user_orders(user_id) do
    Repo.all(
      from o in Order,
        where: o.user_id == ^user_id,
        left_join: i in assoc(o, :line_items),
        left_join: p in assoc(i, :product),
        order_by: [asc: i.inserted_at],
        preload: [line_items: {i, product: p}]
    )
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id) do
    user_query = preload_user()
    Repo.one!(
      from o in Order,
      where: o.id == ^id,
      preload: [user: ^user_query, line_items: [:product]]
    )
  end
  def preload_user do
    from u in User,
    select: %User{
      email: u.email
    }
  end
  def get_user_order_by_id(user_id, id) do
    user_query = preload_user()
    Repo.one!(
      from o in Order,
      where: o.id == ^id and o.user_id == ^user_id,
      preload: [user: ^user_query, line_items: [:product]]
    )
  end

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def insert_order(changeset) do
    Repo.insert(changeset)
  end

  def make_order(%ShoppingCart.Cart{} = cart, attrs \\ %{}) do
    line_items =
      Enum.map(cart.cart_items, fn item ->
        %LineItem{
          product_id: item.product_id,
          price: item.price_when_carted,
          quantity: item.quantity
        }
      end)

    order =
      change_order(
        %Order{
          user_id: cart.user_id,
          total_price: ShoppingCart.total_cart_price(cart),
          line_items: line_items
        },
        attrs
      )

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:order, order)
    |> Ecto.Multi.run(:prune_cart, fn _repo, _changes ->
      ShoppingCart.prune_cart_items(cart)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{order: order}} -> {:ok, order}
      {:error, name, value, _changes_so_far} -> {:error, {name, value}}
    end
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def get_order_by_transaction_id(transaction_id) do
    Repo.one(from o in Order, where: o.transaction_id == ^transaction_id)
    |> Repo.preload([:user, line_items: [:product]])
  end

  def complete_order(order) do
    Cache.reset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:order, update_order(order, %{status: "Đã giao hàng"}))
    |> Ecto.Multi.update_all(
      :reduce_product_stock,
      fn %{order: order} ->
        from(p in Product,
          left_join: i in LineItem,
          on: p.id == i.product_id,
          where: i.order_id == ^order.id,
          update: [inc: [sold: i.quantity], inc: [stock: -i.quantity]]
        )
      end,
      []
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{order: order}} ->
        {:ok, order}

      {1, _} ->
        :ok

      {:error, name, value, _changes_so_far} ->
        {:error, {name, value}}
    end
  end

  def distinct_years do
    Repo.all(
      from o in Order,
        select: fragment("extract(year from ?) as year", o.inserted_at),
        distinct: true,
        order_by: fragment("year desc")
    )
  end

  def summary(filters) do
    query =
      filter_by_date(Order, filters)
      |> where([o], o.status == :"Đã thanh toán" or o.status == :"Đã giao hàng")

    total_revenue =
      Repo.one(
        from o in query,
          select: sum(o.total_price)
      ) || 0

    total_orders = Repo.aggregate(query, :count, :id)

    unique_customers =
      Repo.one(
        from o in query,
          select: count(o.user_id),
          distinct: true
      ) || 0

    %{
      total_revenue: total_revenue,
      total_orders: total_orders,
      unique_customers: unique_customers
    }
  end

  def revenue_by_month(filters) do
    revenue_list =
      raw_revenue_by_month(filters)
      |> Enum.map(fn {key, value} ->
        %{key.month => value}
      end)
    revenue_map =
      case revenue_list do
      [] -> %{}
      [revenue_map] -> revenue_map
    end
    for month <- 1..12 do
      {month, Map.get(revenue_map, month, 0)}
    end
  end

  def raw_revenue_by_month(filters) do
    from(o in Order)
    |> filter_by_date(filters)
    |> where([o], o.status == :"Đã thanh toán" or o.status == :"Đã giao hàng")
    |> group_by([o], fragment("date_trunc('month', ?)", o.inserted_at))
    |> select([o], {fragment("date_trunc('month', ?)", o.inserted_at), sum(o.total_price)})
    |> Repo.all()
    |> Enum.into(%{}, fn {date, total} ->
      {date, total}
    end)
  end

  def filter_by_date(query, %{"year" => year}) do
    where(query, [o], fragment("extract(year from ?)", o.inserted_at) == ^year)
  end

  @doc """
  Returns the list of order_line_items.

  ## Examples

      iex> list_order_line_items()
      [%LineItem{}, ...]

  """
  def list_order_line_items do
    Repo.all(LineItem)
  end

  @doc """
  Gets a single line_item.

  Raises `Ecto.NoResultsError` if the Line item does not exist.

  ## Examples

      iex> get_line_item!(123)
      %LineItem{}

      iex> get_line_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_line_item!(id), do: Repo.get!(LineItem, id)

  @doc """
  Creates a line_item.

  ## Examples

      iex> create_line_item(%{field: value})
      {:ok, %LineItem{}}

      iex> create_line_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_line_item(attrs \\ %{}) do
    %LineItem{}
    |> LineItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a line_item.

  ## Examples

      iex> update_line_item(line_item, %{field: new_value})
      {:ok, %LineItem{}}

      iex> update_line_item(line_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_line_item(%LineItem{} = line_item, attrs) do
    line_item
    |> LineItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a line_item.

  ## Examples

      iex> delete_line_item(line_item)
      {:ok, %LineItem{}}

      iex> delete_line_item(line_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_line_item(%LineItem{} = line_item) do
    Repo.delete(line_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking line_item changes.

  ## Examples

      iex> change_line_item(line_item)
      %Ecto.Changeset{data: %LineItem{}}

  """
  def change_line_item(%LineItem{} = line_item, attrs \\ %{}) do
    LineItem.changeset(line_item, attrs)
  end
end
