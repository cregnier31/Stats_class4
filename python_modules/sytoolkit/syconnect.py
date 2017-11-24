# -*- coding: UTF-8 -*-


from __future__ import with_statement

# standard import
import sys
import os

# package import
from sytoolkit.syerrors import *

# external import
import pexpect


def end(pterm):
    """Close the connection as well as possible""" 
    # This makes sure the child is dead; 
    # although it would be killed when Python exits.
    if pterm.isalive():
        pterm.sendline('exit')
        pterm.close()

def begin(pcommand, phost, ptimeout = 5):
    """Begin the connection with a spawn to server host."""
    try:
        concat = ''.join([pcommand, ' ', phost])
        pterm = pexpect.spawn(concat, timeout = ptimeout)
    
    except pexpect.TIMEOUT:
        end(pterm)
        raise SytoolkitMTOConnectTimeOut, phost

    except pexpect.EOF:
        end(pterm)
        raise SytoolkitMTOConnectEOF, phost
    
    return pterm

def login(user, password, pterm):
    """Log the user with is password."""
    try:
        pterm.expect(['(?i)user:.*', '(?i)login:.*', '(?i).*username.*'], 
                                                                timeout = 30)
        pterm.sendline(user)
        pterm.expect(['(?i)password:.*', '(?i).*password.*'])
        pterm.sendline(password)
    
    except pexpect.TIMEOUT:
        end(pterm)
        raise SytoolkitMTOConnectTimeOut, "remote host"

    except pexpect.EOF:
        end(pterm)
        raise SytoolkitMTOConnectEOF, "remote host"
    
    return 1

def setHost(host, pterm):
    """Set the target host, used when connection passthrough a firewall/proxy
    """
    try:
        pterm.expect(['(?i)host:.*'])
        pterm.sendline(host)

    except pexpect.TIMEOUT:
        end(pterm)
        raise SytoolkitMTOConnectTimeOut, host

    except pexpect.EOF:
        end(pterm)
        raise SytoolkitMTOConnectEOF, host
    
    return 1


def interact(pterm):
    """Prepare  pterm for user interaction."""
    # print some information ... if we need to exit gracefully one day ;-)
    print("Escape character is '^]'. Use it for exit ... =)")
    # Flush stdout
    sys.stdout.flush()

    # Try Interact now
    try :
        # until the escape caracter or exit command (exception),
        # script is now blocked here:
        pterm.interact()

    except pexpect.TIMEOUT:
        end(pterm)
        raise SytoolkitMTOConnectTimeOut

    except pexpect.EOF:
        end(pterm)
        raise SytoolkitMTOConnectEOF
    
    return 1


# vim: set ts=4 sw=4 tw=79:
