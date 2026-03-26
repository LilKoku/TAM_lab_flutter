import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final List<Task> tasks = const [
    Task(
      title:"Prezentacją na TAM",
      deadline:"jutro",
      done: false,
      priority:"wysoki",
    ),

    Task(
      title:"Raport z labów na AISO",
      deadline:"dzisiaj",
      done: true,
      priority:"wysoki",
    ),

    Task(
      title:"Nauka na kolokwium z matematyki",
      deadline:"za 7 dni",
      done: false,
      priority: "niski",
    ),

    Task(
      title:"Przeczytac dokumentację do projektu z Flutera",
      deadline: "za 3 dni",
      done: false,
      priority: "niski",
    ),
  ];
  @override
  Widget build(BuildContext context) {

    int doneTasks = tasks.where((task) => task.done).length;

    return MaterialApp(
      home:Scaffold(
        appBar: AppBar(
          title:const Text("KrakFlow"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Masz dziś ${tasks.length} zadania(wykonane: $doneTasks)",
                style: const TextStyle(
                    fontSize: 20
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Dziśiejsze zadania",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return TaskCard(
                      title:task.title,
                      subtitle:
                      "termin: ${task.deadline} | priorytet: ${task.priority}",
                      icon: task.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  const Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}