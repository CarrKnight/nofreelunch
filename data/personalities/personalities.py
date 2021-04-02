import os
import pandas as pd

import pyNetLogo
from multiprocessing import Pool
from numpy import random
import numpy

NUMBER_OF_PROCESSORS = 2

NUMBER_OF_RUNS = 5000

VARIABLES_TO_TRACK = [
    "%_happy",
    "%_happy_workers",
    "%_happy_shirkers",
    "mean-perf"
]
SNAPSHOT_TIME = [ 25, 50,
                 75
                 ]
TOT_STEPS = 100

PRE_SETUP_COMMANDS = [
      'set decision_rule "performance window"',
      'set density 50'
]

POST_SETUP_COMMANDS = [
    # "setup-patches",
    # "allocate"
]
SPINUP_GO_CALLS = 0

CSV_RESULT_NAME = 'personalities.csv'
CSV_PARAM_NAME = 'params_' + CSV_RESULT_NAME;

PATH_TO_NLOGO = 'modified.nlogo'

PROBLEM_DEFINITION = {
    'num_vars': 4,
    'names': ['random-seed',
              '%_workers',
              '%_shirkers',
              'window'
              ],
    'bounds': [[1, 100000],
               [2, 48],
               [2, 48],
               [2,10]
               ],
    'round': [
        False,
        True,
        True,
        True
    ]
}


##create link and start the model
def initializer(modelfile):
    '''initialize a subprocess

    Parameters
    ----------
    modelfile : str

    '''

    # we need to set the instantiated netlogo
    # link as a global so run_simulation can
    # use it
    global netlogo

    netlogo = pyNetLogo.NetLogoLink(gui=False,
                                    #netlogo_home="/home/carrknight/Downloads/netlogo-5.3.1-64",
                                    netlogo_home="/opt/netlogo",
                                    #netlogo_version="5"
                                    netlogo_version="6.1"
                                    )
    netlogo.load_model(modelfile)


def get_trend(data):
    x = numpy.arange(0, len(data), dtype=numpy.float)
    y = numpy.array(data, dtype=numpy.float)
    z = numpy.polyfit(x, y, 1)
    return (z[0])


#### single simulation
def run_simulation(experiment):
    '''run a netlogo model

    Parameters
    ----------
    experiments : dict

    '''
    for command in PRE_SETUP_COMMANDS:
        netlogo.command(command)

    print("starting")
    # Set the input parameters
    for key, value in experiment.items():
        if key == 'random-seed':
            # The NetLogo random seed requires a different syntax
            netlogo.command('random-seed {}'.format(value))
        else:
            # Otherwise, assume the input parameters are global variables
            netlogo.command('set {0} {1}'.format(key, value))

    netlogo.command('setup')
    for command in POST_SETUP_COMMANDS:
        netlogo.command(command)

    print("setup done")

    ### if you need to spin up the model before collecting data, do it now
    for i in range(SPINUP_GO_CALLS):
        netlogo.command("go")

    # Run for 100 ticks and return the number of sheep and
    # wolf agents at each time step
    counts = netlogo.repeat_report(VARIABLES_TO_TRACK, TOT_STEPS)

    means = counts.apply(lambda x: x.values.mean())
    means.rename(index=lambda x: "mean_" + x,
                 inplace=True)

    maxs = counts.apply(lambda x: x.values.max())
    maxs.rename(lambda x: "max_" + x,
                inplace=True)

    mins = counts.apply(lambda x: x.values.min())
    mins.rename(lambda x: "min_" + x,
                inplace=True)

    lasts = counts.apply(lambda x: x.values[len(x.values) - 1])
    lasts.rename(lambda x: "last_" + x,
                 inplace=True)

    sds = counts.apply(lambda x: numpy.std(x.values))
    sds.rename(lambda x: "sd_" + x,
               inplace=True)

    trends = counts.apply(lambda x: get_trend(x.values))
    trends.rename(lambda x: "trend_" + x,
                  inplace=True)
    results = pd.concat([means, mins, lasts, sds, trends, maxs])

    #### do snapshots!
    for snapshot in SNAPSHOT_TIME:
        current_snapshot = counts.apply(lambda x: x.values[snapshot])
        current_snapshot.rename(lambda x: "snap_" + str(snapshot) + "_" + x,
                                inplace=True)
        results = pd.concat([results, current_snapshot])

    print("simulation done!")
    return results


if __name__ == '__main__':
    modelfile = os.path.abspath(PATH_TO_NLOGO)

    problem = PROBLEM_DEFINITION

    # we want completely random values or we are going to get smart enough
    # classifiers that figure out where the parameters are concentrated!
    param_values = {}
    for name, bound, rounded in zip(problem['names'], problem['bounds'], problem['round']):
        param_values[name] = random.uniform(bound[0], bound[1], NUMBER_OF_RUNS)
        if rounded:
            param_values[name] = numpy.round(param_values[name])

    experiments = pd.DataFrame(param_values)

    with Pool(NUMBER_OF_PROCESSORS, initializer=initializer, initargs=(modelfile,)) as executor:
        results = []
        for entry in executor.map(run_simulation, experiments.to_dict('records')):
            results.append(entry)

        results = pd.DataFrame(results)
        print(results)
        experiments.to_csv(CSV_PARAM_NAME, index=False)
        results.to_csv(CSV_RESULT_NAME, index=False)
