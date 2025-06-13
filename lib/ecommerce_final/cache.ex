defmodule EcommerceFinal.Cache do
  @cache_name :ecommerce_cache
  @ttl :timer.minutes(30)

  def get(key, fun) do
    case Cachex.get(@cache_name, key) do
      {:ok, nil} ->
        value = fun.()
        Cachex.put(@cache_name, key, value, ttl: @ttl)
        value

      {:ok, value} ->
        value

      error ->
        error
    end
  end

  def update(key, value) do
    Cachex.put(@cache_name, key, value, ttl: @ttl)
  end

  def delete(key) do
    Cachex.del(@cache_name, key)
  end

  def reset, do: Cachex.reset(@cache_name)
end
