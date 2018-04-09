# -*- coding : utf-8 -*-
# vim: set ts=4 sw=4 tw=79:

# standard imports
import re
import os

# package import
import sytoolkit
import sytoolkit.sydate as syd

class SyFile_base(object):
    def __init__(self, filename, gsearch, osearch, run_length=7):
        self.run_length = run_length
        self.filename = filename
        self.basename = os.path.basename(filename)
        self.gsearch = gsearch
        self.osearch = osearch

    # ==========
    # Properties
    # ==========
    @property
    def run_day(self):
        """return string run day"""
        return self.gsearch.group()[1:]

    @property
    def run_date(self):
        """return the SyDate corresponding to the run day"""
        return syd.SyDate(self.run_day)

    def fcstday(self, n):
        """True if file is about n day forecast"""
        if self.osearch:
            cmp_date = syd.SyDate(''.join(self.osearch.groups()))
            # |-- hdct --|-- nwct --|RUN|-- fcst --|-- fcst --|
            if isinstance(n,int) and n==int(n):
                return cmp_date == self.run_date.goforward(n)
            else:
                raise ValueError('can not check %s day forecast' % n)


class SyFile_std(SyFile_base):

    @property
    def fcst(self):
        """True if file is about forecast"""
        if self.osearch:
            cmp_date = syd.SyDate(''.join(self.osearch.groups()))
            # |-- hdct --|-- nwct --|RUN|-- fcst --|-- fcst --|
            return cmp_date >= self.run_date

    @property
    def nwct(self):
        """True if file is about nowcast"""
        if self.osearch:
            cmp_date = syd.SyDate(''.join(self.osearch.groups()))
            # move limit 1 run lenght backward
            # |-- hdct --|-- nwct --|RUN|-- fcst --|-- fcst --|
            limit_date1 = self.run_date
            limit_date2 = self.run_date.gobackward(self.run_length)
            return ( cmp_date > limit_date2 and cmp_date < limit_date1 )

    @property
    def hdct(self):
        """True if file is about hindcast"""
        if self.osearch:
            cmp_date = syd.SyDate(''.join(self.osearch.groups()))
            # move limit 1 run lenght backward
            # |-- hdct --|-- nwct --|RUN|-- fcst --|-- fcst --|
            limit_date = self.run_date.gobackward(self.run_length)
            return cmp_date < limit_date

class SyFile_ibi(SyFile_base):

    @property
    def hdct(self):
        """True if file is about hindcast"""
        if self.osearch:
            cmp_date = syd.SyDate(''.join(self.osearch.groups()))
            # move limit 1 run lenght backward
            # |-- hdct --|-- nwct --|RUN|-- fcst --|-- fcst --|
            return cmp_date < self.run_date

    @property
    def nwct(self):
        """ there is no nowcast run in IBI system """
        return False

    @property
    def fcst(self):
        """True if file is about forecast"""
        if self.osearch:
            cmp_date = syd.SyDate(''.join(self.osearch.groups()))
            # |-- hdct --|-- nwct --|RUN|-- fcst --|-- fcst --|
            return cmp_date >= self.run_date

def SyFile(filename):
    """ return the right SyFile_XXX object """

    if not filename:
        raise SytoolkitFatalError("you should provide a filename")

    _regexp = r'([0-9]{4})(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])'
    _re_gregorianrundate = re.compile('R' + _regexp)
    #_re_sequence_date = re.compile("_" + _regexp + "_" + _regexp + "_") # XXX unused ?
    _re_other_date = re.compile("_" + _regexp + "_")

    _re_ibi_file = re.compile('ibi([0-9]{2}|sr)_(mean|hrly|01hav|01dav)_' + _regexp)

    basename = os.path.basename(filename)

    gsearch = _re_gregorianrundate.search(basename)
    ibisearch = _re_ibi_file.search(basename)
    osearch = _re_other_date.search(basename)
    

    if not gsearch:
        raise SytoolkitFatalError("could not find a run date on file %s" % filename)

    if ibisearch:
        return SyFile_ibi(filename, gsearch, osearch)

    if osearch:
        return SyFile_std(filename, gsearch, osearch)
    
    raise SytoolkitFatalError("no valid matching on file %s" % filename)

