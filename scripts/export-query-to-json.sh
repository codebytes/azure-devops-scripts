#!/bin/bash
# Azure DevOps organization and project details
org=https://dev.azure.com/ORGNAME or https://ORGNAME.visualstudio.com/
project=PROJECT_NAME
saName=xxx
saContainer=xxx

# FIRST, Make sure you have the devops cli extension installed.
# az extension add --name azure-devops --upgrade -y
# NEXT, login into the Azure Devops Portal and create a Personal Access Token (PAT)
# https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate#create-a-pat
# PAT must have work-items READ
# Use the PAT as the password
# az devops login --org $org

# Define queries using WIQL or Query IDs
wiqlquery="SELECT [System.Id] FROM WorkItems WHERE [Work Item Type] = 'Feedback' AND [State] <> 'Closed'"
queryId="6d29866f-30ff-4bc3-bbbb-9d1b795d464f"

# Define format for work item export so that we only get the fields we need
recordFormat='{Id:id,AreaPath:fields."System.AreaPath",AssignedTo:fields."System.AssignedTo".displayName,State:fields."System.State",CreatedDate:fields."System.CreatedDate",ChangedDate:fields."System.ChangedDate",Title:fields."System.Title",StateChangeDate:fields."Microsoft.VSTS.Common.StateChangeDate",ClosedDate:fields."Microsoft.VSTS.Common.ClosedDate",Categories:fields."Custom.Categories",Description:fields."System.Description",Tags:fields."System.Tags"}'

# Create directory for work items
mkdir -p workitems

# Execute queries and export work item ids only
# the --query is for JMESPath query syntax, and '[].id' means return only the id field
# ids=$(az boards query --org=$org --project=$project --wiql "$wiqlquery" --query '[].id' -o tsv)
ids=$(az boards query --org=$org --project=$project --id $queryId --query '[].id' -o tsv)

# Loop through ids and export work items in the correct format to json files
for id in $ids
do
    fileName="workitems/$id.json"
    az boards work-item show --org=$org --id $id -o json --query $recordFormat > $fileName
done

# Optional: Upload to Azure Blob Storage
# Login via 'az login' then upload the files to blob storage
# az storage blob upload-batch --account-name $saName -d $saContainer -s workitems/ --overwrite   