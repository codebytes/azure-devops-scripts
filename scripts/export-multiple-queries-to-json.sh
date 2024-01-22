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

# Define queries using Query IDs
declare -A queries
queries[WorkItemsQ122]=6d29866f-30ff-4bc3-bbbb-9d1b795d464f
queries[WorkItemsQ222]=a9baa1df-cff6-4456-ab44-97b17d6bf3f8
queries[WorkItemsQ322]=abbd4302-eb7e-470b-afbb-850dc355c8e4
queries[WorkItemsQ422]=4da1d748-ab4c-4706-b22b-afef79b9e3ce
queries[WorkItemsQ123]=daa55d79-bb93-430f-bf63-34d2f835ea35
queries[WorkItemsQ223]=1f0b0bf8-e568-4d1d-84ff-6dac1d94276c
queries[WorkItemsQ323]=e6735bf5-aa09-420f-9aa0-4a23cab45e6d
queries[WorkItemsQ423]=2f866d54-7491-4329-a6c3-b2b685bc0c5e
queries[WorkItemsQ124]=680c49a2-4875-40d0-a3a6-f2bc90dc564c

# Define format for work item export so that we only get the fields we need
recordFormat='{Id:id,AreaPath:fields."System.AreaPath",AssignedTo:fields."System.AssignedTo".displayName,State:fields."System.State",CreatedDate:fields."System.CreatedDate",ChangedDate:fields."System.ChangedDate",Title:fields."System.Title",StateChangeDate:fields."Microsoft.VSTS.Common.StateChangeDate",ClosedDate:fields."Microsoft.VSTS.Common.ClosedDate",Categories:fields."Custom.Categories",Description:fields."System.Description",Tags:fields."System.Tags"}'

# Create directory for work items
mkdir -p workitems

allids=()

# this is to tell bash to handle tab as a delimiter
old_ifs="$IFS"
IFS=$'\t'

for key in ${!queries[@]}; do
    echo ${key} ${queries[${key}]}
    allids+=" "
    # Execute queries and export work item ids only
    # the --query is for JMESPath query syntax, and '[].id' means return only the id field
    ids=$(az boards query --org=$org --id ${queries[${key}]} --query '[].id' -o tsv)
    # this is to parse the ids from the query result
    tmp=($ids)
    echo $(echo $tmp | sort | uniq | wc -l) work items to export
    allids+=$ids
done

# this is to revert back to the original delimiter
IFS="$old_ifs"
# this is to remove duplicate ids
uniqueIds=$(echo $allids | sort | uniq)

# Loop through ids and export work items in the correct format to json files
for id in $uniqueIds; do
    trimmedId=$(echo $id |  sed -e 's/[^A-Za-z0-9._-]//g')
    fileName="workitems/$trimmedId.json"
    if [ ! -e $fileName -a ! -s $fileName ]; then
        az boards work-item show --org=$org --id $trimmedId -o json --query $recordFormat > $fileName
    fi
done

# Optional: Upload to Azure Blob Storage
# Login via 'az login' then upload the files to blob storage
# az storage blob upload-batch --account-name $saName -d $saContainer -s workitems/ --overwrite   