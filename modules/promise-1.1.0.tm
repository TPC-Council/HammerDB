# Copyright (c) 2015, Ashok P. Nadkarni
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package require Tcl 8.6

namespace eval promise {
    proc version {} { return 1.1.0 }
}

proc promise::lambda {params body args} {
    # Creates an anonymous procedure and returns a command prefix for it.
    #   params - parameter definitions for the procedure
    #   body - body of the procedures
    #   args - additional arguments to be passed to the procedure when it
    #     is invoked
    #
    # This is just a convenience command since anonymous procedures are
    # commonly useful with promises. The lambda package from tcllib
    # is identical in function.

    return [list ::apply [list $params $body] {*}$args]
}

catch {promise::Promise destroy}
oo::class create promise::Promise {

    # The promise state can be one of
    #  PENDING - Initial state where it has not yet been assigned a
    #            value or error
    #  FULFILLED - The promise has been assigned a value
    #  REJECTED  - The promise has been assigned an error
    #  CHAINED  - The promise is attached to another promise
    variable _state

    # Stores data that is accessed through the setdata/getdata methods.
    # The Promise class itself does not use this.
    variable _clientdata

    # The promise value once it is fulfilled or rejected. In the latter
    # case, it should be an the error message
    variable _value

    # The error dictionary in case promise is rejected
    variable _edict
    
    # Reactions to be notified when the promise is rejected. Each element
    # in this list is a pair consisting of the fulfilment reaction
    # and the rejection reaction. Either element of the pair could be
    # empty signifying no reaction for that case. The list is populated
    # via the then method.
    variable _reactions

    # Reference counting to free up promises since Tcl does not have
    # garbage collection for objects. Garbage collection via reference
    # counting only takes place after at least one done/then reaction
    # is placed on the event queue, not before. Else promises that
    # are immediately resolved on construction would be freed right
    # away before the application even gets a chance to call done/then.
    variable _do_gc
    variable _nrefs

    # If no reject reactions are registered, then the Tcl bgerror
    # handler is invoked. But don't want to do this more than once
    # so track it
    variable _bgerror_done
    
    constructor {cmd} {
        # Create a promise for the asynchronous operation to be initiated
        # by $cmd.
        # cmd - a command prefix that should initiate an asynchronous
        #  operation.
        # The command prefix $cmd is passed an additional argument - the
        # name of this Promise object. It should arrange for one of the
        # object's settle methods [fulfill], [chain] or
        # [reject] to be called when the operation completes.
        
        set _state PENDING
        set _reactions [list ]
        set _do_gc 0
        set _bgerror_done 0
        set _nrefs 0
        array set _clientdata {}
        
        # Errors in the construction command are returned via
        # the standard mechanism of reject.
        #
        if {[catch {
            # For some special cases, $cmd may be "" if the async operation
            # is initiated outside the constructor. This is not a good
            # thing because the error in the initiator will not be
            # trapped via the standard promise error catching mechanism
            # but that's the application's problem (actually pgeturl also
            # uses this).
            if {[llength $cmd]} {
                uplevel #0 [linsert $cmd end [self]]
            }
        } msg edict]} {
            my reject $msg $edict
        }
    }

    destructor {
        # Destroys the object.
        #
        # This method should not be generally called directly as [Promise]
        # objects are garbage collected either automatically or via the [ref]
        # and [unref] methods.
    }
    
    method state {} {
        # Returns the current state of the promise.
        #
        # The promise state may be one of the values 'PENDING',
        # 'FULFILLED', 'REJECTED' or 'CHAINED'
        return $_state
    }

    method getdata {key} {
        # Returns data previously stored through the setdata method.
        #  key - key whose associated values is to be returned.
        # An error will be raised if no value is associated with the key.
        return $_clientdata($key)
    }

    method setdata {key value} {
        # Sets a value to be associated with a key.
        #  key - the lookup key
        #  value - the value to be associated with the key
        # A promise internally maintains a dictionary whose values can
        # be accessed with the [getdata] and [setdata] methods. This
        # dictionary is not used by the Promise class itself but is meant
        # to be used by promise library specializations or applications.
        # Callers need to take care that keys used for a particular
        # promise are sufficiently distinguishable so as to not clash.
        #
        # Returns the value stored with the key.
        set _clientdata($key) $value
    }
    
    method value {} {
        # Returns the settled value for the promise.
        #
        # The returned value may be the fulfilled value or the rejected
        # value depending on whether the associated operation was successfully
        # completed or failed.
        #
        # An error is raised if the promise is not settled yet.
        if {$_state ni {FULFILLED REJECTED}} {
            error "Value is not set."
        }
        return $_value
    }

    method ref {} {
        # Increments the reference count for the object.
        incr _nrefs
    }

    method unref {} {
        # Decrements the reference count for the object.
        #
        # The object may have been destroyed when the call returns.
        incr _nrefs -1
        my GC
    }

    method nrefs {} {
        # Returns the current reference count.
        #
        # Use for debugging only! Note, internal references are not included.
        return $_nrefs
    }
    
    method GC {} {
        if {$_nrefs <= 0 && $_do_gc && [llength $_reactions] == 0} {
            my destroy
        }
    }
    
    method FulfillAttached {value} {
        if {$_state ne "CHAINED"} {
            return
        }
        set _value $value
        set _state FULFILLED
        my ScheduleReactions
        return
    }
    
    method RejectAttached {reason edict} {
        if {$_state ne "CHAINED"} {
            return
        }
        set _value $reason
        set _edict $edict
        set _state REJECTED
        my ScheduleReactions
        return
    }
    
    # Method to invoke to fulfil a promise with a value or another promise.
    method fulfill {value} {
        # Fulfills the promise.
        #   value - the value with which the promise is fulfilled
        #
        # Returns '0' if promise had already been settled and '1' if
        # it was fulfilled by the current call.

        #ruff
        # If the promise has already been settled, the method has no effect.
        if {$_state ne "PENDING"} {
            return 0;             # Already settled
        }
        
        #ruff
        # Otherwise, it is transitioned to the 'FULFILLED' state with
        # the value specified by $value. If there are any fulfillment
        # reactions registered by the [done] or [then] methods, they
        # are scheduled to be run.
        set _value $value
        set _state FULFILLED
        my ScheduleReactions
        return 1
    }

    # Method to invoke to fulfil a promise with a value or another promise.
    method chain {promise} {
        # Chains the promise to another promise.
        #   promise - the [Promise] object to which this promise is to
        #     be chained
        #
        # Returns '0' if promise had already been settled and '1' otherwise.

        #ruff
        # If the promise on which this method is called
        # has already been settled, the method has no effect.
        if {$_state ne "PENDING"} {
            return 0;
        }

        #ruff
        # Otherwise, it is chained to $promise so that it reflects that
        # other promise's state.
        if {[catch {
            $promise done [namespace code {my FulfillAttached}] [namespace code {my RejectAttached}]
        } msg edict]} {
            my reject $msg $edict
        } else {
            set _state CHAINED
        }
        
        return 1
    }

    method reject {reason {edict {}}} {
        # Rejects the promise.
        #   reason - a message string describing the reason for the rejection.
        #   edict - a Tcl error dictionary
        #
        # The $reason and $edict values are passed on to the rejection
        # reactions. By convention, these should be of the form returned
        # by the `catch` or `try` commands in case of errors.
        #
        # Returns '0' if promise had already been settled and '1' if
        # it was rejected by the current call.

        #ruff
        # If the promise has already been settled, the method has no effect.
        if {$_state ne "PENDING"} {
            return 0;             # Already settled
        }

        #ruff
        # Otherwise, it is transitioned to the 'REJECTED' state.  If
        # there are any reject reactions registered by the [done] or
        # [then] methods, they are scheduled to be run.
        
        set _value $reason
        #ruff
        # If $edict is not specified, or specified as an empty string,
        # a suitable error dictionary is constructed in its place
        # to be passed to the reaction.
        if {$edict eq ""} {
            catch {throw {PROMISE REJECTED} $reason} - edict
        }
        set _edict $edict
        set _state REJECTED
        my ScheduleReactions
        return 1
    }

    # Internal method to queue all registered reactions based on
    # whether the promise is succesfully fulfilled or not
    method ScheduleReactions {} {
        if {$_state ni {FULFILLED REJECTED} || [llength $_reactions] == 0 } {
            # Promise is not settled or no reactions registered
            return
        }

        # Note on garbage collection: garbage collection is to be enabled if
        # at least one FULFILLED or REJECTED reaction is registered.
        # Also if the promise is REJECTED but no rejection handlers are run
        # we also schedule a background error.
        # In all cases, CLEANUP reactions do not count.
        foreach reaction $_reactions {
            foreach type {FULFILLED REJECTED} {
                if {[dict exists $reaction $type]} {
                    set _do_gc 1
                    if {$type eq $_state} {
                        set cmd [dict get $reaction $type]
                        if {[llength $cmd]} {
                            if {$type eq "FULFILLED"} {
                                lappend cmd $_value
                            } else {
                                lappend cmd $_value $_edict
                            }
                            set ran_reaction($type) 1
                            # Enqueue the reaction via the event loop
                            after 0 [list after idle $cmd]
                        }
                    }
                }
            }
            if {[dict exists $reaction CLEANUP]} {
                set cmd [dict get $reaction CLEANUP]
                if {[llength $cmd]} {
                    # Enqueue the cleaner via the event loop passing the
                    # *state* as well as the value
                    if {$_state eq "REJECTED"} {
                        lappend cmd $_state $_value $_edict
                    } else {
                        lappend cmd $_state $_value
                    }
                    after 0 [list after idle $cmd]
                    # Note we do not set _do_gc if we only run cleaners
                }
            }
        }
        set _reactions [list ]

        # Check for need to background error (see comments above)
        if {$_state eq "REJECTED" && $_do_gc && ! [info exists ran_reaction(REJECTED)] && ! $_bgerror_done} {
            # TBD - should we also check _nrefs before backgrounding error?

            # Wrap in catch in case $_edict does not follow error conventions
            # or is not even a dictionary
            if {[catch {
                dict get $_edict -level
                dict get $_edict -code
            }]} {
                catch {throw {PROMISE REJECT} $_value} - edict
            } else {
                set edict $_edict
            }
            # TBD - how exactly is level to be handled?
            # If -level is not 0, bgerror barfs because it treates
            # it as TCL_RETURN no matter was -code is
            dict set edict -level 0
            after idle [interp bgerror {}] [list $_value $edict]
            set _bgerror_done 1
        }
        
        my GC
        return 
    } 

    method RegisterReactions {args} {
        # Registers the specified reactions.
        #  args - dictionary keyed by 'CLEANUP', 'FULFILLED', 'REJECTED'
        #     with values being the corresponding reaction callback

        lappend _reactions $args
        my ScheduleReactions
        return
    }
        
    method done {{on_fulfill {}} {on_reject {}}} {
        # Registers reactions to be run when the promise is settled.
        #  on_fulfill - command prefix for the reaction to run
        #    if the promise is fulfilled.
        #    reaction is registered.
        #  on_reject - command prefix for the reaction to run
        #    if the promise is rejected.
        # Reactions are called with an additional argument which is
        # the value with which the promise was settled.
        # 
        # The command may be called multiple times to register multiple
        # reactions to be run at promise settlement. If the promise was
        # already settled at the time the call was made, the reactions
        # are invoked immediately. In all cases, reactions are not called
        # directly, but are invoked by scheduling through the event loop.
        #
        # The method triggers garbage collection of the object if the
        # promise has been settled and any registered reactions have been
        # scheduled. Applications can hold on to the object through
        # appropriate use of the [ref] and [unref] methods.
        #
        # Note that both $on_fulfill and $on_reject may be specified
        # as empty strings if no further action needs to be taken on
        # settlement of the promise. If the promise is rejected, and
        # no rejection reactions are registered, the error is reported
        # via the Tcl 'interp bgerror' facility.

        # TBD - as per the Promise/A+ spec, errors in done should generate
        # a background error (unlike then).

        my RegisterReactions FULFILLED $on_fulfill REJECTED $on_reject

        #ruff
        # The method does not return a value.
        return
    }
    
    method then {on_fulfill {on_reject {}}} {
        # Registers reactions to be run when the promise is settled
        # and returns a new [Promise] object that will be settled by the
        # reactions.
        #  on_fulfill - command prefix for the reaction to run
        #    if the promise is fulfilled. If an empty string, no fulfill
        #    reaction is registered.
        #  on_reject - command prefix for the reaction to run
        #    if the promise is rejected. If unspecified or an empty string,
        #    no reject reaction is registered.
        # Both reactions are called with an additional argument which is
        # the value with which the promise was settled.
        # 
        # The command may be called multiple times to register multiple
        # reactions to be run at promise settlement. If the promise was
        # already settled at the time the call was made, the reactions
        # are invoked immediately. In all cases, reactions are not called
        # directly, but are invoked by scheduling through the event loop.
        #
        # If the reaction that is invoked runs without error, its return
        # value fulfills the new promise returned by the 'then' method.
        # If it raises an exception, the new promise will be rejected
        # with the error message and dictionary from the exception.
        #
        # Alternatively, the reactions can explicitly invoke commands
        # [then_fulfill], [then_reject] or [then_chain] to
        # resolve the returned promise. In this case, the return value
        # (including exceptions) from the reactions are ignored.
        #
        # If 'on_fulfill' (or 'on_reject') is an empty string (or unspecified),
        # the new promise is created and fulfilled (or rejected) with
        # the same value that would have been passed in to the reactions.
        #
        # The method triggers garbage collection of the object if the
        # promise has been settled and registered reactions have been
        # scheduled. Applications can hold on to the object through
        # appropriate use of the [ref] and [unref] methods.
        #
        # Returns a new promise that is settled by the registered reactions.
        
        set then_promise [[self class] new ""]
        my RegisterReactions \
            FULFILLED [list ::promise::_then_reaction $then_promise FULFILLED $on_fulfill] \
            REJECTED [list ::promise::_then_reaction $then_promise REJECTED $on_reject]
        return $then_promise
    }

    # This could be a forward, but then we cannot document it via ruff!
    method catch {on_reject} {
        # Registers reactions to be run when the promise is rejected.
        #   on_reject - command prefix for the reaction
        #     reaction to run if the promise is rejected. If unspecified
        #     or an empty string, no reject reaction is registered. The
        #     reaction is called with an additional argument which is the
        #     value with which the promise was settled.
        # This method is just a wrapper around [then] with the
        # 'on_fulfill' parameter defaulting to an empty string. See
        # the description of that method for details.
        return [my then "" $on_reject]
    }
    
    method cleanup {cleaner} {
        # Registers a reaction to be executed for running cleanup
        # code when the promise is settled.
        #   cleaner - command prefix to run on settlement
        # This method is intended to run a clean up script 
        # when a promise is settled. Its primary use is to avoid duplication
        # of code in the `then` and `catch` handlers for a promise.
        # It may also be called multiple times
        # to clean up intermediate steps when promises are chained.
        # 
        # The method returns a new promise that will be settled
        # as per the following rules.
        # - if the cleaner runs without errors, the returned promise
        #   will reflect the settlement of the promise on which this
        #   method is called.
        # - if the cleaner raises an exception, the returned promise
        #   is rejected with a value consisting of the error message
        #   and dictionary pair.
        #
        # Returns a new promise that is settled based on the cleaner
        set cleaner_promise [[self class] new ""]
        my RegisterReactions CLEANUP [list ::promise::_cleanup_reaction $cleaner_promise $cleaner]
        return $cleaner_promise
    }
}

proc promise::_then_reaction {target_promise status cmd value {edict {}}} {
    # Run the specified command and fulfill/reject the target promise
    # accordingly. If the command is empty, the passed-in value is passed
    # on to the target promise.

    # IMPORTANT!!!!
    # MUST BE CALLED FROM EVENT LOOP AT so info level must be 1. Else
    # promise::then_fulfill/then_reject/then_chain will not work
    # Also, Do NOT change the param name target_promise without changing
    # those procs.
    # Oh what a hack to get around lack of closures. Alternative would have
    # been to pass an additional parameter (target_promise)
    # to the application code but then that script would have had to
    # carry that around.

    if {[info level] != 1} {
        error "Internal error: _then_reaction not at level 1"
    }
    
    if {[llength $cmd] == 0} {
        switch -exact -- $status {
            FULFILLED { $target_promise fulfill $value }
            REJECTED  { $target_promise reject $value $edict}
            CHAINED -
            PENDING  -
            default {
                $target_promise reject "Internal error: invalid status $state"
            }
        }
    } else {
        # Invoke the real reaction code and fulfill/reject the target promise.
        # Note the reaction code may have called one of the promise::then_*
        # commands itself and reactions run resulting in the object being
        # freed. Hence resolve using the safe* variants
        # TBD - ideally we would like to execute at global level. However
        # the then_* commands retrieve target_promise from level 1 (here)
        # which they cannot if uplevel #0 is done. So directly invoke.
        if {$status eq "REJECTED"} {
            lappend cmd $value $edict
        } else {
            lappend cmd $value
        }
        if {[catch $cmd reaction_value reaction_edict]} {
            safe_reject $target_promise $reaction_value $reaction_edict
        } else {
            safe_fulfill $target_promise $reaction_value
        }
    }
    return
}

