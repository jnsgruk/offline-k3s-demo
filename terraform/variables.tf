variable "location" {
  description = "Default Azure region for deployment"
  default     = "uksouth"
}

variable "servers" {
  default = {
    1 = "node-0" 
    2 = "node-1"
    3 = "node-2"
  }
}