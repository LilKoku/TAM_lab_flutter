import 'package:flutter/material.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String selectedFilter = "wszystkie";

  @override
  Widget build(BuildContext context) {

    List<Task> filteredTasks = TaskRepository.tasks;

    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks
          .where((task) => task.done)
          .toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = TaskRepository.tasks
          .where((task) => !task.done)
          .toList();
    }

    int doneTasks =
        TaskRepository.tasks.where((task) => task.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: TaskRepository.tasks.isEmpty
                ? null
                : () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Potwierdzenie"),
                    content: const Text(
                      "Czy na pewno chcesz usunąć wszystkie zadania?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Anuluj"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            TaskRepository.tasks.clear();
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Usunięto wszystkie zadania",
                              ),
                            ),
                          );
                        },
                        child: const Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {

          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(),
            ),
          );

          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Masz dziś ${TaskRepository.tasks.length} zadania (wykonane: $doneTasks)",
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                FilterButton(
                  title: "Wszystkie",
                  active: selectedFilter == "wszystkie",
                  onTap: () {
                    setState(() {
                      selectedFilter = "wszystkie";
                    });
                  },
                ),

                FilterButton(
                  title: "Do zrobienia",
                  active: selectedFilter == "do zrobienia",
                  onTap: () {
                    setState(() {
                      selectedFilter = "do zrobienia";
                    });
                  },
                ),

                FilterButton(
                  title: "Wykonane",
                  active: selectedFilter == "wykonane",
                  onTap: () {
                    setState(() {
                      selectedFilter = "wykonane";
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
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {

                  final task = filteredTasks[index];

                  return Dismissible(
                    key: ValueKey(task.title),
                    direction: DismissDirection.endToStart,

                    onDismissed: (direction) {

                      setState(() {
                        TaskRepository.tasks.remove(task);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Usunięto: ${task.title}",
                          ),
                        ),
                      );
                    },

                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),

                    child: TaskCard(
                      title: task.title,
                      subtitle:
                      "termin: ${task.deadline} | priorytet: ${task.priority}",

                      done: task.done,

                      onChanged: (value) {
                        setState(() {
                          task.done = value!;
                        });
                      },

                      onTap: () async {

                        final Task? updatedTask =
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditTaskScreen(task: task),
                          ),
                        );

                        if (updatedTask != null) {
                          setState(() {

                            final originalIndex =
                            TaskRepository.tasks.indexOf(task);

                            TaskRepository.tasks[originalIndex] =
                                updatedTask;
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
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor:
          active ? Colors.blue : Colors.grey.shade300,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {

  AddTaskScreen({super.key});

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController deadlineController =
  TextEditingController();

  final TextEditingController priorityController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nowe zadanie"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {

                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );

                Navigator.pop(context, newTask);
              },

              child: const Text("Zapisz"),
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

  late final TextEditingController titleController =
  TextEditingController(text: task.title);

  late final TextEditingController deadlineController =
  TextEditingController(text: task.deadline);

  late final TextEditingController priorityController =
  TextEditingController(text: task.priority);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edytuj zadanie"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {

                final updatedTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                );

                Navigator.pop(context, updatedTask);
              },

              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskRepository {

  static List<Task> tasks = [

    Task(
      title: "Prezentacja na TAM",
      deadline: "jutro",
      done: false,
      priority: "wysoki",
    ),

    Task(
      title: "Raport z labów na AISO",
      deadline: "dzisiaj",
      done: true,
      priority: "wysoki",
    ),

    Task(
      title: "Nauka na kolokwium z matematyki",
      deadline: "za 7 dni",
      done: false,
      priority: "niski",
    ),

    Task(
      title: "Przeczytać dokumentację Fluttera",
      deadline: "za 3 dni",
      done: false,
      priority: "niski",
    ),
  ];
}

class Task {

  final String title;
  final String deadline;
  bool done;
  final String priority;

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
  final ValueChanged<bool?>? onChanged;
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
      margin: const EdgeInsets.only(bottom: 16),

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
                ? TextDecoration.lineThrough
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

        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}