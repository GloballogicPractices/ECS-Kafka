#!/usr/bin/python

'''
@Author: Faizan ali
TODO:
Logging setup to make this lambda ready
'''


import boto3
import json
import sys
import argparse
import logging
import yaml
import os
import pprint

parser=argparse.ArgumentParser(description='Arguments for managing services with ecs')
#parser.add_argument('-r',action='store',dest='region',default='us-east-2',help='OPTIONAL: Region. Default is us-east-2')
parser.add_argument('-f',action='store',dest='confFile',default=None,help='OPTIONAL: Config to pass for parsing.')
parser.add_argument('-c',action='store',dest='count',default=int(-1),help='OPTIONAL: Count for scaling up or down, If not specified, will be picked from update conf file')
parser.add_argument('-v',action='store_true',help='OPTIONAL: Verbose flag')
parser.add_argument('-r',action='store',dest='region',required=True,help='Required: Target region [us-east-1,us-east-2]. ')
parser.add_argument('-e',action='store',dest='env',default='dev',help='OPTIONAL: Env (dev,qa,stage) to pick all files automatically. ')
action=parser.add_mutually_exclusive_group(required=True)
action.add_argument('--create',action='store_true',help='REQUIRED/EXCLUSIVE : Create a service from task definition')
action.add_argument('--update',action='store_true',help='REQUIRED/EXCLUSIVE : Update a service. [ task defs, container count etc]')
action.add_argument('--delete',action='store_true',help='REQUIRED/EXCLUSIVE : Delete a service from specified cluster')
action.add_argument('--task',action='store_true',help='REQUIRED/EXCLUSIVE : Create a task def without creating service')




def deleteService(mode,confFile,region,clusterName):
    """Function to parse config file for deleting service"""
    client = boto3.client('ecs',region_name=region)
    with open(confFile, 'r') as config:
         confParser =  yaml.load(config)
    # keeping failure to 503 since no error code is returned
    failedResponseCode = 503

    for modules in confParser['containers']:
        for svc in modules['serviceDelete']:
            svcCluster = clusterName
            svcServiceName = svc['serviceName']
            try:
                if mode:
                   print "Deleting service - %s " % (svcServiceName)
                response = client.delete_service(cluster=svcCluster, service=svcServiceName)
                deleteResponse = response['ResponseMetadata']['HTTPStatusCode']
                if mode:
                   print "Delete response:: %s " %(deleteResponse)
            except Exception, e:
                # verbose
                if mode:
                   print e
                   print "Service delete failed"
                   print "Response::: %s " % (failedResponseCode)
                return failedResponseCode


def registerNUpdateTask(mode,confFile,region):
    """Function to parse config file for registerring and creating/updating task def"""
    client = boto3.client('ecs',region_name=region)
    with open(confFile, 'r') as config:
         confParser =  yaml.load(config)
    # keeping failure to 503 since no error code is returned
    failedResponseCode = 503

    # setup parameter for task-def registration
    for modules in confParser['containers']:
        family=modules['family']
        containerDefinitions=modules['containerDefinitions']
        try:
           volumes = modules['volumes']
        except:
            if mode:
               print "No volumes to be attached"
            volumes = ''
        try:
           networkMode = modules['networkMode']
        except:
           networkMode = 'bridge'
        # verbose
        #if mode:
           #pprint.pprint(containerDefinitions)
        try:
           if mode:
              print "Registerring/updating task def: %s " % (family)
           if volumes:
              response = client.register_task_definition(family=family, networkMode=networkMode, containerDefinitions=containerDefinitions, volumes=volumes)
           else:
              response = client.register_task_definition(family=family, networkMode=networkMode, containerDefinitions=containerDefinitions)
           regResponse=response['ResponseMetadata']['HTTPStatusCode']
           if mode:
              print "Task registerred successfully..."
              print regResponse
           return regResponse
        except Exception, e:
           # verbose
           if mode:
              print e
              print "Service task creation or update failed"
              print "Response::: %s " % (failedResponseCode)
           return failedResponseCode


