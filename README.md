# Azure App service with Postgres

This is an example to create an Azure App Service with an Postgres server  

It automatically generates a random DB password for the user ```dbmaster``` if a custom password is not provided on ```terraform apply|plan```

Replace ```your-subscription-id```, ```your-terraform-storage-account-name```, ```your-container-name``` with your values to store the terraform state in the azure cloud. This way it can run in an Azure dev-op environment.

At the end of the ```terraform apply``` the public link of the app service is prompted.

The database connection string is inserted in the app service instance as environment variables  
 ```SPRING_DATASOURCE_USERNAME```  
 ```SPRING_DATASOURCE_PASSWORD```  
 ```SPRING_DATASOURCE_URL```  

 this can then be used from a Java Spring application to connect to the database.