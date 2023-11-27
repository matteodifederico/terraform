variable "name" {
  type = string
}
variable "environment" {
  type = string
}
variable "region" {
  type = string
}
variable "businessImpact" {
  type = string
}
variable "allowIps" {
  type = list(string)
}
variable "db" {
  type = object({
    sku = string
    adminName = string
    adminPassword = string
  })
}
variable "user" {
  type = object({
    name = string
    password = string
    roles = list(string)
  })
}