proc promise::_cleanup_reaction {target_promise cleaner state value {edict {}}} {
    # Run the specified cleaner and fulfill/reject the target promise
    # accordingly. If the cleaner executes without error, the original
    # value and state is passed on. If the cleaner executes with error
    # the promise is rejected.

    if {[llength $cleaner] == 0} {
        switch -exact -- $state {
            FULFILLED { $target_promise fulfill $value }
            REJECTED  { $target_promise reject $value $edict }
            CHAINED -
            PENDING  -
            default {
                $target_promise reject "Internal error: invalid state $state"
            }
        }
    } else {
        if {[catch {uplevel #0 $cleaner} err edict]} {
            # Cleaner failed. Reject the target promise
            $target_promise reject $err $edict
        } else {
            # Cleaner completed without errors, pass on the original value
            if {$state eq "FULFILLED"} {
                $target_promise fulfill $value
            } else {
                $target_promise reject $value $edict
            }
        }
    }
    return
}

proc promise::then_fulfill {value} {
    # Fulfills the promise returned by a [then] method call from
    # within its reaction.
    #  value - the value with which to fulfill the promise
    #
    # The [Promise.then] method is a mechanism to chain asynchronous
    # reactions by registering them on a promise. It returns a new
    # promise which is settled by the return value from the reaction,
    # or by the reaction calling one of three commands - 'then_fulfill',
    # [then_reject] or [then_chain]. Calling 'then_fulfill' fulfills
    # the promise returned by the 'then' method that queued the currently
    # running reaction.
    #
    # It is an error to call this command from outside a reaction
    # that was queued via the [then] method on a promise.
    
    # TBD - what if someone calls this from within a uplevel #0 ? The
    # upvar will be all wrong
    upvar #1 target_promise target_promise
    if {![info exists target_promise]} {
        set msg "promise::then_fulfill called in invalid context."
        throw [list PROMISE THEN FULFILL NOTARGET $msg] $msg
    }
    $target_promise fulfill $value
}

proc promise::then_chain {promise} {
    # Chains the promise returned by a [then] method call to
    # another promise.
    #  promise - the promise to which the promise returned by [then] is
    #     to be chained
    #
    # The [Promise.then] method is a mechanism to chain asynchronous
    # reactions by registering them on a promise. It returns a new
    # promise which is settled by the return value from the reaction,
    # or by the reaction calling one of three commands - [then_fulfill],
    # 'then_reject' or [then_chain]. Calling 'then_chain' chains
    # the promise returned by the 'then' method that queued the currently
    # running reaction to $promise so that the former will be settled
    # based on the latter.
    #
    # It is an error to call this command from outside a reaction
    # that was queued via the [then] method on a promise.
    upvar #1 target_promise target_promise
    if {![info exists target_promise]} {
        set msg "promise::then_chain called in invalid context."
        throw [list PROMISE THEN FULFILL NOTARGET $msg] $msg
    }
    $target_promise chain $promise
}

proc promise::then_reject {reason edict} {
    # Rejects the promise returned by a [then] method call from
    # within its reaction.
    #   reason - a message string describing the reason for the rejection.
    #   edict - a Tcl error dictionary
    # The [Promise.then] method is a mechanism to chain asynchronous
    # reactions by registering them on a promise. It returns a new
    # promise which is settled by the return value from the reaction,
    # or by the reaction calling one of three commands - [then_fulfill],
    # 'then_reject' or [then_chain]. Calling 'then_reject' rejects
    # the promise returned by the 'then' method that queued the currently
    # running reaction.
    #
    # It is an error to call this command from outside a reaction
    # that was queued via the [then] method on a promise.
    upvar #1 target_promise target_promise
    if {![info exists target_promise]} {
        set msg "promise::then_reject called in invalid context."
        throw [list PROMISE THEN FULFILL NOTARGET $msg] $msg
    }
    $target_promise reject $reason $edict
}

proc promise::all {promises} {
    # Returns a promise that fulfills or rejects when all promises
    # in the $promises argument have fulfilled or any one has rejected.
    #   promises - a list of Promise objects
    # If any of $promises rejects, then the promise returned by the
    # command will reject with the same value. Otherwise, the promise
    # will fulfill when all promises have fulfilled.
    # The resolved value will be a list of the resolved
    # values of the contained promises.
    
    set all_promise [Promise new [lambda {promises prom} {
        set npromises [llength $promises]
        if {$npromises == 0} {
            $prom fulfill {}
            return
        }

        # Ask each promise to update us when resolved.
        foreach promise $promises {
            $promise done \
                [list ::promise::_all_helper $prom $promise FULFILLED] \
                [list ::promise::_all_helper $prom $promise REJECTED]
        }

        # We keep track of state with a dictionary that will be
        # stored in $prom with the following keys:
        #  PROMISES - the list of promises in the order passed
        #  PENDING_COUNT - count of unresolved promises
        #  RESULTS - dictionary keyed by promise and containing resolved value
        set all_state [list PROMISES $promises PENDING_COUNT $npromises RESULTS {}]
        
        $prom setdata ALLPROMISES $all_state
    } $promises]]
                 
    return $all_promise
}

proc promise::all* args {
    # Returns a promise that fulfills or rejects when all promises
    # in the $args argument have fulfilled or any one has rejected.
    # args - list of Promise objects
    # This command is identical to the all command except that it takes
    # multiple arguments, each of which is a Promise object. See [all]
    # for a description.
    return [all $args]
}

# Callback for promise::all.
#  all_promise - the "master" promise returned by the all call.
#  done_promise - the promise whose callback is being serviced.
#  resolution - whether the current promise was resolved with "FULFILLED"
#   or "REJECTED"
#  value - the value of the currently fulfilled promise or error description
#   in case rejected
#  edict - error dictionary (if promise was rejected)
proc promise::_all_helper {all_promise done_promise resolution value {edict {}}} {
    if {![info object isa object $all_promise]} {
        # The object has been deleted. Naught to do
        return
    }
    if {[$all_promise state] ne "PENDING"} {
        # Already settled. This can happen when a tracked promise is
        # rejected and another tracked promise gets settled afterwards.
        return
    }
    if {$resolution eq "REJECTED"} {
        # This promise failed. Immediately reject the master promise
        # TBD - can we somehow indicate which promise failed ?
        $all_promise reject $value $edict
        return
    }

    # Update the state of the resolved tracked promise
    set all_state [$all_promise getdata ALLPROMISES]
    dict set all_state RESULTS $done_promise $value
    dict incr all_state PENDING_COUNT -1
    $all_promise setdata ALLPROMISES $all_state

    # If all promises resolved, resolve the all promise
    if {[dict get $all_state PENDING_COUNT] == 0} {
        set values {}
        foreach prom [dict get $all_state PROMISES] {
            lappend values [dict get $all_state RESULTS $prom]
        }
        $all_promise fulfill $values
    }
    return
}

proc promise::race {promises} {
    # Returns a promise that fulfills or rejects when any promise
    # in the $promises argument is fulfilled or rejected.
    #   promises - a list of Promise objects
    # The returned promise will fulfill and reject with the same value
    # as the first promise in $promises that fulfills or rejects.
    set race_promise [Promise new [lambda {promises prom} {
        if {[llength $promises] == 0} {
            catch {throw {PROMISE RACE EMPTYSET} "No promises specified."} reason edict
            $prom reject $reason $edict
            return
        }
        # Use safe_*, do not directly call methods since $prom may be
        # gc'ed once settled
        foreach promise $promises {
            $promise done [list ::promise::safe_fulfill $prom ] [list ::promise::safe_reject $prom]
        }
    } $promises]]

    return $race_promise
}

proc promise::race* {args} {
    # Returns a promise that fulfills or rejects when any promise
    # in the passed arguments is fulfilled or rejected.
    #   args - list of Promise objects
    # This command is identical to the 'race' command except that it takes
    # multiple arguments, each of which is a Promise object. See [race]
    # for a description.
    return [race $args]
}

proc promise::await {prom} {
    # Waits for a promise to be settled and returns its resolved value.
    #   prom - the promise that is to be waited on
    # This command may only be used from within a procedure constructed
    # with the [async] command or any code invoked from it.
    #
    # Returns the resolved value of $prom if it is fulfilled or raises an error
    # if it is rejected.
    set coro [info coroutine]
    if {$coro eq ""} {
        throw {PROMISE AWAIT NOTCORO} "await called from outside a coroutine"
    }
    $prom done [list $coro success] [list $coro fail]
    lassign [yieldto return -level 0] status val ropts
    if {$status eq "success"} {
        return $val
    } else {
        return -options $ropts $val
    }
}

proc promise::async {name paramdefs body} {
    # Defines an procedure that will run a script asynchronously as a coroutine.
    # name - name of the procedure
    # paramdefs - the parameter definitions to the procedure in the same
    #   form as passed to the standard 'proc' command
    # body - the script to be executed
    #
    # When the defined procedure $name is called, it runs the supplied $body 
    # within a new coroutine. The return value from the $name procedure call
    # will be a promise that will be fulfilled when the coroutine completes
    # normally or rejected if it completes with an error.
    #
    # Note that the passed $body argument is not the body of the
    # the procedure $name. Rather it is run as an anonymous procedure in 
    # the coroutine but in the same namespace context as $name. Thus the
    # caller or the $body script must not make any assumptions about
    # relative stack levels, use of 'uplevel' etc.
    #
    # The primary purpose of this command is to make it easy, in
    # conjunction with the [await] command, to wrap a sequence of asynchronous
    # operations as a single computational unit.
    #
    # Returns a promise that will be settled with the result of the script.
    if {![string equal -length 2 "$name" "::"]} {
        set ns [uplevel 1 namespace current]
        set name ${ns}::$name
    } else {
        set ns ::
    }
    set tmpl {
        proc %NAME% {%PARAMDEFS%} {
            set p [promise::Promise new [promise::lambda {real_args prom} {
                coroutine ::promise::async#[info cmdcount] {*}[promise::lambda {p args} {
                    upvar #1 _current_async_promise current_p
                    set current_p $p
                    set status [catch [list apply [list {%PARAMDEFS%} {%BODY%} %NS%] {*}$args] res ropts]
                    if {$status == 0} {
                        $p fulfill $res
                    } else {
                        $p reject $res $ropts
                    }
                } $prom {*}$real_args]
            } [lrange [info level 0] 1 end]]]
            return $p
        }
    }
    eval [string map [list %NAME% $name \
                          %PARAMDEFS% $paramdefs \
                          %BODY% $body \
                          %NS% $ns] $tmpl]
}