def updateService(mode,confFile,region,count,clusterName):
    """Function to parse config file for updating service"""
    # @TODO : check for task-def update
    client = boto3.client('ecs',region_name=region)
    with open(confFile, 'r') as config:
         confParser =  yaml.load(config)
    # keeping failure to 503 since no error code is returned
    failedResponseCode = 503


    #register task def before creating service.
    # Do not update task def if service count going to 0
    if count == int(0):
       regResponse = 200
    else:
       regResponse = registerNUpdateTask(mode,confFile,region)
       if mode:
          print "Task register response: %s " % (regResponse)

    if regResponse == 200:
       for modules in confParser['containers']:
         for svc in modules['serviceUpdate']:
            svcCluster = clusterName
            svcServiceName = svc['serviceName']
            svcTaskDefinition = svc['taskDefinition']
            # Count of tasks can be specified at the commandline as well
            if count == int(-1): svcDesiredCount = svc['desiredCount']
            else: svcDesiredCount = count
            svcdeploymentConfiguration = svc['deploymentConfiguration']
            try:
                if mode:
                   print "Updating sevice %s with count %s " % (svcServiceName,svcDesiredCount)
                response = client.update_service(cluster=svcCluster, service=svcServiceName, desiredCount=svcDesiredCount, taskDefinition=svcTaskDefinition, deploymentConfiguration=svcdeploymentConfiguration)
                updateResponse = response['ResponseMetadata']['HTTPStatusCode']
                if mode:
                   print "Update response:: %s " %(updateResponse)

            except Exception, e:
                # verbose
                if mode:
                   print e
                   print "Service update failed"
                   print "Response::: %s " % (failedResponseCode)
                return failedResponseCode


def createService(mode,confFile,region,count,clusterName):
    """Function to parse config file for registerring and creating services"""
    client = boto3.client('ecs',region_name=region)
    with open(confFile, 'r') as config:
         confParser =  yaml.load(config)
    # keeping failure to 503 since no error code is returned
    failedResponseCode = 503

    #register task def before creating service
    if count == int(0):
       regResponse = 200
    else:
       regResponse = registerNUpdateTask(mode,confFile,region)
       if mode:
          print regResponse

    if regResponse == 200:
       for modules in confParser['containers']:
           for svc in modules['serviceCreate']:
               #svcCluster = svc['cluster']
               svcCluster = clusterName
               svcServiceName = svc['serviceName']
               svcTaskDefinition = svc['taskDefinition']
               # Count of tasks can be specified at the commandline as well
               if count == int(-1): svcDesiredCount = svc['desiredCount']
               else: svcDesiredCount = count
               svcClientToken = svc['clientToken']
               svcdeploymentConfiguration = svc['deploymentConfiguration']
               try:
                  svcloadBalancers = svc['loadBalancers']
                  svcloadBalancers = []
               except:
                 svcloadBalancers = []
                 svcLbrole = ''
               # verbose
               #if mode:
                  #pprint.pprint(svc)
               try:
                  if mode:
                     print "Creating service %s " % (svcServiceName)
                  # If task def was registerred then create service
                  svcCreateResponse = client.create_service(cluster=svcCluster,serviceName=svcServiceName,taskDefinition=svcTaskDefinition,loadBalancers=svcloadBalancers,desiredCount=svcDesiredCount,clientToken=svcClientToken,deploymentConfiguration=svcdeploymentConfiguration)
                  createResponse=svcCreateResponse['ResponseMetadata']['HTTPStatusCode']
                  if createResponse == 200:
                     # verbose
                     if mode:
                        print createResponse
                        print "Response::: %s " % (createResponse)
                     return createResponse
                  else: return failedResponseCode
               except Exception, e:
                  # verbose
                  if mode:
                     print e
                     print "Service creation failed"
                     print "Response::: %s " % (failedResponseCode)
                  return failedResponseCode

