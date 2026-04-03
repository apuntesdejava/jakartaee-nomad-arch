Kind = "http-route"
Name = "app-routes"

Parents = [
  {
    Name        = "main-gateway"
    SectionName = "http"
  }
]

Rules = [
  # Payara Sales — entrada principal
  {
    Matches  = [{ Path = { Match = "prefix", Value = "/sales" } }]
    Services = [{ Name = "sales-backend" }]
  },
  # Quarkus Products — acceso directo (ej. para backoffice/admin)
  {
    Matches  = [{ Path = { Match = "prefix", Value = "/products" } }]
    Services = [{ Name = "products-backend" }]
  },
  # Quarkus Clients — acceso directo
  {
    Matches  = [{ Path = { Match = "prefix", Value = "/clients" } }]
    Services = [{ Name = "clients-backend" }]
  }
]