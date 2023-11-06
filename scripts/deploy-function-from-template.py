import json
import argparse
import shutil
import os


# Initialize parser
parser = argparse.ArgumentParser()
parser.add_argument("-tpl", "--TemplateName", help = "Name of the template folder.")
parser.add_argument("-fn", "--FunctionName", help = "Name of the function.")
args = parser.parse_args()

def create_path_is_does_not_exist(path):
    # Check whether the specified path exists or not
    isExist = os.path.exists(path)
    if not isExist:
        # Create a new directory because it does not exist
        os.makedirs(path)
        print("The new directory " + path + "was created!")


# Copy template
# path to source directory
src_dir = "../templates/functions/python-sqs-queue-and-trigger"
# path to destination directory
dest_dir = "../functions/" + str(args.FunctionName)
 
# getting all the files in the source directory
files = os.listdir(src_dir)
#create_path_is_does_not_exist(dest_dir)
shutil.copytree(src_dir, dest_dir)



configuration_folders = ["production","development"]
## Update lambda.json in each configuration folder.
for cf in configuration_folders:
    config_file_path = dest_dir +  "/configurations/" + cf + "/lambda.json"
    with open(config_file_path, 'r') as f:
        config = json.load(f)
        config["function_name"] = args.FunctionName
        config["function_description"] = args.FunctionName
    ## Write Results
    with open(config_file_path, "w") as f:
        json.dump(config, f,  indent=8)


configuration_folders = ["production","development"]
## Update sqs_queue.json in each configuration folder.
for cf in configuration_folders:
    config_file_path = dest_dir +  "/configurations/" + cf + "/sqs_queue.json"
    with open(config_file_path, 'r') as f:
        config = json.load(f)
        config["name_append"] = "_service"
        config["description"] = ""
        config["sender_role_attachment_key"] = str(args.FunctionName)
    ## Write Results
    with open(config_file_path, "w") as f:
        json.dump(config, f,  indent=8)


# Configure funtion the environment deployments.
# Production is set to deploy : False by default.
publish_configuration_folders = ["development","production"]
for cf in publish_configuration_folders:
    config_file_path = "../deployments/terraform/devops-lambda-functions-01/configurations/" + cf + "/functions.json"

    record = {
                'name' : args.FunctionName,
                'environment' : "cf",
                'deploy' : False if cf == "production" else True,
            }
    with open(config_file_path, 'r') as f:
        config = json.load(f)
        config[args.FunctionName] = record
    with open(config_file_path, "w") as f:
        json.dump(config, f,  indent=8)


# Configure the service role for the function.
publish_configuration_folders = ["development","production"]
for cf in publish_configuration_folders:
    config_file_path = "../deployments/terraform/devops-lambda-functions-01/configurations/" + cf + "/service_roles.json"
    record = {
                'name_append' : str(args.FunctionName) + "_service",
                'description' : "Service role for function: " + str(args.FunctionName),
                'allowed_assume_users' : "arn:aws:iam::638050436593:user/svc." + str(args.FunctionName)
            }
    with open(config_file_path, 'r') as f:
        config = json.load(f)
        config[args.FunctionName] = record
    with open(config_file_path, "w") as f:
        json.dump(config, f,  indent=8)




# ## customer.json file work
# customers_configuration_file_path = "../../configurations/" + args.ConfigurationFolderName +  "/customers.json"
# with open(customers_configuration_file_path, 'r') as f:
#     customers_configuration = json.load(f)
#     customers_configuration[args.CustomerId] = customers_configuration["000000"]
#     customers_configuration[args.CustomerId]["name"] = args.CustomerName
#     customers_configuration[args.CustomerId]["id"] = args.CustomerId
#     customers_configuration[args.CustomerId]["customershortname"] = args.CustomerShortName
#     customers_configuration[args.CustomerId]["customerstateabbreviation"] = args.CustomerStateAbbreviation
#     customers_configuration[args.CustomerId]["customerurlsuffix"] = args.CustomerUrlSuffix
# ## Write Results
# with open(customers_configuration_file_path, "w") as f:
#     json.dump(customers_configuration, f,  indent=4)


# ## customer_networking.json file work
# customers_netowkring_configuration_file_path = "../../configurations/" + args.ConfigurationFolderName +  "/customers_networking.json"
# with open(customers_netowkring_configuration_file_path, 'r') as f:
#     customers_netowkring_configuration = json.load(f)
#     customers_netowkring_configuration[args.CustomerId] = customers_netowkring_configuration["000000"]
# ## Write Results
# with open(customers_netowkring_configuration_file_path, "w") as f:
#     json.dump(customers_netowkring_configuration, f,  indent=4)
