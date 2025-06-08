defmodule EcommerceFinal.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias EcommerceFinal.Repo
  alias EcommerceFinal.Catalog.{Category, ProductImage, Product, Review}
  import EcommerceFinal.Utils.FormatUtil

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
    pattern = keyword <> "%"

    query =
      from p in Product,
        where: fragment("text_like(unaccent(?), unaccent(?))", ^pattern, p.title),
        limit: 5

    Repo.all(query)
  end

  def search_product(%{} = params) do
    page_no = Map.get(params, "page", "1") |> String.to_integer()
    limit = Map.get(params, "limit", 20)
    offset = (page_no - 1) * limit

    query =
      from p in Product,
        order_by: ^filter_product_order_by(Map.get(params, "sort_by"))

    query =
      case Map.get(params, "keyword", nil) do
        nil ->
          query

        keyword ->
          pattern = keyword <> "%"
          where(query, [p], fragment("text_like(unaccent(?), unaccent(?))", ^pattern, p.title))
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
      |> Repo.all()

    product_per_page = if total_products > limit, do: limit, else: total_products
    total_page = if product_per_page == 0, do: 1, else: ceil(total_products / product_per_page)

    %{products: products, total_page: total_page}
  end

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

  defp filter_product_order_by(_),
    do: []

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
        select_merge: %{
          rating: coalesce(avg(r.rating), 0.0),
          rating_count: coalesce(count(r.rating), 0)
        },
        preload: [:categories]
    )
  end

  def get_product(id) do
    Repo.one(
      from p in Product,
        where: p.id == ^id,
        left_join: r in assoc(p, :reviews),
        select_merge: %{
          rating: coalesce(avg(r.rating), 0.0),
          rating_count: coalesce(count(r.rating), 0)
        }
    )
  end

  def get_product!(id, params) do
    query =
      from(p in Product,
        where: p.id == ^id
      )

    params
    |> Enum.reduce(query, fn param, acc -> product_preload(acc, param) end)
    |> Repo.one!()
  end

  defp product_preload(query, :categories), do: query |> preload(:categories)

  defp product_preload(query, opts) when opts == :images or opts == :cover do
    images_query =
      case opts do
        :cover ->
          cover_query =
            from i in ProductImage,
              select: %{
                id: i.id,
                url: i.url,
                row_number: over(row_number(), :images_partition)
              },
              windows: [images_partition: [partition_by: :id, order_by: :inserted_at]]

          from i0 in ProductImage,
            join: i1 in subquery(cover_query),
            on: i0.id == i1.id and i1.row_number == 1

        _ ->
          from(i in ProductImage)
      end

    preload(query, images: ^images_query)
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
    %Product{}
    |> change_product(attrs)
    |> Repo.insert()
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
    product
    |> change_product(attrs)
    |> Repo.update()
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
    Repo.delete(product)
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
    Repo.all(Category)
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
    category
    |> change_category(attrs)
    |> Repo.update()
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
    subpath = get_subcategory_path(category) <> "%"

    Repo.delete_all(
      from c in Category,
        where: c.id == ^category.id or like(c.path, ^subpath)
    )
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

  def list_reviews_by_product(product_id) do
    Repo.all(
      from r in Review,
        where: r.product_id == ^product_id,
        left_join: u in assoc(r, :user),
        order_by: [desc: :inserted_at],
        preload: [user: u]
    )
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