proc promise::async_fulfill {val} {
    # Fulfills a promise for an async procedure with the specified value.
    #  val - the value with which to fulfill the promise
    # This command must only be called with the context of an [async]
    # procedure.
    #
    # Returns an empty string.
    upvar #1 _current_async_promise current_p
    if {![info exists current_p]} {
        error "async_fulfill called from outside an async context."
    }
    $current_p fulfill $val
    return
}

proc promise::async_reject {val {edict {}}} {
    # Rejects a promise for an async procedure with the specified value.
    #  val - the value with which to reject the promise
    #  edict - error dictionary for rejection
    # This command must only be called with the context of an [async]
    # procedure.
    #
    # Returns an empty string.
    upvar #1 _current_async_promise current_p
    if {![info exists current_p]} {
        error "async_reject called from outside an async context."
    }
    $current_p reject $val $edict
    return
}

proc promise::async_chain {prom} {
    # Chains a promise for an async procedure to the specified promise.
    #  prom - the promise to which the async promise is to be linked.
    # This command must only be called with the context of an [async]
    # procedure.
    #
    # Returns an empty string.
    upvar #1 _current_async_promise current_p
    if {![info exists current_p]} {
        error "async_chain called from outside an async context."
    }
    $current_p chain $prom
    return
}

proc promise::pfulfilled {value} {
    # Returns a new promise that is already fulfilled with the specified value.
    #  value - the value with which to fulfill the created promise
    return [Promise new [lambda {value prom} {
        $prom fulfill $value
    } $value]]
}

