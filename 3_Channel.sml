structure EventSystemWithChannels =
struct
  datatype Priority = Low | Medium | High

  datatype Event = LogEvent of string * Priority
                 | AlertEvent of string * Priority
                 | DataEvent of int * Priority

  (* Simulated Channel *)
  structure Channel =
  struct
    type 'a channel = 'a list ref * 'a list ref

    fun new () : 'a channel = (ref [], ref [])

    fun send ((_, back), x) = back := x :: !back

    fun receive (front, back) =
      case !front of
        [] => 
          (case List.rev (!back) of
             [] => NONE
           | x::xs => (front := xs; back := []; SOME x))
      | x::xs => (front := xs; SOME x)
  end

  val eventChannel : Event Channel.channel = Channel.new()

  (* Priority Queue implementation *)
  structure PriorityQueue =
  struct
    type queue = Event list

    val empty = []

    fun getPriority (LogEvent(_, p)) = p
      | getPriority (AlertEvent(_, p)) = p
      | getPriority (DataEvent(_, p)) = p

    fun insert queue event =
      let
        fun insert' [] = [event]
          | insert' (e::es) =
            case (getPriority event, getPriority e) of
              (High, High) => event :: e :: es
            | (High, _) => event :: e :: es
            | (Medium, Low) => event :: e :: es
            | _ => e :: insert' es
      in
        insert' queue
      end

    fun fifoInsert queue event = queue @ [event]

    fun remove [] = NONE
      | remove (e::es) = SOME(e, es)
  end

  val priorityQueue : PriorityQueue.queue ref = ref PriorityQueue.empty
  val usePriority = ref true
  val totalDelayCost = ref 0.0

  (* Function to publish events *)
  fun publishEvent event =
    Channel.send (eventChannel, event)

  (* Function to process events from the channel *)
  fun processEvents () =
    case Channel.receive eventChannel of
      SOME event =>
        let
          val _ = if !usePriority
                  then priorityQueue := PriorityQueue.insert (!priorityQueue) event
                  else priorityQueue := PriorityQueue.fifoInsert (!priorityQueue) event
          (* Process immediately if it's a high priority event or if the queue is getting full *)
          val shouldProcessNow = 
            case event of
              AlertEvent(_, High) => true
            | _ => List.length(!priorityQueue) > 5
        in
          if shouldProcessNow then (processNextEvent (); ()) else ();
          processEvents ()
        end
    | NONE => ()

  and processNextEvent () =
    case PriorityQueue.remove (!priorityQueue) of
      SOME (event, newQueue) => 
        (priorityQueue := newQueue;
         processEvent event;
         true)
    | NONE => false

  (* Event processing function remains the same *)
  and processEvent (LogEvent (s, p)) =
    (print ("Log event: " ^ s ^ " (Priority: " ^ 
           (case p of Low => "Low" | Medium => "Medium" | High => "High") ^ ")\n");
     OS.Process.sleep(Time.fromMilliseconds (Int.toLarge 50)))
    | processEvent (AlertEvent (s, p)) =
    let
      val baseTime = 30
      val delayPenalty = if not (!usePriority) andalso p = High then 100 else 0
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

  (* Function to run a demonstration *)
  fun runDemo isPriority =
    let
      val _ = priorityQueue := PriorityQueue.empty
      val _ = usePriority := isPriority
      val _ = totalDelayCost := 0.0
      val _ = print (if isPriority then "\n--- Priority Queue ---\n" else "\n--- FIFO Queue ---\n")
      val startTime = Time.now()
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
      val _ = processEvents ()
      val endTime = Time.now()
      val processingTime = Time.toReal(Time.-(endTime, startTime))
    in
      print ("\nTotal processing time: " ^ Real.toString processingTime ^ " seconds\n");
      print ("Additional delay cost: " ^ Real.toString (!totalDelayCost / 1000.0) ^ " seconds\n");
      print ("Effective total time: " ^ Real.toString (processingTime + !totalDelayCost / 1000.0) ^ " seconds\n")
    end

  (* Main function to demonstrate both modes *)
  fun main () =
    (runDemo true; runDemo false)
end

val _ = EventSystemWithChannels.main()