def main(mode,confFile,region,count,action):
    """Function to manage muliple clusters for a single service situation as in consul client"""
    with open(confFile, 'r') as config:
         confParser =  yaml.load(config)
    responseCode = 503

    # If a service has listed multiple clusters then loop over it and
    # deploy service to all clusters. Else deploy to only one cluster
    for modules in confParser['containers']:
        #print modules
        for svc in modules['serviceCreate']:
            svcCluster = svc['cluster']
            #print svc
            if isinstance(svc['cluster'],list):
               if mode:
                  print 'Multiple clusters for service'
               if action == 'create':
                  for cluster in svc['cluster']:
                      print cluster
                      response = createService(mode,serviceConfFile,region,count,cluster)
                      responseCode = response
               if action == 'update':
                  for cluster in svc['cluster']:
                      response = updateService(mode,confFile,region,count,cluster)
                      responseCode = response
               if action == 'delete':
                  for cluster in svc['cluster']:
                      response = deleteService(mode,confFile,region,cluster)
                      responseCode = response
            else:
               if mode:
                  print "Single cluster for single service"
               if action == 'create':
                      response = createService(mode,serviceConfFile,region,count,svc['cluster'])
                      responseCode = response
               if action == 'update':
                      response = updateService(mode,confFile,region,count,svc['cluster'])
                      responseCode = response
               if action == 'delete':
                      response = deleteService(mode,confFile,region,svc['cluster'])
                      responseCode = response

    return responseCode


if __name__ == '__main__':
   # Call the parser to get the values
   args = parser.parse_args()
   # vebosity
   mode=args.v
   confFile = args.confFile
   region = args.region
   # Env is captured directly
   count = int(args.count)


   # *****************************************#
   #### SETUP TASK_DEF ONLY ###
   # *****************************************#
   if args.task:
      action = 'create-task'
      print "Create-task request recieved...\n"
      if confFile:
         #serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
         serviceConfFile = confFile
         # verbose
         if mode:
            print "Service config file : %s " %(serviceConfFile)
         # Create service for a single file
         registerNUpdateTask(mode,confFile,region)
      else:
         # loop over dir and extract all files
         for confFile in os.listdir(os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"):
             if confFile.endswith(".yaml"):
                serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
                if mode:
                   print "Service config file : %s " %(serviceConfFile)
                # Create service for all files in config-env directory
                registerNUpdateTask(mode,confFile,region)


   # *****************************************#
   #### SETUP TASK_DEF AND CREATE_SERVICE ###
   # *****************************************#
   if args.create:
      action = 'create'
      print "Create request recieved...\n"
      if confFile:
         #serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
         serviceConfFile = confFile
         # verbose
         if mode:
            print "Service config file : %s " %(serviceConfFile)
         # Create service for a single file
         main(mode,serviceConfFile,region,count,action)
      else:
         # loop over dir and extract all files
         for confFile in os.listdir(os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"):
             if confFile.endswith(".yaml"):
                serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
                if mode:
                   print "Service config file : %s " %(serviceConfFile)
                # Create service for all files in config-env directory
                main(mode,serviceConfFile,region,count,action)


   # ****************************************
   #### UPDATE EXISTING SERVICE
   #### COUNT,TASKDEF CAN BE UPDATED
   # ***************************************
   if args.update:
      action = 'update'
      print "Update request recieved\n"
      if confFile:
         # loop over dir and extract all files
         #serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
         serviceConfFile = confFile
         if mode:
            print "Service config file : %s " %(serviceConfFile)
         # Update service for a single file
         main(mode,serviceConfFile,region,count,action)
      else:
         for confFile in os.listdir(os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"):
             if confFile.endswith(".yaml"):
                serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
                if mode:
                   print "Service config file : %s " %(serviceConfFile)
                # Update service for all files in config-env directory
                print "...."
                print serviceConfFile
                main(mode,serviceConfFile,region,count,action)


   # *****************************************************
   #### DELETE SERVICES
   #### NOT Count in delete does not have any significance
   # ******************************************************
   if args.delete:
      action = 'delete'
      print "Delete requeste recieved........\n"
      if confFile:
         # loop over dir and extract all files
         #serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
         serviceConfFile = confFile
         # verbose
         if mode:
            print "Service config file : %s " %(serviceConfFile)
            # Delete service for a single file
         main(mode,serviceConfFile,region,count,action)
      else:
         for confFile in os.listdir(os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"):
             if confFile.endswith(".yaml"):
                serviceConfFile = os.path.dirname(os.path.abspath(__file__))+"/config/"+args.env+"/"+confFile
                if mode:
                   print "Service config file : %s " %(serviceConfFile)
                   # Delete service for all files in config-env directory
                main(mode,serviceConfFile,region,count,action)
