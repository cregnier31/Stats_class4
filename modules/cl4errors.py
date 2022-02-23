# -*- coding: UTF-8 -*-
import traceback
""" Exception classes for Class4 """

__all__ = (
        'Class4Exception',
        'Class4FatalError',
        'Class4TypeError',
)

# ==========
# Exceptions
# ==========

class Class4Exception(Exception):
    """ Base class for Class4 exceptions."""
    def __init__(self):
        pass


class Class4FatalError(Class4Exception):
    """A fatal error occured, usually this means a direct exit."""
    def __init__(self, err):
        self.err = err

    def __str__(self):
        return f"Fatal error {self.err}"
        #return f"Fatal error: {traceback.format_exc()}"

class Class4TypeError(Class4Exception):
    """A fatal error occured, usually this means a direct exit."""
    def __init__(self, err):
        self.err = err

    def __str__(self):
        return f"Type error {self.err}"
        #return f"Fatal error: {traceback.format_exc()}"
