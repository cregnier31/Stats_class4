
from __future__ import with_statement
import os
import datetime

class SyFlag(object):
    """A flag is defined by his state (error, running, start ...),
       and an application name.
    """
    def __init__(self, name, state="", *args, **kwargs):
        self._state = state
        self._name = name

    @property
    def state(self):
        return self._state

    @property
    def name(self):
        return self._name

    def set_state(self, new_sate):
        self._state = new_sate

    def send_state(self):
        pass


class FileSyFlag(SyFlag):
    """Flags represented as a file"""
    __STATES = {
            'error' : 'ERROR',
            'running' : 'RUNNING',
            'end_ok' : 'OK'
        }

    def __init__(self, path="", *args, **kwargs):
        super(self.__class__, self).__init__(*args, **kwargs)
        self._path = path

    def send_state(self, *args):
        """ Write a file, name constructed with :
            name-date-state
            name : current flag name
            date : today date time
            state: append current text corresponding with the actual state

            @args : all aguments given are written in file
        """
        # if no path ... do nothing
        if not self._path: return 
        # make sure path exist
        if not os.path.exists(self.path):
            os.makedirs(self.path)
        # build flag name
        date = datetime.date.today().strftime("%Y%m%d")
        flag_name = "%s-%s-%s" % (self.name, date, self.state)
        current_flag = os.path.join(self.path, flag_name) 
        # drop flag
        with open(current_flag, 'w') as f:
            f.write(str(args))

    @property
    def path(self):
        return self._path

    @property
    def set_error(self):
        self._state = self.__STATES.get('error')

    @property
    def set_ok(self):
        self._state = self.__STATES.get('end_ok')

    @property
    def set_running(self):
        self._state = self.__STATES.get('running')

    def send_ok(self, *args):
        """Set current state to OK and write flag"""
        self.set_ok
        self.send_state(*args)

    def send_error(self, *args):
        """Set current state to ERROR and write flag"""
        self.set_error
        self.send_state(*args)
