variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "businessImpact" {
  type = string
}
variable "operatingSystem" {
  type = string
}
variable "dotnetVersion" {
  type = string
}
variable "stack" {
  type = string
}
variable "db" {
  type = object({
    prod = object({
      type = string
      sku = string
      adminName = string
      adminPassword = string
      connectionString = string
    })
    dev = object({
      type = string
      sku = string
      adminName = string
      adminPassword = string
      connectionString = string
    })
  })
}
variable "sku" {
  type = object({
    prod = string
    dev = string
  })
  default = {
    prod = "S1"
    dev = "B1"
  }
}