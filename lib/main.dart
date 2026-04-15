import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  int doneTasks = TaskRepository.tasks.where((task) => task.done).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Text("KrakFlow"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Masz dziś ${TaskRepository.tasks.length} zadania(wykonane: $doneTasks)",
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
                itemCount: TaskRepository.tasks.length,
                itemBuilder: (context, index) {
                  final task = TaskRepository.tasks[index];

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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {

                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}


class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowe zadanie"),
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





class TaskRepository {
  static List<Task> tasks = [
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