proc promise::prejected {value {edict {}}} {
    # Returns a new promise that is already rejected.
    #  value - the value with which to reject the promise
    #  edict - error dictionary for rejection
    # By convention, $value should be of the format returned by
    # [rejection].
    return [Promise new [lambda {value edict prom} {
        $prom reject $value $edict
    } $value $edict]]
}

proc promise::eventloop {prom} {
    # Waits in the eventloop until the specified promise is settled.
    #  prom - the promise to be waited on
    # The command enters the event loop in similar fashion to the
    # Tcl [vwait] command except that instead of waiting on a variable
    # the command waits for the specified promise to be settled. As such
    # it has the same caveats as the vwait command in terms of care
    # being taken in nested calls etc.
    #
    # The primary use of the command is at the top level of a script
    # to wait for one or more promise based tasks to be completed. Again,
    # similar to the vwait forever idiom.
    # 
    #
    # Returns the resolved value of $prom if it is fulfilled or raises an error
    # if it is rejected.

    set varname [namespace current]::_pwait_[info cmdcount]
    $prom done \
        [lambda {varname result} {
            set $varname [list success $result]
        } $varname] \
        [lambda {varname error ropts} {
            set $varname [list fail $error $ropts]
        } $varname]
    vwait $varname
    lassign [set $varname] status result ropts
    if {$status eq "success"} {
        return $result
    } else {
        return -options $ropts $result
    }
}

