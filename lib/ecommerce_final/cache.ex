defmodule EcommerceFinal.Cache do
  @cache_name :ecommerce_cache
  @ttl :timer.minutes(30)

  def get(key, fun) do
    Cachex.fetch(@cache_name, key, fn ->
      {:commit, fun.()}
    end,
    ttl: @ttl)
  end

  def update(key, value) do
    Cachex.put(@cache_name, key, value, ttl: @ttl)
  end

  def delete(key) do
    Cachex.del(@cache_name, key)
  end

  def reset, do: Cachex.reset(@cache_name)
end
