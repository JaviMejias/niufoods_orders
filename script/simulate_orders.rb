require_relative "../config/environment"
require "faker"
require "net/http"
require "uri"
require "json"

restaurant_ids = Restaurant.order(:id).pluck(:id)
product_ids = Product.pluck(:id)
order_types = Order.order_types.keys

abort "No hay restaurantes o productos cargados." if restaurant_ids.empty? || product_ids.empty?

uri = URI("http://127.0.0.1:3000/api/v1/orders")

scenarios = restaurant_ids.product(order_types).map do |restaurant_id, order_type|
  { name: "válido", restaurant_id: restaurant_id, order_type: order_type }
end

[ "nombre vacío", "restaurante inexistente", "sin productos" ].each do |name|
  scenarios << { name: name, restaurant_id: restaurant_ids.first, order_type: "pickup" }
end

scenarios.each_with_index do |scenario, index|
  order_type = scenario[:order_type]
  item_count = rand(1..4)

  payload = {
    restaurant_id: scenario[:restaurant_id],
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

  case scenario[:name]
  when "nombre vacío"
    payload[:customer][:name] = ""
  when "restaurante inexistente"
    payload[:restaurant_id] = restaurant_ids.max + 1
  when "sin productos"
    payload[:items] = []
  end

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["Accept"] = "application/json"
  request.body = JSON.generate(payload)

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  response_body = JSON.parse(response.body)

  puts "Solicitud #{index + 1} (#{scenario[:name]}, restaurante #{payload[:restaurant_id]}, #{order_type}): HTTP #{response.code}"

  if response.is_a?(Net::HTTPSuccess)
    puts "Orden #{response_body["id"]} creada."
    puts "Estado del despacho: #{response_body["dispatch_status"]}"
  else
    puts "La API rechazó la orden:"
    puts JSON.pretty_generate(response_body)
  end
end
