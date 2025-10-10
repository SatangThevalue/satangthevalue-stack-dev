# infra/nomad/config/nomad-server.hcl

data_dir  = "/nomad/data"
bind_addr = "0.0.0.0"
advertise {
  http = "nomad:4646"
  rpc  = "nomad:4647"
  serf = "nomad:4648"
}

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
}

consul {
  address = "consul:8500"
}

vault {
  enabled = true
  address = "http://vault:8200"
}