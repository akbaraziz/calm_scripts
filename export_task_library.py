import json
import sys
import time
import requests
from requests.auth import HTTPBasicAuth
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
def get_request(url, params):
    headers = {'Content-type': 'application/json', 'Accept': 'application/json'}
    resp = requests.get(url, params=params, auth=HTTPBasicAuth('<username>', '<password>'), headers=headers, verify=False)
    if resp.status_code == 200:
        return json.loads(resp.content)
def post_request(url, payload):
    headers = {'Content-type': 'application/json', 'Accept': 'application/json'}
    resp = requests.post(url, auth=HTTPBasicAuth('<username>', '<password>'), headers=headers, data=json.dumps(payload), verify=False)
    if resp.status_code == 200:
        return json.loads(resp.content)
def get_project_uuid(project_name):
    for i in list_projects()['entities']:
        if i['spec']['name'] == project_name:
            return i['metadata']['uuid']
    return None
def list_projects():
    url = 'https://<PC2 IP>:9440/api/nutanix/v3/projects/list'
    return post_request(url=url, payload={"length": 250})
# Assign project
project_name = "<Target project on PC2>"
project_uuid = get_project_uuid(project_name)
# Get all the app task uuids
url1 = 'https://<PC1_IP>:9440/api/nutanix/v3/app_tasks/list'
payload = {"length": 250}
resp1 = post_request(url=url1, payload=payload)
for i in resp1['entities']:
    task_uuid = str(i['metadata']['uuid'])
    task_name = str(i['metadata']['name'])
    # Get task spec and resources
    url2 = 'https://<PC1_IP>:9440/api/nutanix/v3/app_tasks/'+task_uuid
    resp2 = get_request(url=url2, params={})
    # Prepare spec
    del resp2['status']
    del resp2['metadata']['project_reference']
    project_reference = {
        'name': project_name,
        'kind': 'project',
        'uuid': str(project_uuid)
    }
    resp2['metadata'] = {
        'project_reference': project_reference
    }
    url3 = 'https://<PC2 IP>:9440/api/nutanix/v3/app_tasks'
    resp3 = post_request(url=url3, payload=resp2)