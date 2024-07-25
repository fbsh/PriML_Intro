structure EventSystemDemo =
struct
  datatype Priority = Low | Medium | High

  datatype Event = LogEvent of string * Priority
                 | AlertEvent of string * Priority
                 | DataEvent of int * Priority

  (* Queue implementation with switchable priority/FIFO behavior *)
  structure Queue =
  struct
    type item = Event * Real.real  (* Event and timestamp *)
    type queue = item list

    val empty = []

    fun priorityInsert queue (event, timestamp) =
      let
        fun getPriority (LogEvent(_, p)) = p
          | getPriority (AlertEvent(_, p)) = p
          | getPriority (DataEvent(_, p)) = p
        
        fun insert' [] = [(event, timestamp)]
          | insert' ((e, t)::rest) =
            case (getPriority event, getPriority e) of
              (High, High) => if Real.<(timestamp, t) then (event, timestamp)::(e, t)::rest
                              else (e, t)::insert' rest
            | (High, _) => (event, timestamp)::(e, t)::rest
            | (Medium, Low) => (event, timestamp)::(e, t)::rest
            | _ => (e, t)::insert' rest
      in
        insert' queue
      end

    fun fifoInsert queue (event, timestamp) = queue @ [(event, timestamp)]

    fun remove [] = NONE
      | remove ((e, _)::rest) = SOME(e, rest)

    fun isEmpty [] = true
      | isEmpty _ = false
  end

  val eventQueue : Queue.queue ref = ref Queue.empty
  val usePriority = ref true  (* Switch between priority and FIFO *)
  val totalDelayCost = ref 0.0  (* To track additional cost for delayed high-priority events *)

  (* Function to publish events *)
  fun publishEvent event =
    let val timestamp = Time.toReal(Time.now())
        val insertFn = if !usePriority then Queue.priorityInsert else Queue.fifoInsert
    in eventQueue := insertFn (!eventQueue) (event, timestamp)
    end

  (* Function to process the next event *)
  fun processNextEvent processFunc =
    case Queue.remove (!eventQueue) of
      SOME (event, newQueue) => 
        (eventQueue := newQueue;
         processFunc event;
         true)
    | NONE => false

  (* Modified event processing function with variable processing time *)
  fun processEvent (LogEvent (s, p)) =
    (print ("Log event: " ^ s ^ " (Priority: " ^ 
           (case p of Low => "Low" | Medium => "Medium" | High => "High") ^ ")\n");
     OS.Process.sleep(Time.fromMilliseconds (Int.toLarge 50)))
    | processEvent (AlertEvent (s, p)) =
    let
      val baseTime = 30  (* Base processing time for alerts *)
      val delayPenalty = if not (!usePriority) andalso p = High 
                         then 100 else 0  (* Penalty for delayed high-priority alerts in FIFO *)
      val processingTime = baseTime + delayPenalty
    in
      (print ("Alert event: " ^ s ^ " (Priority: " ^ 
             (case p of Low => "Low" | Medium => "Medium" | High => "High") ^ ")\n");
       OS.Process.sleep(Time.fromMilliseconds (Int.toLarge processingTime));
       totalDelayCost := !totalDelayCost + Real.fromInt delayPenalty)
    end
    | processEvent (DataEvent (i, p)) =
    (print ("Data event: " ^ Int.toString i ^ " (Priority: " ^ 
           (case p of Low => "Low" | Medium => "Medium" | High => "High") ^ ")\n");
     OS.Process.sleep(Time.fromMilliseconds (Int.toLarge 80)))

  (* Function to measure total processing time *)
  fun processBatch () =
    let
      val startTime = Time.now()
      fun processAll () =
        if processNextEvent processEvent
        then processAll ()
        else ()
      val _ = processAll ()
      val endTime = Time.now()
    in
      Time.toReal(Time.-(endTime, startTime))
    end

  (* Function to run a demonstration *)
  fun runDemo isPriority =
    let
      val _ = eventQueue := Queue.empty
      val _ = usePriority := isPriority
      val _ = totalDelayCost := 0.0
      val _ = print (if isPriority then "\n--- Priority Queue ---\n" else "\n--- FIFO Queue ---\n")
      val _ = publishEvent (LogEvent ("System startup", Low))
      val _ = publishEvent (DataEvent (42, Low))
      val _ = publishEvent (AlertEvent ("High CPU usage", High))
      val _ = publishEvent (LogEvent ("User login", Low))
      val _ = publishEvent (DataEvent (100, Medium))
      val _ = publishEvent (AlertEvent ("Database error", High))
      val _ = publishEvent (LogEvent ("Cache miss", Medium))
      val _ = publishEvent (DataEvent (200, Low))
      val _ = publishEvent (AlertEvent ("Memory leak detected", High))
      val _ = publishEvent (AlertEvent ("Network latency spike", High))
      val _ = publishEvent (DataEvent (300, Low))
      val _ = publishEvent (AlertEvent ("Disk space critical", High))
      val processingTime = processBatch ()
    in
      print ("\nTotal processing time: " ^ Real.toString processingTime ^ " seconds\n");
      print ("Additional delay cost: " ^ Real.toString (!totalDelayCost / 1000.0) ^ " seconds\n");
      print ("Effective total time: " ^ Real.toString (processingTime + !totalDelayCost / 1000.0) ^ " seconds\n")
    end

  (* Main function to demonstrate both modes *)
  fun main () =
    let
      val _ = runDemo true   (* Run with priority queue *)
      val _ = runDemo false  (* Run with FIFO queue *)
    in
      ()
    end
end

(* Run the main function *)
val _ = EventSystemDemo.main()