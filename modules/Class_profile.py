import matplotlib.pyplot as plt
from matplotlib import style


class Plot_profile(object):
    """
        Class to plot profiles
    """

    def __init__(self,style='ggplot',dpi=100, **kwargs):
        self.style.use('ggplot')
        self.fig, self.ax = plt.subplots(figsize=(5, 7))
        self.ax.invert_yaxis()
        self.dpi = dpi
    def plot(self, x, y, title=title, label=label, linewidth=1,  xmin=None, xmax=None, save=False):
        ax.plot(x, y, 'ko', label=label,\
                            linewidth=linewidth)
