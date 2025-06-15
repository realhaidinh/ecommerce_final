defmodule EcommerceFinalWeb.Admin.Dashboard.Index do
  alias EcommerceFinal.Utils.FormatUtil
  use EcommerceFinalWeb, :live_view
  alias EcommerceFinal.Orders
  @impl true
  def mount(_params, _session, socket) do
    current_year = Date.utc_today().year
    available_years = Orders.distinct_years() |> Enum.map(&Decimal.to_integer/1)
    available_years =
      if Enum.member?(available_years, current_year) do
        available_years
      else
        available_years ++ [current_year]
      end

    {:ok,
     socket
     |> assign(:page_title, "Thống kê doanh thu")
     |> assign(:available_years, available_years)
     |> assign(:selected_year, current_year)
     |> load_data()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <form phx-change="filter" class="flex gap-4 items-center mb-6">
        <div>
          <label class="block text-sm font-medium text-gray-700">Year</label>
          <select name="year" value={@selected_year} class="border rounded px-2 py-1">
            <option
              :for={year <- @available_years}
              value={year}
              selected={to_string(@selected_year) == to_string(year)}
            >
              {year}
            </option>
          </select>
        </div>
      </form>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div class="bg-white rounded-2xl shadow p-4">
          <h2 class="text-sm font-medium text-gray-500">Tổng doanh thu cả năm</h2>
          <p class="text-xl font-bold text-gray-800">
            {FormatUtil.money_to_vnd(@total_revenue)}
          </p>
        </div>
        <div class="bg-white rounded-2xl shadow p-4">
          <h2 class="text-sm font-medium text-gray-500">Tổng đơn hàng</h2>
          <p class="text-xl font-bold text-gray-800">{@total_orders}</p>
        </div>
        <div class="bg-white rounded-2xl shadow p-4">
          <h2 class="text-sm font-medium text-gray-500">Số lượng khách hàng</h2>
          <p class="text-xl font-bold text-gray-800">{@unique_customers}</p>
        </div>
      </div>
      <div class="bg-white rounded-2xl shadow p-6">
        <h2 class="text-lg font-semibold mb-4">Doanh thu từng tháng</h2>
        <canvas id="sales-chart" phx-update="ignore" phx-hook="MonthlyChart" class="w-full h-64">
        </canvas>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("filter", %{"year" => year}, socket) do
    socket =
      socket
      |> assign(:selected_year, String.to_integer(year))
      |> load_data()

    {:noreply, socket}
  end

  defp load_data(socket) do
    filters = %{"year" => socket.assigns.selected_year}

    [summary, chart_data] =
      Task.await_many([
        Task.async(fn ->
          Orders.summary(filters)
        end),
        Task.async(fn ->
          Orders.revenue_by_month(filters)
        end)
      ])

    labels = Enum.map(chart_data, fn {date, _} -> date end)
    values = Enum.map(chart_data, fn {_, value} -> value end)

    assign(socket,
      total_revenue: summary.total_revenue,
      total_orders: summary.total_orders,
      unique_customers: summary.unique_customers
    )
    |> push_event("update_chart", %{
      labels: labels,
      values: values
    })
  end
end
