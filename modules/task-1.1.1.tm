namespace eval ::task {
  variable id    0
  variable evals 0
}

proc ::task::init {} {
  coroutine ::task::task ::task::taskman new
}

# kill the task and all tasks within it cleanly (although not very efficiently right now).
proc ::task::kill {} {
  ::task -cancel [::task -info ids]
  catch {
    rename ::task::task {}
  }
}

proc ::task::evaluate args { tailcall ::task::task $args }

proc ::task::cmdlist args { join $args \; }

proc ::task::time args {
  if {[llength $args] == 1} {
    if { [string is entier -strict $args] } {
      return $args
    }
    set args [lindex $args 0]
  } else {
    set args [string tolower $args]
  }
  return [expr { [clock add 0 {*}$args] * 1000 }]
}

proc ::task args {
  if { [info commands ::task::task] eq {} } {
    ::task::init
  }
  set now [clock milliseconds]
  set execution_time $now
  set action create
  set current {}
  foreach arg $args {
    if { $current ni [list flag flags] } {
      if { [string equal [string index $arg 0] "-"] } {
        set current [string range $arg 1 end]
        switch -glob -- $current {
          ca*   - k*   { set action cancel }
          glob         { lappend flags -all -glob   }
          regex*       { lappend flags -all -regexp }
        }
        continue
      }
    }
    switch -glob -- $current {
      inject { lappend script $arg }
      id     { lappend task_id $arg }
      ids    { lappend task_id {*}$arg }
      in     { set execution_time [expr { $now + [::task::time $arg] }] }
      at     {
        if { [string length $arg] < [string length $now] } {
          # We assume this is seconds since it couldnt be milliseconds :-P
          set execution_time [expr { $arg * 1000 }]
        } else {
          set execution_time $arg
        }
      }
      regex* - glob {
        if { [string is false $arg] } {
          set flags [lsearch -all -inline -not -exact $flags -all]
          switch -glob -- $current {
            r* { set flags [lsearch -all -inline -not -exact $flags -regexp] }
            g* { set flags [lsearch -all -inline -not -exact $flags -glob] }
          }
        }
      }
      delay - dela* {
        # delay the execution time of a current id
        dict set task delay_execution $arg
      }
      every - e*  {
        dict set task every $arg
        set execution_time [expr { $now + [::task::time $arg] }]
      }
      while - w*  { dict set task while $arg }
      info  - i* {
        if { $action eq "create" } { set action info }
        set info $arg
      }
      flag  { lappend flags $arg    }
      flags { lappend flags {*}$arg }
      cancel  - kill - ca* - k* { lappend task_id $arg }
      command - c* { dict set task cmd $arg   }
      times   - t* { dict set task times $arg }
      until   - u* { dict set task until $arg }
      for     - f* { dict set task until [expr { $now + [::task::time $arg] }] }
      subst   - s* {
        if { [string is bool -strict $arg] && $arg } {
          dict set task subst 1
        }
      }
      default {
        throw error "$current is an unknown task argument.  Must be one of \"-id, -in, -at, -every, -while, -times, -until, -command, -info, -subst, -cancel\""
      }
    }
    set current {}
  }

  # If we have any flags and we are sending a task, attach them to the task
  if { [info exists flags] && [info exists task] } {
    dict set task flags $flags
  }

  switch -- $action {
    create {
      if { [info exists task] } {
        if { ! [info exists task_id] || $task_id eq {} } {
          lappend task_id task#[incr ::task::id]
        }
        foreach id $task_id {
          lappend script [list ::task::add_task $id $task $execution_time]
        }
      } else {
        throw INVALID_TASK_ARGS "The requested task can not be created, are you missing the -command argument?  | $args"
      }
    }
    cancel {
      if { ! [info exists task_id] || $task_id eq {} } {
        throw error "-id argument required when cancelling a task"
      }
      if { ! [info exists flags] } {
        set flags [list]
      }
      if { ! [info exists info] } {
        set info total
      }
      lappend script [list ::task::remove_tasks $task_id $flags $info]
    }
    info {
      switch -glob -- $info {
        scheduled - s*     { lappend script [list set scheduled]  }
        ids       - i*     { lappend script {dict keys $tasks}    }
        next_time - n*time { lappend script {lindex $scheduled 1} }
        next_id   - n*id   { lappend script {lindex $scheduled 0} }
        next_task - n*task { lappend script { dict get $tasks [lindex $scheduled 0] } }
        next      - n*     { lappend script { list {*}[lrange $scheduled 0 1] [dict get $tasks [lindex $scheduled 0]] } }
        tasks     - t* {
          if { [info exists task_id] } {
            lappend script [format {dict get $tasks {%s}} $task_id]
          } else {
            lappend script [list set tasks]
          }
        }
        default {
          throw error "$info is an unknown info response, you may request one of \"scheduled, tasks\""
        }
      }
    }
  }
  tailcall ::task::evaluate inject [::task::cmdlist {*}$script]
}

