# SQL Server vNext on Windows Server Containers - Docker demo

# Set variables
$acrRegistry="kemregistry01-on.azurecr.io"
$acrUser="kemregistry01"

# Supply Passwords to use
$saPassword=(Get-Credential).GetNetworkCredential().Password
$acrPassword=(Get-Credential).GetNetworkCredential().Password

# Search Docker Hub for MS SQL Server container images
docker search microsoft/mssql

# Pull MS SQL Server vNext for Windows container image to a local copy
docker pull microsoft/mssql-server-windows

# Display list of local images
docker images

# Start a new container from the container image
docker run -d -p 14331:1433 -e sa_password=$saPassword -e ACCEPT_EULA=Y microsoft/mssql-server-windows

# Display running containers
docker ps

# Display all containers
docker ps -a

# Get container IP address
$containerID="xxxx"
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containerID

# TSQL - create sample database
CREATE DATABASE [SampleDB01];
GO
USE [SampleDB01];
GO
CREATE TABLE dbo.Table01
(PKID INT IDENTITY(1,1) PRIMARY KEY,
 ColA VARCHAR(10),
 ColB VARCHAR(10),
 ColC DATETIME);
GO
INSERT INTO dbo.Table01
(ColA,ColB,ColC)
VALUES
(REPLICATE('A',10),REPLICATE('B',10),GETUTCDATE());
GO 10

# TSQL - Show records with random data in table in sample database
SELECT * FROM dbo.Table01

# Stop the container
docker stop $containerID

# Commit the container to a new image
docker commit $containerID sampleimage01

# Show list of local images
docker images

# Start new container from committed image
docker run -d -p 14332:1433 -e sa_password=$saPassword -e ACCEPT_EULA=Y sampleimage01

# Login to Docker Hub
docker login 

# Login to Azure Container Registry
docker login $acrRegistry -u $acrUser -p $acrPassword

# Tag a container image with a repository
docker tag sampleimage01 ${acrRegistry}/samples/sql:v1

# Show list of local images
docker images

# Push tagged container image to registry
docker push ${acrRegistry}/samples/sql:v1

# Remove container images
docker rmi sampleimage01  ${acrRegistry}/samples/sql:v1

# Pull container image from Azure container registry
docker pull ${acrRegistry}/samples/sql:v1

# Logout from Registry
docker logout $acrRegistry
