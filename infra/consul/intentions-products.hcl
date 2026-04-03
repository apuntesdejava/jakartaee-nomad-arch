Kind = "service-intentions"
Name = "products-backend"
Sources = [
  {
    Name   = "sales-backend"
    Action = "allow"
  },
  {
    Name   = "api-gateway"
    Action = "allow"
  }
]