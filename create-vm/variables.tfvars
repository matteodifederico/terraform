name = "projectName" #project name
region = "westeurope" #eastasia, southeastasia, centralus, eastus, eastus2, westus, northcentralus, southcentralus, northeurope, westeurope, japanwest, japaneast, brazilsouth, australiaeast, australiasoutheast, southindia, centralindia, westindia, canadacentral, canadaeast, uksouth, ukwest, westcentralus, westus2, koreacentral, koreasouth, francecentral, francesouth, australiacentral, australiacentral2, southafricanorth, southafricawest 
businessImpact = "low" #low, medium, high
environment = "dev" #dev, prod
network = {
    VNETAddressSpace = ["10.0.0.0/16"] #Address space for the VNET
    subNetPrefixes = ["10.0.1.0/24"] #Address space for the Subnet
    publicIpAllocationMethod = "Dynamic" #Dynamic, Static
    privateIpAllocationMethod = "Dynamic" #Dynamic, Static
}
storage = {
    tier = "Standard" #Standard, Premium
    replication = "LRS" #LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS
    type = "StorageV2" #BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2
}
vm = {
    size = "Standard_B1s" #Standard_B1s, Standard_F2
    adminUsername = "exampleadmin" #VM admin username
    adminPassword = "Password123" #VM admin password
    osDisk = {
        storage = "StandardSSD_LRS" #StandardSSD_LRS, Standard_LRS, Premium_LRS, UltraSSD_LRS
        caching = "ReadWrite" #None, ReadOnly, ReadWrite
    }
    image = {
        offer = "WindowsServer"
        publisher = "MicrosoftWindowsServer"
        sku = "2019-Datacenter"
        version = "latest"
    }
}