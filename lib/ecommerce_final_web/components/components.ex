defmodule EcommerceFinalWeb.Components do
  use Phoenix.Component
  use Gettext, backend: EcommerceFinalWeb.Gettext
  use EcommerceFinalWeb, :verified_routes
  alias EcommerceFinal.Utils.FormatUtil
  alias EcommerceFinal.ShoppingCart.Cart
  alias EcommerceFinal.Catalog.Product
  alias Phoenix.LiveView.JS
  import EcommerceFinalWeb.CoreComponents

  attr :id, :string, required: true
  attr :table_id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :searchable, :string, default: "false"
  attr :sortable, :string, default: "false"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def data_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div>
      <table
        id={@table_id}
        phx-hook="DataTable"
        data-sortable={@sortable}
        data-searchable={@searchable}
        data-tbody-id={@id}
        data-tbody-phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
      >
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">
              <span class="flex items-center">{col[:label]}</span>
            </th>

            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>

        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={[
                "relative p-0",
                "font-medium text-gray-900 whitespace-nowrap ",
                @row_click && "hover:cursor-pointer"
              ]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>

            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :enum, :list, required: true

  def breadcrumb(assigns) do
    ~H"""
    <.intersperse :let={item} enum={@enum}>
      <:separator>
        <div class="flex items-center">
          <.icon name="hero-chevron-right-mini" />
        </div>
      </:separator>
      <.link
        navigate={item.url}
        class="ms-1 text-sm font-medium text-gray-700 hover:text-blue-600 md:ms-2  "
      >
        {item.title}
      </.link>
    </.intersperse>
    """
  end

  attr :current_user, :any, required: true
  attr :cart, Cart
  attr :role, :atom, required: true

  def navbar(assigns) do
    ~H"""
    <div class="border border-b border-gray-200 bg-gray-200  lg:py-4 ">
      <nav>
        <%= if @role == :user do %>
          <div class="max-w-screen-xl flex flex-wrap items-center justify-end mx-auto p-4">
            <div class="flex items-center md:order-2 space-x-3 md:space-x-0 rtl:space-x-reverse">
              <%= if @current_user do %>
                <button
                  type="button"
                  class="block text-sm  text-black-500 truncate  hover:shadow"
                  id="user-menu-button"
                  aria-expanded="false"
                  data-dropdown-toggle="user-dropdown"
                  data-dropdown-placement="bottom"
                >
                  {@current_user.email}
                </button>
                <!-- Dropdown menu -->
                <div
                  class="z-50 hidden my-4 text-base list-none bg-white divide-y divide-gray-100 rounded-lg shadow  "
                  id="user-dropdown"
                >
                  <ul class="py-2" aria-labelledby="user-menu-button">
                    <li>
                      <.link
                        href="/users/settings"
                        class="block px-4 py-2 text-sm text-gray-900 hover:bg-gray-100   "
                      >
                        Thông tin tài khoản
                      </.link>
                    </li>

                    <li>
                      <.link
                        href="/users/orders"
                        class="block px-4 py-2 text-sm text-gray-900 hover:bg-gray-100   "
                      >
                        Đơn mua
                      </.link>
                    </li>

                    <li>
                      <.link
                        href="/users/log_out"
                        method="delete"
                        class="block px-4 py-2 text-sm text-gray-900 hover:bg-gray-100   "
                      >
                        Đăng xuất
                      </.link>
                    </li>
                  </ul>
                </div>
              <% else %>
                <div class="flex items-center space-x-6 rtl:space-x-reverse">
                  <.link href="/users/log_in" class="text-sm font-medium text-gray-900 md:my-0 ">
                    Đăng nhập
                  </.link>

                  <.link href="/users/register" class="text-sm font-medium text-gray-900 md:my-0 ">
                    Đăng ký
                  </.link>
                </div>
              <% end %>

              <button
                data-collapse-toggle="navbar"
                type="button"
                class="inline-flex items-center p-2 w-10 h-10 justify-center text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200   "
                aria-controls="navbar"
                aria-expanded="false"
              >
                <span class="sr-only">Open main menu</span>
                <svg
                  class="w-5 h-5"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 17 14"
                >
                  <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M1 1h15M1 7h15M1 13h15"
                  />
                </svg>
              </button>
            </div>
          </div>

          <div class="max-w-screen-xl grid grid-cols-6 justify-between items-center mx-auto">
            <div id="navbar" class="justify-center hidden w-full md:flex md:w-auto md:order-1">
              <.link
                class="text-2xl font-medium text-gray-900 md:my-0 "
                navigate="/"
                aria-current="page"
              >
                Trang chủ
              </.link>
            </div>
            <.live_component module={EcommerceFinalWeb.Public.SearchComponent} id="search-bar" />
            <div :if={@current_user} class="order-3 flex col-start-6 justify-center">
              <.link
                id="dropdownDelayButton"
                href="/cart"
                data-dropdown-toggle="dropdownDelay"
                data-dropdown-delay="300"
                data-dropdown-trigger="hover"
                class="bg-transparent flex"
                type="button"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="size-6"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 0 0-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 0 0-16.536-1.84M7.5 14.25 5.106 5.272M6 20.25a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Zm12.75 0a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z"
                  />
                </svg>

                <span class="-top-3 relative bg-white border-2 border-solid rounded-xl px-2">
                  {length(@cart.cart_items)}
                </span>
              </.link>
              <!-- Dropdown menu -->
              <div
                id="dropdownDelay"
                class="flex flex-col justify-between w-1/4 z-10 hidden bg-white divide-y divide-gray-100 shadow"
              >
                <%= if @cart.cart_items == [] do %>
                  <p class="p-4">Giỏ hàng trống</p>
                <% else %>
                  <p class="p-4">Sản phẩm mới thêm</p>
                <% end %>

                <ul class="py-2 text-sm text-gray-700" aria-labelledby="dropdownDelayButton">
                  <li :for={item <- @cart.cart_items}>
                    <div class="flex justify-between m-1.5 p-2">
                      <.link navigate={~p"/products/#{item.product.id}"}>
                      {item.product.title}
                      </.link>
                      <p class="text-orange-500">
                        {FormatUtil.money_to_vnd(item.product.price)}
                      </p>
                    </div>
                  </li>
                </ul>
                <.link
                  class="self-end text-center w-2/3 m-1.5 py-2 bg-black text-white rounded-xl"
                  navigate="/cart"
                >
                  Xem giỏ hàng
                </.link>
              </div>
            </div>
          </div>
        <% else %>
          <div class="max-w-screen-xl flex flex-wrap flex-row-reverse items-center justify-between mx-auto p-4">
            <div class="flex items-center md:order-2 space-x-3 md:space-x-0">
              <%= if @current_user do %>
                <.link
                  navigate="/admin/settings"
                  class="block px-4 py-2 text-sm text-gray-900 hover:bg-gray-100   "
                >
                  Thông tin tài khoản {@current_user.email}
                </.link>

                <.link
                  href="/admin/log_out"
                  method="delete"
                  class="block px-4 py-2 text-sm text-gray-900 hover:bg-gray-100   "
                >
                  Đăng xuất
                </.link>
              <% else %>
                <div class="flex items-center space-x-6 rtl:space-x-reverse">
                  <.link href="/admin/log_in" class="text-sm font-medium text-gray-900 md:my-0 ">
                    Đăng nhập
                  </.link>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </nav>
    </div>
    """
  end

  attr :product, Product, required: true
  attr :id, :string

  def product_card(assigns) do
    ~H"""
    <.link id={@id} patch={"/products/#{@product.id}"}>
      <div class="flex h-full flex-col hover:cursor-pointer w-full max-w-sm bg-white border border-gray-200 rounded-lg shadow  ">
        <img
          class="p-2 self-center sm:h-40 sm:w-40 md:h-50 md:w-50"
          src={@product.cover}
          alt={@product.title}
        />
        <div class="px-2 pb-2 flex flex-col h-[42.5%]">
          <div class="flex flex-col flex-1">
            <p
              style="display: -webkit-box;
                    -webkit-line-clamp: 2;
                    -webkit-box-orient: vertical;
                    overflow: hidden;
                    text-overflow: ellipsis;"
              class="text-lg min-h-14 font-semibold tracking-tight text-gray-900 "
            >
              {@product.title}
            </p>

            <p class="text-xl font-semibold text-orange-500">
              {FormatUtil.money_to_vnd(@product.price)}
            </p>
          </div>

          <div class="flex justify-between mt-2">
            <div class="flex">
              <svg
                class="w-4 h-4 text-yellow-300"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="currentColor"
                viewBox="0 0 22 20"
              >
                <path d="M20.924 7.625a1.523 1.523 0 0 0-1.238-1.044l-5.051-.734-2.259-4.577a1.534 1.534 0 0 0-2.752 0L7.365 5.847l-5.051.734A1.535 1.535 0 0 0 1.463 9.2l3.656 3.563-.863 5.031a1.532 1.532 0 0 0 2.226 1.616L11 17.033l4.518 2.375a1.534 1.534 0 0 0 2.226-1.617l-.863-5.03L20.537 9.2a1.523 1.523 0 0 0 .387-1.575Z" />
              </svg>
              <span class="text-sm">
                {@product.rating}
              </span>
            </div>
            <span class="ml-1 text-sm">
              Đã bán {@product.sold}
            </span>
          </div>
        </div>
      </div>
    </.link>
    """
  end

  attr :images, :list, required: true
  attr :title, :string, required: false, default: ""

  def image_gallery(assigns) do
    ~H"""
    <div id="product-image-gallery">
      <div id="default-carousel" class="relative w-full" data-carousel="static">
        <div class="relative h-56 overflow-hidden rounded-lg md:h-96 z-0">
          <div :for={image <- @images} class="duration-700 ease-in-out" data-carousel-item>
            <img
              src={image.url}
              class="hover:cursor-pointer object-contain gallery-item absolute -translate-x-1/2 -translate-y-1/2 top-1/2 left-1/2"
              alt={@title}
              phx-click={
                show_modal("modal-image") |> JS.set_attribute({"src", image.url}, to: "#image-modal")
              }
            />
          </div>
        </div>

        <div class="bg-slate-500 w-full justify-center absolute z-10 flex -translate-x-1/2 left-1/2 space-x-3 rtl:space-x-reverse">
          <button
            :for={{_, id} <- Enum.with_index(@images)}
            type="button"
            class="w-3 h-3 rounded-full"
            aria-current="true"
            aria-label={"Ảnh #{@title}-#{id}"}
            data-carousel-slide-to={id}
          >
          </button>
        </div>
        <!-- Slider controls -->
        <button
          type="button"
          class="absolute top-0 start-0 z-30 flex items-center justify-center h-full  px-4 cursor-pointer group focus:outline-none"
          data-carousel-prev
        >
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-gray-800/30 hover:bg-gray-800 group-focus:outline-none">
            <svg
              class="w-4 h-4 text-white  rtl:rotate-180"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 6 10"
            >
              <path
                stroke="currentColor"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 1 1 5l4 4"
              />
            </svg>
            <span class="sr-only">Previous</span>
          </span>
        </button>

        <button
          type="button"
          class="absolute top-0 end-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none"
          data-carousel-next
        >
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-gray-800/30 hover:bg-gray-800  group-focus:outline-none">
            <svg
              class="w-4 h-4 text-white  rtl:rotate-180"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 6 10"
            >
              <path
                stroke="currentColor"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="m1 9 4-4-4-4"
              />
            </svg>
            <span class="sr-only">Next</span>
          </span>
        </button>
      </div>

      <.modal id="modal-image">
        <img id="image-modal" class="self-center" src="" alt={@title} loading="lazy" />
      </.modal>
    </div>
    """
  end

  def public_footer(assigns) do
    ~H"""
    <footer class="bg-white rounded-lg shadow  my-8">
      <hr class="my-6 border-gray-200 sm:mx-auto  lg:my-8" />
      <div class="w-full p-4">
        <div class="sm:flex sm:items-center sm:justify-between">
          <.link href="/" class="flex items-center mb-4 sm:mb-0 space-x-3 rtl:space-x-reverse">
            <img src="/uploads/logo.png" class="sm:h-16 sm:w-16 md:h-24 md:w-24" alt="Eshop UIT Logo" />
            <span class="self-center text-2xl font-semibold whitespace-nowrap ">
              Eshop UIT
            </span>
          </.link>
        </div>

        <span class="block text-sm text-gray-500 sm:text-center ">
          © 2024 <.link navigate="/" class="hover:underline">Eshop UIT™</.link>. All Rights Reserved.
        </span>
      </div>
    </footer>
    """
  end
end
