import yaml
from glob import glob
from lib_pyt.libtools.sydate import SyDate
import os
import sys
class FileHandler:
    def __init__(self, config, dirmodel, modele, typemod, data_type, directory, type_run, dateval, param_dict):
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

    def find_file(self, pattern, gridname_list):
        dateval = self.dateval
        # List of possible date formats
        date_formats = [
            dateval,  # Assuming it's already formatted correctly
            f"{dateval[:4]}-{dateval[4:6]}-{dateval[6:]}",  # Convert %Y%m%d to %Y-%m-%d
            f"{dateval[:2]}{dateval[2:4]}{dateval[4:]}",  # Convert %Y%m%d to %YYMMDD
            f"{dateval[:4]}_{dateval[4:6]}_{dateval[6:]}"  # Convert to another variant if needed
        ]
        # Results to store all matching files
        all_files = []
        # Iterate over gridtypes and apply the date format logic
        for i, gridname in enumerate(gridname_list):
            print(self.dirmodel, self.modele,self.daily_pref, gridname, self.directory)

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
                file_tmp = glob(formatted_pattern)
                # If files are found, store them in the list
                if file_tmp:
                    all_files.extend(file_tmp)  # Add found files to the results
        # Return all found files or an empty list if none are found
        return all_files if all_files else None

#    def find_file(self, pattern, list_grids):
#        """
#            Find files based on the specified pattern, with formatting to include model,
#            daily prefix, date, grid types, and directory.
#        """
#        files = []
#        for gridtype in list_grids:
#            # Format the pattern with all necessary variables
#            formatted_pattern = pattern.format(
#                                dirmodel=self.dirmodel,
#                                modele=self.modele,
#                                daily_pref=self.daily_pref,
#                                dateval=self.dateval,
#                                gridtype=gridtype,
#                                directory=self.directory
#                            )
#            # Use glob to find matching files for the formatted pattern
#            files.extend(glob(formatted_pattern))
#        return files

    def load_files(self):
        # Determine the configuration section based on typemod and directory
        config_section = self.config.get('file_handling', {}).get(self.typemod, {})
        # Set directory type for non-clim cases
        self.directory_path = "clim"
        datev = SyDate(str(self.dateval))
        year = str(datev.year)
        month = str(datev.month)
        if datev.month < 10:
            month = '0' + str(datev.month)
        day = str(datev.day)
        if self.directory != "clim":
            self.directory_path = "non_clim"
        # Get the specific directory configuration
        type_run_config = config_section.get(self.directory_path, config_section.get('type_run', {}))
        directory_config = config_section.get(self.directory_path, [])
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
                if file_select:
                    print(f"File ok {file_select}")
                    list_file.extend(file_select)
                else:
                    print(f"File nok {pattern} {self.param_dict.get('gridtype', '')}")
            #else:
            #    # Handle default case for non-clim
            #    default_actions = type_run_dict.get('default', [])
            #    for action in default_actions:
            #        glob_pattern = default_actions[action]
            #        file_select = self.find_file(glob_pattern,
            #                         self.param_dict.get('gridtype', '')))
            #        if file_select:
            #            list_file.extend(file_select)
        return list_file
