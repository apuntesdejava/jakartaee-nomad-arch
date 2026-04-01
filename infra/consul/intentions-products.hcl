Kind = "service-intentions"
Name = "products-backend"
Sources = [
  {
    Name   = "sales-frontend"
    Action = "allow"
  },
  {
    Name   = "api-gateway"
    Action = "allow"
  }
]