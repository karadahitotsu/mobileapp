import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InitialPage(),
    );
  }
}

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  Future<String?> _getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getAccessToken(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error occurred');
        } else {
          final accessToken = snapshot.data;
          if (accessToken == null || accessToken.isEmpty) {
            return const AuthPage();
          } else {
            return const TodoListPage();
          }
        }
      },
    );
  }
}
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/authorization'),
        headers:{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Предположим, что токен возвращается в теле ответа
        final responseBody = jsonDecode(response.body);
        final String status = responseBody['status'];
        if(status=="completed"){
          final String accessToken = responseBody['token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const InitialPage()),
          );
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка авторизации: '+ status)),
          );
        };


      } else {
        // Обработка ошибок
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка авторизации')),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите пароль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                  );
                },
                child:const Text('Registration'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/create_user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String status = responseBody['status'];

        if (status == "completed") {


          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const InitialPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка регистрации: $status')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка регистрации: ${response.statusCode}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  _TodoListPageState createState() => _TodoListPageState();
}
class _TodoListPageState extends State<TodoListPage> {
  List<Task> tasks = [];
  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
          actions: [
          IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
    },
    icon: Icon(Icons.account_circle),
    ),
  ],
  ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (BuildContext context, int index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(task.dueDate),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _completeTask(task.id);
                  },
                  child: const Text('Complete'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context);
        },
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                // Навигация на страницу привычек
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HabitsPage()),
                );

              },
              icon: Icon(Icons.list_alt),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: const Text('Select Date'),
                      ),
                      Text(selectedDate.toString().split(' ')[0]),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _addTaskToServer(context, selectedDate, titleController.text, descriptionController.text);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addTaskToServer(BuildContext context, DateTime selectedDate, String title, String description) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/createTask'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        "token": token,
        'title': title,
        'description': description,
        'dueDate': selectedDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      // Задача успешно добавлена на сервер
      Navigator.of(context).pop();
      _fetchTasks();// Закрываем диалоговое окно
    } else {
      // Произошла ошибка при добавлении задачи на сервер
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add task: ${response.statusCode}'),
        ),
      );
    }
  }
  Future<void> _fetchTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/getTask'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': token!,
      }),
    );

    if (response.statusCode == 200) {
      final tasksJson = jsonDecode(response.body)['tasks'] as List<dynamic>;
      setState(() {
        tasks = tasksJson.map((taskJson) => Task.fromJson(taskJson)).toList();
      });
    } else {
      // Обработка ошибок при загрузке задач
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tasks: ${response.statusCode}'),
        ),
      );
    }
  }
  Future<void> _completeTask(int taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/updateTask'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'token': token!,
        'id': taskId,
      }),
    );

    if (response.statusCode == 200) {
      // Задача успешно завершена
      _fetchTasks(); // Обновляем список задач
    } else {
      // Обработка ошибок при завершении задачи
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete task: ${response.statusCode}'),
        ),
      );
    }
  }
}

class Task {
  final int id;
  final String title;
  final String description;
  final String dueDate;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: json['dueDate'] as String,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  int? level;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/getProfile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'token': token!,
      }),
    );

    if (response.statusCode == 200) {
      final profileData = jsonDecode(response.body);
      setState(() {
        username = profileData['username'];
        email = profileData['email'];
        level = profileData['level']['level'];
      });
    } else {
      // Обработка ошибок при загрузке профиля
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (username != null) Text('Username: $username'),
            if (email != null) Text('Email: $email'),
            if (level != null) Text('Level: $level'),
          ],
        ),
      ),
    );
  }
}


class HabitsPage extends StatefulWidget {
  const HabitsPage({Key? key}) : super(key: key);

  @override
  _HabitsPageState createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  List<Habit> habits = [];

  @override
  void initState() {
    super.initState();
    _fetchHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habits'),
      ),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (BuildContext context, int index) {
          final habit = habits[index];
          return ListTile(
            title: Text(habit.title),
            subtitle: Text(habit.description),
            trailing: Text(habit.frequency),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddHabitDialog(context);
        },
        tooltip: 'Add Habit',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController frequencyController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Habit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  TextFormField(
                    controller: frequencyController,
                    decoration: InputDecoration(labelText: 'Frequency'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      _addHabitToServer(
                        titleController.text,
                        descriptionController.text,
                        frequencyController.text,
                        selectedDate,
                      );
                    },
                    child: Text('Add Habit'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addHabitToServer(String title, String description, String frequency, DateTime dueDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/createHabit'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        "token": token,
        'title': title,
        'description': description,
        'frequency': frequency,
      }),
    );

    if (response.statusCode == 200) {
      // Привычка успешно добавлена на сервер
      Navigator.of(context).pop(); // Закрываем модальное окно
      _fetchHabits(); // Обновляем список привычек
    } else {
      // Произошла ошибка при добавлении привычки на сервер
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add habit: ${response.statusCode}'),
        ),
      );
    }
  }

  Future<void> _fetchHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/getHabit'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': token!,
      }),
    );

    if (response.statusCode == 200) {
      final habitsJson = jsonDecode(response.body)['habits'] as List<dynamic>;
      setState(() {
        habits = habitsJson.map((habitJson) => Habit.fromJson(habitJson)).toList();
      });
    } else {
      // Обработка ошибок при загрузке привычек
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load habits: ${response.statusCode}'),
        ),
      );
    }
  }
}

class Habit {
  final String title;
  final String description;
  final String frequency;
  //final String nextComplete;

  Habit({
    required this.title,
    required this.description,
    required this.frequency,
    //required this.nextComplete,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: json['frequency'] as String,
      //nextComplete: json['nextComplete'] as String,
    );
  }
}