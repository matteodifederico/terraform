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
variable "sku" {
  type = string
  default = "B1"
}
variable "environment" {
  type = string
  default = "prod"
}
variable "db" {
  type = object({
    type = string
    sku = string
    adminName = string
    adminPassword = string
    connectionString = string
  })
}
variable "storage" {
  type = object({
    tier = string
    replication = string
    kind = string
  })
}
  