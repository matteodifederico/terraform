name = "projectName" #project name
environment = "dev" #dev, prod, test, uat, etc.
region = "westeurope" #eastasia, southeastasia, centralus, eastus, eastus2, westus, northcentralus, southcentralus, northeurope, westeurope, japanwest, japaneast, brazilsouth, australiaeast, australiasoutheast, southindia, centralindia, westindia, canadacentral, canadaeast, uksouth, ukwest, westcentralus, westus2, koreacentral, koreasouth, francecentral, francesouth, australiacentral, australiacentral2, southafricanorth, southafricawest 
businessImpact = "low" #low, medium, high
allowIps = ["123.456.789.0", "123.456.789.1", "123.456.789.2"] #IP's authorized in the firewall of the related SQL Server
db = {
    sku = "Basic" #Azure SQL Database pricing tier
    adminName = "sqladmin" #Azure SQL Server admin user name
    adminPassword = "Password123" #Azure SQL Server admin password
}
user = {
    name = "sqladmin" #Azure SQL Server additional user name
    password = "Password123" #Azure SQL Server additional user password
    roles = ["db_datareader", "db_ddladmin", "db_datawriter"] #db_datareader, db_ddladmin, db_datawriter
}