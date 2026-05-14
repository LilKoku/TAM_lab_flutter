import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox("tasks");

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

class Task {
  final int id;
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "deadline": deadline,
      "done": done,
      "priority": priority,
    };
  }

  factory Task.fromMap(Map map) {
    return Task(
      id: map["id"],
      title: map["title"],
      deadline: map["deadline"],
      done: map["done"],
      priority: map["priority"],
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
          id: todo["id"],
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

class TaskLocalDatabase {
  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {
    return _box.values.map((item) {
      return Task.fromMap(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  static Future<void> saveTasks(
      List<Task> tasks,
      ) async {
    await _box.clear();

    for (final task in tasks) {
      await _box.put(
        task.id,
        task.toMap(),
      );
    }
  }

  static Future<void> addTask(
      Task task,
      ) async {
    await _box.put(
      task.id,
      task.toMap(),
    );
  }

  static Future<void> updateTask(
      Task task,
      ) async {
    await _box.put(
      task.id,
      task.toMap(),
    );
  }

  static Future<void> deleteTask(
      int id,
      ) async {
    await _box.delete(id);
  }

  static Future<void> deleteAllTasks() async {
    await _box.clear();
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}

class TaskSyncService {
  static Future<void>
  loadInitialDataIfNeeded() async {
    if (!TaskLocalDatabase.isEmpty()) {
      return;
    }

    final tasks =
    await TaskApiService.fetchTasks();

    await TaskLocalDatabase.saveTasks(tasks);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();

    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService
        .loadInitialDataIfNeeded();

    return TaskLocalDatabase.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_forever,
            ),

            onPressed: () async {
              await TaskLocalDatabase
                  .deleteAllTasks();

              setState(() {
                tasksFuture = loadTasks();
              });
            },
          ),
        ],
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
            await TaskLocalDatabase.addTask(
              newTask,
            );

            setState(() {
              tasksFuture = loadTasks();
            });
          }
        },
      ),

      body: FutureBuilder<List<Task>>(
        future: tasksFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Błąd: ${snapshot.error}",
              ),
            );
          }

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

                      return Dismissible(
                        key: Key(
                          task.id.toString(),
                        ),

                        background:
                        Container(
                          color: Colors.red,
                        ),

                        onDismissed:
                            (_) async {
                          await TaskLocalDatabase
                              .deleteTask(
                            task.id,
                          );

                          setState(() {
                            tasksFuture =
                                loadTasks();
                          });
                        },

                        child: TaskCard(
                          title: task.title,

                          subtitle:
                          "termin: ${task.deadline} "
                              "| priorytet: ${task.priority}",

                          done: task.done,

                          onChanged:
                              (value) async {
                            final updatedTask =
                            Task(
                              id: task.id,
                              title:
                              task.title,
                              deadline:
                              task.deadline,
                              priority:
                              task.priority,
                              done:
                              value ??
                                  false,
                            );

                            await TaskLocalDatabase
                                .updateTask(
                              updatedTask,
                            );

                            setState(() {
                              tasksFuture =
                                  loadTasks();
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
                              await TaskLocalDatabase
                                  .updateTask(
                                updatedTask,
                              );

                              setState(() {
                                tasksFuture =
                                    loadTasks();
                              });
                            }
                          },
                        ),
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
                  id: Random().nextInt(
                    1000000,
                  ),

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
                  context,
                  newTask,
                );
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
                  id: task.id,

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