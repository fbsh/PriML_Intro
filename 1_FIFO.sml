structure SimpleEventSystem =
struct
  datatype Priority = Low | Medium | High

  datatype Event = StringEvent of string * Priority
                 | IntEvent of int * Priority

  (* Simple queue implementation *)
  structure Queue =
  struct
    type 'a queue = 'a list * 'a list

    val empty = ([], [])

    fun enqueue ((front, back), x) = (front, x::back)

    fun dequeue ([], []) = NONE
      | dequeue ([], back) = dequeue (rev back, [])
      | dequeue (x::front, back) = SOME(x, (front, back))

    fun isEmpty ([], []) = true
      | isEmpty _ = false
  end

  val eventQueue : Event Queue.queue ref = ref Queue.empty

  (* Function to publish events *)
  fun publishEvent event =
    eventQueue := Queue.enqueue (!eventQueue, event)

  (* Function to process the next event *)
  fun processNextEvent processFunc =
    case Queue.dequeue (!eventQueue) of
      SOME (event, newQueue) => 
        (eventQueue := newQueue;
         processFunc event;
         true)
    | NONE => false

  (* Example event processing function *)
  fun printEvent (StringEvent (s, p)) =
    print ("String event: " ^ s ^ " (Priority: " ^ 
           (case p of Low => "Low" | Medium => "Medium" | High => "High") ^ ")\n")
    | printEvent (IntEvent (i, p)) =
    print ("Int event: " ^ Int.toString i ^ " (Priority: " ^ 
           (case p of Low => "Low" | Medium => "Medium" | High => "High") ^ ")\n")

  (* Main function to demonstrate usage *)
  fun main () =
    let
      val _ = publishEvent (StringEvent ("Low priority", Low))
      val _ = publishEvent (IntEvent (42, High))
      val _ = publishEvent (StringEvent ("Medium priority", Medium))
      fun processAll () =
        if processNextEvent printEvent
        then processAll ()
        else ()
    in
      processAll ()
    end
end

(* Run the main function *)
val _ = SimpleEventSystem.main()