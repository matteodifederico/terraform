name = "projectName"
region = "westeurope" #eastasia, southeastasia, centralus, eastus, eastus2, westus, northcentralus, southcentralus, northeurope, westeurope, japanwest, japaneast, brazilsouth, australiaeast, australiasoutheast, southindia, centralindia, westindia, canadacentral, canadaeast, uksouth, ukwest, westcentralus, westus2, koreacentral, koreasouth, francecentral, francesouth, australiacentral, australiacentral2, southafricanorth, southafricawest 
businessImpact = "low" #low, medium, high
allowIps = {
    prod = ["123.456.789.0", "123.456.789.1", "123.456.789.2"]
    dev = ["123.456.789.0", "123.456.789.1", "123.456.789.2"]
}
db = {
    prod = {
        sku = "S0"
        type = "SQLAzure"
        adminName = "sqladmin"
        adminPassword = "Password123"
        connectionString = ""
    }
    dev = {
        sku = "Basic"
        type = "SQLAzure"
        adminName = "sqladmin"
        adminPassword = "Password123"
        connectionString = ""
    }
}