proc ::task::taskman args {
  # Run the coroutine asynchronously from the caller
  set coro_response [info coroutine]
  after 0 [info coroutine]
  while 1 {
    incr ::task::evals
    # task will tell us if we need to execute the next task
    set args [lassign $args request]
    # Run any actions before we evaluate the next tasks if necessary
    switch -- $request {
      reset - new {
        # tasks is a dict which holds our tasks.  Its keys are the times that they
        # should execute and their values contain data including the command to
        # execute and any other required context about the task.
        set tasks [dict create]
        # $scheduled is actually a "dict style" list which is sorted so that we
        # can always assume that the next two elements represent the task_id and
        # next_event pair.
        set scheduled [list]
        # $after_id will store the after_id of the coroutine which is set to the
        # next scheduled event. This allows us to cancel it should the tasks
        # change.
        if { [info exists after_id] } {
          after cancel $after_id
        }
        set after_id  {}
        set task_time {}
        set task_scheduled {}
        set task_id {}
        set task {}
        # Our core loop will continually iterate and execute any scheduled tasks
        # that are provided to it.  When it has finished executing the events it will
        # sleep until the next event or until a new task is provided to it.
      }
      inject {
        set coro_response [try [lindex $args 0] on error {} {}]
      }
    }
    while { [next_task] ne {} } {
      # We run in an after so that the execution will not be in our coroutines
      # context anymore.  If we don't do this then we won't be able to schedule
      # tasks within the execution of a task.
      if { [dict exists $task while] } {
        # while is a command to run to test if we should execute the task.  When
        # combined with -every, the command will run until the -while clause is no
        # longer true.  In the case of -in or -at, -while will be a test to check
        # if we still want to execute the event in the case we did not cancel the
        # task for whatever reason.
        try {
          if { [dict exists $task subst] } {
            set should_execute [uplevel #0 [subst -nocommands [dict get $task while]]]
          } else {
            set should_execute [uplevel #0 [dict get $task while]]
          }
          if { ! [string is bool -strict $should_execute] } {
            set should_execute 0
          }
        } on error {r} {
          set should_execute 0
        }
        set cancel_every [expr { ! $should_execute }]
      } else {
        set should_execute 1
        set cancel_every   0
      }

      # If we should still execute the command, we will do so now.
      if { $should_execute } {
        if { [dict exists $task subst] } {
          catch {
            after 0 [subst -nocommands [dict get $task cmd]]
          }
        } else {
          after 0 [list try [dict get $task cmd]]
        }
      }

      if { [dict exists $task every] && ! $cancel_every } {
        # every - we need to schedule the task to occur again
        if { [dict exists $task times] } {
          dict incr task times -1
          if { [dict get $task times] < 1 } {
            continue
          }
        }
        if { [dict exists $task until] && [clock milliseconds] >= [dict get $task until] } {
          continue
        }
        ::task::add_task \
          $task_id \
          $task \
          [expr { [clock milliseconds] + [dict get $task every] }]
      }

    }
    # No need to keep these around while we sleep
    unset -nocomplain task_id
    unset -nocomplain task
    unset -nocomplain task_time
    # We reach here when there are either no more tasks to execute or we need
    # to schedule the next execution evaluation.  $scheduled will tell us this
    # as it will either be {} or the ms until the next event.
    schedule_next
    # We yield and await either the next scheduled task or to be woken up
    # by injection to modify our values.
    set args [yield $coro_response]
    set coro_response [info coroutine]
  }
}

proc ::task::execute { cmd } {

}

# removes a task from the scheduled execution context, responds with the
# value requested.
# respond_with can be: total (total tasks removed) | ids (ids of removed tasks)
proc ::task::remove_tasks { task_ids {flags {}} {respond_with total} } {
  upvar 1 tasks tasks
  upvar 1 scheduled scheduled
  upvar 1 task_scheduled task_scheduled
  set total 0
  set ids   [list]
  foreach task_id $task_ids {
    ::task::remove_task $task_id 0 $flags
  }
  if { $total > 0 } {
    set task_scheduled [expr { [lindex $scheduled 1] - [clock milliseconds] }]
  }
  return [set $respond_with]
}

proc ::task::remove_task { task_id {reschedule 1} {flags {}} } {
  upvar 1 tasks tasks
  upvar 1 scheduled scheduled
  upvar 1 total total
  upvar 1 ids   ids
  # When cancelling, we sort indexes in decreasing order.  This allows us
  # to remove entries without worry that the next match will have changed
  # due to the list changing.
  foreach index [lsort -decreasing -real [lsearch -exact {*}$flags $scheduled $task_id]] {
    if { $index == -1    } {
      break
    }
    # If a value matches in the list we dont want to remove it.
    if { $index % 2 != 0 } {
      continue
    }
    incr total
    set task_id [lindex $scheduled $index]
    lappend ids $task_id
    if { [dict exists $tasks $task_id] } {
      dict unset tasks $task_id
    }
    set scheduled [lreplace $scheduled $index [expr {$index + 1}]]
  }
  if { $reschedule } {
    # We need to reset task_scheduled when this is true
    upvar 1 task_scheduled task_scheduled
    set task_scheduled [expr { [lindex $scheduled 1] - [clock milliseconds] }]
  }
  return
}

# when we add a new task to our tasks list, we will add the context to a hash (dict)
# and our scheduled items to the scheduled list in the order of execution.
proc ::task::add_task { task_id context execution_time } {
  upvar 1 tasks     tasks
  upvar 1 scheduled scheduled
  upvar 1 task_scheduled task_scheduled
  upvar 1 after_id after_id
  if { [dict exists $tasks $task_id] } {
    # If we are scheduling a task with the same id of a previous task
    # then we will remove and cancel the previous task.
    if { [dict exists $context delay_execution] } {
      set execution_time [expr { [dict get $scheduled $task_id] + [dict get $context delay_execution] }]
      set context        [dict get $tasks $task_id]
    }
    remove_task $task_id 0
  }
  if { [dict exists $context cmd] } {
    dict set tasks $task_id $context
    # Add to our event to the list in the appropriate position based on the scheduled time.
    set scheduled [ lsort -stride 2 -index 1 -real [lappend scheduled $task_id $execution_time] ]
  } else {
    # If we appear to have an invalid task (it doesnt have a cmd to execute) we will instead
    # simply sort the scheduled list and schedule next.
    set scheduled [ lsort -stride 2 -index 1 -real $scheduled ]
  }

  set task_scheduled [expr { [lindex $scheduled 1] - [clock milliseconds] }]

  return $task_id
}

# next_event reads the tasks and determines the next time that we should
# wake up.
proc ::task::next_task {} {
  uplevel 1 {
    if { $scheduled eq [list] } {
      set task_id {} ; set task_scheduled {} ; set task {} ; set task_time {}
    } else {
      set task_scheduled [expr { [lindex $scheduled 1] - [clock milliseconds] }]
      if { $task_scheduled <= 0 } {
        # If the event will be executed we will remove them from the scheduled list
        set scheduled [lassign $scheduled task_id task_time]
        set task      [dict get $tasks $task_id]
        dict unset tasks $task_id
      } else {
        set task_id {} ; set task {} ; set task_time {}
      }
    }
    set task_id
  }
}

proc ::task::schedule_next {} {
  upvar 1 task_scheduled task_scheduled
  upvar 1 after_id after_id
  after cancel $after_id
  if { [string is entier -strict $task_scheduled] } {
    # We have an event to execute in the future, we will sleep for the given
    # period of time.
    if { $task_scheduled > 600000 } {
      # If the next task if more than 10 minutes in the future, we will
      # schedule our wakeup in 10 minutes to keep our task manager fresh.
      set task_scheduled 600000
    }
    set after_id [ after $task_scheduled [list catch [list [info coroutine]]] ]
  } else {
    # Nothing to Execute, we will still wakeup in 10 minutes
    set after_id [ after 600000 [list catch [list [info coroutine]]]]
  }
}
