from glob import glob
import os
from .sydate import SyDate
import sys
import datetime as dt
class FileHandler:
    def __init__(self, config,
                 dirmodel, modele,
                 typemod, data_type,
                 directory, type_run,
                 dateval, param_dict, log):
        #module_dir = os.path.dirname(__file__)
        #config_path = os.path.join(module_dir, config_path)
        #with open(config_path, 'r') as f:
        #    self.config = yaml.safe_load(f)
        self.config = config
        self.dirmodel = dirmodel
        self.modele = modele
        self.typemod = typemod
        self.data_type = data_type
        self.directory = directory
        self.type_run = type_run
        self.dateval = dateval
        self.param_dict = param_dict
        self.daily_pref = self.param_dict['daily_pref']
        self.list_smoc_fcst = ['smoc_fcst', 'stokes_fcst']
        self.log = log

    def find_file(self, pattern, gridname_list):
        dateval = self.dateval
        # List of possible date formats
        date_formats = [
            dateval,  # Assuming it's already formatted correctly
            #f"{dateval[:4]}-{dateval[4:6]}-{dateval[6:]}"  # Convert %Y%m%d to %Y-%m-%d
            #f"{dateval[:4]}_{dateval[4:6]}_{dateval[6:]}"  # Convert to another variant if needed
        ]
        # Results to store all matching files
        all_files = []
        # Iterate over gridtypes and apply the date format logic
        for i, gridname in enumerate(gridname_list):
            self.log.debug(gridname)
            self.log.debug(self.dirmodel)
            self.log.debug(self.modele)
            self.log.debug(self.daily_pref)
            self.log.debug(self.directory)
            # Iterate over different date formats and try to find matching files
            for dateval_formatted in date_formats:
                if "fcst" in self.directory :
                    offset=int(self.directory[-1])
                    date_run=dt.date.fromisoformat(dateval)-dt.timedelta(offset)
                    formatted_pattern=f"{self.dirmodel}{self.directory}/{self.modele}_{self.daily_pref}_{dateval_formatted}-{dateval_formatted}_{gridname}_fcst-1_R{date_run:%Y%m%d}.nc"
                    if os.path.exists(formatted_pattern) :
                        all_files.append(formatted_pattern)  # Add found files to the results
                    else :
                        raise NameError(f'File not found {formatted_pattern}')

                elif "pers" in self.directory :
                    offset=int(self.directory[-1])
                    date2=dt.date.fromisoformat(dateval)-dt.timedelta(offset)
                    date_run=dt.date.fromisoformat(dateval)-dt.timedelta(offset-1)
                    formatted_pattern=f"{self.dirmodel}/nwct/{self.modele}_{self.daily_pref}_{date2:%Y%m%d}-{date2:%Y%m%d}_{gridname}_fcst-1_R{date_run:%Y%m%d}.nc"

                    if os.path.exists(formatted_pattern) :
                        all_files.append(formatted_pattern)  # Add found files to the results
                    else :
                        raise NameError(f'File not found {formatted_pattern}')

                else :
                    formatted_pattern = pattern.format(
                            dirmodel=self.dirmodel,
                            modele=self.modele,
                            daily_pref=self.daily_pref,
                            dateval=dateval_formatted,
                            gridtype=gridname,
                            directory=self.directory
                            )
                    file_tmp = glob(formatted_pattern)
                    
                    self.log.debug(dateval_formatted)
                    self.log.debug(formatted_pattern)
                    
                    if len(file_tmp) != 0 :
                        # If files are found, store them in the list
                        self.log.debug(f'File OK {file_tmp}')
                        all_files.extend(file_tmp)  # Add found files to the results
                        self.log.debug(f"{gridname} Add file {file_tmp}")
                    else :
                        raise NameError(f'There are no {formatted_pattern} files')

        # Return all found files or an empty list if none are found
        return all_files if all_files else None

    def load_files(self, leadtime):
        list_clim = ['clim', 'clim_curr']
         # Determine the configuration section based on typemod and directory
        if leadtime in self.list_smoc_fcst:
            config_section = self.config.get('file_handling', {}).get(leadtime, {})
        else:
            config_section = self.config.get('file_handling', {}).get(self.typemod, {})
        # Set directory type for non-clim cases
        self.directory_path = "clim"
        datev = SyDate(str(self.dateval))
        month = f'{datev.month:02}'
        day = f'{datev.day:02}'
        if self.directory not in list_clim:
            self.directory_path = "non_clim"
        # Get the specific directory configuration
        type_run_config = config_section.get(self.directory_path, config_section.get('type_run', {}))
        config_section.get(self.directory_path, [])
        # Prepare the list of files based on the configuration
        list_file = []
        if self.directory == "clim":
            type_run_config = config_section.get(self.directory_path, config_section.get(self.data_type, {}))
            type_run_dict = type_run_config.get(self.data_type, [])
            var_pattern = type_run_dict[self.param_dict['daily_pref']]['glob_pattern']
            glob_pattern = var_pattern.format(
                dirmodel=self.dirmodel,
                month=month,
                day=day
            )
            list_file.extend(glob(glob_pattern))
            if len(list_file) ==0 :
                raise IOError(f'{glob_pattern}')
        elif self.directory == "clim_curr":
            filename = self.param_dict['coordinates']
            list_file.append(filename)
            list_file.append(filename)
        elif self.directory == "bathy":
            filename = self.param_dict['bathy_file']
            list_file.append(filename)
        else:
            # For non-clim cases, handle type_run configurations
            type_run_config = config_section.get(self.directory_path, config_section.get('type_run', {}))
            type_run_dict = type_run_config.get('type_run', [])
            type_run_config_keys = list(type_run_config['type_run'].keys())
            if self.type_run in type_run_config_keys:
                type_run = self.type_run
            else:
                type_run = "default"
            list_actions = type_run_dict.get(type_run, [])
            for action in list_actions:
                pattern = list_actions[action]
                file_select = self.find_file(pattern,
                                 self.param_dict.get('gridtype', ''))
                if len(file_select)>0:
                    self.log.debug(f"File loading ok {file_select}")
                    list_file.extend(file_select)
                else:
                    raise IOError(f"File loading nok {self.directory=} {pattern=} {self.param_dict.get('gridtype', '')}")
                    
        return list_file
