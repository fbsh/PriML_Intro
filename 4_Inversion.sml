structure EventSystemWithClearInversionDemo =
struct
  datatype Priority = Low | Medium | High

  datatype Event = LogEvent of string * Priority * Real.real
                 | AlertEvent of string * Priority * Real.real
                 | DataEvent of int * Priority * Real.real

  exception PriorityInversion of string

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

  (* Modify PriorityQueue to work with the new Event type *)
  structure PriorityQueue =
  struct
    type queue = Event list

    val empty = []

    fun getPriority (LogEvent(_, p, _)) = p
      | getPriority (AlertEvent(_, p, _)) = p
      | getPriority (DataEvent(_, p, _)) = p

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

    fun remove [] = NONE
      | remove (e::es) = SOME(e, es)
  end

  val priorityQueue : PriorityQueue.queue ref = ref PriorityQueue.empty
  val currentEvent : Event option ref = ref NONE
  val systemStartTime = ref (Time.now())

  fun getCurrentTime () =
    Time.toReal(Time.-(Time.now(), !systemStartTime))

  (* Function to publish events *)
  fun publishEvent event =
    let
      val timestamp = getCurrentTime()
      val timedEvent =
        case event of
          LogEvent(s, p, _) => LogEvent(s, p, timestamp)
        | AlertEvent(s, p, _) => AlertEvent(s, p, timestamp)
        | DataEvent(i, p, _) => DataEvent(i, p, timestamp)
    in
      (print ("Event published at " ^ Real.toString timestamp ^ "s: " ^
              (case timedEvent of
                 LogEvent(s, _, _) => "Log: " ^ s
               | AlertEvent(s, _, _) => "Alert: " ^ s
               | DataEvent(i, _, _) => "Data: " ^ Int.toString i) ^ "\n");
       Channel.send (eventChannel, timedEvent))
    end

  (* Function to process events from the channel *)
  fun processEvents () =
    case Channel.receive eventChannel of
      SOME event =>
        (priorityQueue := PriorityQueue.insert (!priorityQueue) event;
         processNextEvent ();
         processEvents ())
    | NONE => ()

  and processNextEvent () =
    case PriorityQueue.remove (!priorityQueue) of
      SOME (event, newQueue) => 
        (priorityQueue := newQueue;
         currentEvent := SOME event;
         processEvent event;
         currentEvent := NONE)
    | NONE => ()

  and processEvent event =
    let
      val startTime = getCurrentTime()
      val (description, priority, publishTime) =
        case event of
          LogEvent(s, p, t) => (s, p, t)
        | AlertEvent(s, p, t) => (s, p, t)
        | DataEvent(i, p, t) => (Int.toString i, p, t)
      val waitTime = startTime - publishTime
    in
      (print ("Processing started at " ^ Real.toString startTime ^ "s: " ^
              (case event of
                 LogEvent _ => "Log: "
               | AlertEvent _ => "Alert: "
               | DataEvent _ => "Data: ") ^ description ^ 
              " (Priority: " ^ (case priority of Low => "Low" | Medium => "Medium" | High => "High") ^ 
              ", Wait time: " ^ Real.toString waitTime ^ "s)\n");
       case event of
         DataEvent _ => OS.Process.sleep(Time.fromMilliseconds (Int.toLarge 500))
       | _ => OS.Process.sleep(Time.fromMilliseconds (Int.toLarge 50));
       let val endTime = getCurrentTime()
           val processTime = endTime - startTime
       in
         print ("Processing completed at " ^ Real.toString endTime ^ "s " ^
                "(Processing time: " ^ Real.toString processTime ^ "s)\n");
         if priority = High andalso waitTime > 0.1 then  (* Threshold for considering it an inversion *)
           print ("Priority Inversion Detected: High priority event waited " ^ 
                  Real.toString waitTime ^ "s\n")
         else ()
       end)
    end

  (* Function to run a demonstration *)
  fun runDemo () =
    (systemStartTime := Time.now();
     print "\n--- Demonstrating Priority Inversion ---\n";
     publishEvent (DataEvent (100, Low, 0.0));
     OS.Process.sleep(Time.fromMilliseconds (Int.toLarge 10));  (* Short delay *)
     publishEvent (AlertEvent ("Critical Error", High, 0.0));
     processEvents ())

  (* Main function *)
  val main = runDemo
end

val _ = EventSystemWithClearInversionDemo.main ()