proc promise::pgeturl {url args} {
    # Returns a promise that will be fulfilled when the a URL is fetched.
    #   url - the URL to fetch
    #   args - arguments to pass to the [http::geturl] command
    # This command invokes the asynchronous form of the [http::geturl] command
    # of the 'http' package. If the operation completes with a status of
    # 'ok', the returned promise is fulfilled with the contents of the
    # http state array (see the documentation of [http::geturl]). If the
    # the status is anything else, the promise is rejected with
    # the 'reason' parameter to the reaction containing the error message
    # and the 'edict' parameter containing the Tcl error dictionary
    # with an additional key 'http_state', containing the
    # contents of the http state array.
    
    uplevel #0 {package require http}
    proc pgeturl {url args} {
        set prom [Promise new [lambda {http_args prom} {
            http::geturl {*}$http_args -command [promise::lambda {prom tok} {
                upvar #0 $tok http_state
                if {$http_state(status) eq "ok"} {
                    $prom fulfill [array get http_state]
                } else {
                    if {[info exists http_state(error)]} {
                        set msg [lindex $http_state(error) 0]
                    }
                    if {![info exists msg] || $msg eq ""} {
                        set msg "Error retrieving URL."
                    }
                    catch {throw {PROMISE PGETURL} $msg} msg edict
                    dict set edict http_state [array get http_state]
                    $prom reject $msg $edict
                }
                http::cleanup $tok
            } $prom]
        } [linsert $args 0 $url]]]
        return $prom
    }
    tailcall pgeturl $url {*}$args
}

