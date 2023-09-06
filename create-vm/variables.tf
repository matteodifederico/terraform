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
variable "network" {
    type = object({
        VNETAddressSpace = list(string)
        subNetPrefixes = list(string)
        publicIpAllocationMethod = string
        privateIpAllocationMethod = string
    })
}
variable "storage" {
    type = object({
        type = string
        tier = string
        replication = string
    })
}
variable "vm" {
    type = object({
      size = string
      adminUsername = string
      adminPassword = string
      osDisk = object({
        caching = string
        storageAccountType = string
      })
      image = object({
        publisher = string
        offer = string
        sku = string
        version = string
      })
    })
}