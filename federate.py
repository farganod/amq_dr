import requests
from requests.auth import HTTPBasicAuth
import sys

# Defining main function
def main():
    user = sys.argv[1]
    password = sys.argv[2]
    admin_url=sys.argv[3]
    full_pri_endpoint = sys.argv[4]
    list = full_pri_endpoint.split('//')
    pri_endpoint = list[1]
    response=requests.put("{}/api/parameters/federation-upstream/%2f/my-upstream".format(admin_url), auth = HTTPBasicAuth(user, password), json={"value":{"uri":"amqps://{}:{}@{}".format(user, password, pri_endpoint),"expires":3600000}})
    print (response)
    print (response.content)
    response=requests.put("{}/api/policies/%2f/federate-me".format(admin_url), auth = HTTPBasicAuth(user, password), json={"pattern":"^amq\.", "definition":{"federation-upstream-set":"all"}, "apply-to":"exchanges","priority":1})
    print (response)
    print (response.content)
  
# Using the special variable 
# __name__
if __name__=="__main__":
    main()