proc promise::ptimer {millisecs {value "Timer expired."}} {
    # Returns a promise that will be fulfilled when the specified time has
    # elapsed.
    #  millisecs - time interval in milliseconds
    #  value - the value with which the promise is to be fulfilled
    # In case of errors (e.g. if $milliseconds is not an integer), the
    # promise is rejected with the 'reason' parameter set to an error
    # message and the 'edict' parameter set to a Tcl error dictionary.
    #
    # Also see [ptimeout] which is similar but rejects the promise instead
    # of fulfilling it.
    
    return [Promise new [lambda {millisecs value prom} {
        if {![string is integer -strict $millisecs]} {
            # We don't allow "idle", "cancel" etc. as an argument to after
            throw {PROMISE TIMER INVALID} "Invalid timeout value \"$millisecs\"."
        }
        after $millisecs [list promise::safe_fulfill $prom $value]
    } $millisecs $value]]
}

proc promise::ptimeout {millisecs {value "Operation timed out."}} {
    # Returns a promise that will be rejected when the specified time has
    # elapsed.
    #  millisecs - time interval in milliseconds
    #  value - the value with which the promise is to be rejected
    # In case of errors (e.g. if $milliseconds is not an integer), the
    # promise is rejected with the 'reason' parameter set to $value
    # and the 'edict' parameter set to a Tcl error dictionary.
    #
    # Also see [ptimer] which is similar but fulfills the promise instead
    # of rejecting it.

    return [Promise new [lambda {millisecs value prom} {
        if {![string is integer -strict $millisecs]} {
            # We don't want to accept "idle", "cancel" etc. for after
            throw {PROMISE TIMER INVALID} "Invalid timeout value \"$millisecs\"."
        }
        after $millisecs [::promise::lambda {prom msg} {
            catch {throw {PROMISE TIMER EXPIRED} $msg} msg edict
            ::promise::safe_reject $prom $msg $edict
        } $prom $value]
    } $millisecs $value]]
}

proc promise::pconnect {args} {
    # Returns a promise that will be fulfilled when the a socket connection
    # is completed.
    #  args - arguments to be passed to the Tcl 'socket' command
    # This is a wrapper for the async version of the Tcl 'socket' command.
    # If the connection completes, the promise is fulfilled with the
    # socket handle.
    # In case of errors (e.g. if the address cannot be fulfilled), the
    # promise is rejected with the 'reason' parameter containing the
    # error message and the 'edict' parameter containing the Tcl error
    # dictionary.
    # 
    return [Promise new [lambda {so_args prom} {
        set so [socket -async {*}$so_args]
        fileevent $so writable [promise::lambda {prom so} {
            fileevent $so writable {}
            set err [chan configure $so -error]
            if {$err eq ""} {
                $prom fulfill $so
            } else {
                catch {throw {PROMISE PCONNECT FAIL} $err} err edict
                $prom reject $err $edict
            }
        } $prom $so]
    } $args]]
}

proc promise::_read_channel {prom chan data} {
    set newdata [read $chan]
    if {[string length $newdata] || ![eof $chan]} {
        append data $newdata
        fileevent $chan readable [list [namespace current]::_read_channel $prom $chan $data]
        return
    }

    # EOF
    set code [catch {
        # Need to make the channel blocking else no error is returned
        # on the close
        fileevent $chan readable {}
        fconfigure $chan -blocking 1
        close $chan
    } result edict]
    if {$code} {
        safe_reject $prom $result $edict
    } else {
        safe_fulfill $prom $data
    }
}

proc promise::pexec {args} {
    # Runs an external program and returns a promise for its output.
    #  args - program and its arguments as passed to the Tcl 'open' call
    #    for creating pipes
    # If the program runs without errors, the promise is fulfilled by its
    # standard output content. Otherwise
    # promise is rejected.
    #
    # Returns a promise that will be settled by the result of the program
    return [Promise new [lambda {open_args prom} {
        set chan [open |$open_args r]
        fconfigure $chan -blocking 0
        fileevent $chan readable [list promise::_read_channel $prom $chan ""]
    } $args]]
}        

proc promise::safe_fulfill {prom value} {
    # Fulfills the specified promise.
    #  prom - the [Promise] object to be fulfilled
    #  value - the fulfillment value
    # This is a convenience command that checks if $prom still exists
    # and if so fulfills it with $value.
    #
    # Returns 0 if the promise does not exist any more, else the return
    # value from its [fulfill] method.
    if {![info object isa object $prom]} {
        # The object has been deleted. Naught to do
        return 0
    }
    return [$prom fulfill $value]
}

