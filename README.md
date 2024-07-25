# From Streaming Event System to PriML with Channel: An Intro

This directory contains four demonstrations of streaming event system concepts implemented in Standard ML (SML). Each demonstration builds upon the previous one, showcasing different aspects of event processing systems.

## Contents

1. `1_FIFO.sml`: Basic FIFO (First-In-First-Out) queue implementation
2. `2_Priority_FIFO.sml`: Comparison of Priority Queue and FIFO Queue
3. `3_Channel.sml`: Introduction of channel concept for event handling
4. `4_Inversion.sml`: Demonstration of priority inversion in non-preemptive systems

## Streaming Systems and Functional Programming

A streaming system is a software architecture designed to handle and process continuous flows of data in real-time. These systems are crucial in scenarios where data is generated continuously and requires immediate processing, such as in financial trading, IoT sensor data analysis, or real-time analytics.

Implementing streaming systems in a functional programming (FP) paradigm offers several benefits:

1. Immutability: FP's emphasis on immutable data structures reduces side effects and makes it easier to reason about the system's behavior.
2. Composability: FP allows for easy composition of functions, enabling the creation of complex data processing pipelines from simple, reusable components.
3. Concurrency: Many FP languages and paradigms provide robust support for concurrent and parallel processing, which is essential for high-performance streaming systems.
4. Declarative style: FP's declarative nature allows developers to focus on what needs to be done rather than how to do it, often resulting in more concise and readable code.

## The Importance of Message Queues and Priority

A good message queue is fundamental to an effective streaming event system. It serves as a buffer between event producers and consumers, enabling asynchronous processing and decoupling system components. This decoupling enhances system resilience and scalability.

Priority is a crucial feature for a high-performance message queue. As demonstrated in `2_Priority_FIFO.sml`, a priority queue can significantly improve the system's responsiveness to critical events. The output shows:

```
--- Priority Queue ---
Total processing time: 0.671959 seconds
Effective total time: 0.671959 seconds

--- FIFO Queue ---
Total processing time: 1.164825 seconds
Effective total time: 1.664825 seconds
```

This demonstrates that priority-based processing can be more than twice as efficient in handling critical events compared to a simple FIFO approach.

## The Role of Channels

Channels, as introduced in `3_Channel.sml`, play a vital role in event streaming systems:

1. Event Buffering: Channels act as intermediaries between event publishers and consumers.
2. Decoupling: They separate event generation from processing, enhancing system modularity.
3. Asynchronous Behavior: Channels enable asynchronous event handling, even in single-threaded environments.
4. Centralization: They provide a central point for event management, useful for monitoring and system-wide policies.
5. Concurrency Potential: Channels lay the groundwork for true concurrent processing in multi-threaded systems.
6. Flow Control: They can implement backpressure mechanisms to manage system load.
7. Abstraction: Channels abstract the communication mechanism, increasing system flexibility.

While the benefits may not be immediately visible in a simple, single-threaded implementation, channels provide a foundation for building more complex, scalable, and concurrent event processing systems.

## Priority Inversion and Preemptive Scheduling

The concept of priority inversion, demonstrated in `4_Inversion.sml`, highlights a critical challenge in priority-based systems. Priority inversion occurs when a high-priority task is indirectly preempted by a lower-priority task, inverting their relative priorities.

Our system lacks preemptive multitasking, which would be necessary to fully prevent priority inversion. A preemptive scheduling system allows the operating system or runtime environment to interrupt (preempt) a running task to allow a higher-priority task to run. Without preemption, once a low-priority task starts executing, it can't be interrupted even if a high-priority task becomes ready to run.

This lack of preemption is why priority inversion is inevitable in our current implementation. Here's the output from `4_Inversion.sml` that clearly demonstrates this issue:

```
--- Demonstrating Priority Inversion ---
Event published at 5.3E~05s: Data: 100
Event published at 0.01335s: Alert: Critical Error
Processing started at 0.01354s: Data: 100 (Priority: Low, Wait time: 0.013487s)
Processing completed at 0.518833s (Processing time: 0.505293s)
Processing started at 0.519169s: Alert: Critical Error (Priority: High, Wait time: 0.505819s)
Processing completed at 0.57287s (Processing time: 0.053701s)
Priority Inversion Detected: High priority event waited 0.505819s
```

This output shows:

1. A low-priority Data event is published first, followed shortly by a high-priority Alert event.
2. The Data event starts processing almost immediately and takes about 0.5 seconds to complete.
3. Despite its high priority, the Alert event has to wait for the Data event to finish, resulting in a wait time of approximately 0.5 seconds.
4. The system correctly detects and reports this as a priority inversion.

To fully address this issue, we would need:

1. A preemptive scheduling system
2. Support from the runtime or operating system for priority inheritance or similar protocols
3. Careful design of tasks to be interruptible

Understanding these concepts is crucial for designing robust, real-time event processing systems, especially in scenarios where responsiveness to high-priority events is critical. The demonstration in `4_Inversion.sml` provides a clear illustration of how priority inversion can occur in non-preemptive systems, even when using priority queues, and underscores the importance of considering these factors in system design.