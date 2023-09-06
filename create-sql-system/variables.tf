variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "businessImpact" {
  type = string
}
variable "allowIps" {
  type = object({
    prod = list(string)
    dev = list(string)
  })
}
variable "db" {
  type = object({
    prod = object({
      sku = string
      adminName = string
      adminPassword = string
    })
    dev = object({
      sku = string
      adminName = string
      adminPassword = string
    })
  })
}