proc promise::safe_reject {prom value {edict {}}} {
    # Rejects the specified promise.
    #  prom - the [Promise] object to be fulfilled
    #  value - see [Promise.reject]
    #  edict - see [Promise.reject]
    # This is a convenience command that checks if $prom still exists
    # and if so rejects it with the specified arguments.
    #
    # Returns 0 if the promise does not exist any more, else the return
    # value from its [reject] method.
    if {![info object isa object $prom]} {
        # The object has been deleted. Naught to do
        return
    }
    $prom reject $value $edict
}

proc promise::ptask {script} {
    # Creates a new Tcl thread to run the specified script and returns
    # a promise for the script results.
    #   script - script to run in the thread
    # Returns a promise that will be settled by the result of the script
    #
    # The `ptask` command runs the specified script in a new Tcl
    # thread. The promise returned from this command will be fulfilled
    # with the result of the script if it completes
    # successfully. Otherwise, the promise will be rejected with an
    # with the 'reason' parameter containing the error message
    # and the 'edict' parameter containing the Tcl error dictionary
    # from the script failure.
    #
    # Note that $script is a standalone script in that it is executed
    # in a new thread with a virgin Tcl interpreter. Any packages used
    # by $script have to be explicitly loaded, variables defined in the
    # the current interpreter will not be available in $script and so on.
    #
    # The command requires the Thread package to be loaded.

    uplevel #0 package require Thread
    proc [namespace current]::ptask script { 
        return [Promise new [lambda {script prom} {
            set thread_script [string map [list %PROM% $prom %TID% [thread::id] %SCRIPT% $script] {
                set retcode [catch {%SCRIPT%} result edict]
                if {$retcode == 0 || $retcode == 2} {
                    # ok or return
                    set response [list ::promise::safe_fulfill %PROM% $result]
                } else {
                    set response [list ::promise::safe_reject %PROM% $result $edict]
                }
                thread::send -async %TID% $response
            }]
            thread::create $thread_script
        } $script]]
    }
    tailcall [namespace current]::ptask $script
}

proc promise::pworker {tpool script} {
    # Runs a script in a worker thread from a thread pool and
    # returns a promise for the same.
    #   tpool - thread pool identifier
    #   script - script to run in the worker thread
    # Returns a promise that will be settled by the result of the script
    #
    # The Thread package allows creation of a thread pool with the
    # 'tpool create' command. The `pworker` command runs the specified
    # script in a worker thread from a thread pool. The promise
    # returned from this command will be fulfilled with the result of
    # the script if it completes successfully.
    # Otherwise, the promise will be rejected with an
    # with the 'reason' parameter containing the error message
    # and the 'edict' parameter containing the Tcl error dictionary
    # from the script failure.
    #
    # Note that $script is a standalone script in that it is executed
    # in a new thread with a virgin Tcl interpreter. Any packages used
    # by $script have to be explicitly loaded, variables defined in the
    # the current interpreter will not be available in $script and so on.

    # No need for package require Thread since if tpool is passed to
    # us, Thread must already be loaded
    return [Promise new [lambda {tpool script prom} {
        set thread_script [string map [list %PROM% $prom %TID% [thread::id] %SCRIPT% $script] {
            set retcode [catch {%SCRIPT%} result edict]
            if {$retcode == 0 || $retcode == 2} {
                set response [list ::promise::safe_fulfill %PROM% $result]
            } else {
                set response [list ::promise::safe_reject %PROM% $result $edict]
            }
            thread::send -async %TID% $response
        }]
        tpool::post -detached -nowait $tpool $thread_script
    } $tpool $script]]
}

if {0} {
    package require http
    proc checkurl {url} {
        set prom [promise::Promise new [promise::lambda {url prom} {
            http::geturl $url -method HEAD -command [promise::lambda {prom tok} {
                upvar #0 $tok http_state
                $prom fulfill [list $http_state(url) $http_state(status)]
                ::http::cleanup $tok
            } $prom]
        } $url]]
        return $prom
    }

    proc checkurls {urls} {
        return [promise::all [lmap url $urls {checkurl $url}]]
    }

    [promise::all [
                   list [
                         promise::ptask {expr 1+1}
                        ] [
                           promise::ptask {expr 2+2}
                          ]
                  ]] done [promise::lambda val {puts [tcl::mathop::* {*}$val]}] 
}

package provide promise [promise::version]

if {[info exists ::argv0] &&
    [file tail [info script]] eq [file tail $::argv0]} {
    set filename [file tail [info script]]
    if {[llength $::argv] == 0} {
        puts "Usage: [file tail [info nameofexecutable]] $::argv0 dist|install|tm|version"
        exit 1
    }
    switch -glob -- [lindex $::argv 0] {
        ver* { puts [promise::version] }
        tm -
        dist* {
            if {[file extension $filename] ne ".tm"} {
                set dir [file join [file dirname [info script]] .. build]
                file mkdir $dir
                file copy -force [info script] [file join $dir [file rootname $filename]-[promise::version].tm]
            } else {
                error "Cannot create distribution from a .tm file"
            }
        }
        install {
            set dir [file join [tcl::pkgconfig get libdir,runtime] tcl8 8.6]
            if {[file extension $filename] eq ".tm"} {
                # We already are a .tm with version number
                set target $filename
            } else {
                set target [file rootname $filename]-[promise::version].tm
            }
            file copy -force [info script] [file join $dir $target]
        }
        default {
            puts stderr "Unknown option/command \"[lindex $::argv 0]\""
            exit 1
        }
    }
}
