Kind = "service-intentions"
Name = "clients-backend"
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