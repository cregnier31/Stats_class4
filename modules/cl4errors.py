# -*- coding: UTF-8 -*-

""" Exception classes for Class4 """

__all__ = (
        'Class4Exception',
        'Class4FatalError',
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
        return "Fatal error: {}".format(self.err)

