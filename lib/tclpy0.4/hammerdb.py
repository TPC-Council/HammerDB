import tclpy
import builtins as __builtin__

def eval_hammerdb_command(command_name,*args):
    to_hdb = command_name
    for arg in args:
            if type(arg) != str:
                to_hdb = ' '.join((to_hdb, str(arg)))
            else:
                to_hdb = ' '.join((to_hdb, arg))

    output = tclpy.eval(to_hdb)
    tclpy.eval('flush stdout')
    if runscript_printline == 0:
        __builtin__.print('\r')
    if output:
        return output

def runscript(output):
    global runscript_printline
    runscript_printline = output

def tclversion():
    a = tclpy.eval('list [info patchlevel]')
    __builtin__.print('Python interface to Tcl version ' + a)

def buildschema(*args):
    jobid = eval_hammerdb_command('buildschema',*args)
    if jobid:
        return jobid

def checkschema(*args):
    eval_hammerdb_command('checkschema',*args)

def deleteschema(*args):
    eval_hammerdb_command('deleteschema',*args)

def clearscript(*args):
    eval_hammerdb_command('clearscript',*args)

def savescript(*args):
    eval_hammerdb_command('savescript',*args)

def customscript(*args):
    eval_hammerdb_command('customscript',*args)

def custommonitor(*args):
    eval_hammerdb_command('custommonitor',*args)

def datagenrun(*args):
    eval_hammerdb_command('datagenrun',*args)

def dbset(*args):
    eval_hammerdb_command('dbset',*args)

def dgset(*args):
    eval_hammerdb_command('dgset',*args)

def diset(*args):
    eval_hammerdb_command('diset',*args)

def giset(*args):
    eval_hammerdb_command('giset',*args)

def distributescript(*args):
    eval_hammerdb_command('distributescript',*args)

def jobs(*args):
    retval = eval_hammerdb_command('jobs',*args)
    if retval:
        return retval

def job(*args):
    retval = eval_hammerdb_command('job',*args)
    if retval:
        return retval

def librarycheck(*args):
    eval_hammerdb_command('librarycheck',*args)

def loadscript(*args):
    eval_hammerdb_command('loadscript',*args)

def print(*args, **kwargs):
    command_list = ['db', 'bm', 'dict', 'generic', 'script', 'vuconf', 'vucreated', 'vustatus', 'datagen', 'tcconf']
    flag = 0
    for j in command_list:
            if args[0]==j:
                flag=1
                break
    if flag==1:
        eval_hammerdb_command('print',*args)
    else:
        return __builtin__.print(*args, **kwargs)

def quit(*args):
    eval_hammerdb_command('quit',*args)

def runtimer(*args):
    eval_hammerdb_command('runtimer',*args)

def metset(*args):
    eval_hammerdb_command('metset',*args)

def metstart(*args):
    eval_hammerdb_command('metstart',*args)

def metstatus(*args):
    eval_hammerdb_command('metstatus',*args)

def metstop(*args):
    eval_hammerdb_command('metstop',*args)

def steprun(*args):
    eval_hammerdb_command('steprun',*args)

def switchmode(*args):
    eval_hammerdb_command('switchmode',*args)

def tcset(*args):
    eval_hammerdb_command('tcset',*args)

def tcstart(*args):
    eval_hammerdb_command('tcstart',*args)

def tcstatus(*args):
    eval_hammerdb_command('tcstatus',*args)

def tcstop(*args):
    eval_hammerdb_command('tcstop',*args)

def vucomplete(*args):
    eval_hammerdb_command('vucomplete',*args)

def vucreate(*args):
    eval_hammerdb_command('vucreate',*args)

def vudestroy(*args):
    eval_hammerdb_command('vudestroy',*args)

def vurun(*args):
    jobid = eval_hammerdb_command('vurun',*args)
    if jobid:
        return jobid

def vuset(*args):
    eval_hammerdb_command('vuset',*args)

def vustatus(*args):
    eval_hammerdb_command('vustatus',*args)

def wsport(*args):
    eval_hammerdb_command('wsport',*args)

def wsstart(*args):
    eval_hammerdb_command('wsstart',*args)

def wsstop(*args):
    eval_hammerdb_command('wsstop',*args)

def wsstatus(*args):
    eval_hammerdb_command('wsstatus',*args)

def waittocomplete(*args):
    eval_hammerdb_command('waittocomplete',*args)

def dvset(*args):
    eval_hammerdb_command('dvset',*args)

def source(filename):
    runscript(1)
    from pathlib import Path

    path = Path(filename)

    if path.is_file():
        exec(open(filename).read())
    else:
        print(f'The file {filename} does not exist')

    runscript(0)

def help(*args):
     eval_hammerdb_command('help',*args)
