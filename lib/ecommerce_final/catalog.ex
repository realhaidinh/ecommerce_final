defmodule EcommerceFinal.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  import EcommerceFinal.Utils.FormatUtil
  alias EcommerceFinal.Accounts
  alias EcommerceFinal.Repo
  alias EcommerceFinal.Catalog.{Category, ProductImage, Product, Review}
  alias EcommerceFinal.ProductRecommend

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    query = from(p in Product)

    query
    |> product_preload(:cover)
    |> product_preload(:rating)
    |> Repo.all()
  end

  def search_product(keyword) when is_binary(keyword) do
    pattern = "%" <> keyword <> "%"

    query =
      from p in Product,
        where: fragment("? like unaccent(?)", p.title_unaccented, ^pattern),
        limit: 5,
        select: %Product{
          id: p.id,
          title: p.title
        }

    Repo.all(query)
  end

  def search_product(params) when is_map(params) do
    page_no = Map.get(params, "page", "1") |> String.to_integer()
    limit = Map.get(params, "limit", 20)
    offset = (page_no - 1) * limit
    min_price = Map.get(params, "min_price") |> get_price()
    max_price = Map.get(params, "max_price") |> get_price()
    query =
      from p in Product,
        order_by: ^filter_product_order_by(Map.get(params, "sort_by")),
        select: %Product{
        title: p.title,
        id: p.id,
        price: p.price
      }

    query =
      case Map.get(params, "keyword") do
        nil ->
          query

        keyword ->
          pattern = "%" <> keyword <> "%"
          where(query, [p], fragment("? like unaccent(?)", p.title_unaccented, ^pattern))
      end

    total_products =
      Repo.aggregate(query |> filter_product_where(params) |> exclude(:group_by), :count)

    products =
      query
      |> limit(^limit)
      |> offset(^offset)
      |> product_preload(:rating)
      |> product_preload(:cover)
      |> filter_product_where(params)
      |> where([p], fragment("(?::int is null or price >= ?)", ^min_price, ^min_price))
      |> where([p], fragment("(?::int is null or price <= ?)", ^max_price, ^max_price))
      |> Repo.all()

    total_page = if total_products == 0, do: 1, else: ceil(total_products / limit)

    %{products: products, total_page: total_page}
  end

  defp get_price(price) when is_nil(price) or price === "", do: nil
  defp get_price(price) when is_binary(price), do: String.to_integer(price)

  defp filter_product_where(query, %{"category_ids" => category_ids}) do
    from p in query,
      left_join: c in "product_categories",
      on: c.product_id == p.id,
      where: c.category_id in ^category_ids,
      group_by: p.id
  end

  defp filter_product_where(query, _) do
    from(p in query)
  end

  defp filter_product_order_by("price_desc"),
    do: [desc: dynamic([p], p.price)]

  defp filter_product_order_by("price_asc"),
    do: [asc: dynamic([p], p.price)]

  defp filter_product_order_by("sales"),
    do: [desc: dynamic([p], p.sold)]

  defp filter_product_order_by("recent"),
    do: [desc: dynamic([p], p.inserted_at)]

  defp filter_product_order_by(_),
    do: [desc: dynamic([p], p.id)]

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id) do
    Repo.one!(
      from p in Product,
        where: p.id == ^id,
        left_join: r in assoc(p, :reviews),
        select: %Product{
          id: p.id,
          title: p.title,
          description: p.description,
          stock: p.stock,
          sold: p.sold,
          price: p.price
        },
        select_merge: %{
          rating: coalesce(avg(r.rating), 0.0),
          rating_count: coalesce(count(r.rating), 0)
        },
        preload: [:categories],
        group_by: [p.id]
    )
  end

  def get_product(id) do
    Repo.one(
      from p in Product,
        where: p.id == ^id,
        left_join: r in assoc(p, :reviews),
        select: %Product{
          id: p.id,
          title: p.title,
          description: p.description,
          stock: p.stock,
          sold: p.sold,
          price: p.price
        },
        select_merge: %{
          rating: coalesce(avg(r.rating), 0.0),
          rating_count: coalesce(count(r.rating), 0)
        },
        group_by: [p.id]
    )
  end

  def get_product!(id, opts) do
    query =
      from(p in Product,
        where: p.id == ^id
      )

    opts
    |> Enum.reduce(query, fn param, acc -> product_preload(acc, param) end)
    |> Repo.one!()
  end

  defp product_preload(query, :categories), do: query |> preload(:categories)

  defp product_preload(query, :images) do
    preload(query, images: ^from(i in ProductImage, select: %{url: i.url}))
  end

  defp product_preload(query, :cover) do
    first_image =
      from pi in ProductImage,
        distinct: pi.product_id,
        order_by: [asc: pi.id],
        select: %{
          id: pi.id,
          product_id: pi.product_id,
          url: pi.url
        }

    from(p in query,
      left_join: pi in subquery(first_image),
      on: pi.product_id == p.id,
      select_merge: %{cover: pi.url},
      group_by: [p.id, pi.url]
    )
  end

  defp product_preload(query, :rating) do
    from(p in query,
      left_join: r in assoc(p, :reviews),
      select_merge: %{
        rating: coalesce(avg(r.rating), 0.0),
        rating_count: coalesce(count(r.rating), 0)
      },
      group_by: [p.id]
    )
  end

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    product =
      %Product{}
      |> change_product(attrs)
      |> Repo.insert()

    ProductRecommend.reload_system()
    product
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product =
      product
      |> change_product(attrs)
      |> Repo.update()

    ProductRecommend.reload_system()
    product
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    product =
      Repo.delete(product)

    ProductRecommend.reload_system()
    product
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    attrs = Map.put(attrs, "slug", slugify(product.title))

    product
    |> Product.changeset(attrs)
    |> build_product_images_assoc(Map.get(attrs, "uploaded_files", []))
    |> build_product_categories_assoc(Map.get(attrs, "category_id"))
  end

  defp build_product_images_assoc(product_chset, uploaded_files) do
    images = Enum.map(uploaded_files, &%ProductImage{url: &1})
    Ecto.Changeset.put_assoc(product_chset, :images, images)
  end

  defp build_product_categories_assoc(product_chset, category_id) do
    categories =
      case get_category(category_id) do
        nil ->
          []

        category ->
          parent_category_ids = String.split(category.path, ".", trim: true)
          [category | list_categories_by_ids(parent_category_ids)]
      end

    Ecto.Changeset.put_assoc(product_chset, :categories, categories)
  end

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category, order_by: [desc: :id])
  end

  def list_categories_by_ids(category_ids) do
    Repo.all(from c in Category, where: c.id in ^category_ids)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)
  def get_category(id), do: Repo.get(Category, id)

  def get_category_with_product_count(id) do
    Repo.one(
      from c in Category,
        where: c.id == ^id,
        left_join: pc in "product_categories",
        on: pc.category_id == c.id,
        select_merge: %{product_count: coalesce(count(pc.category_id), 0)},
        group_by: [c.id]
    )
  end

  def list_root_categories() do
    from(c in Category,
      where: c.path == "0"
    )
    |> category_preload(:product_count)
    |> Repo.all()
  end

  def get_subcategory_path(%Category{} = category) do
    "#{category.path}.#{category.id}"
  end

  def get_subcategories(%Category{} = category) do
    subpath = get_subcategory_path(category)

    from(c in Category,
      where: c.path == ^subpath
    )
    |> category_preload(:product_count)
    |> Repo.all()
  end

  defp category_preload(query, :product_count) do
    from c in query,
      left_join: pc in "product_categories",
      on: pc.category_id == c.id,
      select_merge: %{product_count: coalesce(count(pc.category_id), 0)},
      group_by: [c.id]
  end

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> change_category(attrs)
    |> Repo.insert()
  end

  def insert_category(%Ecto.Changeset{} = chset), do: Repo.insert(chset)

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category =
      category
      |> change_category(attrs)
      |> Repo.update()

    ProductRecommend.reload_system()
    category
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    sub_path = get_subcategory_path(category)

    result =
      Repo.delete_all(
        from c in Category,
          where: c.id == ^category.id or fragment("path <@ ?", ^sub_path)
      )

    ProductRecommend.reload_system()
    result
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    attrs = Map.put(attrs, "slug", slugify(category.title))
    Category.changeset(category, attrs)
  end

  alias EcommerceFinal.Catalog.Review

  @doc """
  Returns the list of reviews.

  ## Examples

      iex> list_reviews()
      [%Review{}, ...]

  """
  def list_reviews do
    Repo.all(Review)
  end

  def list_rating_count_by_product(product_id) do
    query =
      from r in Review,
        where: r.product_id == ^product_id,
        group_by: [r.rating],
        order_by: [asc: r.rating],
        select: %{
          r.rating => count(r.rating)
        }

    Repo.all(query)
  end

  def list_reviews_by_product(product_id, params \\ %{}) do
    page = Map.get(params, :page, 1)
    limit = Map.get(params, :limit, 5)
    offset = (page - 1) * limit

    query =
      from r in Review,
        where: r.product_id == ^product_id

    total = Repo.aggregate(query, :count)
    total_page = if total == 0, do: 1, else: ceil(total / limit)

    reviews =
      Repo.all(
        from r in query,
          left_join: u in assoc(r, :user),
          order_by: [desc: r.inserted_at],
          offset: ^offset,
          limit: ^limit,
          select: %Review{
            id: r.id,
            user: %Accounts.User{
              id: u.id,
              email: u.email
            },
            content: r.content,
            rating: r.rating,
            inserted_at: r.inserted_at
          }
      )

    %{reviews: reviews, total_page: total_page, page: page}
  end

  @doc """
  Gets a single review.

  Raises `Ecto.NoResultsError` if the Review does not exist.

  ## Examples

      iex> get_review!(123)
      %Review{}

      iex> get_review!(456)
      ** (Ecto.NoResultsError)

  """
  def get_review!(id), do: Repo.get!(Review, id)

  @doc """
  Creates a review.

  ## Examples

      iex> create_review(%{field: value})
      {:ok, %Review{}}

      iex> create_review(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_review(attrs \\ %{}) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  def create_review(user_id, product_id, attrs \\ %{}) do
    %Review{
      user_id: user_id,
      product_id: product_id
    }
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a review.

  ## Examples

      iex> update_review(review, %{field: new_value})
      {:ok, %Review{}}

      iex> update_review(review, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_review(%Review{} = review, attrs) do
    review
    |> Review.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a review.

  ## Examples

      iex> delete_review(review)
      {:ok, %Review{}}

      iex> delete_review(review)
      {:error, %Ecto.Changeset{}}

  """
  def delete_review(%Review{} = review) do
    Repo.delete(review)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking review changes.

  ## Examples

      iex> change_review(review)
      %Ecto.Changeset{data: %Review{}}

  """
  def change_review(%Review{} = review, attrs \\ %{}) do
    Review.changeset(review, attrs)
  end
end
