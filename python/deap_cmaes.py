import threading
import random
import time
import math
import csv
import json
import sys
import logging
import os
import datetime

import numpy

from deap import base
from deap import creator
from deap import tools
from deap import algorithms
from deap import cma

import eqpy, ga_utils

# list of ga_utils parameter objects        
def printf(val):
    print(val)
    sys.stdout.flush()

# Not used
def obj_func(x):
    return 0

# {"batch_size":512,"epochs":51,"activation":"softsign",
#"dense":"2000 1000 1000 500 100 50","optimizer":"adagrad","drop":0.1378,
#"learning_rate":0.0301,"conv":"25 25 25 25 25 1"}
def create_list_of_json_strings(list_of_lists, super_delim=";"):
    # create string of ; separated jsonified maps
    res = []
    for l in list_of_lists:
        jmap = {}
        for i,p in enumerate(ea_parameters):
            jmap[p.name] = l[i]

        jstring = json.dumps(jmap)
        res.append(jstring)

    return (super_delim.join(res))

def queue_map(obj_func, pops):
    # Note that the obj_func is not used
    # sending data that looks like:
    # [[a,b,c,d],[e,f,g,h],...]
    if not pops:
        return []

    eqpy.OUT_put(create_list_of_json_strings(pops))
    result = eqpy.IN_get()
    split_result = result.split(';')
    # TODO determine if max'ing or min'ing and use -9999999 or 99999999
    return [(float(x),) if not math.isnan(float(x)) else (float(99999999),) for x in split_result]

def timestamp(scores):
    return str(time.time())

def eaGenerateUpdate(toolbox, ngen, halloffame=None, stats=None,
                     verbose=__debug__):
    logbook = tools.Logbook()
    logbook.header = ['gen', 'nevals'] + (stats.fields if stats else [])
    for gen in range(ngen):
        population = toolbox.generate()
        fitnesses = toolbox.map(toolbox.evaluate, population)
        print(fitnesses[0])
        printf("fitnesses {}".format(fitnesses))
        printf("population {}".format(population))
        for i in range(len(population)):
            for ind, fit in zip([population[i]], [np.array([fitnesses[i][0]])]):
                ind.fitness.values = fit
        if halloffame is not None:
            halloffame.update(population)
        toolbox.update(population)
        record = stats.compile(population) if stats is not None else {}
        logbook.record(gen=gen, nevals=len(population), **record)
        if verbose:
            print(logbook.stream)
    return population, logbook

def check_bounds(ea_parameters):
    def decorator(func):
        def wrapper(*args, **kargs):
            offspring = func(*args, **kargs)
            for child in offspring:
                for i in range(len(child)):
                    ub = ea_parameters[i].upper
                    lb = ea_parameters[i].lower
                    if child[i] > ub:
                        child[i] = ub
                    elif child[i] < lb:
                        child[i] = lb
            return offspring
        return wrapper
    return decorator

def run():
    """
    :param num_iterations: number of generations
    :param seed: random seed
    :param ga parameters file name: ga parameters file name (e.g., "ga_params.json")
    :param num_population population of ga algorithm
    """
    eqpy.OUT_put("Params")
    parameters = eqpy.IN_get()
    # parse params
    printf("Parameters: {}".format(parameters))
    (num_iterations, num_population, sigma, seed, ea_parameters_file) = eval('{}'.format(parameters))

    numpy.random.seed(seed)
    random.seed(seed)

    global ea_parameters
    ea_parameters = ga_utils.create_parameters(ea_parameters_file)
    N = len(ea_parameters)
    centroids = numpy.zeros(N)
    Cov = numpy.identity(N)
    for i,p in enumerate(ea_parameters):
        centroids[i] = (p.upper + p.lower) / 2
        Cov[i,i] = ( (p.upper - p.lower) / 4 )**2
    
    strategy = cma.Strategy(centroid=centroids, sigma=sigma, lambda_=num_population, cmatrix=Cov)

    creator.create("FitnessMin", base.Fitness, weights=(-1.0,))
    creator.create("Individual", list, fitness=creator.FitnessMin)

    toolbox = base.Toolbox()
    toolbox.register("generate", strategy.generate, creator.Individual)
    toolbox.register("update", strategy.update)
    toolbox.register("evaluate", obj_func)
    toolbox.register("map", queue_map)
    toolbox.decorate("generate", check_bounds(ea_parameters))

    hof = tools.HallOfFame(1)

    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("avg", numpy.mean)
    stats.register("std", numpy.std)
    stats.register("min", numpy.min)
    stats.register("max", numpy.max)
    stats.register("ts", timestamp)
   
    pop, log = algorithms.eaGenerateUpdate(toolbox, ngen=num_iterations, stats=stats, halloffame=hof)
    
    eqpy.OUT_put("DONE")
    # return the final population
    eqpy.OUT_put(create_list_of_json_strings([hof[0]]))

