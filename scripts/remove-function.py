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
#files = os.listdir(src_dir)
#create_path_is_does_not_exist(dest_dir)
#shutil.copytree(src_dir, dest_dir)
try:
    shutil.rmtree(dest_dir)
except:
    print("There was an error deleting " + dest_dir + " and it's contents")
#os.remove(dest_dir)


# Remove function from environments
publish_configuration_folders = ["development","production"]
for cf in publish_configuration_folders:
    try:
        config_file_path = "../deployments/terraform/devops-lambda-functions-01/configurations/" + cf + "/functions.json"
        with open(config_file_path, 'r') as f:
            config = json.load(f)
            del config[args.FunctionName]
            with open(config_file_path, "w") as f:
                json.dump(config, f,  indent=8)
    except: 
        print("There was an error deleting function data index: " + args.FunctionName + " from " + config_file_path)




# remove service roles for environment.
    publish_configuration_folders = ["development","production"]
    for cf in publish_configuration_folders:
        try:
            config_file_path = "../deployments/terraform/devops-lambda-functions-01/configurations/" + cf + "/service_roles.json"
            with open(config_file_path, 'r') as f:
                config = json.load(f)
                del config[args.FunctionName]
            with open(config_file_path, "w") as f:
                json.dump(config, f,  indent=8)
        except: 
            print("There was an error deleting service roles data index: " + args.FunctionName + " from " + config_file_path)



