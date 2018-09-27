#!/usr/bin/python
# -*- coding: UTF-8 -*-

from __future__ import with_statement

import os
import sys
import pickle
import gzip
from getpass import getpass

def read_passwords(file_name):
    """ Open the file file_name and unpickle data"""
    if os.path.isfile(file_name):
        # open file, unpickle it 
        #with open(file_name, 'rb+') as f:
        #    data_read = pickle.load(f)
        #    local_dict = dict(data_read)
            #host = data_read[0].decode('base64')
            #login = data_read[1].decode('base64')
            #password = data_read[2].decode('base64')
        fz = gzip.open(file_name, 'rb') 
        data_read = fz.read()
        fz.close()
        local_dict = dict(pickle.loads(data_read))
    else:
        print "ERROR : file missing ..."
        local_dict = dict()
    # all ok
    #return([host, login, password])
    return local_dict
    

def save_passwords(file_name, dict_pass):
    """ Write the user password to an encrypted file. 
    Well ... indeed we just gzip the file, in future it will be crypted.
    """
    #with open(file_name, 'wb') as f:
    #    pickle.dump(dict_pass, f) 
    data_serialized = pickle.dumps(dict_pass)

    fz = gzip.GzipFile(file_name, 'wb')
    fz.write(data_serialized)
    fz.close()


def get_password(host, dict_pass):
    """ Prompt user for his login and password. """
    # prompt user
    print "What's your login and password for", host, "?"
    login = raw_input("User : ")
    password = getpass.getpass("Password : ")
    
    # put our ids in the dictionnary password
    dict_pass[host] = [login, password]

# vim: set ts=4 sw=4 tw=0:
