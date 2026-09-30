require_relative "../config/environment"
require "faker"
require "net/http"
require "uri"
require "json"

restaurant_ids = Restaurant.pluck(:id)
product_ids = Product.pluck(:id)
order_types = Order.order_types.keys

abort "No hay restaurantes o productos cargados." if restaurant_ids.empty? || product_ids.empty?

uri = URI("http://127.0.0.1:3000/api/v1/orders")

5.times do |index|
  order_type = order_types.sample
  item_count = rand(1..4)

  payload = {
    restaurant_id: restaurant_ids.sample,
    order_type: order_type,
    customer: {
      name: Faker::Name.name,
      phone: "+569#{Faker::Number.number(digits: 8)}"
    },
    items: product_ids.sample(item_count).map do |product_id|
      {
        product_id: product_id,
        quantity: rand(1..5)
      }
    end
  }

  if order_type == "delivery"
    payload[:delivery_address] = Faker::Address.full_address
  end

  scenario = "válido"

  case index
  when 1
    payload[:customer][:name] = ""
    scenario = "nombre vacío"
  when 2
    payload[:restaurant_id] = 99_999
    scenario = "restaurante inexistente"
  when 3
    payload[:items] = []
    scenario = "sin productos"
  end

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["Accept"] = "application/json"
  request.body = JSON.generate(payload)

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  response_body = JSON.parse(response.body)

  puts "Solicitud #{index + 1} (#{scenario}): HTTP #{response.code}"

  if response.is_a?(Net::HTTPSuccess)
    puts "Orden #{response_body["id"]} creada."
    puts "Estado del despacho: #{response_body["dispatch_status"]}"
  else
    puts "La API rechazó la orden:"
    puts JSON.pretty_generate(response_body)
  end
end