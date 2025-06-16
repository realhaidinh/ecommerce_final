// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import "flowbite/dist/flowbite.phoenix.js";
import { DataTable } from "simple-datatables";
import Chart from 'chart.js/auto'

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}
const currencyFormatter = new Intl.NumberFormat('vi-VN', {
  style: 'currency',
  currency: 'VND'
})
Hooks.DataTable = {
  createDataTable(element) {
    new DataTable(element, {
      searchable: element.dataset.searchable === "true",
      sortable: element.dataset.sortable === "true"
    })
    const tbody = element.querySelector('tbody')
    tbody.setAttribute("id", element.dataset.tbodyId)
    element.dataset.tbodyPhxUpdate && tbody.setAttribute("phx-update", element.dataset.tbodyPhxUpdate)
  },
  mounted() {
    this.createDataTable(this.el)
  },
  updated() {
    this.createDataTable(this.el)
  }
}
Hooks.MonthlyChart = {
  mounted() {
    this.handleEvent("update_chart", (data) => {
      const { labels, values } = data
      if (this.chart) {
        this.chart.destroy()
      }
      this.chart = this.createChart(labels, values)
    })
  },
  createChart(labels, values) {
    return new Chart(this.el.getContext("2d"), {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Doanh thu',
          data: values,
          backgroundColor: 'rgba(59, 130, 246, 0.6)',
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        scales: {
          x: {
            title: {
              display: true,
              text: 'Tháng',
            }
          },
          y: {
            beginAtZero: true,
            ticks: {
              callback: function (value) {
                return currencyFormatter.format(value);
              }
            }
          }
        }
      }
    })
  }
}
Hooks.SearchInput = {
  mounted() {
    this.products = document.querySelector("#product_preview")
    this.selectedIndex = -1
    this.el.addEventListener("keydown", (e) => {
      if (this.getProductsLength() == 0) {
        this.selectedIndex = -1
        return;
      }
      const prevIndex = this.selectedIndex
      switch (e.key) {
        case "ArrowUp":
          this.selectedIndex = this.selectedIndex >= 0 ? this.selectedIndex - 1 : this.getProductsLength() - 1
          this.selectedIndex >= 0 && this.products.children[this.selectedIndex].classList.add("bg-gray-200")
          prevIndex >= 0 && this.products.children[prevIndex].classList.remove("bg-gray-200")
          this.el.value = this.products.children[this.selectedIndex].children[0].innerText
          break;
        case "ArrowDown":
          this.selectedIndex = this.selectedIndex < this.getProductsLength() - 1 ? this.selectedIndex + 1 : 0
          this.products.children[this.selectedIndex].classList.add("bg-gray-200")
          prevIndex >= 0 && this.products.children[prevIndex].classList.remove("bg-gray-200")
          this.el.value = this.products.children[this.selectedIndex].children[0].innerText
          break;
        case "Enter":
          if (this.selectedIndex != -1) {
            e.preventDefault()
            window.location.href = this.products.children[this.selectedIndex].href
          }
          break;
        default:
          break
      }
    })
  },
  getProductsLength() {
    return this.products.children.length
  }
}

Hooks.ScrollToBottom = {
  updated() {
    this.el.scrollTop = this.el.scrollHeight
  }
}
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

