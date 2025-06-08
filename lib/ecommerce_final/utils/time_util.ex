defmodule EcommerceFinal.Utils.TimeUtil do
  def pretty_print(date = %DateTime{}) do
    {:ok, date} = DateTime.shift_zone(date, "Asia/Saigon")
    Calendar.strftime(date, "%d/%m/%Y")
  end

  def pretty_print_with_time(date = %DateTime{}) do
    {:ok, date} = DateTime.shift_zone(date, "Asia/Saigon")
    Calendar.strftime(date, "%d/%m/%Y %H:%M:%S")
  end

  @epoch DateTime.from_unix!(0)
  def get_current_time() do
    {:ok, time} = DateTime.now("Asia/Saigon")
    DateTime.diff(time, @epoch)
  end
end
