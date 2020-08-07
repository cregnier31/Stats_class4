import numpy as np
import matplotlib.pyplot as plt
import os, sys

if sys.version_info[0] >= 3:
    import configparser as ConfigParser
else:
    import ConfigParser

def load_db():
    db = ConfigParser.ConfigParser()
    db.read(os.path.expanduser(_DBFILE_))
    if not db.sections():
        print ("Configuration file not found !")
        sys.exit(1)
    return db


def pull_names(name_data):
    """
        Convenient name retrieval function
    """
    names = []
    if isinstance(name_data, np.ma.masked_array):
        for letters in name_data:
            value = b''.join(letters.data).strip().decode("utf-8")
            #names.append(str(b''.join(letters.data)).strip())
            names.append(value)
    else:
        for letters in name_data:
            value = b''.join(letters).strip().decode("utf-8")
            names.append(value)
            #names.append(str(b''.join(letters)).strip())
    return names

def discrete_cmap(self,N, base_cmap=None):
    """Create an N-bin discrete colormap from the specified input map"""
    # Note that if base_cmap is a string or None, you can simply do
    #    return plt.cm.get_cmap(base_cmap, N)
    # The following works for string, None, or a colormap instance:
    base = plt.cm.get_cmap(base_cmap,N)
    color_list = base(np.linspace(0, 1))
    cmap_name = base.name + str(N)
    return base.from_list(cmap_name, color_list, N)


def searchcell(array, value):
    """
    look for cell where elements should be inserted
    """
    idx = np.searchsorted(array, value, side="right")
    if idx == 0 or idx == len(array) or np.ma.is_masked(value):
        return np.nan
    else:
        return idx-1

