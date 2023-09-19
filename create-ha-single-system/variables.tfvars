name = "projectName" #project name
region = "westeurope" #eastasia, southeastasia, centralus, eastus, eastus2, westus, northcentralus, southcentralus, northeurope, westeurope, japanwest, japaneast, brazilsouth, australiaeast, australiasoutheast, southindia, centralindia, westindia, canadacentral, canadaeast, uksouth, ukwest, westcentralus, westus2, koreacentral, koreasouth, francecentral, francesouth, australiacentral, australiacentral2, southafricanorth, southafricawest 
failoverRegion = "westus" #eastasia, southeastasia, centralus, eastus, eastus2, westus, northcentralus, southcentralus, northeurope, westeurope, japanwest, japaneast, brazilsouth, australiaeast, australiasoutheast, southindia, centralindia, westindia, canadacentral, canadaeast, uksouth, ukwest, westcentralus, westus2, koreacentral, koreasouth, francecentral, francesouth, australiacentral, australiacentral2, southafricanorth, southafricawest 
businessImpact = "low" #low, medium, high
dotnetVersion = "v6.0" #v2.0, v3.0, v4.0, v5.0, v6.0, v7.0
stack = "dotnet" #dotnet, dotnetcore, node, python, PHP, java
operatingSystem = "Windows" #Windows, Linux, WindowsContainer
environment = "dev" #dev, prod
sku = "S1" #B1, B2, B3, D1, F1, I1, I2, I3, I1v2, I2v2, I3v2, I4v2, I5v2, I6v2, P1v2, P2v2, P3v2, P0v3, P1v3, P2v3, P3v3, P1mv3, P2mv3, P3mv3, P4mv3, P5mv3, S1, S2, S3, SHARED, EP1, EP2, EP3, WS1, WS2, WS3, Y1
db = {
    sku = "S0" #Not necessary if connection string field is valued
    type = "SQLAzure" #Not necessary if connection string field is valued
    adminName = "sqladmin" #Not necessary if connection string field is valued
    adminPassword = "Password123" #Not necessary if connection string field is valued
}
storage = {
    tier: "Standard" #Standard or Premium
    replication: "RAGZRS" #LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS
    kind: "StorageV2" #Storage, StorageV2, BlobStorage
}