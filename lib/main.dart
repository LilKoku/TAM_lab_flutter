import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/todos"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List todos = data["todos"];

      final random = Random();

      final priorities = [
        "niski",
        "średni",
        "wysoki",
      ];

      final deadlines = [
        "dzisiaj",
        "jutro",
        "za 3 dni",
        "za tydzień",
      ];

      return todos.map((todo) {
        return Task(
          title: todo["todo"],
          deadline:
          deadlines[random.nextInt(deadlines.length)],
          done: todo["completed"],
          priority:
          priorities[random.nextInt(priorities.length)],
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();

    tasksFuture = TaskApiService.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
      ),

      floatingActionButton:
      FloatingActionButton(
        child: const Icon(Icons.add),

        onPressed: () async {
          final Task? newTask =
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddTaskScreen(),
            ),
          );

          if (newTask != null) {
            setState(() {});
          }
        },
      ),

      body: FutureBuilder<List<Task>>(
        future: tasksFuture,

        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Błąd: ${snapshot.error}",
              ),
            );
          }

          // DATA
          final tasks = snapshot.data ?? [];

          List<Task> filteredTasks = tasks;

          if (selectedFilter ==
              "wykonane") {
            filteredTasks = tasks
                .where((task) => task.done)
                .toList();
          } else if (selectedFilter ==
              "do zrobienia") {
            filteredTasks = tasks
                .where((task) => !task.done)
                .toList();
          }

          int doneTasks = tasks
              .where((task) => task.done)
              .length;

          return Padding(
            padding:
            const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  "Masz dziś ${tasks.length} zadania "
                      "(wykonane: $doneTasks)",

                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    FilterButton(
                      title: "Wszystkie",

                      active:
                      selectedFilter ==
                          "wszystkie",

                      onTap: () {
                        setState(() {
                          selectedFilter =
                          "wszystkie";
                        });
                      },
                    ),

                    FilterButton(
                      title: "Do zrobienia",

                      active:
                      selectedFilter ==
                          "do zrobienia",

                      onTap: () {
                        setState(() {
                          selectedFilter =
                          "do zrobienia";
                        });
                      },
                    ),

                    FilterButton(
                      title: "Wykonane",

                      active:
                      selectedFilter ==
                          "wykonane",

                      onTap: () {
                        setState(() {
                          selectedFilter =
                          "wykonane";
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Dzisiejsze zadania",

                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    itemCount:
                    filteredTasks.length,

                    itemBuilder:
                        (context, index) {
                      final task =
                      filteredTasks[index];

                      return TaskCard(
                        title: task.title,

                        subtitle:
                        "termin: ${task.deadline} "
                            "| priorytet: ${task.priority}",

                        done: task.done,

                        onChanged: (value) {
                          setState(() {
                            task.done = value!;
                          });
                        },

                        onTap: () async {
                          final Task?
                          updatedTask =
                          await Navigator
                              .push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                  EditTaskScreen(
                                    task: task,
                                  ),
                            ),
                          );

                          if (updatedTask !=
                              null) {
                            setState(() {
                              final index =
                              tasks.indexOf(
                                  task);

                              tasks[index] =
                                  updatedTask;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(right: 8),

      child: TextButton(
        onPressed: onTap,

        style: TextButton.styleFrom(
          backgroundColor: active
              ? Colors.purple
              : Colors.grey.shade300,
        ),

        child: Text(
          title,

          style: TextStyle(
            color: active
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController
  titleController =
  TextEditingController();

  final TextEditingController
  deadlineController =
  TextEditingController();

  final TextEditingController
  priorityController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Nowe zadanie"),
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: titleController,

              decoration:
              const InputDecoration(
                labelText: "Tytuł",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller:
              deadlineController,

              decoration:
              const InputDecoration(
                labelText: "Termin",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller:
              priorityController,

              decoration:
              const InputDecoration(
                labelText: "Priorytet",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title:
                  titleController.text,

                  deadline:
                  deadlineController
                      .text,

                  done: false,

                  priority:
                  priorityController
                      .text,
                );

                Navigator.pop(
                    context, newTask);
              },

              child: const Text(
                "Zapisz",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;

  EditTaskScreen({
    super.key,
    required this.task,
  });

  late final TextEditingController
  titleController =
  TextEditingController(
    text: task.title,
  );

  late final TextEditingController
  deadlineController =
  TextEditingController(
    text: task.deadline,
  );

  late final TextEditingController
  priorityController =
  TextEditingController(
    text: task.priority,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Edytuj zadanie"),
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: titleController,

              decoration:
              const InputDecoration(
                labelText: "Tytuł",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller:
              deadlineController,

              decoration:
              const InputDecoration(
                labelText: "Termin",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller:
              priorityController,

              decoration:
              const InputDecoration(
                labelText: "Priorytet",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final updatedTask =
                Task(
                  title:
                  titleController.text,

                  deadline:
                  deadlineController
                      .text,

                  done: task.done,

                  priority:
                  priorityController
                      .text,
                );

                Navigator.pop(
                  context,
                  updatedTask,
                );
              },

              child: const Text(
                "Zapisz zmiany",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  String title;
  String deadline;
  bool done;
  String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final ValueChanged<bool?>?
  onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
      const EdgeInsets.only(bottom: 16),

      child: ListTile(
        onTap: onTap,

        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),

        title: Text(
          title,

          style: TextStyle(
            decoration: done
                ? TextDecoration
                .lineThrough
                : TextDecoration.none,

            color: done
                ? Colors.grey
                : Colors.black,
          ),
        ),

        subtitle: Text(
          subtitle,

          style: TextStyle(
            color: done
                ? Colors.grey
                : Colors.black54,
          ),
        ),

        trailing:
        const Icon(Icons.chevron_right),
      ),
    );
  }
}