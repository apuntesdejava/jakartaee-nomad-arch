Kind = "service-intentions"
Name = "clients-backend"
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