restaurants = [
  { code: "PROV", name: "Niu Foods Providencia" },
  { code: "LCON", name: "Niu Foods Las Condes" },
  { code: "NUNO", name: "Niu Foods Ñuñoa" }
]

products = [
  { sku: "SKU-001", name: "Niu Roll Salmón", price_clp: 8990 },
  { sku: "SKU-002", name: "California Ebi", price_clp: 7490 },
  { sku: "SKU-003", name: "Avocado Roll", price_clp: 6990 },
  { sku: "SKU-004", name: "Nigiri Salmón x2", price_clp: 3990 },
  { sku: "SKU-005", name: "Gyozas de Pollo x5", price_clp: 4490 },
  { sku: "SKU-006", name: "Edamame", price_clp: 3290 },
  { sku: "SKU-007", name: "Bowl Salmón Teriyaki", price_clp: 9990 },
  { sku: "SKU-008", name: "Bowl Pollo Teriyaki", price_clp: 8990 },
  { sku: "SKU-009", name: "Bebida 350 ml", price_clp: 1990 },
  { sku: "SKU-010", name: "Agua Mineral 500 ml", price_clp: 1590 }
]

restaurants.each do |attributes|
  restaurant = Restaurant.find_or_initialize_by(code: attributes[:code])
  restaurant.assign_attributes(name: attributes[:name])
  restaurant.save!
end

products.each do |attributes|
  product = Product.find_or_initialize_by(sku: attributes[:sku])
  product.assign_attributes(
    name: attributes[:name],
    price_clp: attributes[:price_clp]
  )
  product.save!
end