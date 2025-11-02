from glob import glob
from .sydate import SyDate
import sys
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
            f"{dateval[:4]}-{dateval[4:6]}-{dateval[6:]}"  # Convert %Y%m%d to %Y-%m-%d
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
                formatted_pattern = pattern.format(
                                    dirmodel=self.dirmodel,
                                    modele=self.modele,
                                    daily_pref=self.daily_pref,
                                    dateval=dateval_formatted,
                                    gridtype=gridname,
                                    directory=self.directory
                                )
                self.log.debug(dateval_formatted)
                self.log.debug(formatted_pattern)
                
                file_tmp = glob(formatted_pattern)
                # If files are found, store them in the list
                if file_tmp:
                    self.log.debug(f'File OK {file_tmp}')
                    all_files.extend(file_tmp)  # Add found files to the results
                    self.log.debug(f"{gridname} Add file {file_tmp}")
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
        month = str(datev.month)
        day = str(datev.day)
        if datev.month < 10:
            month = '0' + str(datev.month)
        if datev.day < 10:
            day = f'0{datev.day}'
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
                self.log.debug(f"Pattern = {pattern}")
                self.log.debug(f"GridType = {self.param_dict.get('gridtype', '')}")
                if file_select:
                    self.log.debug(f"File ok {file_select}")
                    list_file.extend(file_select)
                else:
                    self.log.error(f"File nok {self.directory=} {pattern=} {self.param_dict.get('gridtype', '')}")
                    sys.exit(1)
                    
        return list_file
